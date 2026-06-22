# Dotfiles (GNU Stow)

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Packages

| Package     | Stow target | Notes |
| ----------- | ----------- | ----- |
| `1Password` | `~` | |
| `claude`    | `~` | |
| `curlrc`    | `~` | |
| `fonts`     | n/a | not stowed — managed by `fonts/fonts.sh`; installs Nerd Fonts to `~/Library/Fonts` (macOS) or `~/.fonts` (Linux) |
| `ghostty`   | `~` | themes via [dracula-pro-ghostty](https://github.com/charlief0x/dracula-pro-ghostty) submodule |
| `homebrew`  | `~` | `~/.Brewfile` for `brew bundle --global`; host Brewfiles in `homebrew/hosts/` (not stowed — used directly by `install.sh`) |
| `nvim`      | `~` | config via [charlief0x/nvim](https://github.com/charlief0x/nvim) submodule |
| `ssh`       | `~/.ssh` | private repo — see [Bootstrap](#bootstrap) |
| `starship`  | `~` | |
| `tmux`      | `~` | |
| `zsh`       | `~` | |

## Usage

```bash
./install.sh                   # apply all symlinks + install fonts (skips if up to date)
./install.sh --dry-run         # preview without changes
./install.sh --adopt           # pull existing ~/.config files into repo before linking
./install.sh --upgrade-fonts   # re-download all Nerd Fonts (e.g. after a new release)
fonts/fonts.sh                 # run font manager standalone
fonts/fonts.sh --upgrade       # force re-download of all fonts
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

After running `install.sh`, populate `~/.gitconfig.local` with your identity (the file is created automatically as an empty stub):

```ini
[user]
    name = Your Name
    email = you@example.com
```

`~/.config/curlrc.local` is also created as an empty stub for per-machine curl overrides.

## Secrets (macOS Keychain)

Tokens are stored in the macOS Keychain and injected at shell start via `~/.zshrc.local` (not tracked in this repo). This keeps plaintext secrets out of dotfiles entirely.

**Store a secret:**

```bash
security add-generic-password -s <service-name> -a "$USER" -w
# prompts for the password value
```

**`~/.zshrc.local` pattern:**

```zsh
export GITHUB_PERSONAL_ACCESS_TOKEN="$(security find-generic-password -s GITHUB_PERSONAL_ACCESS_TOKEN -a $USER -w 2>/dev/null)"
export SOURCEGRAPH_ACCESS_TOKEN="$(security find-generic-password -s SOURCEGRAPH_ACCESS_TOKEN -a $USER -w 2>/dev/null)"
export SOURCEGRAPH_ENDPOINT="https://fetch.sourcegraphcloud.com"
```

The `2>/dev/null` suppresses errors on machines where a given entry doesn't exist — the variable is just empty on those hosts.
