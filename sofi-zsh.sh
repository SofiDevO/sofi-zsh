#!/bin/bash

# Colors for messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No color

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo:"
  echo "sudo $0"
  exec sudo "$0" "$@"
fi

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

get_latest_release_version() {
    local repo="$1"
    curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null | \
        grep -Eo '"tag_name"[[:space:]]*:[[:space:]]*"[^"]+"' | \
        head -n 1 | \
        sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v?([^"]+)".*/\1/'
}

# BAT installation
echo -e "\n${GREEN}[INFO] 🦝 Installing BAT...${NC}"
DEFAULT_BAT_RELEASE="bat_0.25.0_amd64.deb"
LATEST_BAT_VERSION="$(get_latest_release_version "sharkdp/bat")"
BAT_RELEASE="${LATEST_BAT_VERSION:+bat_${LATEST_BAT_VERSION}_amd64.deb}"
BAT_RELEASE="${BAT_RELEASE:-$DEFAULT_BAT_RELEASE}"

VERSION=$(echo "$BAT_RELEASE" | sed -E 's/bat_([0-9]+\.[0-9]+\.[0-9]+)_amd64\.deb/\1/')
[ -z "$VERSION" ] && error "Invalid package filename. Check the releases at: https://github.com/sharkdp/bat/releases"

BAT_URL="https://github.com/sharkdp/bat/releases/download/v$VERSION/$BAT_RELEASE"
if [ -n "$LATEST_BAT_VERSION" ]; then
    echo -e "${GREEN}[INFO] 🦝 Latest BAT release detected: ${LATEST_BAT_VERSION}${NC}"
else
    echo -e "${GREEN}[INFO] 🦝 Using default BAT release: ${DEFAULT_BAT_RELEASE}${NC}"
fi
curl -LO "$BAT_URL" || error "Failed to download BAT"
sudo dpkg -i "$BAT_RELEASE" || sudo apt install -f -y || error "Failed to install BAT"
rm -f "$BAT_RELEASE"

echo -e "${GREEN}[INFO] 🦝 Configuring BAT...${NC}"
cat > "${USER_HOME}/.bat.conf" <<EOF
# BAT configuration
--style="full"
EOF

echo -e "${GREEN}[INFO] 🦝 Building BAT cache...${NC}"


# LSD installation
echo -e "\n${GREEN}[INFO] 🦝 Installing LSD...${NC}"
DEFAULT_LSD_RELEASE="lsd_1.1.5_amd64.deb"
LATEST_LSD_VERSION="$(get_latest_release_version "lsd-rs/lsd")"
LSD_RELEASE="${LATEST_LSD_VERSION:+lsd_${LATEST_LSD_VERSION}_amd64.deb}"
LSD_RELEASE="${LSD_RELEASE:-$DEFAULT_LSD_RELEASE}"

VERSION_LSD=$(echo "$LSD_RELEASE" | sed -E 's/lsd_([0-9]+\.[0-9]+\.[0-9]+)_amd64\.deb/\1/')
[ -z "$VERSION_LSD" ] && error "Invalid package filename. Check: https://github.com/lsd-rs/lsd/releases"

LSD_URL="https://github.com/lsd-rs/lsd/releases/download/v$VERSION_LSD/$LSD_RELEASE"
if [ -n "$LATEST_LSD_VERSION" ]; then
    echo -e "${GREEN}[INFO] 🦝 Latest LSD release detected: ${LATEST_LSD_VERSION}${NC}"
else
    echo -e "${GREEN}[INFO] 🦝 Using default LSD release: ${DEFAULT_LSD_RELEASE}${NC}"
fi
curl -LO "$LSD_URL" || error "Failed to download LSD"
sudo dpkg -i "$LSD_RELEASE" || sudo apt install -f -y || error "Failed to install LSD"
rm -f "$LSD_RELEASE"

echo -e "\n${GREEN}[INFO] 🦝 Installing productivity tools...${NC}"
sudo apt install -y fzf ripgrep fd-find || error "Failed to install productivity tools."

if ! command -v zoxide >/dev/null 2>&1; then
    echo -e "${GREEN}[INFO] 🦝 Installing zoxide...${NC}"
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash || error "Failed to install zoxide."
fi

echo -e "\n${GREEN}[INFO] 🦝 Installing Git UX tools...${NC}"
if ! command -v lazygit >/dev/null 2>&1; then
    LAZYGIT_VERSION="$(get_latest_release_version "jesseduffield/lazygit")"
    LAZYGIT_VERSION="${LAZYGIT_VERSION:-v0.45.0}"
    LAZYGIT_VERSION="${LAZYGIT_VERSION#v}"
    LAZYGIT_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    curl -fsSL "$LAZYGIT_URL" -o /tmp/lazygit.tar.gz || error "Failed to download lazygit."
    tar -xzf /tmp/lazygit.tar.gz -C /tmp || error "Failed to extract lazygit."
    sudo install /tmp/lazygit /usr/local/bin/lazygit || error "Failed to install lazygit."
    rm -f /tmp/lazygit /tmp/lazygit.tar.gz
fi

if ! command -v delta >/dev/null 2>&1; then
    DELTA_VERSION="$(get_latest_release_version "dandavison/delta")"
    DELTA_VERSION="${DELTA_VERSION:-0.18.2}"
    DELTA_URL="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    curl -fsSL "$DELTA_URL" -o /tmp/delta.tar.gz || error "Failed to download delta."
    tar -xzf /tmp/delta.tar.gz -C /tmp || error "Failed to extract delta."
    sudo install /tmp/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl/delta /usr/local/bin/delta || error "Failed to install delta."
    rm -rf /tmp/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl /tmp/delta.tar.gz
fi

if ! command -v thefuck >/dev/null 2>&1; then
    echo -e "${GREEN}[INFO] 🦝 Installing thefuck...${NC}"
    sudo apt install -y python3-pip || error "Failed to install pip."
    python3 -m pip install --user thefuck || error "Failed to install thefuck."
fi

# Configure aliases in .zshrc
echo -e "\n${GREEN}[INFO] 🦝 Configuring .zshrc...${NC}"
ZSHRC="${USER_HOME}/.zshrc"
cp "${ZSHRC}" "${ZSHRC}.backup" || error "Failed to backup .zshrc"

if ! grep -Fq "# Sofi Zsh aliases" "${ZSHRC}"; then
    cat >>"${ZSHRC}" <<'EOF'

# Sofi Zsh aliases
alias cat="bat"
alias ls="lsd --group-dirs=first"
alias l="ls -l --group-dirs=first"
alias la="ls -a --group-dirs=first"
alias lla="ls -la --group-dirs=first"
alias lt="ls --tree --group-dirs=first"
alias commit="git add . && git commit"
alias fd="fdfind"

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v thefuck >/dev/null 2>&1; then
  eval "$(thefuck --alias)"
fi

if command -v fzf >/dev/null 2>&1; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null
  source /usr/share/doc/fzf/examples/completion.zsh 2>/dev/null
fi

if command -v delta >/dev/null 2>&1; then
  git config --global core.pager delta
  git config --global interactive.diffFilter "delta --color-only"
  git config --global delta.navigate true
  git config --global delta.light false
fi
EOF
else
    echo -e "${GREEN}[INFO] 🦝 Existing Sofi Zsh aliases found; keeping user config intact.${NC}"
fi

echo -e "\n${GREEN}[INFO] 🦝 Installation complete! Restart your terminal or run 'zsh'${NC}"
echo -e "${GREEN}[INFO] 🦝 Enjoy your supercharged terminal! 💜${NC}"