# make-cachyos-kde-look-like-unity

**KDE Branch - Unity-style Layout for CachyOS KDE Plasma**  
**Original Author:** DeltaLima | **Adapted for KDE by:** Anonymo

Transform your CachyOS KDE Plasma desktop into Ubuntu Unity with native KDE features.

## Quick Start

**Prerequisites:** CachyOS with KDE Plasma 6, `wheel` group membership, AUR helper (`yay`/`paru`)

```bash
# Clone and run
git clone -b KDE https://github.com/Anonymo/make-cachyOS-look-like-ubuntu.git
cd make-cachyOS-look-like-ubuntu
bash make-cachyos-kde-look-like-unity.sh
```

**⚠️ Important:** Reboot and re-run the script after first execution.

## Why KDE > GNOME for Unity

- ✅ **Native Global Menu** - No extensions needed
- ✅ **Better Performance** - More efficient than GNOME + extensions  
- ✅ **Stable Configuration** - Settings persist through updates
- ✅ **Perfect Panel Control** - Pixel-perfect Unity measurements
- ✅ **Built-in HUD** - KRunner provides native Alt+Space search

<details>
<summary><strong>➕ 📦 What Gets Installed (click to expand)</strong></summary>

### Official Repository Packages
- Ubuntu fonts, Liberation fonts, Noto fonts
- Plymouth for boot splash
- Thunderbird email client, Konsole terminal
- rofi-wayland alternative launcher

### AUR Packages
- `ttf-ms-fonts` - Microsoft core fonts
- `yaru-gtk-theme`, `yaru-icon-theme`, `yaru-sound-theme` - Ubuntu Yaru themes
- `latte-dock` - Unity-style dock with 48px icons
- `appmenu-gtk-module-git` - Global menu support for GTK apps
- `libdbusmenu-*` - DBus menu libraries

### Optional KDE Yaru Theming
- `kvantum` - Advanced theming engine for KDE
- **KvYaru-Colors** - Yaru-style themes specifically designed for KDE/Plasma
  - **Author:** Gabriel Pöl (GabePoel)  
  - **License:** GPL-3.0  
  - **Our Fork:** https://github.com/Anonymo/KvYaru-Colors (primary source)
  - **Original:** https://github.com/GabePoel/KvYaru-Colors (fallback)
  - Creates attribution file with commit tracking for proper credit
  - Activated via Kvantum Manager

</details>

<details>
<summary><strong>➕ ⚙️ KDE Configuration Details (click to expand)</strong></summary>

### Panel Layout
- **Top Panel (24px height)**
  - Application menu widget
  - Global menu bar (native KDE)
  - System tray and clock
  
- **Left Dock (Latte Dock)**
  - 48px icon size (Unity-style)
  - Unity-style indicators
  - Applications launcher at top
  - Intelligent auto-hide

### Window Management
- Window buttons on left: Close, Minimize, Maximize
- Borderless maximized windows
- Global menu integration (native)

### Keyboard Shortcuts
- **Super key**: Application dashboard
- **Alt+Space**: KRunner (HUD-like search)
- **Ctrl+Alt+T**: Terminal

</details>

<details>
<summary><strong>➕ 🔧 Troubleshooting (click to expand)</strong></summary>

### Global Menu Not Working
**Issue:** GTK apps don't show global menu  
**Solution:** Ensure environment variables are set:
```bash
export GTK_MODULES=appmenu-gtk-module
export UBUNTU_MENUPROXY=1
```

### Bootloader Support (Optional)
The script will ask if you want to configure bootloader for quiet splash:
- **GRUB:** Automatically configured
- **systemd-boot:** Manual instructions for `/boot/loader/entries/`
- **rEFInd:** Manual instructions for `/boot/refind_linux.conf`
- **Limine:** Manual instructions for `/boot/limine.cfg`

### Group Membership
**Issue:** "not in sudo group" error  
**Solution:** `su -c "usermod -aG wheel $USER"`

### Latte Dock Not Starting
**Solutions:**
1. Start manually: `latte-dock --layout Unity &`
2. Check errors: `latte-dock --debug`
3. Restart Plasma: `kquitapp5 plasmashell && kstart5 plasmashell`

### KvYaru-Colors Theme Not Working
1. Open Kvantum Manager: `kvantummanager`
2. Select a Yaru theme variant
3. Go to System Settings > Appearance > Application Style > Kvantum
4. Restart applications

</details>

<details>
<summary><strong>➕ 🔄 Undoing the Transformation (click to expand)</strong></summary>

```bash
# From the repository directory
bash undo-unity-kde-transformation.sh
```

The undo script will:
- ✅ Reset KDE Plasma settings to CachyOS defaults
- ✅ Remove Unity-style layout and Latte Dock
- ✅ Restore window buttons to right side
- ✅ Disable global menu and reset keyboard shortcuts
- ✅ Create backup before making changes
- ⚠️ Optionally remove Ubuntu packages

</details>

<details>
<summary><strong>➕ 🛡️ Dependency Management (click to expand)</strong></summary>

To ensure reliability and avoid issues with external repositories going offline, this project uses a **fork-first** strategy:

### External Dependencies Strategy
- **Primary Source:** Our forked repositories under `github.com/Anonymo/`
- **Fallback:** Original repositories as backup if our fork is unavailable
- **Attribution:** Full credit maintained to original authors with proper licensing

### KvYaru-Colors Dependency
- We maintain a fork at `https://github.com/Anonymo/KvYaru-Colors`
- Original by Gabriel Pöl: `https://github.com/GabePoel/KvYaru-Colors`
- Script tries our fork first, falls back to original if needed
- This ensures continued functionality even if external repositories change

</details>

<details>
<summary><strong>➕ 📊 Comparison: KDE vs GNOME for Unity (click to expand)</strong></summary>

| Feature | KDE | GNOME |
|---------|-----|-------|
| Global Menu | Native ✅ | Extension (unstable) ⚠️ |
| Panel Customization | Native ✅ | Limited ⚠️ |
| Dock | Latte Dock ✅ | Dash-to-Dock extension ⚠️ |
| HUD | KRunner (native) ✅ | gnome-hud (3rd party) ⚠️ |
| Stability | High ✅ | Medium with extensions ⚠️ |
| Performance | Better ✅ | Slower with extensions ⚠️ |

**KDE Plasma makes a better Unity clone than GNOME because global menus and panel customization are native features!**

</details>

<details>
<summary><strong>➕ 🎯 Unity-like Features in Detail (click to expand)</strong></summary>

### Native Global Menu
- **Built-in KDE Feature**: No extensions needed
- **Full Application Support**: Works with Qt and GTK apps
- **Panel Integration**: Menus appear in top panel (24px height)
- **Window Title**: Shows in panel for maximized windows

### HUD Functionality via KRunner
- **Alt+Space**: Opens KRunner for HUD-like search
- **Application Search**: Find apps, files, and settings
- **Command Execution**: Run commands directly
- **Native KDE Feature**: Stable and integrated

### Unity-style Dock (Latte)
- **48px Icons**: Unity-standard icon size
- **Left Positioning**: Classic Unity dock placement  
- **Intelligent Hide**: Auto-hides when windows overlap
- **Unity Indicators**: Running app indicators

</details>

## Screenshot

![Ubuntuish CachyOS KDE Desktop](screenshot/screenshot1.png "Ubuntuish CachyOS KDE Desktop")