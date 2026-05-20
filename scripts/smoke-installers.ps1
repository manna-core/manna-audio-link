$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $ProjectRoot

$PackageVersion = & py -3 -c "import pathlib, tomllib; print(tomllib.loads(pathlib.Path('pyproject.toml').read_text(encoding='utf-8'))['project']['version'])"
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($PackageVersion)) {
    throw "Could not read project version from pyproject.toml."
}
$PackageVersion = $PackageVersion.Trim()

$InstallerOutputDir = Join-Path $ProjectRoot "dist\installer"
$ReceiverInstaller = Join-Path $InstallerOutputDir ("MannaSoundSync-{0}-Receiver-Setup.exe" -f $PackageVersion)
$SenderInstaller = Join-Path $InstallerOutputDir ("MannaSendAudio-{0}-Sender-Setup.exe" -f $PackageVersion)

foreach ($Installer in @($ReceiverInstaller, $SenderInstaller)) {
    if (-not (Test-Path -LiteralPath $Installer)) {
        throw "Missing installer. Run .\scripts\build-installers.ps1 first. Missing: $Installer"
    }
}

$SmokeRoot = Join-Path $ProjectRoot "runtime\install-smoke"
if (Test-Path -LiteralPath $SmokeRoot) {
    $ResolvedProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
    $ResolvedSmokeRoot = (Resolve-Path -LiteralPath $SmokeRoot).Path
    if (-not $ResolvedSmokeRoot.StartsWith($ResolvedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove smoke dir outside project: $ResolvedSmokeRoot"
    }
    for ($Attempt = 1; $Attempt -le 5; $Attempt++) {
        try {
            Remove-Item -LiteralPath $ResolvedSmokeRoot -Recurse -Force -ErrorAction Stop
            break
        } catch {
            if ($Attempt -eq 5) {
                throw
            }
            Start-Sleep -Milliseconds 500
        }
    }
}

$ReceiverDir = Join-Path $SmokeRoot "receiver"
$SenderDir = Join-Path $SmokeRoot "sender"
New-Item -ItemType Directory -Path $ReceiverDir, $SenderDir -Force | Out-Null

Write-Output "Smoke installing receiver to $ReceiverDir"
& $ReceiverInstaller /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOICONS "/DIR=$ReceiverDir"
if ($LASTEXITCODE -ne 0) {
    throw "Receiver silent install failed."
}

Write-Output "Smoke installing sender to $SenderDir"
& $SenderInstaller /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOICONS "/ReceiverIp=192.168.1.25" "/DIR=$SenderDir"
if ($LASTEXITCODE -ne 0) {
    throw "Sender silent install failed."
}

foreach ($InstallDir in @($ReceiverDir, $SenderDir)) {
    $Python = Join-Path $InstallDir "python-runtime\python.exe"
    $Src = Join-Path $InstallDir "src"
    for ($Attempt = 1; $Attempt -le 240 -and ((-not (Test-Path -LiteralPath $Python)) -or (-not (Test-Path -LiteralPath $Src))); $Attempt++) {
        Start-Sleep -Milliseconds 500
    }
    if (-not (Test-Path -LiteralPath $Python)) {
        throw "Installed runtime is missing python.exe: $Python"
    }
    if (-not (Test-Path -LiteralPath $Src)) {
        throw "Installed app is missing src folder: $Src"
    }

    $env:PYTHONPATH = $Src
    & $Python -c "import numpy, soundcard, PIL, pystray; import manna_audio_link.packet; print('installed import smoke ok')"
    if ($LASTEXITCODE -ne 0) {
        throw "Installed import smoke failed for $InstallDir"
    }

    & $Python -m manna_audio_link --help | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Installed CLI help smoke failed for $InstallDir"
    }
}

$ConfigPath = Join-Path (Join-Path $env:APPDATA "Manna Audio Link") "sender-config.json"
if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Sender installer did not write sender config: $ConfigPath"
}

$Config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace([string]$Config.target)) {
    throw "Sender config does not contain a target IP."
}

Write-Output "Smoke install passed."
Write-Output "Sender config target: $($Config.target):$($Config.port)"
Write-Output "Smoke install root: $SmokeRoot"
