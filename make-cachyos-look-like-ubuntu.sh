#!/bin/bash

# Title: make-cachyos-look-like-ubuntu.sh
# Description: This script performs all necessary steps to make a CachyOS Gnome
# desktop look like an Ubuntu desktop with Ubuntu themes and fonts.
# Original Author: DeltaLima
# Adapted for CachyOS by: raul
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
dconf-editor thunderbird"

# install gnome base (AUR packages)
packages[2-desktop-gnome]="gnome-shell-extension-manager gnome-tweaks gnome-shell-extensions"

# AUR packages to be installed separately
aur_packages="ttf-ms-fonts yaru-gtk-theme yaru-icon-theme yaru-sound-theme yaru-gnome-shell-theme"

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
  message error "ERROR!!"
  exit 1
}

confirm_continue()
{
  message warn "Type '${GREEN}y${ENDCOLOR}' or '${GREEN}yes${ENDCOLOR}' and hit [ENTER] to continue"
  read -p "[y/N?] " continue
  if [ "${continue,,}" != "y" ] && [ "${continue,,}" != "yes" ]
  then
    message error "Installation aborted."
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
message "Your user has to be in the 'sudo' group."
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

if ! groups | grep sudo > /dev/null
then
  message error "Your user $USER is not in group 'sudo'."
  message error "Add your user to the group with:"
  message error " ${YELLOW}su -c \"/usr/sbin/usermod -aG sudo ${USER}\"${ENDCOLOR}"
  message error "after that, you need to reboot."
  error
fi
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
    nice)
      # No equivalent needed for CachyOS/pacman
      ;;
  esac
  
  # package installation #
  message "installing packages"
  sudo pacman -S --needed --noconfirm ${packages[$category]} || error
  
  # install AUR packages for specific categories
  if [ "$category" == "2-desktop-gnome" ] && [ -n "$aur_packages" ]
  then
    message "installing AUR packages"
    # Check for available AUR helper
    if command -v yay &> /dev/null
    then
      message "using yay for AUR packages"
      yay -S --needed --noconfirm $aur_packages || error
    elif command -v paru &> /dev/null
    then
      message "using paru for AUR packages"
      paru -S --needed --noconfirm $aur_packages || error
    else
      message error "No AUR helper found. Please install yay or paru first to install AUR packages."
      error
    fi
  fi
  
  message "running post-tasks"
  # post installation steps for categories
  case $category in
    0-base)
      message "sed default grub option"
      sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*$/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"/g' /etc/default/grub || error
      sudo grub-mkconfig -o /boot/grub/grub.cfg
      ;;

    1-desktop-base)
      # fix big cursor issue in qt apps
      message "Set XCURSOR_SIZE=24 in /etc/environment to fix Big cursor bug in QT"
      grep "XCURSOR_SIZE" /etc/environment || echo "XCURSOR_SIZE=24" | sudo tee -a /etc/environment > /dev/null
      ;;

    2-desktop-gnome)
    
      message "allow user-extensions"
      gsettings set org.gnome.shell disable-user-extensions false
      
      message "enable gnome shell extensions"
      gnome-extensions enable ubuntu-appindicators@ubuntu.com
      
      # panel-osd does no longer exist in debian 13
      #gnome-extensions enable panel-osd@berend.de.schouwer.gmail.com
      gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
      gnome-extensions enable dash-to-dock@micxgx.gmail.com
      gnome-extensions enable ding@rastersoft.com
      
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

      # remove firefox-esr from dock (using system firefox instead)
      message "remove firefox-esr from dock"
      gsettings set org.gnome.shell favorite-apps "$(gsettings get  org.gnome.shell favorite-apps  | sed 's/firefox-esr\.desktop, //g' | sed 's/, firefox-esr\.desktop//g' | sed 's/firefox-esr\.desktop//g')"

      # replace evolution with thunderbird in dock
      message "replace evolution with thunderbird in dock"
      gsettings get org.gnome.shell favorite-apps | grep "thunderbird.desktop" > /dev/null ||
      gsettings set org.gnome.shell favorite-apps "$(gsettings get  org.gnome.shell favorite-apps  | sed 's/org\.gnome\.Evolution\.desktop/thunderbird\.desktop/')"

      # replace yelp with settings in dock
      message "replace yelp with settings in dock"
      gsettings get org.gnome.shell favorite-apps | grep "org.gnome.Settings.desktop" > /dev/null ||
      gsettings set org.gnome.shell favorite-apps "$(gsettings get  org.gnome.shell favorite-apps  | sed 's/yelp\.desktop/org\.gnome\.Settings\.desktop/')"
      ;;
  esac
  
done

message "${GREEN}DONE!!${ENDCOLOR}"
message warn "${RED}IMPORTANT!! ${YELLOW}Rerun this script again after a reboot, if this is the first run of it!${ENDCOLOR}"
