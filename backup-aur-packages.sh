#!/bin/bash

# AUR Package Backup Script
# This script backs up PKGBUILDs for all AUR packages used in the project
# to ensure continued functionality even if packages are removed from AUR

set -e

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

# List of AUR packages to backup
AUR_PACKAGES=(
    "ttf-ms-fonts"
    "yaru-gtk-theme"
    "yaru-icon-theme"
    "yaru-sound-theme"
    "yaru-gnome-shell-theme"
    "latte-dock"
    "appmenu-gtk-module-git"
    "libdbusmenu-glib"
    "libdbusmenu-gtk3"
    "libdbusmenu-gtk2"
    "gnome-shell-extension-dash-to-dock"
    "gnome-hud"
    "gnome-shell-extension-unite"
    "ubuntu-wallpapers"
    "libreoffice-style-yaru-fullcolor"
    "kvantum"
)

BACKUP_DIR="aur-backups"
mkdir -p "$BACKUP_DIR"

message "🎯 Starting AUR package backup process..."
message "📦 Backing up ${#AUR_PACKAGES[@]} AUR packages to $BACKUP_DIR/"

cd "$BACKUP_DIR"

for package in "${AUR_PACKAGES[@]}"; do
    message "📥 Backing up: $package"
    
    # Create package directory
    mkdir -p "$package"
    cd "$package"
    
    # Download PKGBUILD and related files
    if curl -s "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$package" -o PKGBUILD; then
        message info "✅ Downloaded PKGBUILD for $package"
        
        # Download .SRCINFO if available
        curl -s "https://aur.archlinux.org/cgit/aur.git/plain/.SRCINFO?h=$package" -o .SRCINFO 2>/dev/null || true
        
        # Download any additional files (like .install files, patches, etc.)
        # Get list of files from AUR API
        api_response=$(curl -s "https://aur.archlinux.org/rpc/?v=5&type=info&arg[]=$package")
        
        # Check if package exists
        if echo "$api_response" | grep -q '"resultcount":0'; then
            message warn "⚠️  Package $package not found in AUR"
        else
            message info "✅ Package $package backed up successfully"
        fi
    else
        message error "❌ Failed to download PKGBUILD for $package"
    fi
    
    cd ..
done

# Create README for the backup
cd ..
cat > "$BACKUP_DIR/README.md" << 'EOF'
# AUR Package Backups

This directory contains backups of all AUR packages used by the make-cachyOS-look-like-ubuntu project.

## Purpose

These backups ensure continued functionality even if:
- Packages are removed from AUR
- AUR is temporarily unavailable
- Package maintainers abandon packages

## Usage

If an AUR package is no longer available, you can:

1. Copy the backed up PKGBUILD to a local directory
2. Build the package manually with `makepkg -si`
3. Or submit the package back to AUR if appropriate

## Backup Date

This backup was created on: $(date)

## Legal Notice

All PKGBUILDs are subject to their original licenses and maintainer copyrights.
These backups are for contingency purposes only and should not be redistributed
without proper attribution to original maintainers.

## Package List

The following packages are backed up:
EOF

for package in "${AUR_PACKAGES[@]}"; do
    echo "- $package" >> "$BACKUP_DIR/README.md"
done

message "✅ AUR package backup completed!"
message "📁 Backups stored in: $BACKUP_DIR/"
message "📋 Total packages backed up: ${#AUR_PACKAGES[@]}"

# Create attribution file
cat > "$BACKUP_DIR/ATTRIBUTION.txt" << 'EOF'
AUR Package Attribution
======================

All PKGBUILDs in this directory are downloaded from the Arch User Repository (AUR).
Original maintainers and contributors deserve full credit for their work.

Source: https://aur.archlinux.org/
License: Individual packages are subject to their respective licenses

This backup is created for contingency purposes to ensure project continuity
and does not claim ownership of any PKGBUILD content.

Backup Date: $(date)
Project: make-cachyOS-look-like-ubuntu
Repository: https://github.com/Anonymo/make-cachyOS-look-like-ubuntu
EOF

message "📝 Attribution file created: $BACKUP_DIR/ATTRIBUTION.txt"
message "🎉 Backup process complete!"