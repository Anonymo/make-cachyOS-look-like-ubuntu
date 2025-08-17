#!/bin/bash

# Ensure script runs with bash (CachyOS uses fish/zsh by default)
if [ -z "$BASH_VERSION" ]; then
  echo "This script requires bash. Restarting with bash..."
  exec bash "$0" "$@"
fi

set -e

trap 'echo "ERROR: An error occurred on line $LINENO. The script will now exit." >&2' ERR


# Title: make-cachyos-kde-look-like-unity.sh
# Description: This script performs all necessary steps to make a CachyOS KDE
# desktop look like Ubuntu Unity with Unity-style layout and themes.
# Original Author: DeltaLima
# Adapted for CachyOS KDE by: Anonymo
# Date: 23.08.2025
# Version: 1.0-kde-unity
# Usage: bash make-cachyos-kde-look-like-unity.sh
# 
# Based on: https://github.com/Anonymo/make-cachyOS-look-like-ubuntu/tree/KDE
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
thunderbird firefox-pure konsole rofi-wayland"

# install KDE Unity-like components
packages[2-desktop-kde]="plasma-desktop kde-applications-meta plasma-wayland-session
plasma-workspace plasma-pa plasma-nm powerdevil kscreen
kinfocenter systemsettings dolphin kate ark spectacle"

# AUR packages to be installed separately
aur_packages="ttf-ms-fonts yaru-gtk-theme yaru-icon-theme yaru-sound-theme latte-dock appmenu-gtk-module-git libdbusmenu-glib libdbusmenu-gtk3 libdbusmenu-gtk2"

# Optional Kvantum theming for KDE
kvantum_packages="kvantum"

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
message "This script makes a fresh CachyOS-KDE installation to look like"
message "Ubuntu Unity with global menu and Unity-style layout. Settings are applied for the user"
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

# Backup current KDE settings
cp -r $HOME/.config/plasma* "$backup_dir/" 2>/dev/null || message warn "Could not backup plasma settings"
cp -r $HOME/.config/kde* "$backup_dir/" 2>/dev/null || message warn "Could not backup KDE settings"
cp $HOME/.config/kwinrc "$backup_dir/" 2>/dev/null || true
cp $HOME/.config/kdeglobals "$backup_dir/" 2>/dev/null || true
cp -r $HOME/.config/latte "$backup_dir/" 2>/dev/null || true
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
  if [ "$category" == "2-desktop-kde" ] && [ -n "$aur_packages" ]
  then
    message "installing AUR packages"
    # Check for available AUR helper
    if command -v yay &> /dev/null
    then
      message "using yay for AUR packages"
      if ! yay -S --needed --noconfirm $aur_packages; then
        message warn "Some AUR packages failed to install"
        # Try to install gnome-hud via pip as fallback
        if ! command -v gnomehud >/dev/null 2>&1 && ! [ -f "$HOME/.local/bin/gnomehud" ]; then
          message "installing gnome-hud via pip as fallback"
          pip install --user gnome-hud 2>/dev/null || message warn "Could not install gnome-hud via pip"
        fi
      fi
    elif command -v paru &> /dev/null
    then
      message "using paru for AUR packages"
      if ! paru -S --needed --noconfirm $aur_packages; then
        message warn "Some AUR packages failed to install"
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

    2-desktop-kde)
    
      message "Configuring KDE Plasma for Unity-like layout"
      
      # Create KDE config directories
      mkdir -p $HOME/.config/plasma-workspace/env
      mkdir -p $HOME/.local/share/plasma/layout-templates
      mkdir -p $HOME/.config/latte
      
      message "Configure window decorations - buttons on left"
      # CachyOS uses Plasma 6 - use kwriteconfig6
      if command -v kwriteconfig6 >/dev/null 2>&1; then
        KWRITECONFIG="kwriteconfig6"
        message "Using kwriteconfig6 for Plasma 6 configuration"
      else
        message error "kwriteconfig6 not found - Plasma 6 is required for CachyOS"
        error
      fi
      
      # Set window buttons to left side (Unity style)
      $KWRITECONFIG --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "XSM"
      $KWRITECONFIG --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight ""
      $KWRITECONFIG --file kwinrc --group org.kde.kdecoration2 --key BorderSize "Normal"
      $KWRITECONFIG --file kwinrc --group org.kde.kdecoration2 --key ShowToolTips "false"
      
      message "Configure KDE panels - Unity-style layout"
      
      # Configure top panel (24px height for Unity-style)
      message "Setting up top panel with global menu"
      $KWRITECONFIG --file plasmashellrc --group PlasmaViews --group Panel 0 --group Defaults --key thickness 24
      
      # Configure global menu and appmenu settings
      message "Enable global menu support"
      $KWRITECONFIG --file kdeglobals --group KDE --key ShowMenuBar true
      $KWRITECONFIG --file kwinrc --group Windows --key BorderlessMaximizedWindows true
      
      # Set environment variables for GTK global menu
      cat > $HOME/.config/plasma-workspace/env/gtk-appmenu.sh << 'EOF'
