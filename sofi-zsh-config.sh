#!/bin/bash

# Colors for messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No color

# Function to display errors
error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

echo -e "${GREEN}[INFO] 🦝 Installing dependencies...${NC}"
# Instalamos dependencias utilizando sudo solo cuando sea necesario
sudo apt update || error "Failed to update the package list."
sudo apt install -y zsh git curl || error "Failed to install Zsh, Git, or Curl."

echo -e "${GREEN}[INFO] 🦝 Changing default shell to Zsh...${NC}"
# Cambiar la shell por defecto solo con sudo
sudo chsh -s $(which zsh) "$USER" || error "Failed to change the default shell."

echo -e "${GREEN}[INFO] 🦝 Installing Oh My Zsh...${NC}"
# Evitamos ejecutar el script de instalación como root, se ejecuta como usuario normal
export RUNZSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || error "Failed to install Oh My Zsh."

echo -e "${GREEN}[INFO] 🦝 Installing Zsh plugins...${NC}"
# Instalar los plugins en el directorio de usuario
USER_HOME=$(eval echo ~$SUDO_USER)
ZSH_CUSTOM="${USER_HOME}/.oh-my-zsh/custom"
git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" || error "Failed to clone zsh-autosuggestions."
git clone https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" || error "Failed to clone zsh-syntax-highlighting."
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting "${ZSH_CUSTOM}/plugins/fast-syntax-highlighting" || error "Failed to clone fast-syntax-highlighting."
git clone https://github.com/marlonrichert/zsh-autocomplete "${ZSH_CUSTOM}/plugins/zsh-autocomplete" || error "Failed to clone zsh-autocomplete."

echo -e "${GREEN}[INFO] 🦝 Installing Powerlevel10k theme...${NC}"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM}/themes/powerlevel10k" || error "Failed to clone Powerlevel10k."

echo -e "${GREEN}[INFO] 🦝 Configuring .zshrc...${NC}"

ZSHRC="${USER_HOME}/.zshrc"

# Always backup the existing .zshrc before overwriting
cp "${ZSHRC}" "${ZSHRC}.backup" || error "Failed to create a backup of .zshrc."

# Overwrite .zshrc with default configuration
cat > "${ZSHRC}" <<EOF
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)
source \$ZSH/oh-my-zsh.sh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF

echo -e "${GREEN}[INFO] 🦝 Installation complete. Restart your terminal or run 'zsh' to start.${NC}"
