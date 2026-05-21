# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Deploying symlinks

```bash
./install.sh            # apply all symlinks + brew bundle
./install.sh --dry-run  # preview without changes (skips brew bundle)
./install.sh --adopt    # pull existing ~/.config files into repo before linking
```

`install.sh` runs `gh auth login` + `gh auth setup-git` first (if `gh` is available and not already authenticated), then `git submodule update --init --recursive`, stows all packages, then runs `brew bundle --global` (common) and `brew bundle --file=homebrew/hosts/${HOST_NAME}/Brewfile` (host-specific) if brew is available. All submodules use HTTPS remotes; no SSH key is required.

The `ssh` package is stowed to `~/.ssh`; all other packages stow to `~`.

## Structure

Each top-level directory is a GNU Stow package. The directory tree inside a package mirrors the target path relative to `~`. For example, `starship/.config/starship.toml` becomes `~/.config/starship.toml`.

All config files are symlinks into this repo — edits to `~/.config/starship.toml` are edits to the file here.

Current packages: `1Password`, `claude`, `curlrc`, `git`, `ghostty`, `homebrew`, `nvim`, `ssh`, `starship`, `tmux`, `zsh`.

**Keep `README.md` in sync** — whenever a package is added, removed, or its stow target changes, update the packages table in `README.md`.

## Zsh config loading order

1. `.zshenv` — sets `$ZSH_CONFIG_DIR`, `$XDG_*`, path helpers, OS detection; sources `os/common/`, `os/${OS_TYPE}/`, and `hosts/${HOST_NAME}/` env + path files
2. `.zshrc` — interactive shell; thin orchestrator; guarded by `DOTFILES_ZSHRC_LOADED` (uses `typeset +x` so it is not exported to child shells)

`.zshrc` sources in this order:
- `os/common/`, `os/${OS_TYPE}/`, `hosts/${HOST_NAME}/` — `interactive.zsh`
- Functions harness — adds `functions/`, `os/${OS_TYPE}/functions/`, `hosts/${HOST_NAME}/functions/` to `fpath` and autoloads all files
- Plugins (zsh-autosuggestions, zsh-history-substring-search, fast-syntax-highlighting, fzf)
- `os/common/`, `os/${OS_TYPE}/`, `hosts/${HOST_NAME}/` — `aliases.zsh`
- starship init
- `compinit` + `fzf-tab` (must be after `compinit`)

Each layer type has its own file: `env.zsh`, `paths.zsh`, `interactive.zsh`, `aliases.zsh`, and a `functions/` directory.

Plugins live in `zsh/.config/zsh/plugins/` as git submodules. `fzf-tab` must be sourced **after** `compinit`.

## Homebrew

- `homebrew/.Brewfile` — common packages; stowed to `~/.Brewfile` and run via `brew bundle --global`
- `homebrew/hosts/${HOST_NAME}/Brewfile` — host-specific packages; run via `brew bundle --file=`

## Tmux config loading order

`tmux.conf` glob-sources `conf.d/*.conf` in numeric order:
- `00-core.conf` — prefix, terminal, hooks (SSH status pill via `client-attached` + `session-created`)
- `10-navigation.conf`
- `20-copy-paste.conf`
- `30-plugins.conf`
- `40-theme-dracula.conf` — Dracula Pro theme; sets `@pill_*` color aliases
- `50-misc.conf` — status-left/right bar layout
- `99-tpm.conf` — TPM bootstrap

**Important:** `set -g` (not `set -gF`) must be used for any `status-right`/`status-left` segment containing a runtime `#{?...}` conditional (e.g. the SSH pill). `-gF` evaluates format strings at load time and bakes in empty values.

## SSH status pill

`tmux/.config/tmux/scripts/ssh-status.sh` runs on `client-attached` and `session-created`. It reads `tmux showenv SSH_CLIENT` to set/unset `@ssh_active`, then calls `tmux refresh-client -S`. The status bar reads `#{?#{@ssh_active},...}`.

`ssh/config` sets `SetEnv TERM=xterm-256color` for all hosts to prevent `TERM=xterm-ghostty` from being forwarded into SSH sessions (which would trigger Ghostty shell integration a second time and break ZLE prompt width). `os/macos/interactive.zsh` also overrides `TERM` when `$SUDO_USER` is set, for the same reason in `sudo -s` shells.

## Known constraints

- Amazon Q shell integration must not be added — it injects unguarded ANSI into the prompt, causing ZLE width miscalculation in tmux.
- `zsh-autocomplete` was replaced with `fzf-tab` for the same reason.
- `DOTFILES_ZSHRC_LOADED` must remain unexported (`typeset +x`) to avoid suppressing `.zshrc` in SSH child shells.