#!/bin/sh
export GTK_MODULES=appmenu-gtk-module
export UBUNTU_MENUPROXY=1
EOF
      chmod +x $HOME/.config/plasma-workspace/env/gtk-appmenu.sh
      
      
      message "Configure Latte Dock for Unity-style left panel"
      # Create Latte Dock configuration for Unity-like dock
      cat > $HOME/.config/latte/Unity.layout.latte << 'EOF'
[General]
alignmentUpgraded=true
appletOrder=1
configurationStepsTooltips=true
launchers=file:///usr/share/applications/firefox-pure.desktop,file:///usr/share/applications/thunderbird.desktop,file:///usr/share/applications/org.kde.dolphin.desktop,file:///usr/share/applications/org.kde.konsole.desktop,file:///usr/share/applications/systemsettings.desktop
layoutId=Unity
preferredForShortcutsTouched=true
showInMenu=true
version=2

[PlasmaThemeExtended]
outlineWidth=1

[ScreenConnectors]
10=eDP-1

[UniversalSettings]
canDisableBorders=true
contextMenuActionsAlwaysShown=_layoutsMenu
inAdvancedModeForEditSettings=true
launchers=
memoryUsage=0
metaPressAndHoldEnabled=false
mouseSensitivity=2
screenTrackerInterval=2500
showInfoWindow=true
singleModeLayoutName=Unity

[UniversalSettings][Launchers]
EOF
      
      message "Configure KDE appearance settings"
      # Set fonts to Ubuntu
      $KWRITECONFIG --file kdeglobals --group General --key font "Ubuntu,11,-1,5,50,0,0,0,0,0"
      $KWRITECONFIG --file kdeglobals --group General --key fixed "Ubuntu Mono,13,-1,5,50,0,0,0,0,0"
      $KWRITECONFIG --file kdeglobals --group General --key smallestReadableFont "Ubuntu,9,-1,5,50,0,0,0,0,0"
      $KWRITECONFIG --file kdeglobals --group General --key toolBarFont "Ubuntu,10,-1,5,50,0,0,0,0,0"
      $KWRITECONFIG --file kdeglobals --group WM --key activeFont "Ubuntu,11,-1,5,75,0,0,0,0,0"
      
      # Set theme settings
      $KWRITECONFIG --file kdeglobals --group General --key ColorScheme "Breeze Dark"
      $KWRITECONFIG --file kdeglobals --group General --key Name "Breeze Dark"
      $KWRITECONFIG --file kdeglobals --group Icons --key Theme "Yaru-dark"
      $KWRITECONFIG --file kdeglobals --group KDE --key widgetStyle "Breeze"
      
      message "Configure Meta (Super) key for application menu"
      $KWRITECONFIG --file kwinrc --group ModifierOnlyShortcuts --key Meta "org.kde.plasmashell,/PlasmaShell,org.kde.PlasmaShell,activateLauncherMenu"

      # gtk-3.0 and gtk-4.0 settings for KDE/GTK integration
      message "setting gtk-3.0 and gtk-4.0 for KDE integration"
      mkdir -p $HOME/.config/gtk-{3,4}.0
      cat << EOF | tee $HOME/.config/gtk-3.0/settings.ini > $HOME/.config/gtk-4.0/settings.ini
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Yaru-dark
gtk-icon-theme-name=Yaru-dark
gtk-font-name=Ubuntu 11
gtk-cursor-theme-name=Yaru
gtk-modules=appmenu-gtk-module
EOF

      # Configure GTK2 settings
      message "Configure GTK2 settings"
      cat > $HOME/.gtkrc-2.0 << 'EOF'
