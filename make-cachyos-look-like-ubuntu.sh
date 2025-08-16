#!/bin/bash

# Ensure script runs with bash (CachyOS uses fish/zsh by default)
if [ -z "$BASH_VERSION" ]; then
  echo "This script requires bash. Restarting with bash..."
  exec bash "$0" "$@"
fi

set -e

trap 'echo "ERROR: An error occurred on line $LINENO. The script will now exit." >&2' ERR


# Title: make-cachyos-look-like-ubuntu.sh
# Description: This script performs all necessary steps to make a CachyOS Gnome
# desktop look like an Ubuntu desktop with Ubuntu themes and fonts.
# Original Author: DeltaLima
# Adapted for CachyOS by: Anonymo
# Date: 23.08.2025
# Version: 1.1-cachyos
# Usage: bash make-cachyos-look-like-ubuntu.sh
# 
# Based on: https://github.com/Anonymo/make-cachyOS-look-like-ubuntu
# 
# Copyright 2023 DeltaLima (Marcus Hanisch)
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy 
# of this software and associated documentation files (the “Software”), to deal
# in the Software without restriction, including without limitation the rights 
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
# copies of the Software, and to permit persons to whom the Software is 
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# 
#

arguments="$@"

# define the $packages[] array
declare -A packages

# the first three array entries are numbered because they have to be ordered

# install base desktop stuff
packages[0-base]="plymouth ecryptfs-utils curl wget python binutils" 

# install desktop base
packages[1-desktop-base]="ttf-ubuntu-font-family ttf-liberation
noto-fonts noto-fonts-emoji ttf-dejavu ttf-hack
gnome-software networkmanager-openvpn
dconf-editor thunderbird firefox-pure gnome-terminal"

# install gnome base (AUR packages)
packages[2-desktop-gnome]="extension-manager gnome-tweaks gnome-shell-extensions gnome-shell-extension-appindicator gnome-shell-extension-desktop-icons-ng"

# AUR packages to be installed separately
aur_packages="ttf-ms-fonts yaru-gtk-theme yaru-icon-theme yaru-sound-theme yaru-gnome-shell-theme gnome-shell-extension-dash-to-dock"

# if you want to add for automation purposes your own packages, just add another array field, like
#packages[4-my-packages]="shutter solaar steam-installer chromium dosbox gimp vlc audacity keepassxc audacious nextcloud-desktop"


# colors for colored output 8)
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

function message() {
     case $1 in
     warn)
       MESSAGE_TYPE="${YELLOW}WARN${ENDCOLOR}"
     ;;
     error)
       MESSAGE_TYPE="${RED}ERROR${ENDCOLOR}"
     ;;
     info|*)
       MESSAGE_TYPE="${GREEN}INFO${ENDCOLOR}"
     ;;
     esac

     if [ "$1" == "info" ] || [ "$1" == "warn" ] || [ "$1" == "error" ]
     then
       MESSAGE=$2
     else
       MESSAGE=$1
     fi

     echo -e "[${MESSAGE_TYPE}] $MESSAGE"
}

error () 
{
  message error "An error occurred! Check the output above for details."
  message error "Script execution failed at line $BASH_LINENO"
  exit 1
}

confirm_continue()
{
  message warn "Type '${GREEN}y${ENDCOLOR}' or '${GREEN}yes${ENDCOLOR}' and hit [ENTER] to continue"
  read -p "[y/N?] " user_confirmation
  # Convert to lowercase using tr for better shell compatibility
  user_confirmation_lower=$(echo "$user_confirmation" | tr '[:upper:]' '[:lower:]')
  if [ "$user_confirmation_lower" != "y" ] && [ "$user_confirmation_lower" != "yes" ]
  then
    message error "Installation aborted by user."
    exit 1
  fi
}

###

if [ "$(whoami)" == "root" ]
then message error "I cannot run as root"
error
fi

if [ -z "$arguments" ]
then
  package_categories="${!packages[@]}"
else
  package_categories="$@"
fi

