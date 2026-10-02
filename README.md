# Sofi Zsh Installer Script

This script automates the installation and configuration of **Zsh**, **Oh My Zsh**, the **Powerlevel10k** theme, and a curated set of plugins for Debian/Ubuntu-based systems, plus modern CLI tools and shell aliases.

The installer is fully **idempotent** — it can be run multiple times safely. Each step checks whether its target is already in place before acting.

---

## Prerequisites

- Debian/Ubuntu-based system (amd64)
- `sudo` access enabled for your user
- `curl` installed (`sudo apt install curl`)
- A terminal font compatible with Powerlevel10k

> [!WARNING]
> The script enforces `sudo` at startup by checking `$EUID`. If the user is not root, it re-runs itself with `sudo` automatically:
>
> ```bash
> sudo ./sofi-zsh.sh
> ```

> [!IMPORTANT]
> **Font Installation**
>
> Powerlevel10k requires a Nerd Font. Download and install before running the script:
> - [MesloLGS NF Regular.ttf](https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf)
>
> After installing the font, set it as the terminal font in your terminal profile settings.

---

## Installation

### One-line installation

```bash
curl -fsSL https://raw.githubusercontent.com/SofiDevO/sofi-zsh/main/sofi-zsh.sh -o sofi-zsh.sh && sudo bash sofi-zsh.sh && rm -f sofi-zsh.sh
```

This command downloads the installer, executes it with root privileges, and removes the temporary file after completion.

---

## What the script does

The installer performs a complete, idempotent setup of a modern developer shell environment. Each step is guarded: if the component already exists, it is skipped.

### Core components
- **Zsh** as the default shell
- **Oh My Zsh** framework
- **Powerlevel10k** theme
- Optimized plugins — conflict-free, ~1s startup time:
  - `git`, `sudo`, `command-not-found`, `colored-man-pages`
  - `jsontools`, `extract`, `bgnotify`, `copypath`
  - `gitignore`, `web-search`, `emoji`
  - `zsh-autosuggestions` + `fast-syntax-highlighting` (loaded last)

> [!NOTE]
> `zsh-syntax-highlighting` and `zsh-autocomplete` are intentionally excluded. They conflict with `fast-syntax-highlighting` and `zsh-autosuggestions` respectively by redefining the same ZLE widgets.

### Developer tooling
- **bat**: `cat` alternative with syntax highlighting and line numbers
- **lsd**: modern replacement for `ls` with colors and tree output
- **fzf**: interactive fuzzy finder for files, command history, and Git
- **ripgrep (`rg`)**: fast recursive search tool
- **fd**: modern replacement for `find`
- **lazygit**: terminal UI for Git workflows
- **delta**: improved Git diff viewer

### Shell configuration written to `~/.zshrc`

The script modifies `.zshrc` in multiple surgical steps — it never blindly appends or overwrites:

1. **PATH**: prepends `~/.local/bin` (user binaries)
2. **Theme**: sets or replaces `ZSH_THEME="powerlevel10k/powerlevel10k"`
3. **Plugin block**: replaces any existing `plugins=(...)` with the curated list using a line-anchored `perl` replace, so the commented example line in the stock Oh My Zsh template is never touched
4. **Autosuggestions color**: inserts `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#9e9e9e"` before `source $ZSH/oh-my-zsh.sh`
5. **Completion menu**: inserts `zstyle ':completion:*' menu select` after `source $ZSH/oh-my-zsh.sh`, followed by `bindkey` bindings for `↑`/`↓` history search and `Shift+Tab` reverse menu (Oh My Zsh runs `compinit` itself)
6. **Powerlevel10k**: appends `[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh`
7. **Aliases block**: appended once, guarded by `# Sofi Zsh aliases` marker

Before finishing, the script runs `zsh -n ~/.zshrc` plus assertions on the theme line, the plugin list, and the number of `plugins=(...)` blocks.

```bash
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
```

`delta` is configured as the git pager at install time (`git config --global`), so the shell does not run `git config` on every start.

---

## Idempotency

Every install step checks before acting. Running the script multiple times is safe — it skips what is already in place and only installs what is missing.