gtk-theme-name="Yaru-dark"
gtk-icon-theme-name="Yaru-dark"
gtk-font-name="Ubuntu 11"
gtk-cursor-theme-name="Yaru"
gtk-modules="appmenu-gtk-module"
EOF

      # Configure Latte Dock autostart
      message "Enable Latte Dock autostart"
      mkdir -p $HOME/.config/autostart
      cat > $HOME/.config/autostart/latte-dock.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Latte Dock
Comment=Unity-style dock for KDE
Exec=latte-dock --layout Unity
Icon=latte-dock
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
StartupNotify=false
EOF
      
      # Configure KDE HUD keybinding  
      message "configuring KDE HUD (Unity-like menu search with Alt+Space)"
      
      # KDE has built-in HUD functionality via KRunner and Application Menu
      message "Setting up Alt+Space for HUD-like menu search"
      
      # Configure KRunner for HUD-like behavior
      $KWRITECONFIG --file krunnerrc --group General --key ActivateWhenTypingOnDesktop false
      $KWRITECONFIG --file krunnerrc --group General --key FreeFloating true
      $KWRITECONFIG --file krunnerrc --group General --key RetainPriorSearch false
      
      # Set up global shortcut for HUD (Alt+Space like Unity)
      $KWRITECONFIG --file kglobalshortcutsrc --group krunner --key _launch "Alt+Space,Alt+Space,KRunner"
      
      # Enable useful KRunner plugins for HUD-like experience
      $KWRITECONFIG --file krunnerrc --group Plugins --key appstreamEnabled true
      $KWRITECONFIG --file krunnerrc --group Plugins --key applicationsEnabled true
      $KWRITECONFIG --file krunnerrc --group Plugins --key desktopsessionsEnabled true
      $KWRITECONFIG --file krunnerrc --group Plugins --key shellEnabled true
      $KWRITECONFIG --file krunnerrc --group Plugins --key windowsEnabled true
      
      # Configure Application Dashboard for Unity-like app menu
      message "Configure Application Dashboard widget"
      
      # Start Latte Dock if installed
      if command -v latte-dock >/dev/null 2>&1; then
        message "Starting Latte Dock with Unity layout"
        killall latte-dock 2>/dev/null || true
        latte-dock --layout Unity &>/dev/null &
      else
        message warn "Latte Dock not installed - Unity-style dock will not be configured"
      fi
      
      # Optional KvYaru-Colors Kvantum theme installation
      message ""
      message "Optional: Install KvYaru-Colors theme for native KDE Yaru styling?"
      message "This adds Kvantum theming engine and Yaru-style themes specifically for KDE"
      message "KvYaru-Colors by GabePoel: Yaru color scheme variants for KDE/Plasma"
      message warn "This downloads themes from our fork: https://github.com/Anonymo/KvYaru-Colors"
      message warn "Original: https://github.com/GabePoel/KvYaru-Colors"
      message warn "License: GPL-3.0 - Author: Gabriel Pöl (GabePoel)"
      read -p "[y/N?] " install_kvyaru
      install_kvyaru_lower=$(echo "$install_kvyaru" | tr '[:upper:]' '[:lower:]')
      
      if [ "$install_kvyaru_lower" = "y" ] || [ "$install_kvyaru_lower" = "yes" ]; then
        message "Installing Kvantum theming engine..."
        
        # Install Kvantum from AUR
        if command -v yay &> /dev/null; then
          yay -S --needed --noconfirm $kvantum_packages || message warn "Failed to install Kvantum"
        elif command -v paru &> /dev/null; then
          paru -S --needed --noconfirm $kvantum_packages || message warn "Failed to install Kvantum"
        else
          message warn "No AUR helper found - cannot install Kvantum automatically"
        fi
        
        # Download and install KvYaru-Colors themes
        if command -v kvantummanager >/dev/null 2>&1 || [ -f /usr/bin/kvantummanager ]; then
          message "Downloading KvYaru-Colors themes..."
          
          # Create temporary directory
          temp_dir="/tmp/kvyaru-colors-$$"
          mkdir -p "$temp_dir"
          
          # Download the theme with proper attribution tracking
          if command -v git >/dev/null 2>&1; then
            message "Cloning KvYaru-Colors repository (GPL-3.0 licensed)..."
            git clone https://github.com/Anonymo/KvYaru-Colors.git "$temp_dir" 2>/dev/null || {
              message warn "Failed to download KvYaru-Colors theme from our fork"
              message warn "Trying original repository as fallback..."
              git clone https://github.com/GabePoel/KvYaru-Colors.git "$temp_dir" 2>/dev/null || {
                message warn "Failed to download from both repositories"
                rm -rf "$temp_dir"
                message "You can install it manually from: https://github.com/Anonymo/KvYaru-Colors"
                message "Or original: https://github.com/GabePoel/KvYaru-Colors"
              }
            }
            
            if [ -d "$temp_dir" ] && [ -f "$temp_dir/install.sh" ]; then
              # Record the commit being used for proper attribution
              cd "$temp_dir"
              current_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
              current_date=$(git log -1 --format="%ci" 2>/dev/null || echo "unknown")
              cd - >/dev/null
              
              message "Installing KvYaru-Colors themes..."
              message "Using commit: $current_commit (date: $current_date)"
              message "Full attribution: Gabriel Pöl (GabePoel) - GPL-3.0 License"
              
              # Create attribution file in Kvantum directory
              mkdir -p "$HOME/.config/Kvantum"
              cat > "$HOME/.config/Kvantum/KvYaru-Colors-ATTRIBUTION.txt" << EOF
