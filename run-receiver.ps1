param(
    [int]$Port = 44555,
    [string]$OutputDevice = "",
    [int]$PrebufferPackets = 16,
    [int]$MaxBufferPackets = 120
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

    throw "Missing Python runtime. Run .\setup.ps1 from source or reinstall Manna Sound Sync."
}

$Python = Resolve-MannaPython
$env:PYTHONPATH = Join-Path $Root "src"
$ArgsList = @(
    "-m", "manna_audio_link",
    "receive",
    "--port", "$Port",
    "--prebuffer-packets", "$PrebufferPackets",
    "--max-buffer-packets", "$MaxBufferPackets"
)

if ($OutputDevice.Trim().Length -gt 0) {
    $ArgsList += @("--output-device", $OutputDevice)
}

& $Python @ArgsList
