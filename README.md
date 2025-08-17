# make-cachyos-look-like-ubuntu

**GNOME Branch - Ubuntu Desktop for CachyOS GNOME**  
**Original Author:** DeltaLima | **Adapted for CachyOS by:** Anonymo

Transform your CachyOS GNOME desktop into Ubuntu with Unity-like HUD, global menu, and authentic theming.

## Quick Start

**Prerequisites:** CachyOS with GNOME, `wheel` group membership, AUR helper (`yay`/`paru`)

```bash
# Clone and run
git clone https://github.com/Anonymo/make-cachyOS-look-like-ubuntu.git
cd make-cachyOS-look-like-ubuntu
bash make-cachyos-look-like-ubuntu.sh
```

**⚠️ Important:** Reboot and re-run the script after first execution.

### Undoing the Transformation

To revert back to original CachyOS GNOME:

```bash
# From the repository directory
bash undo-ubuntu-transformation.sh
```

## Key CachyOS Adaptations

- ✅ **Package Manager** - Uses `pacman` instead of `apt`
- ✅ **AUR Support** - Supports both `yay` and `paru` helpers
- ✅ **Native Packages** - CachyOS/Arch Linux package names
- ✅ **Yaru Theme** - Ubuntu's Yaru theme from AUR
- ✅ **No Flatpak Dependencies** - Uses system packages

<details>
<summary><strong>📦 What Gets Installed (click to expand)</strong></summary>

### Official Repository Packages
- Ubuntu fonts, Liberation fonts, Noto fonts
- Plymouth, GNOME extensions, GNOME tweaks
- GNOME Software (package manager GUI)
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
- `gnome-shell-extension-unite` - Unity-like GNOME Shell interface with global menu integration
- `ubuntu-wallpapers` - Authentic Ubuntu wallpaper collection
- `libreoffice-style-yaru-fullcolor` - Yaru-styled LibreOffice icons

### GNOME Extensions

#### Automatically Installed & Enabled
- **AppIndicator Support** - System tray support
- **Dash to Dock** - Ubuntu-style dock
- **Desktop Icons NG** - Desktop icons
- **User Themes** - Custom shell themes
- **Unite Shell** - Unity-like interface with global menu support

#### Manual Installation (if needed)
Some extensions may need manual installation via Extension Manager:
1. **Open Extension Manager** (installed by script)
2. **Search and install** any missing extensions
3. **Enable manually** using `gnome-extensions enable <extension-id>`

</details>

<details>
<summary><strong>🎯 Unity-like Features (click to expand)</strong></summary>

### HUD (Heads-Up Display)
- **Quick Menu Access**: Press `Ctrl + Alt + Space` to open the HUD
- **Search Application Menus**: Type to quickly find any menu item in the current application  
- **Keyboard-Driven Navigation**: Access any application function without clicking through menus

### Global Menu & Unity Interface
- **Unite Shell Extension**: Transforms GNOME Shell to look like Unity's interface
- **Window Title Integration**: Shows current window title in the panel for maximized windows
- **Global Menu Support**: Application menus appear in the top panel (Unity-style)
- **Clean Window Decorations**: Removes window borders for maximized apps

This complete package recreates the authentic Ubuntu Unity desktop experience!

</details>

<details>
<summary><strong>🔧 Troubleshooting (click to expand)</strong></summary>

### Shell Compatibility
**Issue:** Script exits immediately or shows "Installation aborted"  
**Cause:** CachyOS uses fish/zsh by default, script requires bash  
**Solution:** The script automatically detects and restarts with bash

### Bootloader Support (Optional)
The script will ask if you want to configure bootloader for quiet splash:
- **GRUB:** Automatically configured
- **systemd-boot:** Manual instructions for `/boot/loader/entries/`
- **rEFInd:** Manual instructions for `/boot/refind_linux.conf`
- **Limine:** Manual instructions for `/boot/limine.cfg`

### Group Membership
**Issue:** "not in sudo group" error  
**Solution:** `su -c "usermod -aG wheel $USER"`

### GNOME HUD Not Working
**Issue:** Ctrl+Alt+Space doesn't open HUD menu  
**Solutions:**
1. Check if gnome-hud installed: `which gnomehud`
2. Install manually if needed: `pip install --user gnome-hud`
3. Start the service: `gnomehud-service &`
4. Check keybinding: `gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/gnome-hud/ binding`
5. Restart GNOME Shell: `Alt+F2`, type `r`, press Enter

### Extensions Not Enabling
**Issue:** Unite or other extensions not enabled automatically  
**Solution:** Use Extension Manager GUI to enable manually  
**Alternative:** `sudo pacman -S gnome-shell-extensions`

</details>


## Screenshot

![Ubuntuish CachyOS GNOME Desktop](screenshot/screenshot1.png "Ubuntuish CachyOS GNOME Desktop")