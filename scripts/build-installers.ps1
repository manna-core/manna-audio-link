$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $ProjectRoot

function Copy-Tree {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Source path not found: $Source"
    }

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Copy-Item -Path (Join-Path $Source "*") -Destination $Destination -Recurse -Force
}

function Resolve-Iscc {
    $Command = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($Command) {
        return $Command.Source
    }

    $Candidates = @(
        (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe"),
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        "C:\Program Files\Inno Setup 6\ISCC.exe"
    )

    foreach ($Candidate in $Candidates) {
        if (Test-Path -LiteralPath $Candidate) {
            return $Candidate
        }
    }

    throw "Inno Setup is not installed. Install it with: winget install --id JRSoftware.InnoSetup -e --accept-source-agreements --accept-package-agreements"
}

$PackageVersion = & py -3 -c "import pathlib, tomllib; print(tomllib.loads(pathlib.Path('pyproject.toml').read_text(encoding='utf-8'))['project']['version'])"
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($PackageVersion)) {
    throw "Could not read project version from pyproject.toml."
}
$PackageVersion = $PackageVersion.Trim()

$VenvPython = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
if (-not (Test-Path -LiteralPath $VenvPython)) {
    & py -3 -m venv (Join-Path $ProjectRoot ".venv")
}
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $VenvPython)) {
    throw "Could not create project virtual environment."
}

& $VenvPython -m pip install --upgrade pip
if ($LASTEXITCODE -ne 0) {
    throw "Could not upgrade pip in the project virtual environment."
}

& $VenvPython -m pip install -r (Join-Path $ProjectRoot "requirements.txt")
if ($LASTEXITCODE -ne 0) {
    throw "Could not install project dependencies."
}

$BasePythonExe = & $VenvPython -c "import sys; print(sys._base_executable)"
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($BasePythonExe)) {
    throw "Could not resolve the base Python executable."
}
$PythonRoot = Split-Path -Parent $BasePythonExe.Trim()
if (-not (Test-Path -LiteralPath $PythonRoot)) {
    throw "Resolved Python runtime root does not exist: $PythonRoot"
}

$SitePackages = & $VenvPython -c "import sysconfig; print(sysconfig.get_paths()['purelib'])"
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($SitePackages)) {
    throw "Could not resolve the project virtual environment site-packages path."
}
$SitePackages = $SitePackages.Trim()
if (-not (Test-Path -LiteralPath $SitePackages)) {
    throw "Resolved site-packages path does not exist: $SitePackages"
}

$IsccPath = Resolve-Iscc
$InstallerStagingRoot = Join-Path $ProjectRoot "dist\installer-staging"
$StagingDir = Join-Path $InstallerStagingRoot ("MannaAudioLink-{0}-source-runtime" -f $PackageVersion)
$StagingAppDir = Join-Path $StagingDir "MannaAudioLink"
$InstallerOutputDir = Join-Path $ProjectRoot "dist\installer"
New-Item -ItemType Directory -Path $InstallerOutputDir -Force | Out-Null

if (Test-Path -LiteralPath $StagingDir) {
    $ResolvedProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
    $ResolvedStagingDir = (Resolve-Path -LiteralPath $StagingDir).Path
    if (-not $ResolvedStagingDir.StartsWith($ResolvedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove staging dir outside project: $ResolvedStagingDir"
    }
    Remove-Item -LiteralPath $ResolvedStagingDir -Recurse -Force
}
New-Item -ItemType Directory -Path $StagingAppDir -Force | Out-Null

Copy-Tree -Source (Join-Path $ProjectRoot "src") -Destination (Join-Path $StagingAppDir "src")
Copy-Tree -Source (Join-Path $ProjectRoot "assets") -Destination (Join-Path $StagingAppDir "assets")
Copy-Tree -Source (Join-Path $PythonRoot "DLLs") -Destination (Join-Path $StagingAppDir "python-runtime\DLLs")
Copy-Tree -Source (Join-Path $PythonRoot "Lib") -Destination (Join-Path $StagingAppDir "python-runtime\Lib")
if (Test-Path -LiteralPath (Join-Path $PythonRoot "tcl")) {
    Copy-Tree -Source (Join-Path $PythonRoot "tcl") -Destination (Join-Path $StagingAppDir "python-runtime\tcl")
}
Copy-Tree -Source $SitePackages -Destination (Join-Path $StagingAppDir "python-runtime\Lib\site-packages")

$RuntimeDir = Join-Path $StagingAppDir "python-runtime"
New-Item -ItemType Directory -Path $RuntimeDir -Force | Out-Null
$RuntimeFiles = @(
    "LICENSE.txt",
    "python.exe",
    "pythonw.exe",
    "python3.dll",
    "python314.dll",
    "vcruntime140.dll",
    "vcruntime140_1.dll"
)

foreach ($FileName in $RuntimeFiles) {
    $SourceFile = Join-Path $PythonRoot $FileName
    if (Test-Path -LiteralPath $SourceFile) {
        $DestinationFile = Join-Path $RuntimeDir $FileName
        Copy-Item -LiteralPath $SourceFile -Destination $DestinationFile -Force
        if (-not (Test-Path -LiteralPath $DestinationFile)) {
            throw "Failed to stage runtime file: $DestinationFile"
        }
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $RuntimeDir "python.exe"))) {
    throw "Staged runtime is missing python.exe."
}

