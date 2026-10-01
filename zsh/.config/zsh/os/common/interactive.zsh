# Shared interactive zsh settings go here.

HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase  # remove the older duplicate entry, keeping the most recent
setopt appendhistory
setopt incappendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
setopt auto_cd

if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"
else
    export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/.git/*" 2>/dev/null'
    export FZF_ALT_C_COMMAND='find . -type d -not -path "*/.git/*" 2>/dev/null'
    export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"
fi

# Root gets a "#" prompt character instead of "%". Starship has no root-aware
# character option and escapes zsh's %#, so derive a root copy of the config.
# The copy goes in a fresh mktemp dir under /tmp, not $XDG_CACHE_HOME or
# $TMPDIR: under sudo those can point at user-owned paths, letting a non-root
# user swap in a config (custom modules run commands) for root's prompt.
_starship_config="$XDG_CONFIG_HOME/starship.toml"
if (( EUID == 0 )) && [[ -r "$_starship_config" ]]; then
    if _starship_root_dir=$(mktemp -d /tmp/starship-root.XXXXXXXXXX); then
        sed 's/\[%\]/[#]/g' "$_starship_config" > "$_starship_root_dir/starship.toml" \
            && export STARSHIP_CONFIG="$_starship_root_dir/starship.toml"
        _starship_root_cleanup() { rm -rf -- "$_starship_root_dir" }
        autoload -Uz add-zsh-hook
        add-zsh-hook zshexit _starship_root_cleanup
    fi
fi
unset _starship_config

# ANSI escape codes for up/down arrows — used by zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
