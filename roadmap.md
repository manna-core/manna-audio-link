# Manna Audio Link Roadmap

## End Goal

Build a dead-simple local audio bridge so Grayson can play a fullscreen game on the main PC, watch a video on the laptop, and hear both through the same headphones.

The feel target is closer to Syncthing than pro-audio routing software: one job, obvious roles, minimal ceremony.

## Product Principles

- local LAN first
- no accounts
- no cloud dependency
- simple enough to run while gaming
- truthful status over fancy UI
- one small working path before pairing or polish

## Phase 1 - Command-Line LAN MVP

- main PC runs receiver
- laptop runs sender
- capture laptop system audio through Windows loopback
- stream low-latency PCM over UDP
- play through main PC default headphones
- document exact main-PC and laptop commands

## Phase 2 - Reliability Pass

- better jitter handling
- clearer packet loss/latency status
- friendlier device selection
- Windows Firewall troubleshooting notes
- optional startup shortcuts

## Phase 3 - Simplicity Layer

- one-click receiver launcher
- one-click sender launcher
- local config file for target IP and preferred devices
- visible status that says connected, waiting, or receiving

## Phase 4 - Discovery and Pairing

- LAN discovery so the laptop can find the main PC
- simple trust prompt
- remember approved devices locally

## Phase 5 - Packaging

- small Windows app or tray app
- install/update story
- optional latency presets
- no advanced routing UI unless the simple path is already excellent

## What This Should Not Become Yet

- a cloud service
- a pro-audio mixer
- a Discord replacement
- a general remote-desktop/audio suite
- a complicated virtual-cable setup
