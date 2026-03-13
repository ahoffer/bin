# Xpra setup

Chrome and Signal run on bigfish as X11 applications, forwarded to clown via Xpra over SSH.
Bigfish keeps the sessions alive permanently via systemd. Clown connects on demand.

---

## Architecture

```
clown (macOS)                     bigfish (Linux)
─────────────────────             ──────────────────────────────────
Xpra.app                          systemd --user
  attach ssh://bigfish/:100  ───►  xpra-chrome.service → Chrome :100
  attach ssh://bigfish/:101  ───►  xpra-signal.service → Signal :101
```

- Sessions on bigfish survive client disconnects, network drops, and reboots.
- Systemd restarts a session automatically if Chrome or Signal crashes.
- No watchdog scripts, no SSH port forwarding, no LaunchAgents.

---

## Sessions

| App     | Display | Systemd service  | User-data dir                      |
|---------|---------|------------------|------------------------------------|
| Chrome  | :100    | xpra-chrome      | ~/.config/google-chrome-xpra       |
| Signal  | :101    | xpra-signal      | ~/.config/signal-xpra              |

Signal's user-data dir is isolated from any native Signal installation on bigfish.

---

## Prerequisites

### On bigfish
- `xpra` installed: `/usr/bin/xpra`
- `python3-avahi` installed (for mDNS): `sudo apt-get install python3-avahi`
- `google-chrome` and `signal-desktop` installed
- Systemd linger enabled so services start at boot without login:
  ```bash
  loginctl enable-linger aaron
  ```
  Verify: `loginctl show-user aaron | grep Linger`

### On clown
- Xpra.app in `/Applications/Xpra.app` (v6.4.3-r0 or later)
  - If it ends up in the Trash: `mv ~/.Trash/Xpra.app /Applications/Xpra.app`
  - Clear quarantine if needed: `xattr -d com.apple.quarantine /Applications/Xpra.app`
- SSH access to bigfish via `~/.ssh/config` (key auth, no password prompt)
- `~/.xpra/xpra.conf` must have `ssh = ssh -x` (see clown setup below)

---

## bigfish setup

### Systemd service files

`~/.config/systemd/user/xpra-chrome.service`:
```ini
[Unit]
Description=Xpra Chrome session
After=network.target
StartLimitBurst=10
StartLimitIntervalSec=300

[Service]
Type=simple
ExecStart=/usr/bin/xpra start :100 --daemon=no \
  --start-child="google-chrome --ozone-platform=x11 --new-window --user-data-dir=/home/aaron/.config/google-chrome-xpra" \
  --exit-with-children \
  --html=off \
  --mdns=yes \
  --log-file=/home/aaron/.xpra/xpra-chrome.log
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
```

`~/.config/systemd/user/xpra-signal.service`:
```ini
[Unit]
Description=Xpra Signal session
After=network.target
StartLimitBurst=10
StartLimitIntervalSec=300

[Service]
Type=simple
ExecStart=/usr/bin/xpra start :101 --daemon=no \
  --start-child="signal-desktop --ozone-platform=x11 --user-data-dir=/home/aaron/.config/signal-xpra" \
  --exit-with-children \
  --html=off \
  --mdns=yes \
  --log-file=/home/aaron/.xpra/xpra-signal.log
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
```

### Enable and start
```bash
systemctl --user daemon-reload
systemctl --user enable --now xpra-chrome.service xpra-signal.service
```

### Verify
```bash
systemctl --user status xpra-chrome xpra-signal   # both active (running)
xpra list                                          # LIVE session at :100, :101
```

---

## clown setup

### `~/.xpra/xpra.conf`
```
# Preserve physical Control/Command semantics for remote apps.
swap-keys = off

# Use system SSH so ~/.ssh/config, key auth, and ControlMaster work correctly.
# Without this, Xpra uses its built-in Paramiko SSH which ignores ~/.ssh/config.
ssh = ssh -x
```

This file is deployed by `~/bin/mac/sync-live-configs` from `~/bin/mac/config/xpra.conf`.

### Desktop launchers

Two AppleScript apps on the Desktop connect with a double-click, no Terminal window:

