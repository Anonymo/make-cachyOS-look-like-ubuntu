#!/bin/bash

# Ensure script runs with bash (CachyOS uses fish/zsh by default)
if [ -z "$BASH_VERSION" ]; then
  echo "This script requires bash. Restarting with bash..."
  exec bash "$0" "$@"
fi

set -e

trap 'echo "ERROR: An error occurred on line $LINENO. The script will now exit." >&2' ERR

# Title: undo-unity-kde-transformation.sh
# Description: Undo script for make-cachyos-kde-look-like-unity.sh
# This script attempts to restore CachyOS KDE defaults and remove Unity theming

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

message "🔄 CachyOS KDE Unity Transformation Undo Script"
message ""
message warn "This script will attempt to:"
message "• Restore KDE Plasma to default CachyOS settings"
message "• Remove Unity-style layout and themes"
message "• Reset panel and dock configuration"
message "• Disable global menu and restore default window buttons"
message "• Remove Ubuntu packages (keeping system packages)"
message ""
message warn "⚠️  This may not restore everything perfectly!"
message warn "⚠️  Some changes may require manual intervention!"
message ""
confirm_continue

message "🎯 Starting undo process..."

# Find the original backup created by the main script
if [ -f "$HOME/.ubuntu-transformation-backup-location" ]; then
    original_backup_dir=$(cat "$HOME/.ubuntu-transformation-backup-location")
    if [ -d "$original_backup_dir" ]; then
        message info "Found original backup: $original_backup_dir"
        use_original_backup=true
    else
        message warn "Original backup directory not found: $original_backup_dir"
        use_original_backup=false
    fi
else
    message warn "No original backup location found"
    use_original_backup=false
fi

# Create backup of current (Unity-transformed) settings before undoing
current_backup_dir="$HOME/.unity-kde-transformation-current-backup-$(date +%s)"
mkdir -p "$current_backup_dir"
message info "Creating backup of current Unity-KDE settings in: $current_backup_dir"

# Backup current KDE settings
cp -r $HOME/.config/plasma* "$current_backup_dir/" 2>/dev/null || true
cp -r $HOME/.config/kde* "$current_backup_dir/" 2>/dev/null || true
cp $HOME/.config/kwinrc "$current_backup_dir/" 2>/dev/null || true
cp $HOME/.config/kdeglobals "$current_backup_dir/" 2>/dev/null || true
cp -r $HOME/.config/latte "$current_backup_dir/" 2>/dev/null || true
cp $HOME/.config/krunnerrc "$current_backup_dir/" 2>/dev/null || true
cp $HOME/.config/kglobalshortcutsrc "$current_backup_dir/" 2>/dev/null || true

if [ "$use_original_backup" = true ]; then
    message "🔧 Restoring original CachyOS KDE settings from backup..."
    
    # Restore original KDE configuration files
    if [ -d "$original_backup_dir/plasma-org.kde.plasma.desktop-appletsrc" ]; then
        cp -r "$original_backup_dir"/plasma* "$HOME/.config/" 2>/dev/null || message warn "Could not restore plasma settings"
    fi
    
    if [ -d "$original_backup_dir/kde" ] || [ -f "$original_backup_dir/kdeglobals" ]; then
        cp -r "$original_backup_dir"/kde* "$HOME/.config/" 2>/dev/null || true
        [ -f "$original_backup_dir/kdeglobals" ] && cp "$original_backup_dir/kdeglobals" "$HOME/.config/" 2>/dev/null || true
    fi
    
    if [ -f "$original_backup_dir/kwinrc" ]; then
        cp "$original_backup_dir/kwinrc" "$HOME/.config/" 2>/dev/null || message warn "Could not restore kwin settings"
    fi
    
    if [ -d "$original_backup_dir/latte" ]; then
        cp -r "$original_backup_dir/latte" "$HOME/.config/" 2>/dev/null || true
    fi
    
else
    message "🔧 Resetting KDE settings to defaults (no original backup found)..."

    # Reset window decorations
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "HIAX"
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key BorderSize "Normal"
    kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ShowToolTips "true"
    
    # Reset global menu settings
    kwriteconfig5 --file kdeglobals --group KDE --key ShowMenuBar false
    kwriteconfig5 --file kwinrc --group Windows --key BorderlessMaximizedWindows false
    
    # Reset fonts to system defaults
    kwriteconfig5 --file kdeglobals --group General --delete font
    kwriteconfig5 --file kdeglobals --group General --delete fixed
    kwriteconfig5 --file kdeglobals --group General --delete smallestReadableFont
    kwriteconfig5 --file kdeglobals --group General --delete toolBarFont
    kwriteconfig5 --file kdeglobals --group WM --delete activeFont
    
    # Reset theme settings
    kwriteconfig5 --file kdeglobals --group General --key ColorScheme "Breeze"
    kwriteconfig5 --file kdeglobals --group General --key Name "Breeze"
    kwriteconfig5 --file kdeglobals --group Icons --key Theme "breeze"
    kwriteconfig5 --file kdeglobals --group KDE --key widgetStyle "Breeze"
    
    # Reset Meta key behavior
    kwriteconfig5 --file kwinrc --group ModifierOnlyShortcuts --delete Meta
    
    # Reset KRunner settings
    kwriteconfig5 --file krunnerrc --group General --delete ActivateWhenTypingOnDesktop
    kwriteconfig5 --file krunnerrc --group General --delete FreeFloating
    kwriteconfig5 --file krunnerrc --group General --delete RetainPriorSearch
    
    # Reset KRunner shortcut to default (Alt+F2)
    kwriteconfig5 --file kglobalshortcutsrc --group krunner --key _launch "Alt+F2,Alt+F2,KRunner"
fi

