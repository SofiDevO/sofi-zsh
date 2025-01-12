#!/bin/bash

# Colors for messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No color

# Function to display errors
lerror() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if the script is being run as root
if [[ "$EUID" -ne 0 ]]; then
    echo -e "${RED}[ERROR]🦝 You must run this script as root or with sudo.${NC}"
    exit 1
fi

echo -e "${GREEN}[INFO] 🦝 Installing dependencies...${NC}"
sudo apt update || error "Failed to update the package list."
sudo apt install -y zsh git curl || error "Failed to install Zsh, Git, or Curl."

echo -e "${GREEN}[INFO] 🦝 Changing default shell to Zsh...${NC}"
chsh -s $(which zsh) "$USER" || error "Failed to change the default shell."

# Instructions after installation
echo -e "${GREEN}[INFO] 🦝 Installation complete. Please restart your terminal or run 'zsh' to start.${NC}"
echo -e "${GREEN}[INFO] 🦝 Once Zsh is active, please run the second script to install plugins and configure .zshrc.${NC}"

echo -e "${GREEN}[INFO] 🦝 Select option (0) when prompted to create the .zshrc file, and avoid running the script again to prevent overwriting.${NC}"
echo ""
echo "You can:"
echo "(0) Exit, creating the file ~/.zshrc containing just a comment."
echo "(1) Continue to the main menu."
echo "(2) Populate your ~/.zshrc with the configuration recommended by the system administrator."
