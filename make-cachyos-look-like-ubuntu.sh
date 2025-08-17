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

# Check if user wants status check only
if [ "$1" = "--status" ] || [ "$1" = "-s" ]; then
    message "🔍 Ubuntu Transformation Status Check"
    message "======================================="
    validate_configuration
    exit $?
fi

# Display help if requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    message "🛠️ Ubuntu Transformation Script for CachyOS GNOME"
    message "Usage: $0 [OPTIONS] [CATEGORIES]"
    message ""
    message "Options:"
    message "  --status, -s    Check current transformation status"
    message "  --help, -h      Show this help message"
    message ""
    message "Categories:"
    message "  0-base          Base system packages and configuration"
    message "  1-desktop-base  Desktop environment packages"
    message "  2-desktop-gnome GNOME-specific packages and configuration"
    message ""
    message "Examples:"
    message "  $0                    # Full transformation"
    message "  $0 --status          # Check current status"
    message "  $0 2-desktop-gnome   # Install only GNOME packages"
    exit 0
fi

# define the $packages[] array
declare -A packages

# the first three array entries are numbered because they have to be ordered

# install base desktop stuff
packages[0-base]="plymouth ecryptfs-utils curl wget python binutils" 

# install desktop base
packages[1-desktop-base]="ttf-ubuntu-font-family ttf-liberation
noto-fonts noto-fonts-emoji ttf-dejavu ttf-hack
gnome-software dconf-editor thunderbird firefox-pure gnome-terminal rofi-wayland"

# install gnome base (AUR packages)
packages[2-desktop-gnome]="extension-manager gnome-tweaks gnome-shell-extensions gnome-shell-extension-appindicator gnome-shell-extension-desktop-icons-ng"

# AUR packages to be installed separately
aur_packages="ttf-ms-fonts yaru-gtk-theme yaru-icon-theme yaru-sound-theme yaru-gnome-shell-theme gnome-shell-extension-dash-to-dock gnome-hud appmenu-gtk-module-git gnome-shell-extension-unite ubuntu-wallpapers libreoffice-style-yaru-fullcolor"

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

# Retry mechanism for network operations
function retry_command() {
    local max_attempts=3
    local delay=2
    local attempt=1
    local command=("$@")
    
    while [ $attempt -le $max_attempts ]; do
        message info "Attempt $attempt/$max_attempts: ${command[*]}"
        
        if "${command[@]}"; then
            return 0
        else
            if [ $attempt -lt $max_attempts ]; then
                message warn "Attempt $attempt failed, retrying in ${delay}s..."
                sleep $delay
                delay=$((delay * 2))  # Exponential backoff
            else
                message error "All $max_attempts attempts failed for: ${command[*]}"
                return 1
            fi
        fi
        ((attempt++))
    done
}

# Enhanced package installation with retry and progress tracking
function install_packages_retry() {
    local package_manager="$1"
    shift
    local packages=("$@")
    local package_count=${#packages[@]}
    
    if [ $package_count -eq 1 ]; then
        message "📦 Installing package: ${packages[*]}"
    else
        message "📦 Installing $package_count packages: ${packages[*]}"
    fi
    
    case "$package_manager" in
        "pacman")
            retry_command sudo pacman -S --needed --noconfirm "${packages[@]}"
            ;;
        "yay")
            retry_command yay -S --needed --noconfirm "${packages[@]}"
            ;;
        "paru")
            retry_command paru -S --needed --noconfirm "${packages[@]}"
            ;;
        *)
            message error "Unknown package manager: $package_manager"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        if [ $package_count -eq 1 ]; then
            message info "✅ Package installed successfully"
        else
            message info "✅ All $package_count packages installed successfully"
        fi
    fi
}

