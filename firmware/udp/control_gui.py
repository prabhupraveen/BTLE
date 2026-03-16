#!/usr/bin/env python3
"""
ble_control_gui.py  —  BLE FPGA Control GUI
Orchestrates btle_ll (AntSDR via SSH), ble_fpga_ctl | wireshark (local capture),
and ble_send_cmd (local commands) for AntSDR E200 BLE PHY/LL testing.

Requirements:
    pip install PyQt6 paramiko

Place this file in the same directory as the compiled binaries:
    ble_fpga_ctl   ble_send_cmd
"""

import sys
import os
import json
import select
import subprocess
import datetime
from dataclasses import dataclass, asdict, field
from typing import Optional

from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QGridLayout,
    QGroupBox, QLabel, QPushButton, QLineEdit, QCheckBox, QDialog,
    QFormLayout, QDialogButtonBox, QMessageBox, QPlainTextEdit, QSizePolicy,
    QFrame, QScrollArea, QSpacerItem, QTabWidget
)
from PyQt6.QtCore import Qt, QThread, pyqtSignal, QTimer
from PyQt6.QtGui import QColor, QTextCharFormat, QFont, QTextCursor, QPalette

try:
    import paramiko
    HAS_PARAMIKO = True
except ImportError:
    HAS_PARAMIKO = False

# ─────────────────────────────────────────────────────────────────────────────
# Constants
# ─────────────────────────────────────────────────────────────────────────────
APP_DIR     = os.path.dirname(os.path.abspath(__file__))
CONFIG_FILE = os.path.join(APP_DIR, "config.json")

# ─────────────────────────────────────────────────────────────────────────────
# Config
# ─────────────────────────────────────────────────────────────────────────────
@dataclass
class AppConfig:
    host_ip:             str  = "10.8.0.50"
    antsdr_ip:           str  = "192.168.10.61"
    cmd_port:            int  = 50000
    data_port:           int  = 50001
    ssh_user:            str  = "root"
    ssh_password:        str  = ""
    btle_ll_dir:         str  = "/root/vis"
    default_channel:     str  = "37"
    default_aa:          str  = "0x8E89BED6"
    default_crc_init:    str  = "0x555555"
    sudo_password:       str  = ""
    use_sudo_fpga_ctl:   bool = True
    use_sudo_send_cmd:   bool = True

    def save(self, path: str = CONFIG_FILE) -> None:
        data = asdict(self)

        # Never persist sensitive fields
        data.pop("ssh_password", None)
        data.pop("sudo_password", None)

        with open(path, "w") as f:
            json.dump(data, f, indent=2)

    @classmethod
    def load(cls, path: str = CONFIG_FILE) -> "AppConfig":
        if not os.path.exists(path):
            return cls()
        try:
            with open(path) as f:
                data = json.load(f)
            # Backward compatibility: old configs used `remote_work_dir`
            if "btle_ll_dir" not in data and "remote_work_dir" in data:
                data["btle_ll_dir"] = data.get("remote_work_dir", "/root/vis")

            valid = {k: v for k, v in data.items() if k in cls.__dataclass_fields__}
            cfg = cls(**valid)
            # Always blank sensitive fields
            cfg.ssh_password = ""
            cfg.sudo_password = ""
            return cfg
            
        except Exception:
            return cls()


# ─────────────────────────────────────────────────────────────────────────────
# Worker threads
# ─────────────────────────────────────────────────────────────────────────────

class PingWorker(QThread):
    finished = pyqtSignal(bool, str)   # success, message

    def __init__(self, host: str, count: int = 8):
        super().__init__()
        self.host  = host
        self.count = count

    def run(self):
        try:
            result = subprocess.run(
                ["ping", "-c", str(self.count), "-W", "2", self.host],
                capture_output=True, text=True, timeout=30
            )
            output   = result.stdout + result.stderr
            received = 0
            for line in output.splitlines():
                if "received" in line:
                    for part in line.split(","):
                        part = part.strip()
                        if "received" in part:
                            try:
                                received = int(part.split()[0])
                            except (ValueError, IndexError):
                                pass
            if received > 0:
                self.finished.emit(True,
                    f"✓  Reachable — {received}/{self.count} packets received")
            else:
                self.finished.emit(False,
                    f"✗  Unreachable — 0/{self.count} packets received\n\n"
                    f"Check:\n  • VPN connected?\n  • AntSDR powered on?\n  • IP correct ({self.host})?")
        except subprocess.TimeoutExpired:
            self.finished.emit(False, "Ping timed out (30 s). Device unreachable.")
        except Exception as e:
            self.finished.emit(False, f"Ping error: {e}")


