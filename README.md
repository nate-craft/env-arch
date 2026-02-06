# Arch Install

## Explanation

Minimal Sway Arch Linux installation.  
Public configuration and scripts in `/public/` available on git.
Private configuration, data, and large file private USB backup.

Details on installation available in `install.sh`.
Quick installation via curl in `quick.sh`.

## Usage

1. Connect to WiFi: `iwctl station wlan0 connect <network_name>`.  
2. Install **minimal** Arch Linux with the `archinstall` script.  
  2A. Select `NetworkManager` as wifi for new system.  
3. Reboot.  
4. Connect to WiFi: `nmtui`.  
5. (Optional) Connect to USB drive containing large/private files.  
6. `curl --proto '=https' --tlsv1.2 -LsSf https://raw.githubusercontent.com/nate-craft/env-arch/refs/heads/main/quick.sh | sh`  

## Keymap

In my sway configuration, L-Ctrl and L-Alt are swapped. The keymapping below
shows what is actually being pressed, but this may appear differently in the
sway configuration file when examined.

### Navigation

- `Alt+j`          : move to workspace left
- `Alt+k`           : move to workspace right
- `Alt+#`           : move to workspace by number
- `Shift+Alt+#`     : move container to workspace by number
- `Alt+Tab`         : move to workspace next 
- `Shift+Alt+Tab`   : move to workspace previous
- `Sup+j`           : move focus left
- `Sup+k`           : move focus right
- `Sup+f`           : fullscreen
- `Alt+q`           : kill container

### TMUX

- `> panel`         : attach to tmux
- `Alt+b`           : leader prefix
- `Leader+#`        : move to tmux workspace by number
- `Leader+h`        : split across horizontal axis
- `Leader+v`        : split across vertical axis
- `Leader+d`        : detach
- `Alt+w`           : close tmux workspace
- `Alt+v`           : visual mode
- `{VISUAL}, v`     : enter selection mode
- `{VISUAL}, y`     : yank selection and exit selection mode
- `{VISUAL}, Esc`   : exit selection mode

### Misc

- `Alt+Space`       : app launcher
- `Shift+Alt+Space` : math launcher
- `Shift+Alt+b`     : show bookmarks
- `Shift+Sup+b`     : create bookmark from clipboard
- `Shift+Sup+e`     : logout sway
- `Shift+Sup+r`     : reload sway
- `Print`           : screenshot selection to clipboard
- `Alt+Print`       : screenshot focused container to clipboard
- `Shift+Print`     : screenshot selection to ~/Photos/Screenshots/
- `Shift+Alt+Print` : screenshot focused container to ~/Photos/Screenshots/