| Resource | Idempotency check | Action if present |
|---|---|---|
| zsh, git, curl | `dpkg -s` | skip |
| Default shell | `readlink -f` of `getent passwd` vs `command -v zsh` | skip |
| Oh My Zsh | `[ -d ~/.oh-my-zsh ]` | skip |
| zsh-autosuggestions | `[ -d .../plugin ]` | skip |
| fast-syntax-highlighting | `[ -d .../plugin ]` | skip |
| Powerlevel10k | `[ -d .../powerlevel10k ]` | skip |
| `~/.oh-my-zsh/custom` ownership | always | `chown -R` to the invoking user |
| bat | `command -v bat` | skip (prints installed version) |
| bat config | `grep style ~/.config/bat/config` | skip |
| lsd | `command -v lsd` | skip (prints installed version) |
| fzf / ripgrep / fd-find | `dpkg -s` per package | installs only missing ones |
| lazygit, delta | `command -v` | skip |
| delta as git pager | runs once at install | rewrites `git config --global` |
| PATH in .zshrc | `grep -q 'export PATH...'` | skip |
| ZSH_THEME in .zshrc | replaces existing value | replaces with `powerlevel10k` |
| plugins block in .zshrc | `perl` line-anchored replace | rewrites to desired state |
| Leftover example block | `grep '^# Example format: plugins=($'` | removes the region |
| `source $ZSH/oh-my-zsh.sh` | `grep` before inserting | aborts if missing |
| Autosuggestions color | `grep -q ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE` | skip |
| Completion config | `grep -q "zstyle ':completion:"` | skip |
| Arrow-key bindings | `grep -q "bindkey '^[[A'"` | skip |
| `~/.p10k.zsh` source line | `grep -q p10k.zsh` | skip |
| Aliases block | `grep -Fq "# Sofi Zsh aliases"` | skip |

### Post-write verification

These run at the end of every installation:

- `zsh -n ~/.zshrc` — the file must parse
- `ZSH_THEME` is `powerlevel10k/powerlevel10k`
- `zsh-autosuggestions` and `fast-syntax-highlighting` are present in the plugin list
- exactly one `plugins=(...)` block exists

Any failure triggers the rollback below.

---

## Version handling for bat and lsd

The script queries the GitHub Releases API to detect the latest version of `bat` and `lsd`:

```bash
curl -fsSL "https://api.github.com/repos/<owner>/<repo>/releases/latest"
```

The leading `v` is stripped from the tag, and the `.deb` download tries both the `v1.2.3` and `1.2.3` asset paths, since upstream projects differ in tag format. If the API is unavailable (rate limiting, no internet), it falls back to known stable defaults:

- bat: `bat_0.25.0_amd64.deb`
- lsd: `lsd_1.1.5_amd64.deb`

Downloads are written to `/tmp` and removed after installation.

---

## Error handling and rollback

Before modifying `.zshrc`, the script prompts:

```
[WARN] This will modify ~/.zshrc and may overwrite your current configuration.
[WARN] A backup will be saved as ~/.zshrc.backup
Do you want to continue? [Y/n]:
```

Pressing Enter defaults to `Y`. Typing `n` skips the `.zshrc` step and exits. On a non-interactive stdin (no TTY) the prompt is skipped and the step proceeds.

The installer tracks every completed step with boolean state flags (`INSTALLED_ZSH`, `INSTALLED_OMZ`, etc.). If any step fails, the `error()` function:

1. Prints the exact failure reason in red
2. Calls `cleanup()` which undoes every completed step in reverse order:
   - restores `.zshrc` from backup if it was modified
   - removes installed binaries (`delta`, `lazygit`)
   - uninstalls apt packages (`fzf`, `ripgrep`, `fd-find`, `lsd`, `bat`)
   - removes Oh My Zsh, plugins, and the Powerlevel10k theme
   - reverts the default shell back to `/bin/bash`
3. Exits with a non-zero code

On success the backup at `~/.zshrc.backup` is kept.

This guarantees a clean system state after any partial failure, so the installer can be run again from scratch without manual cleanup.

---

## Post-installation

After the script completes:

1. Restart your terminal or run `zsh`
2. Powerlevel10k runs `p10k configure` on first start — complete the interactive wizard (font, icons, prompt style)
3. The chosen configuration is saved to `~/.p10k.zsh` and loaded from `~/.zshrc`
4. All aliases and CLI tools are immediately available

---

## Troubleshooting

### Script exits with a sudo message
This is intentional. Run it with:

```bash
sudo ./sofi-zsh.sh
```

### bat or lsd cannot be downloaded
Verify:
- your internet connection is active
- the package URL is valid for the detected release
- the fallback default version still matches the upstream asset naming convention

### Completion menu (↓ navigation) not working
The script inserts `zstyle ':completion:*' menu select` and the `bindkey` history-search bindings into `.zshrc`. If these are missing, run the script again — it will detect and insert them.

---

## What this installation gives you

- **Base**: Zsh + Oh My Zsh + 13 conflict-free plugins
- **Terminal aesthetics**: Powerlevel10k
- **Productivity**: fzf + rg + fd
- **Git UX**: lazygit + delta

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
