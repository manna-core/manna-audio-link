param(
    [string]$Target = "",
    [int]$Port = 44555,
    [string]$InputDevice = "",
    [int]$BlockMs = 10,
    [double]$Gain = 0.85
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Resolve-MannaPython {
    $Candidates = @(
        (Join-Path $Root ".venv\Scripts\python.exe"),
        (Join-Path $Root "python-runtime\python.exe")
    )

    foreach ($Candidate in $Candidates) {
        if (Test-Path -LiteralPath $Candidate) {
            return $Candidate
        }
    }

    throw "Missing Python runtime. Run .\setup.ps1 from source or reinstall Manna Send Audio."
}

function Get-SenderConfigPath {
    return (Join-Path (Join-Path $env:APPDATA "Manna Audio Link") "sender-config.json")
}

function Read-SenderConfig {
    $ConfigPath = Get-SenderConfigPath
    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        return $null
    }

    try {
        return (Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json)
    } catch {
        throw "Could not read sender config at $ConfigPath. Run .\configure-sender.ps1 to recreate it."
    }
}

if ([string]::IsNullOrWhiteSpace($Target)) {
    $Config = Read-SenderConfig
    if ($null -eq $Config -or [string]::IsNullOrWhiteSpace([string]$Config.target)) {
        throw "Missing sender target. Run .\configure-sender.ps1 or pass -Target MAIN_PC_IP."
    }
    $Target = [string]$Config.target
    if ($Config.PSObject.Properties.Name -contains "port") {
        $Port = [int]$Config.port
    }
    if ($Config.PSObject.Properties.Name -contains "gain") {
        $Gain = [double]$Config.gain
    }
    if ($Config.PSObject.Properties.Name -contains "block_ms") {
        $BlockMs = [int]$Config.block_ms
    }
    if (($Config.PSObject.Properties.Name -contains "input_device") -and -not [string]::IsNullOrWhiteSpace([string]$Config.input_device)) {
        $InputDevice = [string]$Config.input_device
    }
}

$Python = Resolve-MannaPython
$env:PYTHONPATH = Join-Path $Root "src"
$ArgsList = @(
    "-m", "manna_audio_link",
    "send",
    "--target", $Target,
    "--port", "$Port",
    "--block-ms", "$BlockMs",
    "--gain", "$Gain"
)

if ($InputDevice.Trim().Length -gt 0) {
    $ArgsList += @("--input-device", $InputDevice)
}

& $Python @ArgsList
