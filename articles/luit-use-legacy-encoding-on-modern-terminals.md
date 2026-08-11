---
title: "luitを使ってUTF-8前提のターミナルでもEUC-JPを使おう！"
emoji: "🍢"
type: "tech"
topics: ["linux", "vscode", "terminal", "encoding"]
published: true
---

## はじめに

まだまだ文字コードにEUC-JPを使っている人はいると思います。

そんな中、ひと昔前とは違って(?)、モダンな端末エミュレータはUTF-8のみ対応していることが多いです。

例えば、私が普段使っているVS Codeの統合ターミナル(LinuxとのSSH接続時)やWindows Terminalも、UTF-8しか扱えません。

私は普段WindowsからSSH接続したLinuxマシンで作業することが多く、今までは標準のLANGがEUC-JPの環境に入るときは、無理やり`export LANG=ja_JP.UTF-8`してから作業するか、nkfを駆使するか、あるいはRloginのようなEUC-JP対応のターミナルエミュレータを使うしかありませんでした。

また、今まで何度もVS Codeの統合ターミナルでEUC-JPの文字を表示しようと試みたのですが、結局どれも上手くいかず、諦めていました。

そんな中、[ターミナルを自作したら、1日のコミット数が500を超えて、生産性がバグった話](https://zenn.dev/singularity/articles/diy-terminal-500-commits)を見ると、VS Codeの統合ターミナルで利用されているxterm.jsの話がありました。

@[card](https://zenn.dev/singularity/articles/diy-terminal-500-commits)

もしかしたら、xterm.jsの中で文字コード変換をしてくれる仕組みがあるのではないかと思い、調べることに。

すると、[Legacy Encodings - xterm.js](https://xtermjs.org/docs/guides/encoding/#legacy-encodings)にxterm.jsはUTF-8しかサポートしていないこと、そしてほかのエンコーディングを使う場合は、luitのような外部ツールを使って変換する必要があることが書かれていました。
まあ、xterm.js側でサポートしていたら、VS Codeの統合ターミナルでもEUC-JPをサポートしますよね。

> `xterm.js` does not support any legacy encoding and probably never will. If you have to deal with older systems or programs that dont understand UTF-8, we strongly suggest to use a streamline transcoder like luit to translate between the foreign encoding and UTF-8. `luit` was designed with terminal data streams in mind and can handle most scenarios with escape sequences correctly.

出典: [Legacy Encodings - xterm.js](https://xtermjs.org/docs/guides/encoding/#legacy-encodings)

luit自体は2000年代前半に登場したようなので、当時からLinuxを使っている方にとっては、luitって馴染みのあるツールなのかもしれません。

では、さっそく、VS Codeの統合ターミナルでEUC-JPを使う方法を紹介します。

## インストール方法

```bash
sudo dnf install luit    # Fedora系
sudo apt install luit    # Debian系
```

## 使用方法

下記のように使用します。

```bash
luit -encoding eucJP -- コマンド
```

頻繁に使う場合は、エイリアスを`~/.bashrc`などに設定しておくと便利です。

```bash
alias eucjp='luit -encoding eucJP --'
```

これで、下記のように使えます。

```bash
eucjp コマンド
```

## VS Codeの統合ターミナルで使う方法

前述のコマンドをVS Codeの統合ターミナルで毎回打つのは面倒なので、`settings.json`にターミナルプロファイルを追加しておくと便利です。

```json:settings.json
"terminal.integrated.profiles.linux": {
  "bash (EUC-JP via luit)": {
    "path": "luit",
    "args": [
      "-encoding",
      "eucJP",
      "--",
      "bash",
      "--login"
    ]
  }
},
```

もし、常にVS Codeの統合ターミナルをluit経由で使いたい場合は、`terminal.integrated.defaultProfile.linux`に上記のプロファイル名を指定します。

```json:settings.json
"terminal.integrated.defaultProfile.linux": "bash (EUC-JP via luit)"
```

## SSHで設定

SSHで接続する場合は、`~/.ssh/config`に下記のように設定しておくと便利です。

対話型のシェルを使うため、RequestTTYをyesに設定し、RemoteCommandでluit経由でbashを起動するようにします。

```text:~/.ssh/config
Host euc-example-1
    HostName 1.example.com
    User username
    RequestTTY yes
    RemoteCommand luit -encoding eucJP -- /bin/bash --login
```

あらかじめ設定しておくことで、設定したホストへSSH接続する際に、luit経由でEUC-JPを使うことができます。

以下は、実際にSSH接続してEUC-JPが使えることを確認した例です。

```bash
client$ ssh euc-example-1                         # SSH接続時に、サーバー側でluit経由のbashを起動

euc-example-1$ echo $LANG                         # LANGがEUC-JPに設定されている環境でも、
ja_JP.eucJP

euc-example-1$ date
2026年  8月 12日 水曜日 01:29:08 JST              # 日付が文字化けせず表示される(=正しくluit経由でEUC-JPが使えている)

euc-example-1$ echo テスト > text-eucjp.txt       # 入力した文字も、

euc-example-1$ nkf -g text-eucjp.txt              # nkfで文字コードを確認すると、EUC-JPで保存されていることがわかる
EUC-JP
```

また、複数のホストで同じ設定を使いたい場合は、`Host`にワイルドカードを使うこともできます。

```text:~/.ssh/config
# EUC-JP環境用のテンプレート設定
Host euc-*
  RequestTTY yes
  RemoteCommand luit -encoding eucJP -- /bin/bash --login

# Host名にeuc-を付けることで、テンプレート設定が適用される
Host euc-example-1
  HostName 1.example.com
  User username

Host euc-example-2
  HostName 2.example.com
  User username
```

## まとめ

いままで何度も調査していた、VS Codeの統合ターミナルでEUC-JPを使う方法が、luitを使うことで解決できました。

そろそろ私自身EUC-JPから卒業したいと思っているのですが、まだまだEUC-JPを使わざるを得ない環境は多いと思います。

現代の標準であるUTF-8に抗うといろいろと不便なこと[^1]が多いですが、luitを使うことで、VS Codeの統合ターミナルでもEUC-JPを使えるようになることがわかりました。

参考になれば幸いです。

[^1]: 例えば、VS CodeでEUC-JPのファイル内に"〜: 波ダッシュ(0xA1 0xC1)"があると、ファイルの保存時に"～: 全角チルダ(0x8F 0xA2 0xB7)"という一般的ではない文字に変換されるなどの問題が起こります。波ダッシュと全角チルダについては、拙作の[Wave Dash Unify](https://marketplace.visualstudio.com/items?itemName=yutotnh.wave-dash-unify)というVS Code拡張機能を使うことで、問題を解決できます。
