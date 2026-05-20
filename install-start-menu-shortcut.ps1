$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Launcher = Join-Path $Root "launch-manna-sound-sync.ps1"
$Programs = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$ShortcutPath = Join-Path $Programs "Manna Sound Sync.lnk"
$PowerShell = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"

if (-not (Test-Path -LiteralPath $Launcher)) {
    throw "Missing launcher: $Launcher"
}

New-Item -ItemType Directory -Force -Path $Programs | Out-Null

$Shell = New-Object -ComObject WScript.Shell
$Shortcut = $Shell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $PowerShell
$Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Launcher`""
$Shortcut.WorkingDirectory = $Root
$Shortcut.Description = "Start the Manna Sound Sync tray receiver"
$Shortcut.IconLocation = "$env:SystemRoot\System32\imageres.dll,233"
$Shortcut.Save()

Write-Host "Installed Start Menu shortcut:"
Write-Host $ShortcutPath
Write-Host ""
Write-Host "Open Windows search and type: Manna Sound Sync"