# Configuration validation after installation
function validate_configuration() {
    local validation_errors=0
    
    message "🔍 Validating transformation configuration..."
    
    # Check if essential GNOME extensions are enabled
    if command -v gnome-extensions >/dev/null 2>&1; then
        local enabled_extensions=$(gnome-extensions list --enabled 2>/dev/null)
        
        if echo "$enabled_extensions" | grep -q "dash-to-dock"; then
            message info "✅ Dash to Dock extension enabled"
        else
            message warn "⚠️ Dash to Dock extension not enabled"
            ((validation_errors++))
        fi
        
        if echo "$enabled_extensions" | grep -q "unite"; then
            message info "✅ Unite Shell extension enabled"
        else
            message warn "⚠️ Unite Shell extension not enabled"
        fi
        
        if echo "$enabled_extensions" | grep -q "appindicator"; then
            message info "✅ AppIndicator extension enabled"
        else
            message warn "⚠️ AppIndicator extension not enabled"
        fi
    else
        message warn "⚠️ gnome-extensions command not available"
        ((validation_errors++))
    fi
    
    # Check theme configuration
    local gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
    if [[ "$gtk_theme" == *"Yaru"* ]]; then
        message info "✅ Yaru GTK theme applied: $gtk_theme"
    else
        message warn "⚠️ Yaru GTK theme not applied (current: $gtk_theme)"
    fi
    
    local icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")
    if [[ "$icon_theme" == *"Yaru"* ]]; then
        message info "✅ Yaru icon theme applied: $icon_theme"
    else
        message warn "⚠️ Yaru icon theme not applied (current: $icon_theme)"
    fi
    
    # Check font configuration
    local font_name=$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null | tr -d "'")
    if [[ "$font_name" == *"Ubuntu"* ]]; then
        message info "✅ Ubuntu font applied: $font_name"
    else
        message warn "⚠️ Ubuntu font not applied (current: $font_name)"
    fi
    
    # Check if GNOME HUD is configured
    if command -v gnomehud >/dev/null 2>&1 || [ -f "$HOME/.local/bin/gnomehud" ]; then
        message info "✅ GNOME HUD is available"
        
        # Check if keybinding is configured
        local hud_binding=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/gnome-hud/ binding 2>/dev/null | tr -d "'" | tr -d "[]")
        if [[ "$hud_binding" == *"Primary"* && "$hud_binding" == *"Alt"* && "$hud_binding" == *"space"* ]]; then
            message info "✅ GNOME HUD keybinding configured: $hud_binding"
        else
            message warn "⚠️ GNOME HUD keybinding may not be configured"
        fi
    else
        message warn "⚠️ GNOME HUD not found"
    fi
    
    # Check Super key configuration
    local overlay_key=$(gsettings get org.gnome.mutter overlay-key 2>/dev/null | tr -d "'")
    local toggle_app_view=$(gsettings get org.gnome.shell.keybindings toggle-application-view 2>/dev/null)
    if [[ "$overlay_key" == "" ]] && [[ "$toggle_app_view" == *"Super_L"* ]]; then
        message info "✅ Super key configured for application view"
    else
        message warn "⚠️ Super key configuration may not be complete"
    fi
    
    if [ $validation_errors -eq 0 ]; then
        message info "✅ Configuration validation completed - transformation looks good!"
    else
        message warn "⚠️ Configuration validation found $validation_errors potential issues"
        message warn "Run the script again or check troubleshooting section in README"
    fi
    
    return $validation_errors
}

