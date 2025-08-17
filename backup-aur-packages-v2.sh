#!/bin/bash

# AUR Package Backup Script v2
# This script backs up PKGBUILDs and source files for all AUR packages
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

message "🎯 Starting AUR package backup process (v2 with source files)..."
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
        
        # Parse PKGBUILD for source files
        if [ -f PKGBUILD ]; then
            message info "📂 Checking for source files in PKGBUILD..."
            
            # Create sources subdirectory
            mkdir -p sources
            
            # Extract source URLs from PKGBUILD
            # This handles source=() arrays in various formats
            source_urls=$(grep -E "^source.*=|^source_" PKGBUILD | sed 's/source.*=(//' | sed 's/)$//' | tr -d '"' | tr -d "'" | tr ' ' '\n' | grep -E "^https?://|^ftp://")
            
            # Also check for specific architecture sources
            arch_sources=$(grep -E "^source_x86_64=|^source_i686=" PKGBUILD | sed 's/source.*=(//' | sed 's/)$//' | tr -d '"' | tr -d "'" | tr ' ' '\n' | grep -E "^https?://|^ftp://")
            
            all_sources="$source_urls $arch_sources"
            
            if [ -n "$all_sources" ]; then
                for source_url in $all_sources; do
                    # Skip git sources as they're dynamic
                    if [[ "$source_url" == *"git+"* ]] || [[ "$source_url" == *".git"* ]]; then
                        message warn "⏭️  Skipping git source: $source_url"
                        continue
                    fi
                    
                    # Extract filename from URL
                    filename=$(basename "$source_url" | sed 's/?.*//')
                    
                    if [ -n "$filename" ] && [ "$filename" != "" ]; then
                        message info "⬇️  Downloading source: $filename"
                        curl -L -s "$source_url" -o "sources/$filename" 2>/dev/null || {
                            message warn "❌ Failed to download: $filename"
                        }
                        
                        # Check if file was downloaded successfully
                        if [ -f "sources/$filename" ] && [ -s "sources/$filename" ]; then
                            message info "✅ Downloaded: $filename ($(du -h "sources/$filename" | cut -f1))"
                        fi
                    fi
                done
            else
                message info "ℹ️  No external source files found for $package"
            fi
            
            # Download any .install files, patches, etc. from AUR
            # Get list of additional files from the AUR git repository
            additional_files=$(curl -s "https://aur.archlinux.org/cgit/aur.git/tree/?h=$package" | grep -oE 'href="[^"]+\.(install|patch|desktop|service|conf|cfg|xml)"' | sed 's/href="//' | sed 's/"//')
            
            for file_path in $additional_files; do
                filename=$(basename "$file_path")
                message info "📄 Downloading additional file: $filename"
                curl -s "https://aur.archlinux.org$file_path" -o "$filename" 2>/dev/null || {
                    message warn "Failed to download: $filename"
                }
            done
        fi
        
        # Check if package exists
        api_response=$(curl -s "https://aur.archlinux.org/rpc/?v=5&type=info&arg[]=$package")
        
        if echo "$api_response" | grep -q '"resultcount":0'; then
            message warn "⚠️  Package $package not found in AUR"
        else
            # Count backed up files
            file_count=$(find . -type f | wc -l)
            message info "✅ Package $package backed up successfully ($file_count files)"
        fi
    else
        message error "❌ Failed to download PKGBUILD for $package"
    fi
    
    cd ..
done

# Create README for the backup
cd ..
cat > "$BACKUP_DIR/README.md" << 'EOF'
# AUR Package Backups (v2)

This directory contains backups of all AUR packages used by the make-cachyOS-look-like-ubuntu project.

## What's New in v2

- **Source Files Included**: All external source files referenced in PKGBUILDs are downloaded
- **Additional Files**: .install scripts, patches, desktop files, etc. are included
- **Offline Building**: Complete package data for building without internet access

## Purpose

These backups ensure continued functionality even if:
- Packages are removed from AUR
- AUR is temporarily unavailable
- Package maintainers abandon packages
- External source files disappear

## Directory Structure

```
package-name/
├── PKGBUILD          # Build recipe
├── .SRCINFO          # Package metadata
├── sources/          # Downloaded source files
│   ├── archive.tar.gz
│   └── other-files
├── *.install         # Install scripts (if any)
└── *.patch           # Patches (if any)
```

## Usage

If an AUR package is no longer available, you can:

1. Copy the backed up package directory to a build location
2. Build the package manually with `makepkg -si`
3. Source files are already downloaded in the `sources/` subdirectory

## Backup Date

This backup was created on: $(date)

## Legal Notice

All PKGBUILDs and source files are subject to their original licenses and maintainer copyrights.
These backups are for contingency purposes only and should not be redistributed
without proper attribution to original maintainers.

## Package List

The following packages are backed up:
EOF

for package in "${AUR_PACKAGES[@]}"; do
    if [ -d "$BACKUP_DIR/$package" ]; then
        file_count=$(find "$BACKUP_DIR/$package" -type f | wc -l)
        echo "- $package ($file_count files)" >> "$BACKUP_DIR/README.md"
    else
        echo "- $package (failed)" >> "$BACKUP_DIR/README.md"
    fi
done

message "✅ AUR package backup completed!"
message "📁 Backups stored in: $BACKUP_DIR/"
message "📋 Total packages backed up: ${#AUR_PACKAGES[@]}"

# Create attribution file
cat > "$BACKUP_DIR/ATTRIBUTION.txt" << 'EOF'
AUR Package Attribution (v2)
============================

All PKGBUILDs and source files in this directory are downloaded from:
- The Arch User Repository (AUR): https://aur.archlinux.org/
- Original upstream sources as specified in PKGBUILDs

Original maintainers and contributors deserve full credit for their work.
Each package directory contains the original PKGBUILD with maintainer information.

License: Individual packages and source files are subject to their respective licenses
Source files may have different licenses than the PKGBUILDs themselves.

This backup is created for contingency purposes to ensure project continuity
and does not claim ownership of any PKGBUILD or source file content.

Backup Date: $(date)
Project: make-cachyOS-look-like-ubuntu
Repository: https://github.com/Anonymo/make-cachyOS-look-like-ubuntu
EOF

message "📝 Attribution file created: $BACKUP_DIR/ATTRIBUTION.txt"

# Calculate total backup size
total_size=$(du -sh "$BACKUP_DIR" | cut -f1)
message "💾 Total backup size: $total_size"
message "🎉 Backup process complete!"