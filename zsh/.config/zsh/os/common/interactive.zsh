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

# ANSI escape codes for up/down arrows — used by zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
