#!/usr/bin/env sh

#   ,----.              ,--.         ,--.                ,--.          ,--.,--.               
#  /  O   \,--.--. ,---.|  ,---.     |  |,--,--,  ,---.,-'  '-. ,--,--.|  ||  | ,---. ,--.--. 
# |  .-.  ||  .--'| .--'|  .-.  |    |  ||      \(  .-''-.  .-'' ,-.  ||  ||  || .-. :|  .--' 
# |  | |  ||  |   \ `--.|  | |  |    |  ||  ||  |.-'  `) |  |  \ '-'  ||  ||  |\   --.|  |    
# `--' `--'`--'    `---'`--' `--'    `--'`--''--'`----'  `--'   `--`--'`--'`--' `----'`--'    
#
# This script is designed to install local files and enable systemd services, scripts, and other
# programs necessary for my Arch Linux installation.
#
# No personal information is present, but many of the choices fit my individual technology stack.
#
# No editing is necessary for the following script, but individual programs can be changed if desired.
#
# For file syncing, this script will attempt to copy the current directory filled with environmental data
# to the given $ENV_DIR_NAME. After, an attempt will be made to copy Music, Photos, Documents, and
# other large directories from the given $USB identifier. This is likely unneeded for non-me people.


#------------------------------------------------------------------
#                          VARIABLES START
# -----------------------------------------------------------------


# environment options

ENV_DIR_NAME="Env"
ENV="${HOME}/${ENV_DIR_NAME}"

# file syncing

USB="DC95-5829"
USB_MOUNT_DIR="/mnt/drive"
USB_OPTIONS="exfat defaults,uid=1000,gid=1000,nosuid,nodev,nofail,x-systemd.automount 0 0"
RSYNC_ARGS="-a --mkpath --partial --ignore-missing-args --info=progress2"

# packages 

PKG_BASE="git base-devel openssh networkmanager rsync exfat-utils"
PKG_SWAY="sway swayidle swaylock waybar polkit foot \
          libnotify wl-clipboard dunst slurp grim rofi \
          7zip bluez"
PKG_DRIVER="intel-media-driver"
PKG_THEME="adw-gtk-theme qt6-wayland qt5-wayland"
PKG_CLI_BASE="bat ripgrep fd bc tmux jq helix libsixel tealdeer man"
PKG_CLI_EXTRA="bluetui yt-dlp fzf socat shellcheck-bin gurk imagemagick
               htop markdown-oxide auditorium yt-feeds yazi"
PKG_GUI="gammastep mpv imv pavucontrol zathura zathura-pdf-poppler \
         librewolf-bin libreoffice-fresh freetube-bin picard calibre"

#------------------------------------------------------------------
#                          SCRIPT START
# -----------------------------------------------------------------

# rules 
        
BLUETOOTH_RULE='polkit.addRule(function(action, subject) {
    if (action.lookup("unit") == "bluetooth.service" 
            && subject.isInGroup("wheel") 
            && (action.lookup("verb") == "start" || action.lookup("verb") == "stop")
        ) {

        return polkit.Result.YES;
    }
});
'

SYSTEMD_DIR="/etc/systemd/system/getty@tty1.service.d/"
SYSTEMD_FILE="/etc/systemd/system/getty@tty1.service.d/override.conf"
SYSTEMD_SWAY="[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${USER} %I 38400 linux
"
USB_FSTAB_ENTRY="UUID=${USB} ${USB_MOUNT_DIR} ${USB_OPTIONS}"

if [ -f "globals.sh" ]; then
    . ./globals.sh
else
    printf "%sScript must be executed from the '${ENV_DIR_NAME}' directory on first run!\n" "$(tput setaf 1)"
    exit 0
fi

msg "Arch Installation Started"

if ! prompt "Do you want to continue with a minimal sway environment configuration?"; then
    exit 0
fi

msg "This script will need to prompt for super user permissions to install programs and move files!"
msg "Pacman will now sync packages to avoid future dependency issues..."
sudo pacman -Syu

# base

if ! prog_exists git || ! prog_exists ssh || ! prog_exists rsync; then
    sudo pacman -S --needed $PKG_BASE
fi

if [ "$PWD" != "$ENV" ]; then
    mkdir -p "$ENV"
    rsync -a --mkpath --ignore-missing-args ./ "$ENV"
fi

# sway

if ! prog_exists sway; then
    sudo pacman -S --needed $PKG_DRIVER $PKG_SWAY $PKG_CLI_BASE
