# Dotfiles (GNU Stow)

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Packages

| Package     | Stow target | Notes |
| ----------- | ----------- | ----- |
| `1Password` | `~` | |
| `claude`    | `~` | |
| `curlrc`    | `~` | |
| `git`       | `~` | global gitconfig + gitignore; identity in untracked `~/.gitconfig.local` |
| `ghostty`   | `~` | themes via [dracula-pro-ghostty](https://github.com/charlief0x/dracula-pro-ghostty) submodule |
| `homebrew`  | `~` | `~/.Brewfile` for `brew bundle --global`; host Brewfiles in `homebrew/hosts/` (not stowed — used directly by `install.sh`) |
| `nvim`      | `~` | config via [charlief0x/nvim](https://github.com/charlief0x/nvim) submodule |
| `ssh`       | `~/.ssh` | private repo — see [Bootstrap](#bootstrap) |
| `starship`  | `~` | |
| `tmux`      | `~` | |
| `zsh`       | `~` | |

## Usage

```bash
./install.sh            # apply all symlinks
./install.sh --dry-run  # preview without changes
./install.sh --adopt    # pull existing ~/.config files into repo before linking
```

`install.sh` initializes all git submodules before stowing and handles GitHub
authentication via the `gh` CLI.

## Bootstrap

On a fresh machine:

1. **Install `gh`** (GitHub CLI) — via brew or your package manager.

2. **Clone the dotfiles repo:**
   ```bash
   git clone https://github.com/charlief0x/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

3. **Run install** — it will prompt for `gh auth login` before cloning submodules:
   ```bash
   ./install.sh
   ```

All submodules use HTTPS remotes; `gh auth setup-git` configures the gh
credential helper so no SSH key is required.

After running `install.sh`, create `~/.gitconfig.local` with your identity:

```ini
[user]
    name = Your Name
    email = you@example.com
```
