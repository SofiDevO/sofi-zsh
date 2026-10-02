#!/bin/bash

# Colors for messages
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo:"
  echo "sudo $0"
  # Resolve to an absolute path first: `bash sofi-zsh.sh` gives a bare $0 that
  # sudo would look up in its own secure PATH instead of the current directory.
  SELF="$(readlink -f "$0" 2>/dev/null || printf '%s' "$0")"
  exec sudo bash "$SELF" "$@"
fi

# ─── Paths ──────────────────────────────────────────────────────────────────
# Everything that belongs to the real user must be created with their HOME,
# otherwise root's HOME leaks into installers and writes land in /root.
if [ -z "$SUDO_USER" ]; then
  echo "SUDO_USER is not set. Run this script with sudo:"
  echo "sudo $0"
  exit 1
fi
USER_HOME=$(eval echo ~"$SUDO_USER")
USER_GROUP="$(id -gn "$SUDO_USER" 2>/dev/null || id -gn root)"
ZSH_CUSTOM="${USER_HOME}/.oh-my-zsh/custom"
ZSHRC="${USER_HOME}/.zshrc"
OMZ_TEMPLATE="${USER_HOME}/.oh-my-zsh/templates/zshrc.zsh"
BAT_CONFIG_DIR="${USER_HOME}/.config/bat"
BAT_CONFIG="${BAT_CONFIG_DIR}/config"

# ─── State flags (set to 1 as each step completes) ──────────────────────────
INSTALLED_ZSH=0
INSTALLED_OMZ=0
INSTALLED_PLUGINS=0
INSTALLED_P10K=0
INSTALLED_BAT=0
INSTALLED_BAT_CONF=0
INSTALLED_LSD=0
INSTALLED_PRODUCTIVITY=0
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
        rm -f "${BAT_CONFIG}"
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
        apt remove -y zsh zsh-common 2>/dev/null
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

#  Helper: download a .deb from GitHub releases.
#  Tries both the "v1.2.3" and the "1.2.3" tag formats, because projects differ
#  (bat tags with a leading v, lsd does not). Prints the local path on success.
fetch_github_deb() {
    local repo="$1" pkg="$2" version="$3"
    local deb="${pkg}_${version}_amd64.deb"
    local prefix url
    for prefix in v ""; do
        url="https://github.com/${repo}/releases/download/${prefix}${version}/${deb}"
        if curl -fsSL -o "/tmp/${deb}" "$url" 2>/dev/null; then
            echo "/tmp/${deb}"
            return 0
        fi
    done
    return 1
}