fi

# git

if prompt "Do you want to configure your Git settings?"; then
    ask "username" "What is your Git username?"
    git config --global user.name "$username"
    msg "Username set as ${username}"
    ask "email" "What is your Git email?"
    git config --global user.email "$email"
    msg "Email set as ${email}"
    git config --global init.defaultBranch main
fi

# shell

if prompt "Do you want to install shell programs?"; then
    if prompt "Do you want to install dash as the default shell for running scripts?"; then
        sudo pacman -S --needed dash
        sudo rm -f /bin/sh
        sudo ln -sf /bin/dash /bin/sh
    fi

    if prompt "Do you want to install fish as the interative shell?"; then
        sudo pacman -S --needed fish
        command -v fish | sudo tee -a /etc/shells > /dev/null 2>&1
        chsh -s "$(command -v fish)"
    fi
fi

# security

if prompt "Do you want to enable sane security defaults?"; then
    sudo pacman -S --needed ufw
    sudo ufw default deny incoming
    sudo systemctl enable --now ufw
    sudo ufw enable
fi

# local files

if prompt "Do you enable local data syncing?"; then

    # copy home files from local env files

    if prompt "Do you want to install custom configuration and scripts?"; then
        sudo rsync $RSYNC_ARGS "${ENV}/public/etc" "/"
        rsync $RSYNC_ARGS "${ENV}/public/.config" "$HOME"
        rsync $RSYNC_ARGS "${ENV}/public/.local/bin" "$HOME/.local/"
        chmod +x -R "${HOME}/.local/bin"
        chmod +x -R "${HOME}/.config/waybar/"
    fi

    # copy user files locally
 
    if prompt "Do you want to sync large/private documents, photos, and music from the USB ${USB}?"; then
        if ! grep "$USB" /etc/fstab > /dev/null 2>&1; then
            echo "$USB_FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null 2>&1
        fi

        sudo systemctl daemon-reload
        sudo systemctl restart mnt-drive.automount
        sudo mkdir -p "$USB_MOUNT_DIR"
        sudo chown -R "${USER}:${USER}" "$USB_MOUNT_DIR"

        if lsblk -o UUID | grep -q "$USB"; then
            rsync $RSYNC_ARGS "${USB_MOUNT_DIR}/files/Documents" "$HOME"
            rsync $RSYNC_ARGS "${USB_MOUNT_DIR}/files/Music" "$HOME"
            rsync $RSYNC_ARGS "${USB_MOUNT_DIR}/files/Photos" "$HOME"
            rsync $RSYNC_ARGS "${USB_MOUNT_DIR}/private/.local/share" "$HOME/.local/"
            rsync $RSYNC_ARGS "${USB_MOUNT_DIR}/private/.librewolf" "$HOME/"
            rsync $RSYNC_ARGS "${USB_MOUNT_DIR}/private/.ssh" "$HOME/"
            rsync $RSYNC_ARGS "${USB_MOUNT_DIR}/private/.config/gnupg" "$HOME/.config/"
            rsync $RSYNC_ARGS "${USB_MOUNT_DIR}/private/.local/share/gurk" "$HOME/.local/share"

            chmod -R 755 "${HOME}/Documents/"
            chmod -R 755 "${HOME}/Music/"
            chmod -R 755 "${HOME}/Photos/"
            chmod -R 755 "${HOME}/.local/share"
            chmod 755 "${HOME}/.ssh"
            chmod 600 "$HOME"/.ssh/*
            chmod 644 "$HOME"/.ssh/*.pub
            find "${HOME}/.config/gnupg" -type f -exec chmod 600 {} \;
            find "${HOME}/.config/gnupg" -type d -exec chmod 700 {} \;
            rm -rf "$HOME/.gnupg"
        else
            msg_err "USB ${USB} not available. Not syncing documents and music from remote drive"    
        fi        
    fi    
fi

# paru

if ! prog_exists paru; then
    pacman -S --needed rustup
    git clone https://aur.archlinux.org/paru.git
    (
        cd paru || (msg_err "Could not install paru!" && exit 1)
        makepkg -si
    )
    rm -rf paru
fi

# utilities

if prompt "Do you want to install utilities like bluetooth, brightness control, printing, and battery management?"; then

    # dashi for utility control

    if ! prog_exists dashi; then
        paru -Syu dashi
        sudo groupadd -f wheel
        sudo usermod -aG wheel "$USER"
    fi

    # passwords

    if prompt "Do you want to install password/2FA management?"; then
        paru -S --needed cotp
    fi

    # printing

    if prompt "Do you want to enable over the air printing?"; then
        paru -S --needed cups cups-browsed
        sudo systemctl enable cups-browsed
    fi

    if prompt "Do you want to install tuned as a battery profile manager?"; then
        paru -S --needed tuned
        sudo systemctl enable tuned.service
        sudo systemctl start tuned.service
        if prompt "Do you want to enable the recommended balanced-powersave mode?"; then
            tuned-adm profile balanced-battery
        fi
    fi
fi

# developer dependencies & utilities

if prompt "Do you want to install developer utilities, programs, and libraries?"; then
    if prompt "Do you want to install rust components and programs?"; then
        paru -S --needed rust-analyzer cmake lldb sccache 
    
        export RUSTUP_HOME="$HOME/.local/share/rustup/"
        export CARGO_HOME="$HOME/.local/share/cargo/"

        rustup default stable
        rustup component add rustfmt
    fi

    if prompt "Do you want to install Haskell components?"; then
    	curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh 
    fi

    if prompt "Do you want to install virtualization components?"; then
    	paru -S --needed docker docker-compose docker-buildx
    	sudo usermod -aG docker "$USER"
    fi

    if prompt "Do you want to install Java develpoment components and programs?"; then
    	paru -S --needed jdk-openjdk intellij-idea-ce-eap
    fi

    if prompt "Do you want to install JavaScript development components?"; then
        curl -fsSL https://bun.com/install | bash
        paru -S --needed typescript-language-server vscode-html-languageserver
    fi
fi
 
# core apps

if prompt "Do you want to install user applications?"; then
    paru -S --needed $PKG_THEME $PKG_CLI_EXTRA $PKG_GUI

    if ! systemd_running NetworkManager.service; then
        sudo systemctl enable NetworkManager.service
        sudo systemctl start NetworkManager.service
    fi

    if prompt "Do you want to install nerd fonts, chinese iconography, and emojis?"; then
        paru -S --needed ttf-jetbrains-mono-nerd noto-fonts-cjk noto-fonts-emoji
        fc-cache -fv
    fi

    if prompt "Do you want to enable screen sharing/recording components?"; then
        paru -S --needed wf-recorder xdg-desktop-portal-gtk
    fi

	if prompt "Do you want to install gaming components?"; then
		paru -S --needed glfw-wayland-minecraft-cursorfix prismlauncher
	fi

    # source-built applications

    if prompt "Do you want to install mpv usability scripts?"; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tomasklaen/uosc/HEAD/installers/unix.sh)"
        git clone https://github.com/po5/thumbfast
        (
            cd thumbfast || (msg_err "Could not install thumbfast" && exit 1)
            mkdir -p ~/.config/mpv/scripts/
            cp -p thumbfast.lua ~/.config/mpv/scripts/
        )
        rm -rf thumbfast
        git clone https://github.com/po5/mpv_sponsorblock
        (
            cd mpv_sponsorblock || (msg_err "Could not install mpv sponsorblock" && exit 1)
            mkdir -p ~/.config/mpv/scripts/
            cp -rp sponsorblock.lua sponsorblock_shared/ ~/.config/mpv/scripts/
        )
        rm -rf mpv_sponsorblock
    fi

    if prompt "Do you want to add iCloud photo syncing?"; then
        paru -S --needed icloudpd
        icloudpd --auth-only
        if prompt "Do you want to sync iCloud photos now?"; then
            icloudpd --skip-live-photos --only-print-filenames --folder-structure none --directory ~/Photos/Cloud/
        fi
    fi
fi

if prompt "Installation complete. Would you like to clean up pre-installed files and programs?"; then
	./clean.sh
fi

if prompt "Would you like to enable auto start with swaylock enabled?${NEW_LINE}This will automatically logout of any graphical environment"; then
    if [ ! -f $SYSTEMD_FILE ]; then
        sudo mkdir -p "$SYSTEMD_DIR"
        sudo touch "$SYSTEMD_FILE"
        echo "$SYSTEMD_SWAY" | sudo tee "$SYSTEMD_FILE" > /dev/null 2>&1
    fi

    sudo systemctl enable getty@tty1
    sudo systemctl start getty@tty1
fi

if prompt "Would you like to reboot now?"; then
    reboot
fi
