#!/usr/bin/env python3
"""
Nautilus "Copy Path" Extension
==============================

Adds a "Copy Path" option to the right-click context menu in GNOME Files (Nautilus).
Copies the absolute path(s) of selected file(s) to the clipboard.

Installation
------------
1. Install the Python Nautilus bindings:
       sudo apt install python3-nautilus

2. Create the extensions directory (if it doesn't exist):
       mkdir -p ~/.local/share/nautilus-python/extensions

3. Copy this file to the extensions directory:
       cp nautilus-copy-path.py ~/.local/share/nautilus-python/extensions/copy-path.py

4. Restart Nautilus:
       nautilus -q

5. Open Nautilus and right-click any file - "Copy Path" should appear in the menu.

Uninstallation
--------------
    rm ~/.local/share/nautilus-python/extensions/copy-path.py
    nautilus -q

Tested on: Nautilus 46.4 (GNOME Files), Ubuntu 24.x
"""

from gi.repository import Nautilus, GObject, Gdk, GLib

class CopyPathExtension(GObject.GObject, Nautilus.MenuProvider):
    def copy_path(self, menu, files):
        paths = '\n'.join(f.get_location().get_path() for f in files)
        clipboard = Gdk.Display.get_default().get_clipboard()
        clipboard.set(paths)

    def get_file_items(self, files):
        if not files:
            return []

        label = "Copy Path" if len(files) == 1 else "Copy Paths"
        item = Nautilus.MenuItem(
            name="CopyPathExtension::CopyPath",
            label=label,
            tip="Copy absolute path to clipboard"
        )
        item.connect('activate', self.copy_path, files)
        return [item]
