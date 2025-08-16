# make-cachyos-look-like-ubuntu

**Adapted for CachyOS from:** https://git.la10cy.net/DeltaLima/make-debian-look-like-ubuntu  
**Original Author:** DeltaLima  
**Adapted by:** Anonymo

This script performs all necessary steps to make a CachyOS GNOME desktop look like an Ubuntu desktop.

## Key Changes for CachyOS

- ✅ **Package Manager**: Replaced `apt` with `pacman` 
- ✅ **AUR Support**: Added support for both `yay` and `paru` AUR helpers
- ✅ **Package Names**: Updated to CachyOS/Arch Linux equivalents
- ✅ **Yaru Theme**: Installs Ubuntu's Yaru theme from AUR
- ✅ **No Firefox Flatpak**: Removed Firefox flatpak installation (uses system Firefox)
- ✅ **No Flatpak Dependencies**: Removed unnecessary flatpak/flathub setup
- ✅ **Repository Config**: Uses pacman.conf instead of sources.list

## Prerequisites

- CachyOS with GNOME desktop environment
- User must be in the `wheel` group (for sudo access)
- An AUR helper installed (`yay` or `paru`)

## Installation

### Step 1: Install prerequisites (if needed)
```bash
# Install git (if not already installed)
sudo pacman -S git

# Install an AUR helper (if you don't have yay or paru)
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
```

### Step 2: Clone and run
```bash
# Clone the repository
git clone https://github.com/Anonymo/make-cachyOS-look-like-ubuntu.git
cd make-cachyOS-look-like-ubuntu

# Run the transformation script
bash make-cachyos-look-like-ubuntu.sh
```

**Important!** After the first run, you have to **reboot and re-run** the script. 
When the script runs the first time, it is normal that the terminal font looks different after it. This normalizes after a reboot.

## What it installs

### Official Repository Packages
- Ubuntu fonts, Liberation fonts, Noto fonts
- Plymouth, GNOME extensions, GNOME tweaks
- GNOME Software (package manager GUI)
- NetworkManager OpenVPN support
- Thunderbird email client
- rofi-wayland (menu system for HUD functionality)

### AUR Packages
- `ttf-ms-fonts` - Microsoft core fonts
- `yaru-gtk-theme` - Ubuntu's Yaru GTK theme
- `yaru-icon-theme` - Ubuntu's Yaru icon theme  
- `yaru-sound-theme` - Ubuntu's Yaru sound theme
- `yaru-gnome-shell-theme` - Ubuntu's Yaru GNOME Shell theme
- `gnome-shell-extension-dash-to-dock` - Dash to Dock extension
- `gnome-hud` - Unity-like HUD menu for quick application menu access
- `appmenu-gtk-module-git` - Global menu support for GTK applications

### GNOME Extensions

The script automatically installs and enables these GNOME extensions:

#### Automatically Installed & Enabled
- **AppIndicator Support** (`gnome-shell-extension-appindicator`) - System tray support
- **Dash to Dock** (`gnome-shell-extension-dash-to-dock`) - Ubuntu-style dock
- **Desktop Icons NG** (`gnome-shell-extension-desktop-icons-ng`) - Desktop icons
- **User Themes** (from `gnome-shell-extensions`) - Custom shell themes

#### Manual Installation Required

Some extensions may need to be installed manually via Extension Manager:

1. **Open Extension Manager** (installed by the script)
2. **Search for and install:**
   - Any additional extensions that failed to auto-enable
   - Custom extensions for specific Ubuntu features

**Tip:** If any extensions show as "not enabled" after running the script, you can manually enable them using:
```bash
gnome-extensions enable <extension-id>
```

Or use the Extension Manager GUI for easier management.

## Troubleshooting

### Shell Compatibility
- **Issue:** Script exits immediately or shows "Installation aborted"
- **Cause:** CachyOS uses fish/zsh by default, script requires bash
- **Solution:** The script automatically detects and restarts with bash

### Bootloader Support
- **GRUB:** Automatically configured for quiet splash
- **systemd-boot:** Manual configuration needed (instructions provided)
- **rEFInd/Limine:** Manual configuration needed (instructions provided)

### Group Membership
- **Issue:** "not in sudo group" error
- **Solution:** Add user to wheel group: `su -c "usermod -aG wheel $USER"`

## Undoing the Transformation

If you want to revert back to the original CachyOS GNOME appearance:

```bash
# From the repository directory
bash undo-ubuntu-transformation.sh
```

The undo script will:
- ✅ Reset GNOME settings to CachyOS defaults
- ✅ Disable Ubuntu-style extensions  
- ✅ Remove theme customizations
- ✅ Reset taskbar/dock configuration
- ✅ Create a backup before making changes
- ⚠️ Optionally remove Ubuntu packages

**Note:** Some changes may require manual cleanup via Extension Manager.

## Unity-like Features

The script now includes **gnome-hud**, which brings back Unity's signature HUD (Heads-Up Display) functionality:

- **Quick Menu Access**: Press `Ctrl + Alt + Space` to open the HUD
- **Search Application Menus**: Type to quickly find any menu item in the current application
- **Keyboard-Driven Navigation**: Access any application function without clicking through menus
- **Authentic Ubuntu Experience**: Restores one of Unity's most beloved features

This makes the desktop feel even more like classic Ubuntu with Unity!

![Ubuntuish CachyOS GNOME Desktop](screenshot/screenshot1.png "Ubuntuish CachyOS GNOME Desktop")
