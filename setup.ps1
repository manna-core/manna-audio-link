$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

if (-not (Test-Path -LiteralPath ".venv\Scripts\python.exe")) {
    py -m venv .venv
}

& ".\.venv\Scripts\python.exe" -m pip install --upgrade pip
& ".\.venv\Scripts\python.exe" -m pip install -r requirements.txt

Write-Host ""
Write-Host "Manna Audio Link is ready."
Write-Host "Main PC tray: .\install-start-menu-shortcut.ps1, then search Manna Sound Sync"
Write-Host "Main PC CLI:  .\run-receiver.ps1"
Write-Host "Laptop:  .\configure-sender.ps1, then .\run-sender.ps1"
