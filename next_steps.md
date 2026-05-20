# Next Steps - Manna Audio Link

## Best Next Move

Live-test the public `v0.1.0` installer path on the actual two-machine setup:

1. Main PC: download and run `MannaSoundSync-0.1.0-Receiver-Setup.exe` from the GitHub release.
2. Main PC: launch `Manna Sound Sync` from Windows search.
3. Main PC: confirm the tray receiver says `Waiting for laptop`.
4. Main PC: use `Show main PC IPs` if the laptop needs the current IPv4 address.
5. Laptop: download and run `MannaSendAudio-0.1.0-Sender-Setup.exe` from the GitHub release.
6. Laptop: enter the main PC IPv4 address during sender setup.
7. Laptop: launch `Manna Send Audio` from Windows search.
8. Confirm the visible sender stats move, the receiver tray changes to `Playing`, and headphone audio stays clean.
9. Stop the laptop sender with `Ctrl+C`.

Release:

```text
https://github.com/manna-core/manna-audio-link/releases/tag/v0.1.0
```

## If The Main PC IP Changes

Launch:

```text
Configure Manna Send Audio
```

or run:

```powershell
.\configure-sender.ps1
```

The sender target lives at:

```text
%APPDATA%\Manna Audio Link\sender-config.json
```

## If Audio Quality Regresses

If it sounds distorted and sender `clipped` rises, lower gain:

```powershell
.\run-sender.ps1 -Target MAIN_PC_IP -Gain 0.65
```

If it crackles and receiver `missing`, `late`, or `underruns` rises, increase prebuffer:

```powershell
.\run-receiver.ps1 -PrebufferPackets 24
```

## Release Commands

Build installers:

```powershell
.\scripts\build-installers.ps1
```

Smoke test installers:

```powershell
.\scripts\smoke-installers.ps1
```

Artifacts:

```text
dist\installer\MannaSoundSync-0.1.0-Receiver-Setup.exe
dist\installer\MannaSendAudio-0.1.0-Sender-Setup.exe
```

## Recommended Next Product Move

After the installer live test, the best v0.1.1 candidate is not discovery yet. It is a tiny sender config quality pass:

- show the configured target before launch
- make `Configure Manna Send Audio` easier to find after install
- optionally add a `stable` receiver preset only if real installer-path audio crackles

## Not Yet

- automatic pairing
- encryption/authentication
- multiple senders
- laptop tray app
- cloud relay
- public-internet streaming

Those stay out until the installer-based LAN path is proven comfortable on the actual two-machine setup.
