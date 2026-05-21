# Dotfiles (GNU Stow)

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Packages

| Package     | Stow target | Notes |
| ----------- | ----------- | ----- |
| `1Password` | `~` | |
| `claude`    | `~` | |
| `curlrc`    | `~` | |
| `git`       | `~` | global gitconfig + gitignore |
| `ghostty`   | `~` | themes via [dracula-pro-ghostty](https://github.com/charlief0x/dracula-pro-ghostty) submodule |
| `homebrew`  | `~` | `~/.Brewfile` for `brew bundle --global`; host Brewfiles in `homebrew/hosts/` |
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

`install.sh` also initializes all git submodules before stowing.

## Bootstrap

On a fresh machine the `ssh` submodule is a private repo cloned via the
`github-personal` SSH alias. Because that alias is defined inside the `ssh`
submodule itself, you need to set it up manually first:

1. **Install 1Password** and enable the SSH agent  
   → Settings → Developer → Use the SSH agent  
   → Enable your personal GitHub SSH key

2. **Set `SSH_AUTH_SOCK`** in your shell (add to `~/.zshenv` or `~/.zprofile`):
   ```sh
   export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
   ```

3. **Add the `github-personal` SSH alias** to `~/.ssh/config`:
   ```sshconfig
   Host github-personal
       HostName github.com
       User git
       IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
       IdentitiesOnly yes
       IdentityFile ~/.ssh/<your-personal-key>.pub
       ControlMaster no
   ```

4. **Clone the dotfiles repo and run install:**
   ```bash
   git clone git@github-personal:charlief0x/dotfiles.git ~/code/personal/dotfiles
   cd ~/code/personal/dotfiles
   ./install.sh
   ```

The full SSH config (including all host aliases) will be symlinked into `~/.ssh/`
by `install.sh` after the submodule is cloned.
