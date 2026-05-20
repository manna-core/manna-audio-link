# Laptop Codex Prompt

Use this on the laptop side after the `manna-audio-link` project folder is available through Syncthing or manual copy.

```text
/build manna-audio-link laptop side

Goal: make this laptop send its normal system audio to my main PC so the laptop video audio comes through the headphones attached to the main PC.

Project folder:
D:\Manna-core\projects\manna-audio-link

Read README.md, current_state.md, next_steps.md, and task_state.json first.

Do this:
1. Run .\setup.ps1 from the project folder.
2. Run .\list-devices.ps1 and identify the laptop speaker/output device used for normal video playback.
3. Ask me for the main PC IP address if I have not provided it.
4. Start the sender with:
   .\run-sender.ps1 -Target MAIN_PC_IP
5. If audio does not arrive, try:
   .\run-sender.ps1 -Target MAIN_PC_IP -InputDevice "Speakers"
6. If audio works but sounds distorted, try:
   .\run-sender.ps1 -Target MAIN_PC_IP -Gain 0.65
7. Keep the fix simple. Do not add pairing, accounts, cloud services, or unrelated UI unless the basic LAN audio path works first.

Safety boundary: LAN only. "Same internet" should mean the same Wi-Fi/router/local network. Do not expose ports to the public internet. Do not install random audio drivers.

Report:
- whether setup succeeded
- which device is being captured
- the exact sender command that is running
- any Windows Firewall or dependency issue
```
