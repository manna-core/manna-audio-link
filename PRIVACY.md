# Privacy

`Manna Audio Link` is a local-first LAN audio utility.

## Current Privacy Model

- Audio is captured locally from the sender computer's Windows loopback device.
- Audio packets are sent directly to the receiver IP on the local network.
- The app does not require sign-in.
- The app does not use a cloud service.
- The app does not include analytics or telemetry.

## Local Files

The app may write:

- sender settings under `%APPDATA%\Manna Audio Link\sender-config.json`
- receiver and tray logs under the installed/source app `logs` folder

The sender config stores the receiver IP, UDP port, and simple sender defaults. Do not expose the UDP port to the public internet.

## Scope

This project currently targets simple Windows desktop LAN use. It is not encrypted, authenticated, or designed for public-internet audio streaming.
