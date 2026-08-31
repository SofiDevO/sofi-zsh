#!/bin/bash

# Colors for messages
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo:"
  echo "sudo $0"
  exec sudo "$0" "$@"
fi

USER_HOME=$(eval echo ~"$SUDO_USER")
ZSH_CUSTOM="${USER_HOME}/.oh-my-zsh/custom"
ZSHRC="${USER_HOME}/.zshrc"

# ─── State flags (set to 1 as each step completes) ──────────────────────────
INSTALLED_ZSH=0
INSTALLED_OMZ=0
INSTALLED_PLUGINS=0
INSTALLED_P10K=0
INSTALLED_BAT=0
INSTALLED_BAT_CONF=0
INSTALLED_LSD=0
INSTALLED_PRODUCTIVITY=0
INSTALLED_ZOXIDE=0
INSTALLED_LAZYGIT=0
INSTALLED_DELTA=0
ZSHRC_BACKED_UP=0
ZSHRC_MODIFIED=0

# ─── Cleanup: undoes everything this script touched ─────────────────────────
cleanup() {
    echo -e "\n${YELLOW}[CLEANUP] Rolling back changes...${NC}"

    if [ "$ZSHRC_MODIFIED" -eq 1 ]; then
        echo -e "${YELLOW}[CLEANUP] Restoring original .zshrc...${NC}"
        mv "${ZSHRC}.backup" "${ZSHRC}" 2>/dev/null
    elif [ "$ZSHRC_BACKED_UP" -eq 1 ]; then
        rm -f "${ZSHRC}.backup"
    fi

    if [ "$INSTALLED_DELTA" -eq 1 ]; then
        echo -e "${YELLOW}[CLEANUP] Removing delta...${NC}"
        rm -f /usr/local/bin/delta
    fi

    if [ "$INSTALLED_LAZYGIT" -eq 1 ]; then
        echo -e "${YELLOW}[CLEANUP] Removing lazygit...${NC}"
        rm -f /usr/local/bin/lazygit
    fi

    if [ "$INSTALLED_ZOXIDE" -eq 1 ]; then
        echo -e "${YELLOW}[CLEANUP] Removing zoxide...${NC}"
        rm -f "${USER_HOME}/.local/bin/zoxide"
    fi

    if [ "$INSTALLED_PRODUCTIVITY" -eq 1 ]; then
        echo -e "${YELLOW}[CLEANUP] Removing fzf, ripgrep, fd-find...${NC}"
        apt remove -y fzf ripgrep fd-find 2>/dev/null
    fi

    if [ "$INSTALLED_LSD" -eq 1 ]; then
        echo -e "${YELLOW}[CLEANUP] Removing lsd...${NC}"
        apt remove -y lsd 2>/dev/null
    fi

    if [ "$INSTALLED_BAT_CONF" -eq 1 ]; then
        echo -e "${YELLOW}[CLEANUP] Removing bat config...${NC}"
        rm -f "${USER_HOME}/.bat.conf"
    fi

    if [ "$INSTALLED_BAT" -eq 1 ]; then
        echo -e "${YELLOW}[CLEANUP] Removing bat...${NC}"
        apt remove -y bat 2>/dev/null
    fi

    if [ "$INSTALLED_P10K" -eq 1 ]; then
        echo -e "${YELLOW}[CLEANUP] Removing Powerlevel10k...${NC}"
        rm -rf "${ZSH_CUSTOM}/themes/powerlevel10k"
    fi

    if [ "$INSTALLED_PLUGINS" -eq 1 ]; then
        echo -e "${YELLOW}[CLEANUP] Removing Zsh plugins...${NC}"
        rm -rf \
            "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" \
            "${ZSH_CUSTOM}/plugins/fast-syntax-highlighting"
    fi

    if [ "$INSTALLED_OMZ" -eq 1 ]; then
        echo -e "${YELLOW}[CLEANUP] Removing Oh My Zsh...${NC}"
        rm -rf "${USER_HOME}/.oh-my-zsh"
    fi

    if [ "$INSTALLED_ZSH" -eq 1 ]; then
        echo -e "${YELLOW}[CLEANUP] Restoring original shell...${NC}"
        chsh -s /bin/bash "$SUDO_USER" 2>/dev/null
        apt remove -y zsh 2>/dev/null
    fi

    echo -e "${YELLOW}[CLEANUP] Done. Your system is back to its original state.${NC}"
}

#  Error handler
error() {
    local msg="$1"
    echo -e "\n${RED}[ERROR] ${msg}${NC}"
    echo -e "${RED}[ERROR] Installation aborted. Starting cleanup...${NC}"
    cleanup
    exit 1
}

