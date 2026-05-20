from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
import os
from pathlib import Path
import subprocess
import sys
import threading
import time
from typing import TextIO


try:
    from PIL import Image, ImageDraw
    import pystray
except ImportError as exc:  # pragma: no cover - exercised by real launcher
    raise SystemExit("Tray dependencies missing. Run .\\setup.ps1 first.") from exc


PROJECT_ROOT = Path(__file__).resolve().parents[2]
LOG_DIR = PROJECT_ROOT / "logs"
LOG_PATH = LOG_DIR / "receiver.log"
TRAY_LOG_PATH = LOG_DIR / "tray.log"


@dataclass
class TrayState:
    lock: threading.Lock = field(default_factory=threading.Lock)
    process: subprocess.Popen[str] | None = None
    status: str = "Starting"
    last_line: str = ""
    last_remote: str = ""
    playback: str = ""
    stats: str = ""
    started_at: datetime | None = None
    preset: str = "balanced"

    def snapshot(self) -> dict[str, str | bool]:
        with self.lock:
            running = self.process is not None and self.process.poll() is None
            return {
                "running": running,
                "status": self.status,
                "remote": self.last_remote,
                "playback": self.playback,
                "stats": self.stats,
                "last_line": self.last_line,
                "preset": self.preset,
            }


state = TrayState()
tray_icon: pystray.Icon | None = None


def _log(message: str) -> None:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with TRAY_LOG_PATH.open("a", encoding="utf-8") as handle:
        handle.write(f"[{stamp}] {message}\n")


def _python_console_executable() -> str:
    executable = Path(sys.executable)
    candidate = executable.with_name("python.exe")
    if candidate.exists():
        return str(candidate)
    return str(executable)


def _receiver_env() -> dict[str, str]:
    env = os.environ.copy()
    src = str(PROJECT_ROOT / "src")
    existing = env.get("PYTHONPATH")
    env["PYTHONPATH"] = src if not existing else f"{src}{os.pathsep}{existing}"
    return env


def _set_status(status: str, line: str = "") -> None:
    with state.lock:
        state.status = status
        if line:
            state.last_line = line
    if tray_icon is not None:
        tray_icon.title = _title_text()
        tray_icon.update_menu()


def _title_text() -> str:
    snapshot = state.snapshot()
    if snapshot["remote"]:
        return f"Manna Sound Sync - {snapshot['status']} from {snapshot['remote']}"
    return f"Manna Sound Sync - {snapshot['status']}"


def _handle_receiver_line(line: str) -> None:
    clean = line.strip()
    if not clean:
        return

    with state.lock:
        state.last_line = clean
        if clean.startswith("Listening"):
            state.status = "Waiting for laptop"
        elif clean.startswith("Receiving from "):
            state.status = "Receiving"
            state.last_remote = clean.replace("Receiving from ", "", 1)
        elif clean.startswith("Playing through:"):
            state.status = "Playing"
            state.playback = clean.replace("Playing through:", "", 1).strip()
        elif clean.startswith("receiver "):
            state.status = "Playing"
            state.stats = clean.replace("receiver ", "", 1)
        elif "Address already in use" in clean or "WinError 10048" in clean:
            state.status = "Port already in use"
        elif "Traceback" in clean or clean.startswith("OSError"):
            state.status = "Receiver error"

    if tray_icon is not None:
        tray_icon.title = _title_text()
        tray_icon.update_menu()


def _pipe_reader(pipe: TextIO, log_handle: TextIO) -> None:
    try:
        for line in pipe:
            log_handle.write(line)
            log_handle.flush()
            _handle_receiver_line(line)
    except Exception as exc:  # pragma: no cover - defensive thread guard
        _log(f"pipe reader failed: {exc}")


