$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Resolve-MannaPythonw {
    $Candidates = @(
        (Join-Path $Root ".venv\Scripts\pythonw.exe"),
        (Join-Path $Root ".venv\Scripts\python.exe"),
        (Join-Path $Root "python-runtime\pythonw.exe"),
        (Join-Path $Root "python-runtime\python.exe")
    )

    foreach ($Candidate in $Candidates) {
        if (Test-Path -LiteralPath $Candidate) {
            return $Candidate
        }
    }

    throw "Missing Python runtime. Run .\setup.ps1 from source or reinstall Manna Sound Sync."
}

$Pythonw = Resolve-MannaPythonw
$env:PYTHONPATH = Join-Path $Root "src"
Start-Process -FilePath $Pythonw -ArgumentList @("-m", "manna_audio_link.tray_app") -WorkingDirectory $Root -WindowStyle Hidden
