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
sudo apt update || error "Failed to update the package list."
sudo apt install -y zsh git curl || error "Failed to install Zsh, Git, or Curl."

echo -e "${GREEN}[INFO] 🦝 Changing default shell to Zsh...${NC}"
chsh -s $(which zsh) "$USER" || error "Failed to change the default shell."

echo -e "${GREEN}[INFO] 🦝 Installing Oh My Zsh🌈...${NC}"
export RUNZSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || error "Failed to install Oh My Zsh."

echo -e "${GREEN}[INFO] 🦝 Installing Zsh plugins...${NC}"
USER_HOME=$(eval echo ~$SUDO_USER)
ZSH_CUSTOM="${USER_HOME}/.oh-my-zsh/custom"
git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" || error "Failed to clone zsh-autosuggestions."
git clone https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" || error "Failed to clone zsh-syntax-highlighting."
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting "${ZSH_CUSTOM}/plugins/fast-syntax-highlighting" || error "Failed to clone fast-syntax-highlighting."
git clone https://github.com/marlonrichert/zsh-autocomplete "${ZSH_CUSTOM}/plugins/zsh-autocomplete" || error "Failed to clone zsh-autocomplete."

echo -e "${GREEN}[INFO] 🦝 Installing Powerlevel10k theme...${NC}"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM}/themes/powerlevel10k" || error "Failed to clone Powerlevel10k."

# Instalación de BAT
echo -e "\n${GREEN}[INFO] 🦝 Installing BAT...${NC}"
echo -e "${GREEN}[INFO] 🦝 Releases disponibles: https://github.com/sharkdp/bat/releases${NC}"
DEFAULT_BAT_RELEASE="bat_0.25.0_amd64.deb"
read -p "Enter BAT release filename [$DEFAULT_BAT_RELEASE]: " BAT_RELEASE
BAT_RELEASE=${BAT_RELEASE:-$DEFAULT_BAT_RELEASE}

VERSION=$(echo "$BAT_RELEASE" | sed -E 's/bat_([0-9]+\.[0-9]+\.[0-9]+)_amd64\.deb/\1/')
[ -z "$VERSION" ] && error "Formato de nombre incorrecto. Verifica las releases en: https://github.com/sharkdp/bat/releases"

BAT_URL="https://github.com/sharkdp/bat/releases/download/v$VERSION/$BAT_RELEASE"
curl -LO "$BAT_URL" || error "Failed to download BAT"
sudo dpkg -i "$BAT_RELEASE" || sudo apt install -f -y || error "Failed to install BAT"
rm -f "$BAT_RELEASE"

echo -e "${GREEN}[INFO] 🦝 Configuring BAT...${NC}"
cat > "${USER_HOME}/.bat.conf" <<EOF
# Configuración de BAT
--style="full"
EOF

echo -e "${GREEN}[INFO] 🦝 Building BAT cache...${NC}"


# Instalación de LSD
echo -e "\n${GREEN}[INFO] 🦝 Installing LSD...${NC}"
echo -e "${GREEN}[INFO] 🦝 Releases disponibles: https://github.com/lsd-rs/lsd/releases${NC}"
DEFAULT_LSD_RELEASE="lsd_1.1.5_amd64.deb"
read -p "Enter LSD release filename [$DEFAULT_LSD_RELEASE]: " LSD_RELEASE
LSD_RELEASE=${LSD_RELEASE:-$DEFAULT_LSD_RELEASE}

VERSION_LSD=$(echo "$LSD_RELEASE" | sed -E 's/lsd_([0-9]+\.[0-9]+\.[0-9]+)_amd64\.deb/\1/')
[ -z "$VERSION_LSD" ] && error "Nombre de archivo inválido. Consulta: https://github.com/lsd-rs/lsd/releases"

LSD_URL="https://github.com/lsd-rs/lsd/releases/download/v$VERSION_LSD/$LSD_RELEASE"
curl -LO "$LSD_URL" || error "Failed to download LSD"
sudo dpkg -i "$LSD_RELEASE" || sudo apt install -f -y || error "Failed to install LSD"
rm -f "$LSD_RELEASE"

# Instalación de gitmoji
echo -e "\n${GREEN}[INFO] 🦝 Installing gitmoji...${NC}"
if ! command -v npm &>/dev/null; then
    error "npm is required. Install Node.js first."
fi
sudo npm install -g gitmoji-cli || error "Failed to install gitmoji"

# Configuración de aliases en .zshrc
echo -e "\n${GREEN}[INFO] 🦝 Configuring .zshrc...${NC}"
ZSHRC="${USER_HOME}/.zshrc"
cp "${ZSHRC}" "${ZSHRC}.backup" || error "Failed to backup .zshrc"

cat >"${ZSHRC}" <<EOF
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)
source \$ZSH/oh-my-zsh.sh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Aliases
alias cat="bat"
alias ls="lsd --group-dirs=first"
alias l="ls -l --group-dirs=first"
alias la="ls -a --group-dirs=first"
alias lla="ls -la --group-dirs=first"
alias lt="ls --tree --group-dirs=first"
alias commit="gitmoji -i && git add . && git commit "
EOF

echo -e "\n${GREEN}[INFO] 🦝 Installation complete! Restart your terminal or run 'zsh'${NC}"
echo -e "${GREEN}[INFO] 🦝 Enjoy your supercharged terminal! 💜${NC}"