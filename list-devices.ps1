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

    throw "Missing Python runtime. Run .\setup.ps1 from source or reinstall Manna Audio Link."
}

$Python = Resolve-MannaPython
$env:PYTHONPATH = Join-Path $Root "src"
& $Python -m manna_audio_link devices