class SSHWorker(QThread):
    """Starts btle_ll on the AntSDR over SSH and streams its output."""
    log_line       = pyqtSignal(str, str)   # (text, category)
    status_changed = pyqtSignal(str)        # 'connecting'|'running'|'stopped'|'error'

    def __init__(self, config: AppConfig, cmd: str):
        super().__init__()
        self.config     = config
        self.cmd        = cmd
        self._stop_flag = False
        self.ssh: Optional["paramiko.SSHClient"] = None

    def run(self):
        if not HAS_PARAMIKO:
            self.log_line.emit("ERROR: paramiko not installed. Run: pip install paramiko", "error")
            self.status_changed.emit("error")
            return

        self.status_changed.emit("connecting")
        self.log_line.emit(
            f"SSH → {self.config.ssh_user}@{self.config.antsdr_ip}  cmd: {self.cmd}", "ssh")

        try:
            self.ssh = paramiko.SSHClient()
            self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            self.ssh.connect(
                hostname=self.config.antsdr_ip,
                username=self.config.ssh_user,
                password=self.config.ssh_password,
                timeout=10,
                look_for_keys=False,
                allow_agent=False,
            )
        except Exception as e:
            self.log_line.emit(f"SSH connect failed: {e}", "error")
            self.status_changed.emit("error")
            return

        self.log_line.emit("SSH connected. Launching btle_ll...", "ssh")
        self.status_changed.emit("running")

        try:
            _, stdout, stderr = self.ssh.exec_command(self.cmd, get_pty=False)
            channel = stdout.channel
            channel.setblocking(False)

            while not self._stop_flag:
                # Non-blocking reads
                if channel.recv_ready():
                    chunk = channel.recv(4096).decode("utf-8", errors="replace")
                    for line in chunk.splitlines():
                        if line.strip():
                            self.log_line.emit(line, "ssh")
                if channel.recv_stderr_ready():
                    chunk = channel.recv_stderr(4096).decode("utf-8", errors="replace")
                    for line in chunk.splitlines():
                        if line.strip():
                            self.log_line.emit(line, "ssh_err")
                if channel.exit_status_ready():
                    # Drain leftovers
                    for line in stdout.read().decode(errors="replace").splitlines():
                        if line.strip(): self.log_line.emit(line, "ssh")
                    for line in stderr.read().decode(errors="replace").splitlines():
                        if line.strip(): self.log_line.emit(line, "ssh_err")
                    break
                self.msleep(120)

        except Exception as e:
            self.log_line.emit(f"SSH exec error: {e}", "error")
        finally:
            if self.ssh:
                self.ssh.close()
                self.ssh = None
            self.status_changed.emit("stopped")
            self.log_line.emit("btle_ll stopped.", "ssh")

    def stop(self):
        self._stop_flag = True
        if not HAS_PARAMIKO:
            return
        try:
            k = paramiko.SSHClient()
            k.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            k.connect(hostname=self.config.antsdr_ip,
                      username=self.config.ssh_user,
                      password=self.config.ssh_password,
                      timeout=5, look_for_keys=False, allow_agent=False)
            k.exec_command("pkill -SIGTERM btle_ll 2>/dev/null")
            k.close()
        except Exception:
            pass   # best effort


