# bin
The contents of my bin dir. Eventually expand to "Configure your desktop with Ansible". Useful when I crash, burn, corrupt, despoil, savage, or ravage my system. 


## Playbooks
Ansible playbooks are in a subdirectory

### IntelliJ Run Configurations
Subdirectory `.run`

## NOTES

## Ansible's dconf plugin

Did not work for me to set up keyboard shortcuts. Here is what I tried:

```
    #     psutil upgrade was needed for Ubuntu 20.04
    #      - name: Update pip
    #        shell: pip3 install --upgrade psutil
    #   Use dconf dump / to look at all the gnome settings.
    #   For example,
    #     [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
    #      name='Flameshot'
    #      command='flameshot gui'
    #      binding='Print'

    #     THIS DOES NOT WORK
    #      - name: Print key shortcut name
    #        dconf:
    #          key: "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/name"
    #          value: "'Flameshot'"
    #      - name: Print key shortcut command
    #        dconf:
    #          key: "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/command"
    #          value: "'flameshot gui'"
    #      - name: Print key shortcut binding
    #        dconf:
    #          key: "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/binding"
    #          value: "'Print'"
```