def start_receiver(_icon: pystray.Icon | None = None, _item: object | None = None) -> None:
    with state.lock:
        if state.process is not None and state.process.poll() is None:
            return
        state.status = "Starting receiver"
        state.last_line = ""
        state.stats = ""
        state.started_at = datetime.now()

    LOG_DIR.mkdir(parents=True, exist_ok=True)
    receiver_log = LOG_PATH.open("a", encoding="utf-8", buffering=1)
    receiver_log.write(
        f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] starting receiver\n"
    )

    with state.lock:
        preset = state.preset
    command = [
        _python_console_executable(),
        "-m",
        "manna_audio_link",
        "receive",
    ]
    if preset == "low-latency":
        command += ["--prebuffer-packets", "8", "--max-buffer-packets", "80"]
    elif preset == "gaming":
        command += ["--prebuffer-packets", "48", "--max-buffer-packets", "240"]
    command += ["--reset-after-underruns", "6", "--reset-after-gap-seconds", "1.5"]
    creationflags = 0
    if os.name == "nt":
        creationflags = subprocess.CREATE_NO_WINDOW

    try:
        process = subprocess.Popen(
            command,
            cwd=PROJECT_ROOT,
            env=_receiver_env(),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            creationflags=creationflags,
        )
    except Exception as exc:
        _set_status("Launch failed", str(exc))
        _log(f"receiver launch failed: {exc}")
        receiver_log.close()
        return

    with state.lock:
        state.process = process

    if os.name == "nt" and preset == "gaming":
        try:
            import psutil  # type: ignore[import-not-found]

            psutil.Process(process.pid).nice(psutil.HIGH_PRIORITY_CLASS)
            _log("receiver priority raised through psutil")
        except Exception:
            try:
                process_handle = subprocess.Popen(
                    [
                        "powershell.exe",
                        "-NoProfile",
                        "-Command",
                        f"(Get-Process -Id {process.pid}).PriorityClass='High'",
                    ],
                    creationflags=creationflags,
                )
                process_handle.wait(timeout=3)
                _log("receiver priority raised through powershell")
            except Exception as exc:
                _log(f"could not raise receiver priority: {exc}")

    if process.stdout is not None:
        threading.Thread(
            target=_pipe_reader,
            args=(process.stdout, receiver_log),
            daemon=True,
        ).start()

    threading.Thread(target=_watch_receiver, args=(process, receiver_log), daemon=True).start()
    _set_status("Waiting for laptop")


def _watch_receiver(process: subprocess.Popen[str], log_handle: TextIO) -> None:
    code = process.wait()
    log_handle.write(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] exited {code}\n")
    log_handle.close()

    with state.lock:
        if state.process is process:
            state.process = None
            if code == 0:
                state.status = "Stopped"
            elif state.status not in {"Port already in use", "Receiver error", "Launch failed"}:
                state.status = f"Stopped with code {code}"

    if tray_icon is not None:
        tray_icon.title = _title_text()
        tray_icon.update_menu()


def stop_receiver(_icon: pystray.Icon | None = None, _item: object | None = None) -> None:
    with state.lock:
        process = state.process
    if process is None or process.poll() is not None:
        _set_status("Stopped")
        return

    _set_status("Stopping")
    process.terminate()
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait(timeout=5)
    _set_status("Stopped")


def set_preset(preset: str) -> None:
    with state.lock:
        state.preset = preset
    _log(f"preset set to {preset}")
    running = _is_running()
    if running:
        stop_receiver()
        start_receiver()
    elif tray_icon is not None:
        tray_icon.update_menu()


def set_low_latency(_icon: pystray.Icon, _item: object) -> None:
    set_preset("low-latency")


def set_balanced(_icon: pystray.Icon, _item: object) -> None:
    set_preset("balanced")


def set_gaming(_icon: pystray.Icon, _item: object) -> None:
    set_preset("gaming")


def _open_path(path: Path) -> None:
    if os.name == "nt":
        os.startfile(path)  # type: ignore[attr-defined]
    else:  # pragma: no cover - Windows app, harmless fallback
        subprocess.Popen(["xdg-open", str(path)])


def open_logs(_icon: pystray.Icon, _item: object) -> None:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    _open_path(LOG_DIR)