class CaptureWorker(QThread):
    """Runs ble_fpga_ctl piped into wireshark on the host."""
    log_line       = pyqtSignal(str, str)
    status_changed = pyqtSignal(str)

    def __init__(self, config: AppConfig):
        super().__init__()
        self.config     = config
        self._stop_flag = False
        self.fpga_proc: Optional[subprocess.Popen] = None
        self.ws_proc:   Optional[subprocess.Popen] = None

    def run(self):
        self.status_changed.emit("starting")
        fpga_ctl = os.path.join(APP_DIR, "ble_fpga_ctl")

        if not os.path.isfile(fpga_ctl):
            self.log_line.emit(f"ERROR: {fpga_ctl} not found", "error")
            self.status_changed.emit("error")
            return

        fpga_cmd = [fpga_ctl, "-p", str(self.config.data_port)]
        use_sudo  = self.config.use_sudo_fpga_ctl and self.config.sudo_password
        if use_sudo:
            fpga_cmd = ["sudo", "-S"] + fpga_cmd

        try:
            self.log_line.emit(f"→ {' '.join(fpga_cmd)} | wireshark -k -i -", "capture")
            self.fpga_proc = subprocess.Popen(
                fpga_cmd,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            if use_sudo:
                self.fpga_proc.stdin.write(f"{self.config.sudo_password}\n".encode())
                self.fpga_proc.stdin.flush()
            self.fpga_proc.stdin.close()

            self.ws_proc = subprocess.Popen(
                ["wireshark", "-k", "-i", "-"],
                stdin=self.fpga_proc.stdout,
                stderr=subprocess.PIPE,
            )
            self.fpga_proc.stdout.close()   # wireshark owns it now
            self.status_changed.emit("running")
            self.log_line.emit("Capture running — Wireshark launched.", "capture")

            # Stream ble_fpga_ctl stderr into the log
            while not self._stop_flag:
                rlist, _, _ = select.select([self.fpga_proc.stderr], [], [], 0.3)
                if self.fpga_proc.stderr in rlist:
                    line = self.fpga_proc.stderr.readline()
                    if line:
                        self.log_line.emit(line.decode(errors="replace").rstrip(), "capture")
                    else:
                        break
                if self.fpga_proc.poll() is not None:
                    break

        except FileNotFoundError as e:
            self.log_line.emit(
                f"wireshark not found: {e}\n  Install: sudo apt install wireshark", "error")
            self.status_changed.emit("error")
            return
        except Exception as e:
            self.log_line.emit(f"Capture error: {e}", "error")
            self.status_changed.emit("error")
            return
        finally:
            self._cleanup()
            self.status_changed.emit("stopped")
            self.log_line.emit("Capture stopped.", "capture")

    def stop(self):
        self._stop_flag = True

    def _cleanup(self):
        for proc in [self.fpga_proc, self.ws_proc]:
            if proc and proc.poll() is None:
                try:
                    proc.terminate()
                    proc.wait(timeout=3)
                except Exception:
                    try:
                        proc.kill()
                    except Exception:
                        pass
        self.fpga_proc = None
        self.ws_proc   = None


class SendCmdWorker(QThread):
    """Runs ble_send_cmd once with the given extra args."""
    log_line = pyqtSignal(str, str)
    finished = pyqtSignal(bool, str)

    def __init__(self, config: AppConfig, extra_args: list):
        super().__init__()
        self.config     = config
        self.extra_args = extra_args

    def run(self):
        send_cmd_bin = os.path.join(APP_DIR, "ble_send_cmd")
        if not os.path.isfile(send_cmd_bin):
            self.finished.emit(False, f"ble_send_cmd not found at {send_cmd_bin}")
            return

        cmd = [send_cmd_bin,
               "-t", self.config.antsdr_ip,
               "-p", str(self.config.cmd_port)] + self.extra_args

        use_sudo = self.config.use_sudo_send_cmd and self.config.sudo_password
        if use_sudo:
            cmd = ["sudo", "-S"] + cmd

        self.log_line.emit(f"$ {' '.join(cmd)}", "send")
        try:
            proc = subprocess.Popen(
                cmd,
                stdin=subprocess.PIPE if use_sudo else None,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            if use_sudo:
                proc.stdin.write(f"{self.config.sudo_password}\n".encode())
                proc.stdin.close()
            out, err = proc.communicate(timeout=10)
            for line in out.decode(errors="replace").splitlines():
                if line.strip():
                    self.log_line.emit(line, "send")
            for line in err.decode(errors="replace").splitlines():
                if line.strip():
                    self.log_line.emit(line, "error" if proc.returncode != 0 else "send")
            ok = proc.returncode == 0
            self.finished.emit(ok, "OK" if ok else f"Exit code {proc.returncode}")
        except subprocess.TimeoutExpired:
            self.finished.emit(False, "Timeout waiting for ble_send_cmd")
        except Exception as e:
            self.finished.emit(False, str(e))


# ─────────────────────────────────────────────────────────────────────────────
# Small widgets
# ─────────────────────────────────────────────────────────────────────────────

class StatusDot(QWidget):
    _COLORS = {
        "unknown": "#64748b",
        "ok":      "#22c55e",
        "error":   "#ef4444",
        "warning": "#f59e0b",
        "busy":    "#3b82f6",
    }

    def __init__(self, label: str, parent=None):
        super().__init__(parent)
        lay = QHBoxLayout(self)
        lay.setContentsMargins(2, 0, 8, 0)
        lay.setSpacing(5)
        self._dot = QLabel("●")
        self._dot.setFixedWidth(14)
        self._dot.setFont(QFont("sans-serif", 11))
        self._lbl = QLabel(label)
        self._lbl.setFont(QFont("monospace", 9))
        lay.addWidget(self._dot)
        lay.addWidget(self._lbl)
        self.set_state("unknown")

    def set_state(self, state: str, tip: str = ""):
        color = self._COLORS.get(state, self._COLORS["unknown"])
        self._dot.setStyleSheet(f"color: {color};")
        if tip:
            self.setToolTip(tip)


class LogWidget(QPlainTextEdit):
    _COLORS = {
        "ssh":     QColor("#60a5fa"),   # blue
        "ssh_err": QColor("#93c5fd"),   # lighter blue
        "capture": QColor("#4ade80"),   # green
        "send":    QColor("#fbbf24"),   # amber
        "error":   QColor("#f87171"),   # red
        "info":    QColor("#94a3b8"),   # slate
    }

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setReadOnly(True)
        self.setFont(QFont("Monospace", 9))
        self.setStyleSheet("background:#0f172a; color:#94a3b8; border:none;")
        self.setMaximumBlockCount(3000)

    def append_line(self, text: str, cat: str = "info"):
        ts  = datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]
        cur = self.textCursor()
        cur.movePosition(QTextCursor.MoveOperation.End)
        fmt = QTextCharFormat()
        fmt.setForeground(self._COLORS.get(cat, self._COLORS["info"]))
        cur.insertText(f"[{ts}] {text}\n", fmt)
        self.setTextCursor(cur)
        self.ensureCursorVisible()


# ─────────────────────────────────────────────────────────────────────────────
# Config dialog
# ─────────────────────────────────────────────────────────────────────────────

class ConfigDialog(QDialog):
    def __init__(self, cfg: AppConfig, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Configuration")
        self.setMinimumWidth(460)
        self.cfg = cfg
        self._build()

    def _row(self, form: QFormLayout, label: str, widget: QWidget):
        lbl = QLabel(label)
        lbl.setStyleSheet("color:#94a3b8;")
        form.addRow(lbl, widget)

    def _le(self, text: str, placeholder: str = "", password: bool = False) -> QLineEdit:
        w = QLineEdit(text)
        if placeholder:
            w.setPlaceholderText(placeholder)
        if password:
            w.setEchoMode(QLineEdit.EchoMode.Password)
        return w

    def _build(self):
        lay = QVBoxLayout(self)
        lay.setSpacing(10)

        # ── Network ──────────────────────────────────
        g = QGroupBox("Network")
        f = QFormLayout(g)
        self.host_ip   = self._le(self.cfg.host_ip)
        self.antsdr_ip = self._le(self.cfg.antsdr_ip)
        self.cmd_port  = self._le(str(self.cfg.cmd_port))
        self.data_port = self._le(str(self.cfg.data_port))
        self._row(f, "Host IP:",       self.host_ip)
        self._row(f, "AntSDR IP:",     self.antsdr_ip)
        self._row(f, "Command Port:",  self.cmd_port)
        self._row(f, "Data Port:",     self.data_port)
        lay.addWidget(g)

        # ── SSH ──────────────────────────────────────
        g = QGroupBox("SSH")
        f = QFormLayout(g)
        self.ssh_user    = self._le(self.cfg.ssh_user)
        self.ssh_pass    = self._le(self.cfg.ssh_password, password=True)
        self.remote_dir  = self._le(self.cfg.btle_ll_dir)
        self._row(f, "Username:",     self.ssh_user)
        self._row(f, "Password:",     self.ssh_pass)
        self._row(f, "btle_ll Dir:",  self.remote_dir)
        lay.addWidget(g)

        # ── BLE defaults ─────────────────────────────
        g = QGroupBox("BLE Defaults")
        f = QFormLayout(g)
        self.def_ch  = self._le(self.cfg.default_channel)
        self.def_aa  = self._le(self.cfg.default_aa)
        self.def_crc = self._le(self.cfg.default_crc_init)
        self._row(f, "Default Channel:",      self.def_ch)
        self._row(f, "Default Access Addr:",  self.def_aa)
        self._row(f, "Default CRC Init:",     self.def_crc)
        lay.addWidget(g)

        # ── Sudo ─────────────────────────────────────
        g = QGroupBox("Elevated Privileges (sudo)")
        f = QFormLayout(g)
        self.sudo_pass = self._le(
            self.cfg.sudo_password,
            placeholder="Leave blank if ble_fpga_ctl runs without sudo",
            password=True
        )
        self.sudo_fpga_ctl  = QCheckBox("Use sudo for ble_fpga_ctl")
        self.sudo_fpga_ctl.setChecked(self.cfg.use_sudo_fpga_ctl)
        self.sudo_send_cmd  = QCheckBox("Use sudo for ble_send_cmd")
        self.sudo_send_cmd.setChecked(self.cfg.use_sudo_send_cmd)
        self._row(f, "Sudo Password:", self.sudo_pass)
        self._row(f, "",               self.sudo_fpga_ctl)
        self._row(f, "",               self.sudo_send_cmd)
        lay.addWidget(g)

        btns = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Save |
            QDialogButtonBox.StandardButton.Cancel
        )
        btns.accepted.connect(self.accept)
        btns.rejected.connect(self.reject)
        lay.addWidget(btns)

    def result_config(self) -> AppConfig:
        def _int(s: str, default: int) -> int:
            try:
                return int(s.strip())
            except ValueError:
                return default
        return AppConfig(
            host_ip=self.host_ip.text().strip(),
            antsdr_ip=self.antsdr_ip.text().strip(),
            cmd_port=_int(self.cmd_port.text(), 50000),
            data_port=_int(self.data_port.text(), 50001),
            ssh_user=self.ssh_user.text().strip(),
            ssh_password=self.ssh_pass.text(),
            btle_ll_dir=self.remote_dir.text().strip() or "/root/vis",
            default_channel=self.def_ch.text().strip(),
            default_aa=self.def_aa.text().strip(),
            default_crc_init=self.def_crc.text().strip(),
            sudo_password=self.sudo_pass.text(),
            use_sudo_fpga_ctl=self.sudo_fpga_ctl.isChecked(),
            use_sudo_send_cmd=self.sudo_send_cmd.isChecked(),
        )


# ─────────────────────────────────────────────────────────────────────────────
# btle_ll panel
# ─────────────────────────────────────────────────────────────────────────────

class BtleLLPanel(QGroupBox):
    """Builds the SSH command for btle_ll and exposes Start/Stop buttons."""
    params_changed = pyqtSignal()

    def __init__(self, cfg: AppConfig, parent=None):
        super().__init__("  btle_ll  ·  AntSDR (SSH)", parent)
        self.cfg = cfg
        self._build()

    def _build(self):
        lay = QVBoxLayout(self)
        lay.setSpacing(8)

        # Derived-from-config info row
        self._info_lbl = QLabel()
        self._info_lbl.setStyleSheet("color:#64748b; font-size:10px; font-family:monospace;")
        lay.addWidget(self._info_lbl)

        # Editable BLE parameters
        form = QFormLayout()
        form.setSpacing(6)

        def _lbl(t):
            l = QLabel(t)
            l.setStyleSheet("color:#94a3b8; font-size:10px;")
            return l

        self.n_edit = QLineEdit(self.cfg.default_channel)
        self.c_edit = QLineEdit(self.cfg.default_crc_init)
        self.a_edit = QLineEdit(self.cfg.default_aa)
        for w in (self.n_edit, self.c_edit, self.a_edit):
            w.setFont(QFont("monospace", 10))
        form.addRow(_lbl("-n  Channel:"),      self.n_edit)
        form.addRow(_lbl("-c  CRC Init:"),     self.c_edit)
        form.addRow(_lbl("-a  Access Addr:"),  self.a_edit)
        lay.addLayout(form)

        # Emit params_changed on edit (for mismatch detection)
        for w in (self.n_edit, self.c_edit, self.a_edit):
            w.textChanged.connect(self.params_changed)

        # Command preview
        self._preview = QLabel()
        self._preview.setStyleSheet(
            "color:#475569; font-size:9px; font-family:monospace; padding:4px 0;")
        self._preview.setWordWrap(True)
        lay.addWidget(self._preview)
        for w in (self.n_edit, self.c_edit, self.a_edit):
            w.textChanged.connect(self._update_preview)

        # Separator
        sep = QFrame()
        sep.setFrameShape(QFrame.Shape.HLine)
        sep.setStyleSheet("color:#334155;")
        lay.addWidget(sep)

        # Start / Stop
        btn_row = QHBoxLayout()
        self.start_btn = QPushButton("▶  Start btle_ll")
        self.stop_btn  = QPushButton("■  Stop")
        self.stop_btn.setEnabled(False)
        self.start_btn.setStyleSheet(_BTN_GREEN)
        self.stop_btn.setStyleSheet(_BTN_RED)
        btn_row.addWidget(self.start_btn)
        btn_row.addWidget(self.stop_btn)
        btn_row.addStretch()
        lay.addLayout(btn_row)

        self._refresh_info()
        self._update_preview()

    def _refresh_info(self):
        self._info_lbl.setText(
            f"-H {self.cfg.host_ip}  -P {self.cfg.data_port}  -L {self.cfg.cmd_port}"
            f"  (from config)")

    def _update_preview(self):
        self._preview.setText(f"→ {self._build_cmd()}")

    def _build_cmd(self) -> str:
        c = self.cfg
        return (f"cd {c.btle_ll_dir} && ./btle_ll"
                f" -H {c.host_ip}"
                f" -P {c.data_port}"
                f" -L {c.cmd_port}"
                f" -n {self.get_n()}"
                f" -c {self.get_c()}"
                f" -a {self.get_a()}")

    def get_ssh_cmd(self) -> str:
        return self._build_cmd()

    def update_config(self, cfg: AppConfig):
        self.cfg = cfg
        self._refresh_info()
        self._update_preview()

    def get_n(self) -> str: return self.n_edit.text().strip() or self.cfg.default_channel
    def get_c(self) -> str: return self.c_edit.text().strip() or self.cfg.default_crc_init
    def get_a(self) -> str: return self.a_edit.text().strip() or self.cfg.default_aa

    def set_running(self, running: bool):
        self.start_btn.setEnabled(not running)
        self.stop_btn.setEnabled(running)
        for w in (self.n_edit, self.c_edit, self.a_edit):
            w.setEnabled(not running)


# ─────────────────────────────────────────────────────────────────────────────
# ble_send_cmd panel
# ─────────────────────────────────────────────────────────────────────────────

class SendCmdPanel(QGroupBox):
    """Checkbox-driven panel for ble_send_cmd flags."""
    params_changed = pyqtSignal()

    def __init__(self, cfg: AppConfig, parent=None):
        super().__init__("  ble_send_cmd  ·  Host", parent)
        self.cfg = cfg
        self._build()

    def _mk_row(self, grid: QGridLayout, row: int,
                flag: str, label: str, default: str,
                placeholder: str = "", maxlen: int = 0):
        cb = QCheckBox(f"{flag}  {label}")
        cb.setStyleSheet("color:#94a3b8; font-size:10px;")
        le = QLineEdit(default)
        le.setFont(QFont("monospace", 10))
        le.setEnabled(False)
        if placeholder:
            le.setPlaceholderText(placeholder)
        if maxlen:
            le.setMaxLength(maxlen)
        cb.toggled.connect(le.setEnabled)
        cb.toggled.connect(self.params_changed)
        le.textChanged.connect(self.params_changed)
        grid.addWidget(cb, row, 0)
        grid.addWidget(le, row, 1)
        return cb, le

    def _build(self):
        lay = QVBoxLayout(self)
        lay.setSpacing(8)

        grid = QGridLayout()
        grid.setSpacing(6)
        grid.setColumnStretch(1, 1)

        self.n_cb, self.n_edit = self._mk_row(
            grid, 0, "-n", "Channel:",     self.cfg.default_channel)
        self.a_cb, self.a_edit = self._mk_row(
            grid, 1, "-a", "Access Addr:", self.cfg.default_aa)
        self.c_cb, self.c_edit = self._mk_row(
            grid, 2, "-c", "CRC Init:",    self.cfg.default_crc_init)
        self.m_cb, self.m_edit = self._mk_row(
            grid, 3, "-m", "Message:",     "",
            placeholder="max 26 chars", maxlen=26)
        lay.addLayout(grid)

        # Command preview
        self._preview = QLabel()
        self._preview.setStyleSheet(
            "color:#475569; font-size:9px; font-family:monospace; padding:4px 0;")
        self._preview.setWordWrap(True)
        lay.addWidget(self._preview)
        for cb in (self.n_cb, self.a_cb, self.c_cb, self.m_cb):
            cb.toggled.connect(self._update_preview)
        for le in (self.n_edit, self.a_edit, self.c_edit, self.m_edit):
            le.textChanged.connect(self._update_preview)

        # Separator
        sep = QFrame()
        sep.setFrameShape(QFrame.Shape.HLine)
        sep.setStyleSheet("color:#334155;")
        lay.addWidget(sep)

        # Send button
        btn_row = QHBoxLayout()
        self.send_btn = QPushButton("⚡  Send Command")
        self.send_btn.setStyleSheet(_BTN_BLUE)
        btn_row.addWidget(self.send_btn)
        btn_row.addStretch()
        lay.addLayout(btn_row)

        self._update_preview()

    def _update_preview(self):
        args = self.get_extra_args()
        if args:
            cmd = (f"./ble_send_cmd -t {self.cfg.antsdr_ip}"
                   f" -p {self.cfg.cmd_port} {' '.join(args)}")
        else:
            cmd = "(no flags checked — nothing will be sent)"
        self._preview.setText(f"→ {cmd}")

    def get_extra_args(self) -> list:
        args = []
        if self.n_cb.isChecked() and self.n_edit.text().strip():
            args += ["-n", self.n_edit.text().strip()]
        if self.a_cb.isChecked() and self.a_edit.text().strip():
            args += ["-a", self.a_edit.text().strip()]
        if self.c_cb.isChecked() and self.c_edit.text().strip():
            args += ["-c", self.c_edit.text().strip()]
        if self.m_cb.isChecked() and self.m_edit.text():
            args += ["-m", self.m_edit.text()]
        return args

    def update_config(self, cfg: AppConfig):
        self.cfg = cfg
        self._update_preview()

    def set_mismatch(self, text: str):
        # Mismatch warnings are shown in the main log instead of occupying panel space.
        pass

    def get_n(self) -> Optional[str]:
        return self.n_edit.text().strip() if self.n_cb.isChecked() else None
    def get_c(self) -> Optional[str]:
        return self.c_edit.text().strip() if self.c_cb.isChecked() else None
    def get_a(self) -> Optional[str]:
        return self.a_edit.text().strip() if self.a_cb.isChecked() else None

    def set_busy(self, busy: bool):
        self.send_btn.setEnabled(not busy)
        self.send_btn.setText("Sending…" if busy else "⚡  Send Command")


# ─────────────────────────────────────────────────────────────────────────────
# Shared button styles
# ─────────────────────────────────────────────────────────────────────────────
_BTN_GREEN = (
    "QPushButton{background:#15803d;color:#fff;font-weight:bold;"
    "padding:6px 14px;border-radius:5px;border:none;}"
    "QPushButton:hover{background:#16a34a;}"
    "QPushButton:disabled{background:#1e3a2a;color:#4b5563;}"
)
_BTN_RED = (
    "QPushButton{background:#991b1b;color:#fff;font-weight:bold;"
    "padding:6px 14px;border-radius:5px;border:none;}"
    "QPushButton:hover{background:#b91c1c;}"
    "QPushButton:disabled{background:#2d1515;color:#4b5563;}"
)
_BTN_BLUE = (
    "QPushButton{background:#1d4ed8;color:#fff;font-weight:bold;"
    "padding:6px 14px;border-radius:5px;border:none;}"
    "QPushButton:hover{background:#2563eb;}"
    "QPushButton:disabled{background:#172554;color:#4b5563;}"
)
_BTN_SLATE = (
    "QPushButton{background:#334155;color:#cbd5e1;font-weight:bold;"
    "padding:6px 14px;border-radius:5px;border:none;}"
    "QPushButton:hover{background:#475569;}"
    "QPushButton:disabled{background:#1e293b;color:#4b5563;}"
)


# ─────────────────────────────────────────────────────────────────────────────
# Main window
# ─────────────────────────────────────────────────────────────────────────────

class MainWindow(QMainWindow):
    def __init__(self, cfg: AppConfig):
        super().__init__()
        self.cfg = cfg
        self.ssh_worker:     Optional[SSHWorker]     = None
        self.capture_worker: Optional[CaptureWorker] = None
        self.send_worker:    Optional[SendCmdWorker] = None
        self.ping_worker:    Optional[PingWorker]    = None
        self._last_mismatch_text: str = ""

        self.setWindowTitle("BLE FPGA Control  —  AntSDR E200")
        self.setMinimumSize(860, 720)
        self._apply_stylesheet()
        self._build_ui()

    # ── stylesheet ──────────────────────────────────────────────────────────
    def _apply_stylesheet(self):
        self.setStyleSheet("""
            QMainWindow, QDialog, QWidget {
                background-color: #0f172a;
                color: #e2e8f0;
                font-family: 'IBM Plex Sans', 'Source Sans Pro', 'Segoe UI', sans-serif;
            }
            QGroupBox {
                border: 1px solid #1e293b;
                border-radius: 8px;
                margin-top: 14px;
                padding: 12px 10px 10px 10px;
                font-weight: 600;
                font-size: 11px;
                color: #7dd3fc;
            }
            QGroupBox::title {
                subcontrol-origin: margin;
                left: 12px;
                padding: 0 6px;
                background: #0f172a;
            }
            QLineEdit {
                background: #1e293b;
                border: 1px solid #334155;
                border-radius: 5px;
                padding: 5px 9px;
                color: #e2e8f0;
                font-family: 'JetBrains Mono', 'Fira Code', 'Monospace';
                font-size: 10px;
            }
            QLineEdit:focus {
                border: 1px solid #3b82f6;
                background: #1e2d3d;
            }
            QLineEdit:disabled {
                background: #111827;
                color: #374151;
                border-color: #1e293b;
            }
            QCheckBox {
                spacing: 7px;
                font-size: 10px;
            }
            QCheckBox::indicator {
                width: 14px; height: 14px;
                border-radius: 3px;
                border: 1px solid #475569;
                background: #1e293b;
            }
            QCheckBox::indicator:checked {
                background: #3b82f6;
                border-color: #3b82f6;
            }
            QLabel { color: #e2e8f0; }
            QMenuBar {
                background: #020617;
                color: #94a3b8;
                border-bottom: 1px solid #1e293b;
                padding: 2px;
            }
            QMenuBar::item:selected { background: #1e293b; border-radius: 4px; }
            QMenu {
                background: #0f172a;
                border: 1px solid #334155;
                color: #e2e8f0;
            }
            QMenu::item:selected { background: #1e293b; }
            QScrollBar:vertical {
                background: #0f172a; width: 8px; border-radius: 4px;
            }
            QScrollBar::handle:vertical {
                background: #334155; border-radius: 4px; min-height: 20px;
            }
            QFormLayout QLabel { color: #94a3b8; font-size: 10px; }
            QDialogButtonBox QPushButton {
                background:#1d4ed8; color:#fff; font-weight:bold;
                padding:5px 18px; border-radius:5px; border:none;
            }
            QDialogButtonBox QPushButton:hover { background:#2563eb; }
        """)

    # ── UI build ─────────────────────────────────────────────────────────────
    def _build_ui(self):
        # Menu bar
        mb = self.menuBar()
        cfg_m = mb.addMenu("⚙  Config")
        cfg_m.addAction("Open Configuration…").triggered.connect(self._open_config)
        help_m = mb.addMenu("Help")
        help_m.addAction("About").triggered.connect(lambda: QMessageBox.information(
            self, "About",
            "BLE FPGA Control GUI\n\n"
            "Orchestrates btle_ll · ble_fpga_ctl · ble_send_cmd\n"
            "for AntSDR E200 BLE PHY/LL testing.\n\n"
            "Binaries must be in the same directory as this script."))

        # Central
        central = QWidget()
        self.setCentralWidget(central)
        root = QVBoxLayout(central)
        root.setSpacing(8)
        root.setContentsMargins(10, 8, 10, 8)

        # ── Status row ──────────────────────────────
        status_box = QGroupBox("  System Status")
        status_lay = QHBoxLayout(status_box)
        status_lay.setSpacing(4)

        self.dot_vpn    = StatusDot("VPN")
        self.dot_antsdr = StatusDot("AntSDR")
        self.dot_ssh    = StatusDot("btle_ll / SSH")
        self.dot_cap    = StatusDot("Capture")

        # VPN: we can't auto-detect, mark warning
        self.dot_vpn.set_state("warning", "Cannot auto-detect — verify VPN manually")

        for d in (self.dot_vpn, self.dot_antsdr, self.dot_ssh, self.dot_cap):
            status_lay.addWidget(d)

        # Divider
        div = QFrame()
        div.setFrameShape(QFrame.Shape.VLine)
        div.setStyleSheet("color:#334155;")
        status_lay.addWidget(div)
        status_lay.addStretch()

        self.ping_btn = QPushButton("🔍  Ping AntSDR")
        self.ping_btn.setStyleSheet(_BTN_SLATE)
        self.ping_btn.setFixedWidth(140)
        self.ping_btn.clicked.connect(self._do_ping)
        status_lay.addWidget(self.ping_btn)
        root.addWidget(status_box)

        # ── Main panels (side-by-side) ───────────────
        panels_row = QHBoxLayout()
        panels_row.setSpacing(8)

        self.btle_panel = BtleLLPanel(self.cfg)
        self.btle_panel.start_btn.clicked.connect(self._start_btle_ll)
        self.btle_panel.stop_btn.clicked.connect(self._stop_btle_ll)
        self.btle_panel.params_changed.connect(self._check_mismatch)
        panels_row.addWidget(self.btle_panel, stretch=1)

        self.send_panel = SendCmdPanel(self.cfg)
        self.send_panel.send_btn.clicked.connect(self._send_cmd)
        self.send_panel.params_changed.connect(self._check_mismatch)
        panels_row.addWidget(self.send_panel, stretch=1)

        root.addLayout(panels_row)

        # ── Capture row ──────────────────────────────
        cap_box = QGroupBox("  Capture  ·  ble_fpga_ctl → Wireshark (local)")
        cap_lay = QHBoxLayout(cap_box)

        self.cap_start_btn = QPushButton("▶  Start Capture + Wireshark")
        self.cap_stop_btn  = QPushButton("■  Stop")
        self.cap_status    = QLabel("Idle")
        self.cap_start_btn.setStyleSheet(_BTN_GREEN)
        self.cap_stop_btn.setStyleSheet(_BTN_RED)
        self.cap_stop_btn.setEnabled(False)
        self.cap_status.setStyleSheet("color:#475569; font-style:italic; font-size:10px;")
        self.cap_start_btn.clicked.connect(self._start_capture)
        self.cap_stop_btn.clicked.connect(self._stop_capture)
        cap_lay.addWidget(self.cap_start_btn)
        cap_lay.addWidget(self.cap_stop_btn)
        cap_lay.addWidget(self.cap_status)
        cap_lay.addStretch()
        root.addWidget(cap_box)

        # ── Log ──────────────────────────────────────
        log_box = QGroupBox("  Log")
        log_lay = QVBoxLayout(log_box)
        log_lay.setSpacing(4)

        hdr = QHBoxLayout()
        legend = QLabel(
            '<small>'
            '<span style="color:#60a5fa">■ btle_ll/SSH</span>  '
            '<span style="color:#4ade80">■ capture</span>  '
            '<span style="color:#fbbf24">■ send_cmd</span>  '
            '<span style="color:#f87171">■ error</span>'
            '</small>'
        )
        clear_btn = QPushButton("Clear")
        clear_btn.setFixedWidth(60)
        clear_btn.setStyleSheet(_BTN_SLATE)
        clear_btn.clicked.connect(lambda: self.log.clear())
        hdr.addWidget(legend)
        hdr.addStretch()
        hdr.addWidget(clear_btn)
        log_lay.addLayout(hdr)

        self.log = LogWidget()
        self.log.setMinimumHeight(200)
        log_lay.addWidget(self.log)
        root.addWidget(log_box, stretch=1)

        # Initial log messages
        self.log.append_line("BLE FPGA Control GUI ready.", "info")
        if not HAS_PARAMIKO:
            self.log.append_line(
                "⚠  paramiko not installed — SSH features disabled.  "
                "Run: pip install paramiko", "error")

    # ── Mismatch check ───────────────────────────────────────────────────────
    def _check_mismatch(self):
        def norm(v: str) -> str:
            try:
                return str(int(v.strip(), 0))
            except (ValueError, TypeError):
                return v.strip().lower()

        msgs = []
        sc_n = self.send_panel.get_n()
        sc_c = self.send_panel.get_c()
        sc_a = self.send_panel.get_a()

        if sc_n and norm(self.btle_panel.get_n()) != norm(sc_n):
            msgs.append(f"-n: btle_ll={self.btle_panel.get_n()}  vs  send_cmd={sc_n}")
        if sc_c and norm(self.btle_panel.get_c()) != norm(sc_c):
            msgs.append(f"-c: btle_ll={self.btle_panel.get_c()}  vs  send_cmd={sc_c}")
        if sc_a and norm(self.btle_panel.get_a()) != norm(sc_a):
            msgs.append(f"-a: btle_ll={self.btle_panel.get_a()}  vs  send_cmd={sc_a}")

        mismatch_text = "\n".join(msgs)
        self.send_panel.set_mismatch(mismatch_text)

        if mismatch_text != self._last_mismatch_text:
            if mismatch_text:
                self.log.append_line(
                    "Parameter mismatch detected between btle_ll and send_cmd:\n"
                    + mismatch_text,
                    "info"
                )
            elif self._last_mismatch_text:
                self.log.append_line(
                    "Parameter mismatch resolved between btle_ll and send_cmd.",
                    "info"
                )
            self._last_mismatch_text = mismatch_text

    # ── Ping ─────────────────────────────────────────────────────────────────
    def _do_ping(self):
        if self.ping_worker and self.ping_worker.isRunning():
            return
        self.ping_btn.setEnabled(False)
        self.ping_btn.setText("Pinging…")
        self.dot_antsdr.set_state("busy", "Pinging…")
        self.log.append_line(f"Pinging {self.cfg.antsdr_ip} (8 packets)…", "info")

        self.ping_worker = PingWorker(self.cfg.antsdr_ip, count=8)
        self.ping_worker.finished.connect(self._on_ping_done)
        self.ping_worker.start()

    def _on_ping_done(self, ok: bool, msg: str):
        self.ping_btn.setEnabled(True)
        self.ping_btn.setText("🔍  Ping AntSDR")
        cat = "capture" if ok else "error"
        self.log.append_line(f"Ping → {msg}", cat)
        if ok:
            self.dot_antsdr.set_state("ok", msg)
            self.dot_vpn.set_state("ok", msg)
        else:
            self.dot_antsdr.set_state("error", msg)
            box = QMessageBox(self)
            box.setWindowTitle("AntSDR Unreachable")
            box.setIcon(QMessageBox.Icon.Warning)
            box.setText(msg)
            box.exec()

    # ── btle_ll ──────────────────────────────────────────────────────────────
    def _start_btle_ll(self):
        if not HAS_PARAMIKO:
            QMessageBox.critical(self, "Missing Dependency",
                "paramiko is required for SSH.\nInstall: pip install paramiko")
            return
        if self.ssh_worker and self.ssh_worker.isRunning():
            return

        cmd = self.btle_panel.get_ssh_cmd()
        self.btle_panel.set_running(True)
        self.dot_ssh.set_state("busy", "Connecting via SSH…")

        self.ssh_worker = SSHWorker(self.cfg, cmd)
        self.ssh_worker.log_line.connect(lambda t, c: self.log.append_line(t, c))
        self.ssh_worker.status_changed.connect(self._on_ssh_status)
        self.ssh_worker.start()

    def _stop_btle_ll(self):
        if self.ssh_worker:
            self.log.append_line("Stopping btle_ll (sending SIGTERM)…", "ssh")
            self.ssh_worker.stop()

    def _on_ssh_status(self, s: str):
        m = {"connecting": ("busy",    "Connecting via SSH…"),
             "running":    ("ok",      "btle_ll running on AntSDR"),
             "stopped":    ("unknown", "btle_ll stopped"),
             "error":      ("error",   "SSH / btle_ll error")}
        state, tip = m.get(s, ("unknown", ""))
        self.dot_ssh.set_state(state, tip)
        if s in ("stopped", "error"):
            self.btle_panel.set_running(False)

    # ── Capture ──────────────────────────────────────────────────────────────
    def _start_capture(self):
        if self.capture_worker and self.capture_worker.isRunning():
            return
        self.cap_start_btn.setEnabled(False)
        self.cap_stop_btn.setEnabled(True)
        self.cap_status.setText("Starting…")
        self.dot_cap.set_state("busy", "Starting…")

        self.capture_worker = CaptureWorker(self.cfg)
        self.capture_worker.log_line.connect(lambda t, c: self.log.append_line(t, c))
        self.capture_worker.status_changed.connect(self._on_cap_status)
        self.capture_worker.start()

    def _stop_capture(self):
        if self.capture_worker:
            self.log.append_line("Stopping capture…", "capture")
            self.capture_worker.stop()

    def _on_cap_status(self, s: str):
        if s == "running":
            self.dot_cap.set_state("ok", "Capture running")
            self.cap_status.setText("Running")
        elif s in ("stopped", "error"):
            self.dot_cap.set_state("error" if s == "error" else "unknown", s)
            self.cap_status.setText("Stopped" if s == "stopped" else "Error")
            self.cap_start_btn.setEnabled(True)
            self.cap_stop_btn.setEnabled(False)

    # ── Send command ─────────────────────────────────────────────────────────
    def _send_cmd(self):
        if self.send_worker and self.send_worker.isRunning():
            return
        extra = self.send_panel.get_extra_args()
        if not extra:
            QMessageBox.information(self, "Nothing to send",
                "Check at least one flag checkbox before sending.")
            return
        self.send_panel.set_busy(True)

        self.send_worker = SendCmdWorker(self.cfg, extra)
        self.send_worker.log_line.connect(lambda t, c: self.log.append_line(t, c))
        self.send_worker.finished.connect(self._on_send_done)
        self.send_worker.start()

    def _on_send_done(self, ok: bool, msg: str):
        self.send_panel.set_busy(False)
        if not ok:
            self.log.append_line(f"Send failed: {msg}", "error")

    # ── Config ───────────────────────────────────────────────────────────────
    def _open_config(self):
        dlg = ConfigDialog(self.cfg, self)
        if dlg.exec() == QDialog.DialogCode.Accepted:
            self.cfg = dlg.result_config()
            self.cfg.save()
            self.btle_panel.update_config(self.cfg)
            self.send_panel.update_config(self.cfg)
            self.log.append_line("Configuration saved to config.json", "info")

    # ── Close ─────────────────────────────────────────────────────────────────
    def closeEvent(self, event):
        if self.ssh_worker and self.ssh_worker.isRunning():
            self.ssh_worker.stop()
            self.ssh_worker.wait(2000)
        if self.capture_worker and self.capture_worker.isRunning():
            self.capture_worker.stop()
            self.capture_worker.wait(2000)
        event.accept()


# ─────────────────────────────────────────────────────────────────────────────
# Startup dialogs
# ─────────────────────────────────────────────────────────────────────────────

def run_startup_checks(cfg: AppConfig) -> bool:
    """Returns False if the user chose to quit."""

    # ── Dialog 1: VPN ──────────────────────────────
    d1 = QMessageBox()
    d1.setWindowTitle("Pre-flight Check  ①  VPN")
    d1.setIcon(QMessageBox.Icon.Warning)
    d1.setText(
        "<b>Are you connected to VPN?</b><br><br>"
        "The AntSDR is typically reachable only over VPN.<br>"
        "Make sure your VPN tunnel is active before proceeding."
    )
    yes_btn  = d1.addButton("✓  VPN is active — Continue", QMessageBox.ButtonRole.AcceptRole)
    quit_btn = d1.addButton("✗  Not yet — Quit",           QMessageBox.ButtonRole.RejectRole)
    d1.exec()
    if d1.clickedButton() is quit_btn:
        return False

    # ── Dialog 2: Recompile ─────────────────────────
    d2 = QMessageBox()
    d2.setWindowTitle("Pre-flight Check  ②  Binaries")
    d2.setIcon(QMessageBox.Icon.Information)
    d2.setText(
        "<b>Have you recompiled the C binaries after any edits?</b><br><br>"
        "<b>Host</b> (same dir as this script):<br>"
        "&nbsp;&nbsp;• <code>gcc -O2 -o ble_send_cmd ble_send_cmd.c -lpthread</code><br>"
        "&nbsp;&nbsp;• <code>gcc -O2 -o ble_fpga_ctl ble_fpga_ctl.c</code><br><br>"
        f"<b>AntSDR</b> (<code>{cfg.btle_ll_dir}/</code> on device):<br>"
        "&nbsp;&nbsp;• <code>gcc -O2 -o btle_ll btle_ll.c -lpthread</code>"
    )
    d2.addButton("✓  Binaries are up-to-date", QMessageBox.ButtonRole.AcceptRole)
    d2.addButton("⏭  Skip (continue anyway)",  QMessageBox.ButtonRole.AcceptRole)
    d2.exec()
    return True


# ─────────────────────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────────────────────

def main():
    app = QApplication(sys.argv)
    app.setApplicationName("BLE FPGA Control")
    app.setStyle("Fusion")

    # Load (or create) config before showing any window
    cfg = AppConfig.load(CONFIG_FILE)

    # Startup checks — these show before the main window appears
    if not run_startup_checks(cfg):
        sys.exit(0)

    win = MainWindow(cfg)
    win.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()