$ProjectFiles = @(
    "README.md",
    "PRIVACY.md",
    "LICENSE",
    "pyproject.toml",
    "requirements.txt",
    "configure-sender.ps1",
    "launch-manna-send-audio.ps1",
    "launch-manna-sound-sync.ps1",
    "list-devices.ps1",
    "run-receiver.ps1",
    "run-sender.ps1",
    "show-local-ip.ps1"
)

foreach ($FileName in $ProjectFiles) {
    $SourceFile = Join-Path $ProjectRoot $FileName
    if (Test-Path -LiteralPath $SourceFile) {
        Copy-Item -LiteralPath $SourceFile -Destination (Join-Path $StagingAppDir $FileName) -Force
    }
}

Get-ChildItem -LiteralPath $StagingAppDir -Recurse -Directory -Filter "__pycache__" | Remove-Item -Recurse -Force
Get-ChildItem -LiteralPath $StagingAppDir -Recurse -File |
    Where-Object { $_.Extension -in @(".pyc", ".pyo") } |
    Remove-Item -Force

$CompileBaseArgs = @(
    "/Qp",
    "/DAppVersion=$PackageVersion",
    "/DSourceDir=$StagingAppDir",
    "/DOutputDir=$InstallerOutputDir"
)

$ReceiverScript = Join-Path $ProjectRoot "installer\receiver.iss"
$SenderScript = Join-Path $ProjectRoot "installer\sender.iss"

Write-Output "Building Manna Audio Link installers from $ProjectRoot"
Write-Output "Version: $PackageVersion"
Write-Output "Inno Setup compiler: $IsccPath"
Write-Output "Installer staging: $StagingAppDir"
Write-Output "Bundled Python runtime: $PythonRoot"
Write-Output "Bundled site-packages: $SitePackages"

& $IsccPath @($CompileBaseArgs + $ReceiverScript)
if ($LASTEXITCODE -ne 0) {
    throw "Receiver installer build failed."
}

& $IsccPath @($CompileBaseArgs + $SenderScript)
if ($LASTEXITCODE -ne 0) {
    throw "Sender installer build failed."
}

$Artifacts = @(
    (Join-Path $InstallerOutputDir ("MannaSoundSync-{0}-Receiver-Setup.exe" -f $PackageVersion)),
    (Join-Path $InstallerOutputDir ("MannaSendAudio-{0}-Sender-Setup.exe" -f $PackageVersion))
)

foreach ($Artifact in $Artifacts) {
    if (-not (Test-Path -LiteralPath $Artifact)) {
        throw "Expected installer artifact was not created: $Artifact"
    }

    $HashPath = [System.IO.Path]::ChangeExtension($Artifact, ".sha256.txt")
    $Hash = (Get-FileHash -LiteralPath $Artifact -Algorithm SHA256).Hash.ToLowerInvariant()
    Set-Content -Path $HashPath -Value ("{0} *{1}" -f $Hash, (Split-Path -Leaf $Artifact)) -Encoding ascii
    Write-Output "Built: $Artifact"
    Write-Output "SHA256: $HashPath"
}

Write-Output "Installer build complete."