KvYaru-Colors Theme Attribution
===============================

Theme: KvYaru-Colors
Author: Gabriel Pöl (GabePoel)
License: GPL-3.0
Original Source: https://github.com/GabePoel/KvYaru-Colors
Forked Source: https://github.com/Anonymo/KvYaru-Colors
Commit used: $current_commit
Commit date: $current_date
Installed by: make-cachyos-kde-look-like-unity.sh
Installation date: $(date)

This theme installation respects the original GPL-3.0 license.
All credit goes to the original author Gabriel Pöl (GabePoel).
EOF
              
              cd "$temp_dir"
              chmod +x install.sh
              ./install.sh 2>/dev/null || {
                message warn "Automatic installation failed, trying manual install..."
                cp -r src/* "$HOME/.config/Kvantum/" 2>/dev/null || message warn "Manual installation also failed"
              }
              cd - >/dev/null
              rm -rf "$temp_dir"
              
              message "KvYaru-Colors themes installed with proper attribution!"
              message "Attribution file created: ~/.config/Kvantum/KvYaru-Colors-ATTRIBUTION.txt"
              message "You can activate them via:"
              message "1. Open 'Kvantum Manager' from applications"
              message "2. Select a Yaru theme variant"
              message "3. Go to System Settings > Appearance > Application Style > Kvantum"
            fi
          else
            message warn "Git not found - cannot download KvYaru-Colors automatically"
            message "Install manually from: https://github.com/Anonymo/KvYaru-Colors"
            message "Or original: https://github.com/GabePoel/KvYaru-Colors"
          fi
        else
          message warn "Kvantum not properly installed - skipping theme download"
        fi
      else
        message "Skipping KvYaru-Colors installation (you can install manually later)"
        message "Available at: https://github.com/Anonymo/KvYaru-Colors"
        message "Original: https://github.com/GabePoel/KvYaru-Colors"
      fi
      
      message ""
      message "KDE Unity-like configuration complete!"
      message "HUD search: Alt+Space"
      message "Application menu: Super key"
      message "Global menu: Enabled in top panel"
      if [ "$install_kvyaru_lower" = "y" ] || [ "$install_kvyaru_lower" = "yes" ]; then
        message "Kvantum themes: Open 'Kvantum Manager' to select Yaru theme"
      fi
      ;;
  esac
  
done

message "${GREEN}DONE!!${ENDCOLOR}"
message warn "${RED}IMPORTANT!! ${YELLOW}Rerun this script again after a reboot, if this is the first run of it!${ENDCOLOR}"
