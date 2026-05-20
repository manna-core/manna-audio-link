$ErrorActionPreference = "Stop"

$ShortcutPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Manna Send Audio.lnk"

if (Test-Path -LiteralPath $ShortcutPath) {
    Remove-Item -LiteralPath $ShortcutPath
    Write-Host "Removed Start Menu shortcut:"
    Write-Host $ShortcutPath
} else {
    Write-Host "Shortcut was not installed:"
    Write-Host $ShortcutPath
}
