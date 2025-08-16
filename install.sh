#!/bin/bash

# One-command installer for make-cachyos-look-like-ubuntu
# This script automatically installs dependencies, clones the repo, and runs the main script

set -e  # Exit on any error

# Colors for output
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
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

message info "🚀 Starting CachyOS to Ubuntu transformation installer..."

# Check if running as root
if [ "$(whoami)" == "root" ]; then
    message error "This script should not be run as root!"
    exit 1
fi

# Get current user
CURRENT_USER=$(whoami)
USER_GROUPS=$(groups)

# Check if user is in sudo or wheel group (CachyOS uses wheel)
if ! echo "$USER_GROUPS" | grep -E "(sudo|wheel)" > /dev/null; then
    message error "Your user '$CURRENT_USER' is not in the 'sudo' or 'wheel' group."
    message error "CachyOS typically uses the 'wheel' group for sudo access."
    message error "Add your user to the wheel group with:"
    message error " ${YELLOW}su -c \"usermod -aG wheel ${CURRENT_USER}\"${ENDCOLOR}"
    message error "Then logout/login or reboot and run this script again."
    exit 1
fi

# Verify sudo access works
if ! sudo -n true 2>/dev/null; then
    message info "Sudo password may be required for installation"
fi

message info "✅ User '$CURRENT_USER' is in the $(echo "$USER_GROUPS" | grep -oE "(sudo|wheel)" | head -1) group"

# Install git if not present
if ! command -v git &> /dev/null; then
    message info "📦 Installing git..."
    sudo pacman -S --needed --noconfirm git
else
    message info "✅ git is already installed"
fi

# Check for AUR helper (yay or paru)
AUR_HELPER=""
if command -v yay &> /dev/null; then
    AUR_HELPER="yay"
    message info "✅ Found AUR helper: yay"
elif command -v paru &> /dev/null; then
    AUR_HELPER="paru"
    message info "✅ Found AUR helper: paru"
else
    message info "📦 Installing yay AUR helper..."
    
    # Install base-devel if not present
    sudo pacman -S --needed --noconfirm base-devel
    
    # Create temp directory and install yay
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    rm -rf "$TEMP_DIR"
    
    AUR_HELPER="yay"
    message info "✅ yay installed successfully"
fi

# Clone the repository
REPO_DIR="$HOME/make-cachyOS-look-like-ubuntu"
if [ -d "$REPO_DIR" ]; then
    message info "📂 Repository already exists, updating..."
    cd "$REPO_DIR"
    git pull
else
    message info "📥 Cloning repository..."
    cd "$HOME"
    git clone https://github.com/Anonymo/make-cachyOS-look-like-ubuntu.git
    cd "$REPO_DIR"
fi

# Make script executable
chmod +x make-cachyos-look-like-ubuntu.sh

# Run the main script
message info "🎨 Running Ubuntu transformation script..."
./make-cachyos-look-like-ubuntu.sh

message info "🎉 Installation completed!"
message warn "📝 Remember to reboot and run the script again if this was the first time!"
message info "📁 Repository saved to: $REPO_DIR"