def open_project(_icon: pystray.Icon, _item: object) -> None:
    _open_path(PROJECT_ROOT)


def show_local_ips(_icon: pystray.Icon, _item: object) -> None:
    script = PROJECT_ROOT / "show-local-ip.ps1"
    subprocess.Popen(
        [
            "powershell.exe",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-NoExit",
            "-File",
            str(script),
        ],
        cwd=PROJECT_ROOT,
    )


def quit_app(icon: pystray.Icon, _item: object) -> None:
    stop_receiver()
    icon.stop()


def _is_running(_item: object | None = None) -> bool:
    return bool(state.snapshot()["running"])


def _is_stopped(_item: object | None = None) -> bool:
    return not _is_running()


def _status_text(_item: object | None = None) -> str:
    snapshot = state.snapshot()
    return f"Status: {snapshot['status']}"


def _remote_text(_item: object | None = None) -> str:
    snapshot = state.snapshot()
    remote = snapshot["remote"] or "none yet"
    return f"Laptop: {remote}"


def _playback_text(_item: object | None = None) -> str:
    snapshot = state.snapshot()
    playback = snapshot["playback"] or "default headphones"
    return f"Output: {playback}"


def _stats_text(_item: object | None = None) -> str:
    snapshot = state.snapshot()
    stats = snapshot["stats"] or "waiting for stream"
    return f"Stats: {stats}"


def _preset_text(_item: object | None = None) -> str:
    preset = str(state.snapshot()["preset"])
    label = {
        "low-latency": "Low Latency",
        "balanced": "Balanced",
        "gaming": "Gaming",
    }.get(preset, preset)
    return f"Preset: {label}"


def _is_preset(preset: str):
    def checker(_item: object | None = None) -> bool:
        return state.snapshot()["preset"] == preset

    return checker


def _make_icon_image() -> Image.Image:
    image = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((7, 10, 57, 54), radius=12, fill=(18, 28, 44), outline=(93, 213, 255), width=3)
    draw.polygon([(20, 32), (31, 22), (31, 42)], fill=(118, 237, 201))
    draw.arc((30, 22, 48, 42), start=-45, end=45, fill=(255, 255, 255), width=3)
    draw.arc((35, 16, 58, 48), start=-45, end=45, fill=(93, 213, 255), width=3)
    return image


def _build_menu() -> pystray.Menu:
    return pystray.Menu(
        pystray.MenuItem(_status_text, None, enabled=False),
        pystray.MenuItem(_remote_text, None, enabled=False),
        pystray.MenuItem(_playback_text, None, enabled=False),
        pystray.MenuItem(_preset_text, None, enabled=False),
        pystray.MenuItem(_stats_text, None, enabled=False),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem(
            "Preset",
            pystray.Menu(
                pystray.MenuItem("Low Latency", set_low_latency, checked=_is_preset("low-latency")),
                pystray.MenuItem("Balanced", set_balanced, checked=_is_preset("balanced")),
                pystray.MenuItem("Gaming / Stable", set_gaming, checked=_is_preset("gaming")),
            ),
        ),
        pystray.MenuItem("Start receiver", start_receiver, enabled=_is_stopped),
        pystray.MenuItem("Stop receiver", stop_receiver, enabled=_is_running),
        pystray.MenuItem("Show main PC IPs", show_local_ips),
        pystray.MenuItem("Open logs", open_logs),
        pystray.MenuItem("Open project folder", open_project),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem("Quit", quit_app),
    )


def _heartbeat() -> None:
    while tray_icon is not None:
        if tray_icon.visible:
            tray_icon.title = _title_text()
        time.sleep(5)


def main() -> int:
    global tray_icon
    _log("tray starting")
    tray_icon = pystray.Icon(
        "manna-sound-sync",
        _make_icon_image(),
        "Manna Sound Sync",
        _build_menu(),
    )
    start_receiver()
    threading.Thread(target=_heartbeat, daemon=True).start()
    tray_icon.run()
    _log("tray stopped")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