#  Helper: make a path owned by the real user (clones run as root otherwise)
own() {
    chown -R "${SUDO_USER}:${USER_GROUP}" "$1" 2>/dev/null || \
        echo -e "${YELLOW}[WARN] Could not fix ownership of $1${NC}"
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
NEED_ZSH=0
dpkg -s zsh   >/dev/null 2>&1 || NEED_ZSH=1
if [ "$NEED_ZSH" -eq 1 ] || ! dpkg -s git >/dev/null 2>&1 || ! dpkg -s curl >/dev/null 2>&1; then
    echo -e "${GREEN}[INFO] Installing dependencies...${NC}"
    apt update || error "Failed to update the package list."
    apt install -y zsh git curl || error "Failed to install zsh, git, or curl."
    [ "$NEED_ZSH" -eq 1 ] && INSTALLED_ZSH=1
else
    echo -e "${GREEN}[INFO] Dependencies already installed, skipping.${NC}"
fi

echo -e "${GREEN}[INFO] Checking default shell...${NC}"
CURRENT_SHELL="$(getent passwd "$SUDO_USER" | cut -d: -f7)"
ZSH_BIN="$(command -v zsh)"
if [ -z "$ZSH_BIN" ]; then
    error "zsh binary not found in PATH."
fi
# /bin/zsh and /usr/bin/zsh are usually the same file via symlink; compare targets
if [ "$(readlink -f "$CURRENT_SHELL")" = "$(readlink -f "$ZSH_BIN")" ]; then
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
    # --unattended: never prompt (we may be running without a TTY).
    # RUNZSH/CHSH are set explicitly: we do not want OMZ to spawn a shell or
    # change the login shell behind our back. KEEP_ZSHRC keeps any existing
    # .zshrc untouched (we back it up and edit it ourselves below).
    su -c 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" -- --unattended' "$SUDO_USER" \
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

# git clone above runs as root, which would leave the user unable to run
# `omz update` or manage plugins. Always restore ownership of the custom tree.
own "${ZSH_CUSTOM}"

# BAT — idempotente: solo instala si no existe
if command -v bat >/dev/null 2>&1; then
    echo -e "\n${GREEN}[INFO] bat already installed ($(bat --version 2>/dev/null)), skipping.${NC}"
else
    echo -e "\n${GREEN}[INFO] Installing bat...${NC}"
    DEFAULT_BAT_VERSION="0.25.0"
    LATEST_BAT_VERSION="$(get_latest_release_version "sharkdp/bat")"
    BAT_VERSION="${LATEST_BAT_VERSION:-$DEFAULT_BAT_VERSION}"
    BAT_VERSION="${BAT_VERSION#v}"
    [ -z "$BAT_VERSION" ] && error "Could not determine bat version. Check: https://github.com/sharkdp/bat/releases"
    [ -n "$LATEST_BAT_VERSION" ] \
        && echo -e "${GREEN}[INFO] Latest bat release: ${BAT_VERSION}${NC}" \
        || echo -e "${GREEN}[INFO] Using default bat release: ${DEFAULT_BAT_VERSION}${NC}"
    BAT_DEB="$(fetch_github_deb "sharkdp/bat" "bat" "$BAT_VERSION")" \
        || error "Failed to download bat ${BAT_VERSION}. Check https://github.com/sharkdp/bat/releases"
    dpkg -i "$BAT_DEB" || apt install -f -y || error "Failed to install bat."
    rm -f "$BAT_DEB"
    INSTALLED_BAT=1
fi

echo -e "${GREEN}[INFO] Checking bat config...${NC}"
# bat reads $XDG_CONFIG_HOME/bat/config (~/.config/bat/config) — NOT ~/.bat.conf.
# Remove the file written by older versions of this script.
[ -f "${USER_HOME}/.bat.conf" ] && rm -f "${USER_HOME}/.bat.conf"
if [ -f "${BAT_CONFIG}" ] && grep -q 'style' "${BAT_CONFIG}" 2>/dev/null; then
    echo -e "${GREEN}[INFO] bat config already exists, skipping.${NC}"
else
    echo -e "${GREEN}[INFO] Configuring bat...${NC}"
    mkdir -p "${BAT_CONFIG_DIR}"
    cat > "${BAT_CONFIG}" <<'BATEOF'
# BAT configuration
--style=full
BATEOF
    own "${BAT_CONFIG_DIR}"
    INSTALLED_BAT_CONF=1
fi

# LSD — idempotente: solo instala si no existe
if command -v lsd >/dev/null 2>&1; then
    echo -e "\n${GREEN}[INFO] lsd already installed ($(lsd --version 2>/dev/null)), skipping.${NC}"
else
    echo -e "\n${GREEN}[INFO] Installing lsd...${NC}"
    DEFAULT_LSD_VERSION="1.1.5"
    LATEST_LSD_VERSION="$(get_latest_release_version "lsd-rs/lsd")"
    LSD_VERSION="${LATEST_LSD_VERSION:-$DEFAULT_LSD_VERSION}"
    LSD_VERSION="${LSD_VERSION#v}"
    [ -z "$LSD_VERSION" ] && error "Could not determine lsd version. Check: https://github.com/lsd-rs/lsd/releases"
    [ -n "$LATEST_LSD_VERSION" ] \
        && echo -e "${GREEN}[INFO] Latest lsd release: ${LSD_VERSION}${NC}" \
        || echo -e "${GREEN}[INFO] Using default lsd release: ${DEFAULT_LSD_VERSION}${NC}"
    LSD_DEB="$(fetch_github_deb "lsd-rs/lsd" "lsd" "$LSD_VERSION")" \
        || error "Failed to download lsd ${LSD_VERSION}. Check https://github.com/lsd-rs/lsd/releases"
    dpkg -i "$LSD_DEB" || apt install -f -y || error "Failed to install lsd."
    rm -f "$LSD_DEB"
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
    DELTA_VERSION="${DELTA_VERSION#v}"
    DELTA_URL="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    curl -fsSL "$DELTA_URL" -o /tmp/delta.tar.gz        || error "Failed to download delta."
    tar -xzf /tmp/delta.tar.gz -C /tmp                  || error "Failed to extract delta."
    install /tmp/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl/delta /usr/local/bin/delta \
        || error "Failed to install delta."
    rm -rf /tmp/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl /tmp/delta.tar.gz
    INSTALLED_DELTA=1
fi

# ─── git: delta como pager (como el usuario real, no como root) ───
# Configured at install time so it does not spawn 4 `git config` processes on
# every shell start. This does not touch .zshrc, so it runs even if the user
# declines the .zshrc step below.
if command -v delta >/dev/null 2>&1; then
    echo -e "${GREEN}[INFO] Configuring git to use delta...${NC}"
    HOME="${USER_HOME}" git config --global core.pager delta           || error "Failed to configure git pager."
    HOME="${USER_HOME}" git config --global interactive.diffFilter "delta --color-only"
    HOME="${USER_HOME}" git config --global delta.navigate true
    HOME="${USER_HOME}" git config --global delta.light false
    own "${USER_HOME}/.gitconfig"
fi

#  Configure .zshrc — validación antes de sobrescribir
echo -e "\n${YELLOW}[WARN] This will modify ${ZSHRC} and may overwrite your current configuration.${NC}"
echo -e "${YELLOW}[WARN] A backup will be saved as ${ZSHRC}.backup${NC}"
if [ -t 0 ]; then
    printf "${YELLOW}Do you want to continue? [Y/n]: ${NC}"
    read -r _confirm
    _confirm=${_confirm:-Y}
else
    echo -e "${YELLOW}[INFO] Non-interactive shell detected, continuing without prompt.${NC}"
    _confirm=Y
fi
if [[ ! "$_confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}[INFO] Aborted by user.${NC}"
    echo -e "${YELLOW}[INFO] Installed tools were left in place (run again and answer 'n' after a failure to roll those back, or remove them manually).${NC}"
    exit 0
fi

echo -e "\n${GREEN}[INFO] Configuring .zshrc...${NC}"

# Guarantee a .zshrc exists before backing it up (KEEP_ZSHRC=yes may mean OMZ
# did not create one on a machine that had no zshrc at all).
if [ ! -f "${ZSHRC}" ]; then
    [ -f "${OMZ_TEMPLATE}" ] || error "No ${ZSHRC} and no Oh My Zsh template at ${OMZ_TEMPLATE}."
    cp "${OMZ_TEMPLATE}" "${ZSHRC}" || error "Failed to create .zshrc from the Oh My Zsh template."
    own "${ZSHRC}"
fi

cp "${ZSHRC}" "${ZSHRC}.backup" || error "Failed to backup .zshrc."
ZSHRC_BACKED_UP=1
# From here on the file is going to be rewritten: flag it immediately so a
# failure in any later step restores the original instead of deleting it.
ZSHRC_MODIFIED=1

# ─── Asegura PATH temprano para binarios del usuario en ~/.local/bin ───
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

# ─── Plugins ───
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
# El patrón va anclado a inicio de línea (^) con /m. Sin el ancla, la primera
# ocurrencia de "plugins=(...)" es el COMENTARIO de ejemplo de OMZ
# ("# Example format: plugins=(...)"): ahí se reemplazaba, dejando la lista sin
# comentar (se ejecutaba como comandos) y el plugins=(git) real intacto.
# El /g reescribe cualquier asignación duplicada para que solo quede una.
# Si un .zshrc heredado trae el comentario de ejemplo de OMZ con la lista de
# plugins sin comentar y el ')' suelto, se elimina esa región entera antes de
# reescribir, para que no quede código suelto fuera del bloque plugins=(...).
if grep -qE '^# Example format: plugins=\($' "${ZSHRC}"; then
    echo -e "${YELLOW}[INFO] Cleaning up a leftover plugin example block in .zshrc...${NC}"
    perl -i -0777 -pe 's{^# Example format: plugins=\(\n(?:[^\n]*\n)*?^\)\n}{}m' "${ZSHRC}" \
        || error "Failed to clean the leftover plugin block in .zshrc."
fi

if grep -qE '^plugins=\(' "${ZSHRC}"; then
    perl -i -0777 -pe "s{^plugins=\([^)]*\)}{${DESIRED_PLUGINS}}gm" "${ZSHRC}" \
        || error "Failed to configure plugins in .zshrc."
    grep -q 'fast-syntax-highlighting' "${ZSHRC}" || error "Plugin block was not written to .zshrc."
else
    echo -e "${YELLOW}[WARN] No plugins=(...) assignment found, appending one.${NC}"
    printf '\n%s\n' "$DESIRED_PLUGINS" >> "${ZSHRC}"
fi

# ─── Autosuggestions visible en Kitty/P10k ───
# Los dos bloques siguientes (esta línea y zstyle/bindkey) se anclan en la línea
# de carga de OMZ, así que antes comprobamos que esa línea existe tal cual.
if ! grep -qE '^source \$ZSH/oh-my-zsh\.sh[[:space:]]*$' "${ZSHRC}"; then
    error "Oh My Zsh is not loaded: no 'source \$ZSH/oh-my-zsh.sh' line in ${ZSHRC}."
fi
# Va ANTES de source $ZSH/oh-my-zsh.sh: es la configuración del plugin.
if ! grep -q 'ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE' "${ZSHRC}"; then
    sed -i '/^source \$ZSH\/oh-my-zsh\.sh[[:space:]]*$/i ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#9e9e9e"' "${ZSHRC}"
fi

# ─── Completion menu select + arrow key navigation ───
# Note: compinit must NOT be called manually after oh-my-zsh.sh loads.
# OMZ handles it internally; a second call overwrites keybindings.
if ! grep -q "zstyle ':completion:" "${ZSHRC}"; then
    sed -i '/^source \$ZSH\/oh-my-zsh\.sh[[:space:]]*$/a zstyle '"'"':completion:*'"'"' menu select' "${ZSHRC}"
fi
if ! grep -q "bindkey '\^\[\[A'" "${ZSHRC}"; then
    sed -i "/zstyle ':completion:\*'/a bindkey '^[[A' history-search-backward\\nbindkey '^[[B' history-search-forward\\nbindkey '^[[Z' reverse-menu-complete" "${ZSHRC}"
fi

# ─── Powerlevel10k config ───
# ~/.p10k.zsh is created by the p10k wizard on first interactive start;
# source it when it exists so the chosen configuration persists.
if ! grep -q 'p10k\.zsh' "${ZSHRC}"; then
    cat >> "${ZSHRC}" <<'P10KEOF'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
P10KEOF
fi

if ! grep -Fq "# Sofi Zsh aliases" "${ZSHRC}"; then
    cat >> "${ZSHRC}" <<'ZSHRCEOF'

# Sofi Zsh aliases
alias cat="bat"
alias ls="lsd --group-dirs=first"
alias l="ls -l"
alias la="ls -a"
alias lla="ls -la"
alias lt="ls --tree"
alias commit="git add . && git commit"
alias fd="fdfind"

if command -v fzf >/dev/null 2>&1; then
  for _fzf_dir in /usr/share/doc/fzf/examples /usr/share/fzf; do
    [[ -f "$_fzf_dir/key-bindings.zsh" ]] && source "$_fzf_dir/key-bindings.zsh"
    [[ -f "$_fzf_dir/completion.zsh" ]] && source "$_fzf_dir/completion.zsh"
  done
  unset _fzf_dir
fi
ZSHRCEOF
fi

# ─── Verificación: nunca dar por buena una .zshrc que no parsea ───
echo -e "${GREEN}[INFO] Verifying .zshrc...${NC}"
if ! zsh -n "${ZSHRC}" 2>"${ZSHRC}.check"; then
    echo -e "${RED}[ERROR] .zshrc has syntax errors:${NC}"
    head -n 5 "${ZSHRC}.check"
    rm -f "${ZSHRC}.check"
    error ".zshrc failed the zsh syntax check."
fi
rm -f "${ZSHRC}.check"

grep -q '^ZSH_THEME="powerlevel10k/powerlevel10k"' "${ZSHRC}" || error "Theme line missing from .zshrc."
grep -q '^  zsh-autosuggestions$'                "${ZSHRC}" || error "zsh-autosuggestions missing from the plugin list."
grep -q '^  fast-syntax-highlighting$'           "${ZSHRC}" || error "fast-syntax-highlighting missing from the plugin list."

# Exactly one plugins=(...) block: leftovers from an older, broken run would
# make the last assignment win and silently drop our curated list.
N_PLUGIN_BLOCKS="$(grep -cE '^plugins=\(' "${ZSHRC}")"
if [ "$N_PLUGIN_BLOCKS" -ne 1 ]; then
    error "Expected exactly one plugins=(...) block in ${ZSHRC}, found ${N_PLUGIN_BLOCKS}."
fi

echo -e "\n${GREEN}[INFO] Installation complete! Restart your terminal or run 'zsh'.${NC}"
echo -e "${GREEN}[INFO] Your previous .zshrc was saved as ${ZSHRC}.backup${NC}"
echo -e "${GREEN}[INFO] On first start, Powerlevel10k will run 'p10k configure' (pick your font/style).${NC}"
echo -e "${GREEN}[INFO] Enjoy your supercharged terminal!${NC}"