- `Chrome on bigfish.app`
- `Signal on bigfish.app`

To recreate if lost, run `~/bin/mac/sync-live-configs` — it copies them from `~/bin/mac/`
to the Desktop. The canonical copies live in `~/bin/mac/Chrome on bigfish.app` and
`~/bin/mac/Signal on bigfish.app`.

Logs go to `/tmp/xpra-chrome.log` and `/tmp/xpra-signal.log`.

---

## Connecting

Double-click `Chrome on bigfish.app` or `Signal on bigfish.app` on the Desktop.
The Xpra window appears in a few seconds. No Terminal window.

**CLI fallback:**
```bash
/Applications/Xpra.app/Contents/MacOS/Xpra attach ssh://aaron@bigfish/:100
/Applications/Xpra.app/Contents/MacOS/Xpra attach ssh://aaron@bigfish/:101
```

---

## Disconnecting and reconnecting

Closing the Xpra window does **not** stop the session on bigfish. Chrome and Signal keep
running. Reconnect any time by double-clicking the Desktop app; tabs and state are preserved.

---

## Checking status on bigfish

```bash
# Are the services running?
systemctl --user status xpra-chrome xpra-signal

# Are the sessions live?
xpra list

# Service logs
journalctl --user -u xpra-chrome.service -n 50
journalctl --user -u xpra-signal.service -n 50

# Child processes running?
pgrep -c chrome
pgrep -c signal-desktop
```

---

## Crash recovery

Systemd restarts automatically on failure (`Restart=on-failure`, `RestartSec=5`).
`StartLimitBurst=10` / `StartLimitIntervalSec=300` caps restarts to 10 per 5 minutes.

To test:
```bash
kill -9 $(systemctl --user show -p MainPID --value xpra-chrome.service)
sleep 6
systemctl --user status xpra-chrome   # should show restarted
xpra info :100                         # display responsive
```

---

## Adding a new session

1. **On bigfish:** create `~/.config/systemd/user/xpra-APPNAME.service` following the
   chrome or signal pattern, using an unused display (e.g. `:102`).
   ```bash
   systemctl --user daemon-reload
   systemctl --user enable --now xpra-APPNAME.service
   ```
2. **On clown:** create a new Desktop launcher with the corresponding display number.

---

## Display debugging (bigfish)

```bash
DISPLAY=:100 xdpyinfo | head
```

To run Playwright tests visibly through the Xpra window on clown:
```bash
cd ~/projects/cx-search/proximity/test/playwright
DISPLAY=:100 npx playwright test
```

---

## Pitfalls and gotchas

- **`ssh = ssh -x` is required** in `~/.xpra/xpra.conf`. Without it, Xpra uses its
  built-in Paramiko SSH which ignores `~/.ssh/config` and key auth, causing connection failures.

- **Xpra.app ends up in the Trash** after macOS updates or accidental deletion.
  Check `/Applications/Xpra.app` and restore from `~/.Trash/Xpra.app` if needed.

- **mDNS warning in logs is harmless.** Xpra logs "unable to publish mDNS record for ssh
  connections" for the IPv6 (`::`) address. mDNS is still advertised on IPv4 and works.
  Verify with: `dns-sd -B _xpra._tcp local.` on clown.

- **Xpra GUI Browse button shows "No sessions found"** on clown. The Browse button only
  scans local Unix sockets. The mDNS browser (`xpra mdns-gui`) is Linux-only and not
  available on macOS. Use the Desktop launchers instead.

- **Logs go to journald, not the log file.** With `--daemon=no`, xpra output goes to
  journald even though `--log-file` is specified. Use `journalctl` to read them.

- **Karabiner modifier key remapping.** `~/.config/karabiner/karabiner.json` excludes
  Xpra's bundle ID (`^org\.xpra\.xpra$`) from modifier-key remapping rules. Without this,
  Ctrl/Command keys behave wrongly inside Xpra windows. To re-apply after a Karabiner reset:
  `~/bin/mac/config/karabiner/addxpraexclusion`

- **GStreamer / No Audio warning** on connect is harmless — audio is not used.