# Pre-flight validation checks
function validate_system() {
    local validation_errors=0
    
    message "🔍 Running pre-flight validation checks..."
    
    # Check if running as root
    if [ "$(whoami)" == "root" ]; then
        message error "Cannot run as root user"
        return 1
    fi
    
    # Check desktop environment
    if [ -z "$XDG_CURRENT_DESKTOP" ]; then
        message warn "Could not detect desktop environment"
    elif [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]]; then
        message warn "This script is designed for GNOME. Current DE: $XDG_CURRENT_DESKTOP"
        message warn "Some features may not work correctly"
    else
        message info "✅ GNOME desktop environment detected"
    fi
    
    # Check internet connectivity
    if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
        message info "✅ Internet connectivity verified"
    else
        message error "❌ No internet connection detected"
        message error "Internet connection required for package downloads"
        ((validation_errors++))
    fi
    
    # Check available disk space (at least 2GB recommended)
    local available_mb=$(df -BM "$HOME" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/M//' 2>/dev/null || echo "0")
    if [ "$available_mb" -gt 2048 ]; then
        message info "✅ Sufficient disk space available (${available_mb}MB)"
    else
        message warn "⚠️ Low disk space: ${available_mb}MB available (2GB+ recommended)"
    fi
    
    # Check if pacman is available
    if command -v pacman >/dev/null 2>&1; then
        message info "✅ Pacman package manager available"
    else
        message error "❌ Pacman not found - this script requires Arch-based distribution"
        ((validation_errors++))
    fi
    
    # Check for AUR helper
    if command -v yay >/dev/null 2>&1; then
        message info "✅ yay AUR helper detected"
    elif command -v paru >/dev/null 2>&1; then
        message info "✅ paru AUR helper detected"
    else
        message warn "⚠️ No AUR helper found (yay/paru) - some packages may need manual installation"
    fi
    
    if [ $validation_errors -gt 0 ]; then
        message error "Pre-flight validation failed with $validation_errors critical errors"
        message error "Please resolve the issues above before continuing"
        return 1
    else
        message info "✅ Pre-flight validation completed successfully"
        return 0
    fi
}

if [ "$(whoami)" == "root" ]
then message error "I cannot run as root"
error
fi

