param(
    [string]$Target = "",
    [int]$Port = 44555,
    [double]$Gain = 0.85,
    [int]$BlockMs = 10,
    [string]$InputDevice = ""
)

$ErrorActionPreference = "Stop"

function Get-SenderConfigPath {
    $ConfigDir = Join-Path $env:APPDATA "Manna Audio Link"
    New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
    return (Join-Path $ConfigDir "sender-config.json")
}

if ([string]::IsNullOrWhiteSpace($Target)) {
    $Target = Read-Host "Main PC receiver IP address"
}

if ([string]::IsNullOrWhiteSpace($Target)) {
    throw "A main PC receiver IP address is required."
}

$Config = [ordered]@{
    target = $Target.Trim()
    port = $Port
    gain = $Gain
    block_ms = $BlockMs
    input_device = $InputDevice
}

$ConfigPath = Get-SenderConfigPath
$Config | ConvertTo-Json -Depth 3 | Set-Content -Path $ConfigPath -Encoding UTF8

Write-Host "Saved Manna Send Audio config:"
Write-Host $ConfigPath
Write-Host "Target main PC: $($Config.target):$($Config.port)"