# sort the category list, some of them have to be in order
package_categories="$(echo $package_categories | xargs -n1 | sort | xargs)"
message "Welcome to ${GREEN}make-cachyos-look-like-ubuntu${ENDCOLOR}!"
message ""
message "This script makes a fresh CachyOS-Gnome installation to look like"
message "an Ubuntu Gnome installation. Settings are applied for the user"
message "running this script (${YELLOW}${USER}${ENDCOLOR})".
message ""
message "Your user has to be in the 'sudo' or 'wheel' group."
message "If not, the script will guide you."
message ""
message "The process is divided into following steps:"
message "${YELLOW}$package_categories${ENDCOLOR}"
message ""
message "If you want, you can run only a few of them, e.g. just '${YELLOW}2-desktop-gnome${ENDCOLOR}':"
message " ${YELLOW}bash $0 2-desktop-gnome${ENDCOLOR}"
message ""
message warn "Some files, like gtk settings, get overwritten without asking."
message warn "If this is not a fresh installation, make a backup first!"
message ""
confirm_continue

message "Continue with installation..."

# Create backup of original CachyOS settings
backup_dir="$HOME/.cachyos-original-backup-$(date +%s)"
mkdir -p "$backup_dir"
message "Creating backup of original settings in: $backup_dir"

# Backup current dconf settings
dconf dump /org/gnome/ > "$backup_dir/original-gnome-settings.ini" 2>/dev/null || message warn "Could not backup dconf settings"

# Backup specific settings that we'll modify
gsettings get org.gnome.shell favorite-apps > "$backup_dir/original-favorites.txt" 2>/dev/null || true
gsettings get org.gnome.desktop.interface gtk-theme > "$backup_dir/original-gtk-theme.txt" 2>/dev/null || true
gsettings get org.gnome.desktop.interface icon-theme > "$backup_dir/original-icon-theme.txt" 2>/dev/null || true
gsettings get org.gnome.desktop.interface font-name > "$backup_dir/original-font-name.txt" 2>/dev/null || true
gsettings get org.gnome.desktop.background picture-uri > "$backup_dir/original-background.txt" 2>/dev/null || true
gsettings get org.gnome.desktop.background picture-uri-dark > "$backup_dir/original-background-dark.txt" 2>/dev/null || true
gsettings get org.gnome.mutter overlay-key > "$backup_dir/original-overlay-key.txt" 2>/dev/null || true
gsettings get org.gnome.shell.keybindings toggle-application-view > "$backup_dir/original-toggle-application-view.txt" 2>/dev/null || true
xdg-settings get default-web-browser > "$backup_dir/original-default-browser.txt" 2>/dev/null || echo "" > "$backup_dir/original-default-browser.txt"
xdg-settings get default-url-scheme-handler mailto > "$backup_dir/original-default-email.txt" 2>/dev/null || echo "" > "$backup_dir/original-default-email.txt"

# Backup GRUB settings if exists
if [ -f /etc/default/grub ]; then
  cp /etc/default/grub "$backup_dir/original-grub" 2>/dev/null || message warn "Could not backup GRUB settings"
fi

# Backup environment file if exists  
if [ -f /etc/environment ]; then
  cp /etc/environment "$backup_dir/original-environment" 2>/dev/null || true
fi

# Save backup location for undo script
echo "$backup_dir" > "$HOME/.ubuntu-transformation-backup-location"

message "✅ Original settings backed up to: $backup_dir"

# Get current user and groups
CURRENT_USER=$(whoami)
USER_GROUPS=$(groups)

# Check if user is in sudo or wheel group (CachyOS uses wheel)
if ! echo "$USER_GROUPS" | grep -E "(sudo|wheel)" > /dev/null; then
  message error "Your user '$CURRENT_USER' is not in the 'sudo' or 'wheel' group."
  message error "CachyOS typically uses the 'wheel' group for sudo access."
  message error "Add your user to the wheel group with:"
  message error " ${YELLOW}su -c \"usermod -aG wheel ${CURRENT_USER}\"${ENDCOLOR}"
  message error "Then logout/login or reboot and run this script again."
  error
fi