# Run validation checks
if ! validate_system; then
    exit 1
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
categories_array=($package_categories)
total_categories=${#categories_array[@]}
current_category=0

for category in $package_categories
do
  ((current_category++))
  message "📋 Processing category [$current_category/$total_categories]: ${YELLOW}${category}${ENDCOLOR}"
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
  if ! install_packages_retry "pacman" ${packages[$category]}; then
    message error "Failed to install packages after retries: ${packages[$category]}"
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
      if ! install_packages_retry "yay" $aur_packages; then
        message warn "Some AUR packages failed to install after retries"
        # Try to install gnome-hud via pip as fallback
        if ! command -v gnomehud >/dev/null 2>&1 && ! [ -f "$HOME/.local/bin/gnomehud" ]; then
          message "installing gnome-hud via pip as fallback"
          pip install --user gnome-hud 2>/dev/null || message warn "Could not install gnome-hud via pip"
        fi
      fi
    elif command -v paru &> /dev/null
    then
      message "using paru for AUR packages"
      if ! install_packages_retry "paru" $aur_packages; then
        message warn "Some AUR packages failed to install after retries"
        # Try to install gnome-hud via pip as fallback
        if ! command -v gnomehud >/dev/null 2>&1 && ! [ -f "$HOME/.local/bin/gnomehud" ]; then
          message "installing gnome-hud via pip as fallback"
          pip install --user gnome-hud 2>/dev/null || message warn "Could not install gnome-hud via pip"
        fi
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
      message "Bootloader configuration for quiet splash..."
      message warn "Do you want to configure your bootloader for quiet splash boot?"
      message warn "This is optional and depends on your bootloader (GRUB/systemd-boot/rEFInd/Limine)"
      read -p "[y/N?] " configure_bootloader
      configure_bootloader_lower=$(echo "$configure_bootloader" | tr '[:upper:]' '[:lower:]')
      
      if [ "$configure_bootloader_lower" = "y" ] || [ "$configure_bootloader_lower" = "yes" ]; then
        # Detect bootloader and configure accordingly
        if [ -f /etc/default/grub ] && command -v grub-mkconfig >/dev/null 2>&1; then
          message "Detected GRUB bootloader - configuring automatically"
          if ! sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*$/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"/g' /etc/default/grub; then
            message error "Failed to update GRUB configuration"
            error
          fi
          sudo grub-mkconfig -o /boot/grub/grub.cfg
          message "GRUB configured for quiet splash boot"
        elif [ -d /boot/loader/entries ] && command -v bootctl >/dev/null 2>&1; then
          message "Detected systemd-boot bootloader"
          message "Manual configuration needed:"
          message "1. Edit files in /boot/loader/entries/"
          message "2. Add 'quiet splash' to the options line"
          message "Example: options root=UUID=... rw quiet splash"
        elif [ -f /boot/refind_linux.conf ] || [ -d /boot/EFI/refind ]; then
          message "Detected rEFInd bootloader"
          message "Manual configuration needed:"
          message "1. Edit /boot/refind_linux.conf"
          message "2. Add 'quiet splash' to kernel parameters"
        elif [ -f /boot/limine.cfg ] || [ -d /boot/EFI/BOOT ] && grep -q "limine" /boot/EFI/BOOT/* 2>/dev/null; then
          message "Detected Limine bootloader"
          message "Manual configuration needed:"
          message "1. Edit /boot/limine.cfg"
          message "2. Add 'quiet splash' to KERNEL_CMDLINE"
        else
          message warn "Could not detect bootloader type"
          message warn "Manually add 'quiet splash' to your bootloader configuration"
        fi
      else
        message "Skipping bootloader configuration (you can configure manually later)"
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
      
      gnome-extensions enable unite@hardpixel.eu 2>/dev/null || \
      message warn "Could not enable unite-shell extension"
      
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
      
      # Configure gnome-hud keybinding and service
      message "configuring GNOME HUD (Unity-like menu search)"
      
      # Check if gnome-hud is installed via pip or system
      if command -v gnomehud >/dev/null 2>&1 || [ -f "$HOME/.local/bin/gnomehud" ]; then
        message "setting up GNOME HUD keybinding (Ctrl+Alt+Space)"
        
        # Set up custom keybinding for HUD
        custom_bindings=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "[]")
        if ! echo "$custom_bindings" | grep -q "gnome-hud"; then
          # Add new custom keybinding
          gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/gnome-hud/']"
          gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/gnome-hud/ name 'GNOME HUD'
          
          # Try to find gnomehud command in different locations
          if [ -f "$HOME/.local/bin/gnomehud" ]; then
            gnomehud_cmd="$HOME/.local/bin/gnomehud"
          else
            gnomehud_cmd="gnomehud"
          fi
          
          # Use rofi if available for better HUD experience
          if command -v rofi >/dev/null 2>&1; then
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/gnome-hud/ command "${gnomehud_cmd}-rofi"
          else
            gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/gnome-hud/ command "$gnomehud_cmd"
          fi
          
          gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/gnome-hud/ binding '<Primary><Alt>space'
        fi
        
        # Create autostart entry for HUD service
        message "setting up GNOME HUD service autostart"
        mkdir -p "$HOME/.config/autostart"
        
        # Find the correct service command
        if [ -f "$HOME/.local/bin/gnomehud-service" ]; then
          service_cmd="$HOME/.local/bin/gnomehud-service"
        else
          service_cmd="gnomehud-service"
        fi
        
        cat > "$HOME/.config/autostart/gnome-hud.desktop" << EOF
[Desktop Entry]
Type=Application
Name=GNOME HUD Service
Comment=Unity-like HUD menu service
Exec=$service_cmd
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
StartupNotify=false
EOF
        
        # Try to start the service now
        if command -v gnomehud-service >/dev/null 2>&1 || [ -f "$HOME/.local/bin/gnomehud-service" ]; then
          message "starting GNOME HUD service"
          nohup $service_cmd >/dev/null 2>&1 &
        fi
        
        message "GNOME HUD configured - use Ctrl+Alt+Space to open menu search"
      else
        message warn "GNOME HUD not found - it may need to be installed manually with: pip install --user gnome-hud"
      fi
      ;;
  esac
  
done

# Validate the final configuration
message ""
validate_configuration

message "${GREEN}DONE!!${ENDCOLOR}"
message warn "${RED}IMPORTANT!! ${YELLOW}Rerun this script again after a reboot, if this is the first run of it!${ENDCOLOR}"
