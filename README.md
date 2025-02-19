# Sofi Zsh Installer Script 🦝

This script automates the installation and configuration of **Zsh**, **Oh My Zsh**, the **Powerlevel10k** theme, and popular plugins for Ubuntu systems, plus modern CLI tools and aliases.

---

## Prerequisites

Before running the scripts, make sure you're using a **Debian-based** distribution (such as Ubuntu) and have:

- **Root/sudo privileges**
- **Node.js and npm** (for gitmoji installation)
- **MesloLGS NF Font** (for proper icon display)

> [!IMPORTANT]
> **Font Installation Guide**

1. Download the font:
   - [MesloLGS NF Regular.ttf](https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf)

2. Install the font:
   - Open the `.ttf` file and click **Install**
   - Set as terminal font in preferences

---

## Installation

### One-line Installation:

```bash
curl -fsSL https://raw.githubusercontent.com/SofiDevO/sofi-zsh/main/sofi-zsh.sh -o sofi-zsh.sh && bash sofi-zsh.sh && rm -f sofi-zsh.sh
```

## Features Overview

### Core Components
- **Zsh** with **Oh My Zsh** framework
- **Powerlevel10k** theme with interactive configuration
- Essential plugins:
  - `zsh-autosuggestions`
  - `zsh-syntax-highlighting`
  - `fast-syntax-highlighting`
  - `zsh-autocomplete`

### Enhanced CLI Tools
- **Bat** (cat clone with syntax highlighting)
- **LSD** (modern ls replacement)
- **Gitmoji** (emoji-based commit system)

### Smart Aliases
```bash
alias cat="bat"
alias ls="lsd --group-dirs=first"
alias l="ls -l --group-dirs=first"
alias la="ls -a --group-dirs=first"
alias lla="ls -la --group-dirs=first"
alias lt="ls --tree --group-dirs=first"
alias commit="gitmoji -i && git add . && git commit"
```

---

## Custom Installation Options

### Version Selection
During installation, you can specify versions for:
- **Bat**: [Releases](https://github.com/sharkdp/bat/releases)
- **LSD**: [Releases](https://github.com/lsd-rs/lsd/releases)

Example format: `bat_0.25.0_amd64.deb` or `lsd_1.1.5_amd64.deb`

### Automatic Configuration
- Bat themes and settings in `~/.bat.conf`
- LSD directory sorting preferences
- Gitmoji interactive commit workflow

---

## Post-Installation
After installation completes:
1. Restart your terminal
2. Run `zsh` to start configuration wizard
3. Customize Powerlevel10k prompts interactively

---

## Support My Work 💜

If you enjoy using this toolkit, consider supporting its development:

<p align="center">
  <a href="https://github.com/sponsors/SofiDevO" target="_blank">
    <img src="https://img.shields.io/badge/Sponsor%20me%20on%20GitHub-30363D?style=for-the-badge&logo=github-sponsors&logoColor=#EA4AAA" alt="GitHub Sponsors">
  </a>
  <a href="https://ko-fi.com/sofidev" target="_blank">
    <img src="https://img.shields.io/badge/Buy%20me%20a%20coffee-Ko--fi-ff5e5b?style=for-the-badge&logo=ko-fi&logoColor=white" alt="Ko-fi">
  </a>
</p>

---

## Contribution

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a PR with detailed description

---

## Credits
Special thanks to:
- Oh My Zsh & Powerlevel10k teams
- Bat (sharkdp) & LSD (lsd-rs) developers
- Gitmoji contributors
- Zsh plugin maintainers
