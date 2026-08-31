# Sofi Zsh Installer Script

This script automates the installation and configuration of **Zsh**, **Oh My Zsh**, the **Powerlevel10k** theme, and popular plugins for Ubuntu systems, plus modern CLI tools and aliases.

---

## Prerequisites

The installer is designed for Debian/Ubuntu-based systems and expects a non-interactive root session through `sudo`.

```bash
sudo apt-get update
```

Before running the script, make sure you have:

- `sudo` access enabled for your user
- `curl` installed
- a shell that supports bash
- a valid terminal font for Powerlevel10k

> [!WARNING]
> The script enforces `sudo` at the beginning by checking `$EUID`. If the user is not root, it exits with a clear message and tells you to run it as:
>
> ```bash
> sudo ./sofi-zsh.sh
> ```

Install `curl` if it is missing:

```bash
sudo apt install curl
```

> [!IMPORTANT]
> **Font Installation Guide**
>
> 1. Download the font:
>    - [MesloLGS NF Regular.ttf](https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf)
>
> 2. Install the font:
>    - Open the `.ttf` file and click **Install**
>    - Set it as the terminal font in your terminal profile settings

---

## Installation

### One-line installation

```bash
curl -fsSL https://raw.githubusercontent.com/SofiDevO/sofi-zsh/main/sofi-zsh.sh -o sofi-zsh.sh && sudo bash sofi-zsh.sh && rm -f sofi-zsh.sh
```

This command downloads the installer, executes it with root privileges, and removes the temporary file after completion.

---

## What the script does

The installer performs a complete setup of a modern developer shell environment:

### Core Components
- **Zsh** as the default shell
- **Oh My Zsh** framework
- **Powerlevel10k** theme
- Essential plugins:
  - `zsh-autosuggestions`
  - `zsh-syntax-highlighting`
  - `fast-syntax-highlighting`
  - `zsh-autocomplete`

### Developer tooling
- **Bat**: `cat` alternative with syntax highlighting and line numbers
- **LSD**: modern replacement for `ls` with colors and tree output
- **fzf**: interactive fuzzy finder for files, command history and Git
- **ripgrep (`rg`)**: fast and precise recursive search tool
- **fd**: modern replacement for `find`
- **zoxide**: smart directory navigation based on usage history
- **lazygit**: terminal UI for Git workflows
- **delta**: improved Git diff viewer

### Shell aliases and config
The script appends a dedicated block at the end of `~/.zshrc` without overwriting the user’s existing configuration.

```bash
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
```

This approach preserves user customization while injecting the tools that make the terminal more powerful and productive.

---

## Version handling for BAT and LSD

One of the key improvements in the current version is that the installer does not ask the user to manually enter package names during the setup flow.

The script tries to detect the latest release directly from the GitHub Releases API:

```bash
curl -fsSL "https://api.github.com/repos/<owner>/<repo>/releases/latest"
```

If the query succeeds, it extracts the newest tag and builds the corresponding `.deb` filename automatically. If the API request fails or the tag format is unavailable, the script falls back to the known default package names already embedded in the script.

### Default fallback values
- BAT: `bat_0.25.0_amd64.deb`
- LSD: `lsd_1.1.5_amd64.deb`

This ensures the installer remains reliable in environments with restricted network access, rate limiting, or API failures while still preferring the latest stable version when available.

### Why this approach is safer
- avoids repeated manual input by the user
- reduces installation mistakes from mistyped version strings
- keeps the script resilient in CI-like environments and local setups
- guarantees a valid package URL when automatic detection is unavailable

---

## Automatic Configuration

The script configures the following automatically:

- `~/.zshrc` with Oh My Zsh and Powerlevel10k settings
- plugin loading for the selected Zsh extensions
- BAT configuration in `~/.bat.conf`
- LSD-friendly alias behavior and directory formatting
- zoxide initialization for smarter directory navigation
- fzf key bindings and completion for interactive shell workflows
- delta as the default git pager and diff viewer
- lazygit installation for terminal-based Git UX

---

## Error handling and rollback

The installer tracks every step with boolean state flags. If any step fails, the `error()` function:

1. Prints the exact failure reason in red
2. Calls `cleanup()` which undoes every completed step in reverse order:
   - restores `.zshrc` from backup if it was modified
   - removes installed binaries (`delta`, `lazygit`, `zoxide`)
   - uninstalls apt packages (`fzf`, `ripgrep`, `fd-find`, `lsd`, `bat`)
   - removes Oh My Zsh, plugins, and the Powerlevel10k theme
   - reverts the default shell back to `/bin/bash`
3. Exits with a non-zero code

This guarantees a clean system state after any partial failure, so the installer can be run again from scratch without manual cleanup.

---

## Post-Installation

After installation completes:

1. Restart your terminal or run `zsh`
2. Confirm that Powerlevel10k starts correctly
3. If prompted, complete the interactive configuration wizard
4. Use the aliases and enhanced CLI tools immediately

---

## Troubleshooting

### Script exits with a sudo message
This is intentional. The script checks the current user identity and stops if it is not running with privileges:

```bash
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script con sudo:"
  echo "sudo $0"
  exit 1
fi
```

Run it with:

```bash
sudo ./sofi-zsh.sh
```

### Package install fails
If BAT or LSD cannot be downloaded or installed, verify:

- your internet connection is active
- the package URL is valid for the selected release
- the fallback default version still matches the upstream asset naming convention

### zoxide not available after install
Open a new terminal session or run:

```bash
source ~/.zshrc
```

This reloads the configuration so the shell picks up the newly added initialization commands.

---

## What this installation gives you

This installer aims to produce a ready-to-use developer shell with the following stack:

- base: Zsh + Oh My Zsh + plugins
- terminal aesthetics: Powerlevel10k
- productivity: fzf + rg + fd + zoxide
- git UX: lazygit + delta

This combination is a practical and modern terminal setup for software development, fast searching, Git management, and a cleaner daily workflow.

---

## Support My Work

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
- Zsh plugin maintainers
