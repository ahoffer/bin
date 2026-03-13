# Images in Kitty: Mac to bigfish

This documents how screenshots taken on clown (Mac) are shared with Claude Code
and Codex running on bigfish (Linux).

---

## Overview

The flow has three stages:

1. Take a screenshot on clown — it lands in the clipboard automatically.
2. Press Ctrl+Shift+V in Kitty — the image is transferred to bigfish and its
   remote path is pasted into the terminal.
3. Pass the path to Claude Code or Codex — they read the image directly.

---

## Stage 1: Taking a screenshot on clown

### Keyboard shortcut

macOS native screenshot region-select is Cmd+Shift+4. On an external keyboard
that lacks a Mac layout, Karabiner-Elements maps the Print Screen key to
Cmd+Shift+4.

Karabiner rule (in `~/bin/mac/config/karabiner/karabiner.json`):

- Description: "Print Screen for screenshot region select"
- Condition: device_if with vendor_id 13364, product_id 865
- From: `print_screen`
- To: `4` + `left_command` + `left_shift`

The Karabiner config lives at `~/.config/karabiner` on clown, which is a
symlink to `~/bin/mac/config/karabiner/`. It is managed live — no sync step
needed.

### Auto-copy to clipboard

Screenshots save to `~/projects/share/Screenshots/`. A macOS LaunchAgent watches
that directory and runs `~/bin/screenshotclip` whenever a new PNG appears.

`screenshotclip` logic:

1. Waits 0.5 s for the file to finish writing.
2. Finds the newest PNG in `~/projects/share/Screenshots/`.
3. If it differs from the last one copied, writes it to the clipboard via
   AppleScript (`set the clipboard to (read ... as «class PNGf»)`).
4. Saves the path to `.last_clipboard_copy` to avoid re-copying.

After this step the screenshot is on the Mac clipboard, ready to paste.

---

## Stage 2: Transferring the image to bigfish via Kitty

### Kitty keybinding

`~/bin/kitty-config/kitty.conf` maps Ctrl+Shift+V (kitty_mod+v) to run
`~/bin/kittypaste` as a background process with remote control enabled:

```
map kitty_mod+v launch --type=background --allow-remote-control ~/bin/kittypaste
```

This overrides the default paste action.

### kittypaste

`~/bin/kittypaste` runs on clown:

1. Tests whether the clipboard contains an image by running `pngpaste -`.
2. If an image is present: runs `sendfile` (no args) to transfer it to bigfish,
   then uses `kitty @ send-text` to type the returned remote path into the
   active terminal window (with a trailing space).
3. If no image: falls back to `kitty @ action paste_from_clipboard` for normal
   text paste.

### sendfile

`~/bin/sendfile` runs on clown:

- With no args (clipboard image mode):
  1. Generates a timestamped filename: `/tmp/clipimg<YYYYMMDDHHmmSS>.png`.
  2. Saves the clipboard PNG to that temp file using `pngpaste`.
  3. Ensures `/tmp/fromclown/` exists on bigfish via SSH.
  4. Copies the file to `bigfish:/tmp/fromclown/` via `scp`.
  5. Deletes the local temp file.
  6. Prints the remote path, for example:
     `/tmp/fromclown/clipimg20260313104056.png`

- With a file path argument: skips pngpaste, copies the given file directly
  to `bigfish:/tmp/fromclown/` and prints the remote path.

After Ctrl+Shift+V, the remote path is typed into the terminal as if the user
typed it.

---

## Stage 3: Reading images in Claude Code and Codex

Files in `/tmp/fromclown/` are local to bigfish and directly readable.

In Claude Code, pass the path as part of a message. Claude Code's Read tool
can open PNG files and display them visually. Example prompt:

```
sendfile
/tmp/fromclown/clipimg20260313104056.png  <-- Ctrl+Shift+V pastes this
```

Then tell Claude what the image shows or ask it to read it.

In Codex, the same path can be passed as context. Codex reads it the same way.

From CLAUDE.md: "Paths under `/tmp/fromclown/` are already transferred and
safe to read directly."

---

## File map

| File | Host | Purpose |
|---|---|---|
| `~/bin/kittypaste` | clown | Kitty paste handler; detects image vs text |
| `~/bin/sendfile` | clown | Transfers file or clipboard image to bigfish |
| `~/bin/screenshotclip` | clown | Copies newest screenshot to clipboard |
| `~/bin/kitty-config/kitty.conf` | both | Maps Ctrl+Shift+V to kittypaste |
| `~/bin/mac/config/karabiner/karabiner.json` | clown | Maps Print Screen to Cmd+Shift+4 |
| `/tmp/fromclown/` | bigfish | Destination directory for transferred images |
| `~/Library/LaunchAgents/` | clown | Contains the LaunchAgent plist that triggers screenshotclip |

---

## Utility: downsize

`~/bin/downsize` shrinks images in parallel using ImageMagick. Useful before
sharing large screenshots. Output files are named `<original>_small.jpg`,
capped at 1600 px on the long edge and 1 MB.

```
downsize ~/projects/share/Screenshots/screenshot.png
```