message "✅ User '$CURRENT_USER' is in the $(echo "$USER_GROUPS" | grep -oE "(sudo|wheel)" | head -1) group"
message "check pacman configuration"
# Ensure multilib repository is enabled for some packages
if ! grep -q "^\[multilib\]" /etc/pacman.conf
then
  message warn "Enabling multilib repository for additional packages"
  confirm_continue
  message "backup pacman.conf"
  sudo cp /etc/pacman.conf /etc/pacman.conf.$(date "+%s")bak
  sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
  message "pacman -Sy"
  sudo pacman -Sy
fi


# iterate through $packages
for category in $package_categories
do
  message "Packages category: ${YELLOW}${category}${ENDCOLOR}"
  message "Packages contained: "
  message "${GREEN}${packages[$category]}${ENDCOLOR}"
  
  message "running pre-tasks"
  # pre installation steps for categories
  case $category in
    1-desktop-base)
      # Remove unwanted browsers before installing firefox-pure
      message "removing unwanted browsers"
      sudo pacman -Rns --noconfirm firefox epiphany 2>/dev/null || message warn "Some browsers were not installed or could not be removed"
      ;;
    nice)
      # No equivalent needed for CachyOS/pacman
      ;;
  esac
  
  # package installation #
  message "installing packages"
  if ! sudo pacman -S --needed --noconfirm ${packages[$category]}; then
    message error "Failed to install packages: ${packages[$category]}"
    error
  fi
  
  # install AUR packages for specific categories
  if [ "$category" == "2-desktop-gnome" ] && [ -n "$aur_packages" ]
  then
    message "installing AUR packages"
    # Check for available AUR helper
    if command -v yay &> /dev/null
    then
      message "using yay for AUR packages"
      if ! yay -S --needed --noconfirm $aur_packages; then
        message error "Failed to install AUR packages with yay: $aur_packages"
        error
      fi
    elif command -v paru &> /dev/null
    then
      message "using paru for AUR packages"
      if ! paru -S --needed --noconfirm $aur_packages; then
        message error "Failed to install AUR packages with paru: $aur_packages"
        error
      fi
    else
      message error "No AUR helper found. Please install yay or paru first to install AUR packages."
      error
    fi
  fi
  
  message "running post-tasks"
  # post installation steps for categories
  case $category in
    0-base)
      message "Configuring bootloader for quiet splash..."
      
      # Detect bootloader and configure accordingly
      if [ -f /etc/default/grub ] && command -v grub-mkconfig >/dev/null 2>&1; then
        message "Detected GRUB bootloader"
        if ! sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*$/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"/g' /etc/default/grub; then
          message error "Failed to update GRUB configuration"
          error
        fi
        sudo grub-mkconfig -o /boot/grub/grub.cfg
      elif [ -d /boot/loader/entries ] && command -v bootctl >/dev/null 2>&1; then
        message "Detected systemd-boot bootloader"
        message "Note: systemd-boot entries may need manual editing for quiet splash"
        message "Edit files in /boot/loader/entries/ and add 'quiet splash' to options line"
      elif [ -f /boot/refind_linux.conf ] || [ -d /boot/EFI/refind ]; then
        message "Detected rEFInd bootloader"
        message "Note: rEFInd configuration may need manual editing for quiet splash"
        message "Edit /boot/refind_linux.conf or entries in /boot/EFI/refind/"
      elif [ -f /boot/limine.cfg ] || [ -d /boot/EFI/BOOT ] && grep -q "limine" /boot/EFI/BOOT/* 2>/dev/null; then
        message "Detected Limine bootloader"
        message "Note: Limine configuration may need manual editing for quiet splash"
        message "Edit /boot/limine.cfg and add 'quiet splash' to KERNEL_CMDLINE"
      else
        message warn "Could not detect bootloader type"
        message warn "You may need to manually add 'quiet splash' to your bootloader configuration"
      fi
      ;;

    1-desktop-base)
      # fix big cursor issue in qt apps
      message "Set XCURSOR_SIZE=24 in /etc/environment to fix Big cursor bug in QT"
      grep "XCURSOR_SIZE" /etc/environment || echo "XCURSOR_SIZE=24" | sudo tee -a /etc/environment > /dev/null
      
      # Set default applications
      message "configuring default applications"
      
      # Set firefox-pure as default browser
      message "setting firefox-pure as default web browser"
      xdg-settings set default-web-browser firefox-pure.desktop 2>/dev/null || message warn "Could not set firefox-pure as default browser"
      
      # Handle email client defaults
      current_email=$(xdg-settings get default-url-scheme-handler mailto 2>/dev/null || echo "")
      message "checking current default email client: $current_email"
      
      if [[ "$current_email" == "org.gnome.Evolution.desktop" ]]; then
        message "Evolution is default email client - keeping it unchanged"
      else
        message "setting Thunderbird as default email client"
        xdg-settings set default-url-scheme-handler mailto thunderbird.desktop 2>/dev/null || message warn "Could not set Thunderbird as default email client"
      fi
      ;;

    2-desktop-gnome)
    
      message "allow user-extensions"
      gsettings set org.gnome.shell disable-user-extensions false
      
      message "enable gnome shell extensions"
      # AppIndicator extension (try both possible IDs)
      gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com 2>/dev/null || \
      gnome-extensions enable ubuntu-appindicators@ubuntu.com 2>/dev/null || \
      message warn "Could not enable AppIndicator extension - may need to be enabled manually"
      
      # Enable other extensions with error handling
      gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || \
      message warn "Could not enable user-theme extension"
      
      gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || \
      message warn "Could not enable dash-to-dock extension"
      
      gnome-extensions enable ding@rastersoft.com 2>/dev/null || \
      gnome-extensions enable desktop-icons-ng@rastersoft.com 2>/dev/null || \
      message warn "Could not enable desktop-icons extension"
      
      message "apply settings for dash-to-dock"
      # dash-to-dock
      gsettings set org.gnome.shell.extensions.dash-to-dock autohide-in-fullscreen false
      gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
      gsettings set org.gnome.shell.extensions.dash-to-dock background-color '#0c0c0c'
      gsettings set org.gnome.shell.extensions.dash-to-dock custom-background-color true
      gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.64000000000000001
      gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'focus-or-previews'
      gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true
      gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 42
      gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
      gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT'
      gsettings set org.gnome.shell.extensions.dash-to-dock extend-height true
      gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true
      gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DOTS'
      gsettings set org.gnome.shell.extensions.dash-to-dock icon-size-fixed true
      
      
      message "apply settings for gnome desktop"
      # desktop
      gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/gnome/amber-l.jxl'
      gsettings set org.gnome.desktop.background picture-uri-dark 'file:///usr/share/backgrounds/gnome/amber-d.jxl'
      gsettings set org.gnome.desktop.background show-desktop-icons true
      gsettings set org.gnome.desktop.background primary-color '#E66100'
      gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
      gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:appmenu'
      gsettings set org.gnome.desktop.interface enable-hot-corners true
      gsettings set org.gnome.desktop.interface font-antialiasing 'grayscale'
      gsettings set org.gnome.desktop.interface font-hinting 'slight'
      gsettings set org.gnome.desktop.interface font-name 'Ubuntu 11'
      gsettings set org.gnome.desktop.interface monospace-font-name 'Ubuntu Mono 13'
      gsettings set org.gnome.desktop.interface document-font-name 'Sans 11'
      gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Ubuntu Bold 11'
      gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'
      gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark'
      gsettings set org.gnome.desktop.interface icon-theme 'Yaru-dark'

      # yaru gnome-shell theme is a bit broken actually, system osd network ellapse button glitched
      # gsettings set org.gnome.shell.extensions.user-theme name 'Yaru-dark'

      # set accent color to orange
      gsettings set org.gnome.desktop.interface accent-color 'orange'

      # configure Super key to open applications menu (Ubuntu-like behavior)
      message "configure Super key to open applications menu"
      # Disable the default overlay (activities overview) behavior
      gsettings set org.gnome.mutter overlay-key '' 2>/dev/null || message warn "Could not disable overlay-key"
      # Set Super key to toggle application view instead
      gsettings set org.gnome.shell.keybindings toggle-application-view "['Super_L']" 2>/dev/null || message warn "Could not set toggle-application-view keybinding"
      message "Super key configured to open applications menu like Ubuntu"

      # gtk-3.0 and gtk-4.0 settings
      message "setting gtk-3.0 and gtk-4.0 default to dark"
      mkdir -p $HOME/.config/gtk-{3,4}.0
      cat << EOF | tee $HOME/.config/gtk-3.0/settings.ini > $HOME/.config/gtk-4.0/settings.ini
[Settings]
gtk-application-prefer-dark-theme=1
EOF

      # apply adwaita gtk-3.0 and gtk-4.0 orange accent color
      message "setting gtk-3.0 and gtk-4.0 accent color to orange"
      cat << EOF | tee $HOME/.config/gtk-3.0/gtk.css > $HOME/.config/gtk-4.0/gtk.css
@define-color accent_color #ffbe6f;
@define-color accent_bg_color #e66100;
@define-color accent_fg_color #ffffff;
EOF

      # configure essential apps in dock (firefox-pure, thunderbird, terminal)
      message "configure essential applications in dock"
      current_apps=$(gsettings get org.gnome.shell favorite-apps)
      
      # Remove regular firefox if present
      current_apps=$(echo "$current_apps" | sed 's/firefox\.desktop, //g' | sed 's/, firefox\.desktop//g' | sed 's/firefox\.desktop//g')
      
      # Ensure firefox-pure is in dock
      if ! echo "$current_apps" | grep -q "firefox-pure\.desktop"; then
        message "adding Firefox-pure to dock"
        current_apps=$(echo "$current_apps" | sed "s/\]/, 'firefox-pure.desktop']/")
      fi
      
      # Handle email client in dock
      if echo "$current_apps" | grep -q "org\.gnome\.Evolution\.desktop"; then
        message "replacing Evolution with Thunderbird in dock"
        current_apps=$(echo "$current_apps" | sed 's/org\.gnome\.Evolution\.desktop/thunderbird\.desktop/')
      elif ! echo "$current_apps" | grep -q "thunderbird\.desktop"; then
        message "adding Thunderbird to dock"
        current_apps=$(echo "$current_apps" | sed "s/\]/, 'thunderbird.desktop']/")
      fi
      
      # Ensure GNOME terminal is in dock
      if ! echo "$current_apps" | grep -q -E "(gnome-terminal|org\.gnome\.Terminal)\.desktop"; then
        message "adding GNOME terminal to dock"
        # Try to add GNOME terminal (check common desktop file names)
        if [ -f /usr/share/applications/org.gnome.Terminal.desktop ]; then
          current_apps=$(echo "$current_apps" | sed "s/\]/, 'org.gnome.Terminal.desktop']/")
        elif [ -f /usr/share/applications/gnome-terminal.desktop ]; then
          current_apps=$(echo "$current_apps" | sed "s/\]/, 'gnome-terminal.desktop']/")
        else
          message warn "GNOME Terminal not found - may need to install gnome-terminal package"
        fi
      fi
      
      # Apply the updated favorites list
      gsettings set org.gnome.shell favorite-apps "$current_apps"
      message "Essential apps configured in dock: Firefox-pure, Thunderbird, Terminal"

      # replace yelp with settings in dock
      message "replace yelp with settings in dock"
      gsettings get org.gnome.shell favorite-apps | grep "org.gnome.Settings.desktop" > /dev/null ||
      gsettings set org.gnome.shell favorite-apps "$(gsettings get  org.gnome.shell favorite-apps  | sed 's/yelp\.desktop/org\.gnome\.Settings\.desktop/')"
      ;;
  esac
  
done

message "${GREEN}DONE!!${ENDCOLOR}"
message warn "${RED}IMPORTANT!! ${YELLOW}Rerun this script again after a reboot, if this is the first run of it!${ENDCOLOR}"
