#!/bin/bash

# Ensure script runs with bash (CachyOS uses fish/zsh by default)
if [ -z "$BASH_VERSION" ]; then
  echo "This script requires bash. Restarting with bash..."
  exec bash "$0" "$@"
fi

set -e

trap 'echo "ERROR: An error occurred on line $LINENO. The script will now exit." >&2' ERR

# Title: undo-ubuntu-transformation.sh
# Description: Undo script for make-cachyos-look-like-ubuntu.sh
# This script attempts to restore CachyOS defaults and remove Ubuntu theming

# Colors for output
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

confirm_continue() {
  message warn "Type '${GREEN}y${ENDCOLOR}' or '${GREEN}yes${ENDCOLOR}' and hit [ENTER] to continue"
  read -p "[y/N?] " user_confirmation
  # Convert to lowercase using tr for better shell compatibility
  user_confirmation_lower=$(echo "$user_confirmation" | tr '[:upper:]' '[:lower:]')
  if [ "$user_confirmation_lower" != "y" ] && [ "$user_confirmation_lower" != "yes" ]
  then
    message error "Undo operation cancelled by user."
    exit 1
  fi
}

message "🔄 CachyOS Ubuntu Transformation Undo Script"
message ""
message warn "This script will attempt to:"
message "• Restore GNOME to default CachyOS settings"
message "• Remove Ubuntu themes and fonts"
message "• Reset desktop icons and dock configuration"
message "• Disable Ubuntu-style extensions"
message "• Remove Ubuntu packages (keeping system packages)"
message ""
message warn "⚠️  This may not restore everything perfectly!"
message warn "⚠️  Some changes may require manual intervention!"
message ""
confirm_continue

message "🎯 Starting undo process..."

# Backup current settings before undoing
backup_dir="$HOME/.ubuntu-transformation-backup-$(date +%s)"
mkdir -p "$backup_dir"
message info "Creating backup of current settings in: $backup_dir"

# Backup dconf settings
dconf dump /org/gnome/ > "$backup_dir/gnome-settings-backup.ini" 2>/dev/null || true

# Reset GNOME settings to defaults
message "🔧 Resetting GNOME settings to defaults..."

# Reset desktop background
gsettings reset org.gnome.desktop.background picture-uri
gsettings reset org.gnome.desktop.background picture-uri-dark
gsettings reset org.gnome.desktop.background primary-color

# Reset interface settings
gsettings reset org.gnome.desktop.interface gtk-theme
gsettings reset org.gnome.desktop.interface icon-theme
gsettings reset org.gnome.desktop.interface cursor-theme
gsettings reset org.gnome.desktop.interface font-name
gsettings reset org.gnome.desktop.interface monospace-font-name
gsettings reset org.gnome.desktop.interface document-font-name
gsettings reset org.gnome.desktop.interface color-scheme
gsettings reset org.gnome.desktop.interface accent-color

# Reset window manager settings
gsettings reset org.gnome.desktop.wm.preferences button-layout
gsettings reset org.gnome.desktop.wm.preferences titlebar-font

# Reset shell settings
gsettings reset org.gnome.shell favorite-apps
gsettings reset org.gnome.shell disable-user-extensions

# Disable extensions
message "🔌 Disabling Ubuntu-style extensions..."
gnome-extensions disable appindicatorsupport@rgcjonas.gmail.com 2>/dev/null || true
gnome-extensions disable ubuntu-appindicators@ubuntu.com 2>/dev/null || true
gnome-extensions disable dash-to-dock@micxgx.gmail.com 2>/dev/null || true
gnome-extensions disable ding@rastersoft.com 2>/dev/null || true
gnome-extensions disable desktop-icons-ng@rastersoft.com 2>/dev/null || true
gnome-extensions disable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true

# Reset dash-to-dock settings if still enabled
message "🎛️  Resetting dash-to-dock settings..."
gsettings reset-recursively org.gnome.shell.extensions.dash-to-dock 2>/dev/null || true

# Remove Ubuntu theme files
message "🎨 Removing Ubuntu theme customizations..."
rm -f "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null || true
rm -f "$HOME/.config/gtk-4.0/settings.ini" 2>/dev/null || true
rm -f "$HOME/.config/gtk-3.0/gtk.css" 2>/dev/null || true
rm -f "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null || true

# Remove XCURSOR_SIZE from environment (if we set it)
message "🖱️  Cleaning up cursor settings..."
if [ -f /etc/environment ] && grep -q "XCURSOR_SIZE=24" /etc/environment; then
    message warn "Removing XCURSOR_SIZE from /etc/environment (requires sudo)"
    sudo sed -i '/^XCURSOR_SIZE=24$/d' /etc/environment 2>/dev/null || true
fi

# Restore GRUB settings if modified
message "🚀 Checking bootloader configuration..."
if [ -f /etc/default/grub ] && grep -q 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"' /etc/default/grub; then
    message warn "Resetting GRUB quiet splash setting (requires sudo)"
    if sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT=""/' /etc/default/grub; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || message warn "Could not regenerate GRUB config"
    fi
fi

# Optional: Remove Ubuntu packages
message ""
message warn "🗑️  Ubuntu Package Removal"
message "The following Ubuntu-specific packages can be removed:"
message "• Ubuntu fonts (ttf-ubuntu-font-family)"
message "• Yaru themes (yaru-*-theme packages from AUR)"
message "• Microsoft fonts (ttf-ms-fonts from AUR)"
message ""
message warn "Do you want to remove Ubuntu-specific packages?"
read -p "[y/N?] " remove_packages
remove_packages_lower=$(echo "$remove_packages" | tr '[:upper:]' '[:lower:]')

if [ "$remove_packages_lower" = "y" ] || [ "$remove_packages_lower" = "yes" ]; then
    message "📦 Removing Ubuntu-specific packages..."
    
    # Remove AUR packages
    if command -v yay >/dev/null 2>&1; then
        yay -Rns --noconfirm yaru-gtk-theme yaru-icon-theme yaru-sound-theme yaru-gnome-shell-theme ttf-ms-fonts 2>/dev/null || true
    elif command -v paru >/dev/null 2>&1; then
        paru -Rns --noconfirm yaru-gtk-theme yaru-icon-theme yaru-sound-theme yaru-gnome-shell-theme ttf-ms-fonts 2>/dev/null || true
    fi
    
    # Remove official repo packages (keeping essential ones)
    sudo pacman -Rns --noconfirm ttf-ubuntu-font-family 2>/dev/null || true
    
    message info "Ubuntu-specific packages removed"
else
    message info "Keeping Ubuntu packages (you can remove them manually later)"
fi

message ""
message "✅ Undo process completed!"
message ""
message info "🔄 What was done:"
message "• GNOME settings reset to defaults"
message "• Ubuntu extensions disabled"
message "• Theme customizations removed"
message "• Cursor and font settings reset"
message "• Dock configuration reset"
message ""
message info "📁 Backup created at: $backup_dir"
message ""
message warn "📝 Notes:"
message "• You may need to restart GNOME Shell: Alt+F2, type 'r', press Enter"
message "• Some extensions may need manual removal via Extension Manager"
message "• Check Extension Manager for any remaining Ubuntu extensions"
message "• Reboot recommended for complete reset"
message ""
message info "🔧 To restore your backup later:"
message "   dconf load /org/gnome/ < $backup_dir/gnome-settings-backup.ini"