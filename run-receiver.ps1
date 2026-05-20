param(
    [int]$Port = 44555,
    [string]$OutputDevice = "",
    [int]$PrebufferPackets = 48,
    [int]$MaxBufferPackets = 240,
    [switch]$NormalPriority
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
    "--max-buffer-packets", "$MaxBufferPackets",
    "--reset-after-underruns", "6",
    "--reset-after-gap-seconds", "1.5"
)

if ($OutputDevice.Trim().Length -gt 0) {
    $ArgsList += @("--output-device", $OutputDevice)
}

if (-not $NormalPriority) {
    $ArgText = ($ArgsList | ForEach-Object {
        if ($_ -match '[\s"]') {
            '"' + ($_ -replace '"', '\"') + '"'
        } else {
            $_
        }
    }) -join " "
    $Process = Start-Process -FilePath $Python -ArgumentList $ArgText -WorkingDirectory $Root -NoNewWindow -PassThru
    try {
        $Process.PriorityClass = "High"
        Write-Host "Receiver process priority: High"
    } catch {
        Write-Host "Could not raise receiver process priority: $($_.Exception.Message)"
    }
    Wait-Process -Id $Process.Id
    exit $Process.ExitCode
}

& $Python @ArgsList
