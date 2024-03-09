# shell:Local AppData内にVS Code 1.85.2をインストールする

# VS Code 1.85.2のインストール

# ダウンロード

# ダウンロードURL

$url = 'https://update.code.visualstudio.com/1.85.2/win32-x64-archive/stable'

# ダウンロードファイルの保存先

$outfile = "$env:LOCALAPPDATA\VSCode-win32-x64-1.85.2.zip"

# ダウンロード

Invoke-WebRequest -Uri $url -OutFile $outfile

# 展開

# 展開先

$dir = "$env:LOCALAPPDATA\VSCode-win32-x64-1.85.2"

# 展開

Expand-Archive -Path $outfile -DestinationPath $dir

# zipファイルの削除

Remove-Item -Path $outfile

# Portable Modeを有効にする

# dataフォルダの作成

New-Item -Path $dir -Name 'data' -ItemType 'directory'

# スタートメニューに登録する

# ショートカットの作成

$shortcut = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Programs'), 'VS Code 1.85.2.lnk')

$shell = New-Object -ComObject WScript.Shell

$scut = $shell.CreateShortcut($shortcut)

$scut.TargetPath = [System.IO.Path]::Combine($dir, 'Code.exe')

$scut.Save()