#  Helper: fetch latest GitHub release tag
get_latest_release_version() {
    local repo="$1"
    curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null | \
        grep -Eo '"tag_name"[[:space:]]*:[[:space:]]*"[^"]+"' | \
        head -n 1 | \
        sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v?([^"]+)".*/\1/'
}

# Installation


echo -e "${GREEN}"
cat <<'BANNER'
  _____       __ _    _____     _
 / ____|     / _(_)  |_  / |   | |
| (___  ___ | |_ _ ___ / /___| |__
 \___ \/ _ \|  _| |___/ _/ __| '_ \
 ____) | (_) | | | |  / /_\__ \ | | |
|_____/ \___/|_| |_| /____|___/_| |_|
BANNER
echo -e "${NC}"

echo -e "${GREEN}[INFO] Checking dependencies...${NC}"
if ! dpkg -s zsh >/dev/null 2>&1 || ! dpkg -s git >/dev/null 2>&1 || ! dpkg -s curl >/dev/null 2>&1; then
    echo -e "${GREEN}[INFO] Installing dependencies...${NC}"
    apt update || error "Failed to update the package list."
    apt install -y zsh git curl || error "Failed to install zsh, git, or curl."
    INSTALLED_ZSH=1
else
    echo -e "${GREEN}[INFO] Dependencies already installed, skipping.${NC}"
fi

echo -e "${GREEN}[INFO] Checking default shell...${NC}"
CURRENT_SHELL="$(getent passwd "$SUDO_USER" | cut -d: -f7)"
ZSH_BIN="$(which zsh)"
if [ "$CURRENT_SHELL" = "$ZSH_BIN" ]; then
    echo -e "${GREEN}[INFO] Default shell already Zsh, skipping.${NC}"
else
    echo -e "${GREEN}[INFO] Changing default shell to Zsh...${NC}"
    chsh -s "$ZSH_BIN" "$SUDO_USER" || error "Failed to change the default shell."
fi

echo -e "${GREEN}[INFO] Checking Oh My Zsh...${NC}"
if [ -d "${USER_HOME}/.oh-my-zsh" ]; then
    echo -e "${GREEN}[INFO] Oh My Zsh already installed, skipping.${NC}"
else
    echo -e "${GREEN}[INFO] Installing Oh My Zsh...${NC}"
    export RUNZSH=no
    su -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"' "$SUDO_USER" \
        || error "Failed to install Oh My Zsh."
    INSTALLED_OMZ=1
fi

echo -e "${GREEN}[INFO] Checking Zsh plugins...${NC}"
# NOTA: solo se instala fast-syntax-highlighting. zsh-syntax-highlighting es incompatible
# con fast-syntax-highlighting, y zsh-autocomplete es incompatible con zsh-autosuggestions.
if [ -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
    echo -e "${GREEN}[INFO] zsh-autosuggestions already installed, skipping.${NC}"
else
    git clone https://github.com/zsh-users/zsh-autosuggestions       "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"         || error "Failed to clone zsh-autosuggestions."
    INSTALLED_PLUGINS=1
fi
if [ -d "${ZSH_CUSTOM}/plugins/fast-syntax-highlighting" ]; then
    echo -e "${GREEN}[INFO] fast-syntax-highlighting already installed, skipping.${NC}"
else
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting "${ZSH_CUSTOM}/plugins/fast-syntax-highlighting" || error "Failed to clone fast-syntax-highlighting."
    INSTALLED_PLUGINS=1
fi

echo -e "${GREEN}[INFO] Checking Powerlevel10k theme...${NC}"
if [ -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]; then
    echo -e "${GREEN}[INFO] Powerlevel10k already installed, skipping.${NC}"
else
    echo -e "${GREEN}[INFO] Installing Powerlevel10k theme...${NC}"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM}/themes/powerlevel10k" \
        || error "Failed to clone Powerlevel10k."
    INSTALLED_P10K=1
fi

# BAT — idempotente: solo instala si no existe
if command -v bat >/dev/null 2>&1; then
    echo -e "\n${GREEN}[INFO] bat already installed ($(bat --version 2>/dev/null)), skipping.${NC}"
else
    echo -e "\n${GREEN}[INFO] Installing bat...${NC}"
    DEFAULT_BAT_RELEASE="bat_0.25.0_amd64.deb"
    LATEST_BAT_VERSION="$(get_latest_release_version "sharkdp/bat")"
    BAT_RELEASE="${LATEST_BAT_VERSION:+bat_${LATEST_BAT_VERSION}_amd64.deb}"
    BAT_RELEASE="${BAT_RELEASE:-$DEFAULT_BAT_RELEASE}"
    BAT_VERSION=$(echo "$BAT_RELEASE" | sed -E 's/bat_([0-9]+\.[0-9]+\.[0-9]+)_amd64\.deb/\1/')
    [ -z "$BAT_VERSION" ] && error "Could not determine bat version. Check: https://github.com/sharkdp/bat/releases"
    BAT_URL="https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/${BAT_RELEASE}"
    [ -n "$LATEST_BAT_VERSION" ] \
        && echo -e "${GREEN}[INFO] Latest bat release: ${LATEST_BAT_VERSION}${NC}" \
        || echo -e "${GREEN}[INFO] Using default bat release: ${DEFAULT_BAT_RELEASE}${NC}"
    curl -LO "$BAT_URL"                                    || error "Failed to download bat."
    dpkg -i "$BAT_RELEASE" || apt install -f -y            || error "Failed to install bat."
    rm -f "$BAT_RELEASE"
    INSTALLED_BAT=1
fi

echo -e "${GREEN}[INFO] Checking bat config...${NC}"
if [ -f "${USER_HOME}/.bat.conf" ] && grep -q 'style="full"' "${USER_HOME}/.bat.conf" 2>/dev/null; then
    echo -e "${GREEN}[INFO] bat config already exists, skipping.${NC}"
else
    echo -e "${GREEN}[INFO] Configuring bat...${NC}"
    cat > "${USER_HOME}/.bat.conf" <<'BATEOF'
# BAT configuration
--style="full"
BATEOF
    INSTALLED_BAT_CONF=1
fi

# LSD — idempotente: solo instala si no existe
if command -v lsd >/dev/null 2>&1; then
    echo -e "\n${GREEN}[INFO] lsd already installed ($(lsd --version 2>/dev/null)), skipping.${NC}"
else
    echo -e "\n${GREEN}[INFO] Installing lsd...${NC}"
    DEFAULT_LSD_RELEASE="lsd_1.1.5_amd64.deb"
    LATEST_LSD_VERSION="$(get_latest_release_version "lsd-rs/lsd")"
    LSD_RELEASE="${LATEST_LSD_VERSION:+lsd_${LATEST_LSD_VERSION}_amd64.deb}"
    LSD_RELEASE="${LSD_RELEASE:-$DEFAULT_LSD_RELEASE}"
    LSD_VERSION=$(echo "$LSD_RELEASE" | sed -E 's/lsd_([0-9]+\.[0-9]+\.[0-9]+)_amd64\.deb/\1/')
    [ -z "$LSD_VERSION" ] && error "Could not determine lsd version. Check: https://github.com/lsd-rs/lsd/releases"
    LSD_URL="https://github.com/lsd-rs/lsd/releases/download/v${LSD_VERSION}/${LSD_RELEASE}"
    [ -n "$LATEST_LSD_VERSION" ] \
        && echo -e "${GREEN}[INFO] Latest lsd release: ${LATEST_LSD_VERSION}${NC}" \
        || echo -e "${GREEN}[INFO] Using default lsd release: ${DEFAULT_LSD_RELEASE}${NC}"
    curl -LO "$LSD_URL"                                    || error "Failed to download lsd."
    dpkg -i "$LSD_RELEASE" || apt install -f -y            || error "Failed to install lsd."
    rm -f "$LSD_RELEASE"
    INSTALLED_LSD=1
fi

# Productivity tools — idempotente: instala solo los faltantes
MISSING_PROD=""
for _pkg in fzf ripgrep fd-find; do
    if ! dpkg -s "$_pkg" >/dev/null 2>&1; then
        MISSING_PROD="$_pkg $MISSING_PROD"
    fi
done
if [ -z "$MISSING_PROD" ]; then
    echo -e "\n${GREEN}[INFO] Productivity tools (fzf, ripgrep, fd-find) already installed, skipping.${NC}"
else
    echo -e "\n${GREEN}[INFO] Installing productivity tools ($MISSING_PROD)...${NC}"
    # shellcheck disable=SC2086
    apt install -y $MISSING_PROD || error "Failed to install productivity tools."
    INSTALLED_PRODUCTIVITY=1
fi

# zoxide
if ! command -v zoxide >/dev/null 2>&1; then
    echo -e "${GREEN}[INFO] Installing zoxide...${NC}"
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash \
        || error "Failed to install zoxide."
    INSTALLED_ZOXIDE=1
fi

# lazygit
echo -e "\n${GREEN}[INFO] Installing Git UX tools...${NC}"
if ! command -v lazygit >/dev/null 2>&1; then
    LAZYGIT_VERSION="$(get_latest_release_version "jesseduffield/lazygit")"
    LAZYGIT_VERSION="${LAZYGIT_VERSION:-0.45.0}"
    LAZYGIT_VERSION="${LAZYGIT_VERSION#v}"
    LAZYGIT_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    curl -fsSL "$LAZYGIT_URL" -o /tmp/lazygit.tar.gz   || error "Failed to download lazygit."
    tar -xzf /tmp/lazygit.tar.gz -C /tmp               || error "Failed to extract lazygit."
    install /tmp/lazygit /usr/local/bin/lazygit         || error "Failed to install lazygit."
    rm -f /tmp/lazygit /tmp/lazygit.tar.gz
    INSTALLED_LAZYGIT=1
fi

# delta
if ! command -v delta >/dev/null 2>&1; then
    DELTA_VERSION="$(get_latest_release_version "dandavison/delta")"
    DELTA_VERSION="${DELTA_VERSION:-0.18.2}"
    DELTA_URL="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    curl -fsSL "$DELTA_URL" -o /tmp/delta.tar.gz        || error "Failed to download delta."
    tar -xzf /tmp/delta.tar.gz -C /tmp                  || error "Failed to extract delta."
    install /tmp/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl/delta /usr/local/bin/delta \
        || error "Failed to install delta."
    rm -rf /tmp/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl /tmp/delta.tar.gz
    INSTALLED_DELTA=1
fi

#  Configure .zshrc — validación antes de sobrescribir
echo -e "\n${YELLOW}[WARN] This will modify ${ZSHRC} and may overwrite your current configuration.${NC}"
echo -e "${YELLOW}[WARN] A backup will be saved as ${ZSHRC}.backup${NC}"
printf "${YELLOW}Do you want to continue? [Y/n]: ${NC}"
read -r _confirm
_confirm=${_confirm:-Y}
if [[ ! "$_confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}[INFO] Aborted by user. No changes were made.${NC}"
    exit 0
fi

echo -e "\n${GREEN}[INFO] Configuring .zshrc...${NC}"
cp "${ZSHRC}" "${ZSHRC}.backup" || error "Failed to backup .zshrc."
ZSHRC_BACKED_UP=1

# ─── Asegura PATH temprano para plugins que viven en ~/.local/bin (zoxide) ───
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "${ZSHRC}"; then
    # Inserta al inicio para que esté disponible antes de cargar plugins
    sed -i '1i export PATH="$HOME/.local/bin:$PATH"' "${ZSHRC}"
fi

# ─── Tema ───
if grep -q '^ZSH_THEME=' "${ZSHRC}"; then
    sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "${ZSHRC}"
else
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "${ZSHRC}"
fi

# ─── Plugins: reemplaza cualquier bloque plugins=(...) existente ───
# Plugins finales optimizados (13) - sin conflictos: solo fast-syntax-highlighting (no zsh-syntax-highlighting)
# y solo zsh-autosuggestions (no zsh-autocomplete). Orden: autosuggestions y fast al final.
DESIRED_PLUGINS='plugins=(
  git
  sudo
  command-not-found
  colored-man-pages
  jsontools
  extract
  bgnotify
  copypath
  gitignore
  web-search
  emoji
  zsh-autosuggestions
  fast-syntax-highlighting
)'
# Usa perl para reemplazo multilínea robusto
perl -i -0777 -pe "s/plugins=\([^)]*\)/$DESIRED_PLUGINS/s" "${ZSHRC}" || error "Failed to configure plugins in .zshrc."

# ─── Autosuggestions visible en Kitty/P10k ───
if ! grep -q 'ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE' "${ZSHRC}"; then
    # Inserta después de source $ZSH/oh-my-zsh.sh
    sed -i '/source \$ZSH\/oh-my-zsh.sh/a ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#9e9e9e"' "${ZSHRC}"
fi

# ─── Completion menu select (navegar con flecha ↓) ───
if ! grep -q "zstyle ':completion:" "${ZSHRC}"; then
    sed -i '/ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE/a zstyle '"'"':completion:*'"'"' menu select' "${ZSHRC}"
fi
if ! grep -q 'autoload -U compinit' "${ZSHRC}"; then
    sed -i "/zstyle ':completion:\*'/a autoload -U compinit && compinit" "${ZSHRC}"
fi

if ! grep -Fq "# Sofi Zsh aliases" "${ZSHRC}"; then
    cat >> "${ZSHRC}" <<'ZSHRCEOF'

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
ZSHRCEOF
    ZSHRC_MODIFIED=1
else
    echo -e "${GREEN}[INFO] Existing Sofi Zsh aliases found; keeping user config intact.${NC}"
fi


rm -f "${ZSHRC}.backup"

echo -e "\n${GREEN}[INFO] Installation complete! Restart your terminal or run 'zsh'.${NC}"
echo -e "${GREEN}[INFO] Enjoy your supercharged terminal!${NC}"
