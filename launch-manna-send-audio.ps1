$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Sender = Join-Path $Root "run-sender.ps1"
$Configurator = Join-Path $Root "configure-sender.ps1"
$ConfigPath = Join-Path (Join-Path $env:APPDATA "Manna Audio Link") "sender-config.json"

if (-not (Test-Path -LiteralPath $Sender)) {
    throw "Missing sender launcher: $Sender"
}

Set-Location -LiteralPath $Root

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    Write-Host "Manna Send Audio needs the main PC receiver IP once."
    Write-Host "On the main PC, launch Manna Sound Sync, then use Show main PC IPs."
    Write-Host ""
    & $Configurator
    Write-Host ""
}

$Config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
$Target = [string]$Config.target

Write-Host "Manna Send Audio"
Write-Host "Target main PC: $Target"
Write-Host "Press Ctrl+C to stop the sender."
Write-Host ""

& $Sender

Write-Host ""
Write-Host "Manna Send Audio stopped. You can close this window."