# Stop and disable Latte Dock
message "🔌 Stopping Latte Dock..."
killall latte-dock 2>/dev/null || true
rm -f "$HOME/.config/autostart/latte-dock.desktop" 2>/dev/null || true

# Remove Unity-specific environment settings
message "🎨 Removing Unity/GTK integration settings..."
rm -f "$HOME/.config/plasma-workspace/env/gtk-appmenu.sh" 2>/dev/null || true
rm -f "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null || true
rm -f "$HOME/.config/gtk-4.0/settings.ini" 2>/dev/null || true
rm -f "$HOME/.gtkrc-2.0" 2>/dev/null || true

# Remove Latte configuration
message "🗑️  Removing Latte Dock configuration..."
rm -rf "$HOME/.config/latte" 2>/dev/null || true

# Remove XCURSOR_SIZE from environment (if we set it)
message "🖱️  Cleaning up cursor settings..."
if [ -f /etc/environment ] && grep -q "XCURSOR_SIZE=24" /etc/environment; then
    message warn "Removing XCURSOR_SIZE from /etc/environment (requires sudo)"
    sudo sed -i '/^XCURSOR_SIZE=24$/d' /etc/environment 2>/dev/null || true
fi

# Remove GTK_MODULES from environment (if we set it)
if [ -f /etc/environment ] && grep -q "GTK_MODULES=appmenu-gtk-module" /etc/environment; then
    message warn "Removing GTK_MODULES from /etc/environment (requires sudo)"
    sudo sed -i '/^GTK_MODULES=appmenu-gtk-module$/d' /etc/environment 2>/dev/null || true
fi

# Restore GRUB settings if modified
message "🚀 Checking bootloader configuration..."
if [ "$use_original_backup" = true ] && [ -f "$original_backup_dir/original-grub" ]; then
    message warn "Restoring original GRUB configuration (requires sudo)"
    if sudo cp "$original_backup_dir/original-grub" /etc/default/grub; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || message warn "Could not regenerate GRUB config"
        message info "GRUB configuration restored from backup"
    fi
elif [ -f /etc/default/grub ] && grep -q 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"' /etc/default/grub; then
    message warn "Resetting GRUB quiet splash setting (requires sudo)"
    if sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT=""/' /etc/default/grub; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || message warn "Could not regenerate GRUB config"
    fi
fi

# Optional: Remove Ubuntu packages
message ""
message warn "🗑️  Ubuntu Package Removal"
message "The following Unity/Ubuntu-specific packages can be removed:"
message "• Ubuntu fonts (ttf-ubuntu-font-family)"
message "• Yaru themes (yaru-*-theme packages from AUR)"
message "• Microsoft fonts (ttf-ms-fonts from AUR)"
message "• Latte Dock (latte-dock from AUR)"
message "• AppMenu packages (appmenu-gtk-module-git, libdbusmenu-* from AUR)"
message ""
message warn "Do you want to remove Unity/Ubuntu-specific packages?"
read -p "[y/N?] " remove_packages
remove_packages_lower=$(echo "$remove_packages" | tr '[:upper:]' '[:lower:]')

if [ "$remove_packages_lower" = "y" ] || [ "$remove_packages_lower" = "yes" ]; then
    message "📦 Removing Unity/Ubuntu-specific packages..."
    
    # Remove AUR packages
    if command -v yay >/dev/null 2>&1; then
        yay -Rns --noconfirm yaru-gtk-theme yaru-icon-theme yaru-sound-theme ttf-ms-fonts latte-dock appmenu-gtk-module-git libdbusmenu-glib libdbusmenu-gtk3 libdbusmenu-gtk2 2>/dev/null || true
    elif command -v paru >/dev/null 2>&1; then
        paru -Rns --noconfirm yaru-gtk-theme yaru-icon-theme yaru-sound-theme ttf-ms-fonts latte-dock appmenu-gtk-module-git libdbusmenu-glib libdbusmenu-gtk3 libdbusmenu-gtk2 2>/dev/null || true
    fi
    
    # Remove official repo packages (keeping essential ones)
    sudo pacman -Rns --noconfirm ttf-ubuntu-font-family 2>/dev/null || true
    
    message info "Unity/Ubuntu-specific packages removed"
else
    message info "Keeping Unity/Ubuntu packages (you can remove them manually later)"
fi

message ""
message "✅ Undo process completed!"
message ""
message info "🔄 What was done:"
message "• KDE Plasma settings reset to defaults"
message "• Unity-style layout removed"
message "• Window buttons restored to right side"
message "• Global menu disabled"
message "• Latte Dock stopped and configuration removed"
message "• GTK integration settings removed"
message "• Keyboard shortcuts reset to defaults"
message ""
if [ "$use_original_backup" = true ]; then
    message info "📁 Original backup used from: $original_backup_dir"
    message info "📁 Current Unity-KDE settings backed up to: $current_backup_dir"
else
    message info "📁 Current Unity-KDE settings backed up to: $current_backup_dir"
fi
message ""
message warn "📝 Notes:"
message "• You need to logout and login again for changes to take effect"
message "• Plasma may need to be restarted: kquitapp5 plasmashell && kstart5 plasmashell"
message "• Some panel configurations may need manual adjustment"
message "• Check System Settings for any remaining Unity customizations"
message ""
if [ "$use_original_backup" = true ]; then
    message info "✅ Settings restored from original CachyOS backup"
    message info "🔧 To restore Unity settings later:"
    message "   cp -r $current_backup_dir/* $HOME/.config/"
else
    message warn "⚠️  Reset to KDE defaults (no original backup found)"
    message info "🔧 To restore Unity settings later:"
    message "   cp -r $current_backup_dir/* $HOME/.config/"
fi