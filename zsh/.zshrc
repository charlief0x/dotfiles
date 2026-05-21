# Prevent duplicate plugin hook registration when .zshrc is sourced repeatedly.
# To force a full reload: source ~/.zshrc (the guard is shell-local, not exported)
if [[ -n "${DOTFILES_ZSHRC_LOADED:-}" ]]; then
    return 0
fi
typeset +x DOTFILES_ZSHRC_LOADED=1

source_if_exists "${ZSH_CONFIG_DIR}/os/common/interactive.zsh"
source_if_exists "${ZSH_CONFIG_DIR}/os/${OS_TYPE}/interactive.zsh"
source_if_exists "${ZSH_CONFIG_DIR}/hosts/${HOST_NAME}/interactive.zsh"

# Functions harness — add dirs to fpath and autoload all files in each
_load_functions() {
    local dir="$1"
    [[ -d "$dir" ]] || return
    fpath=("$dir" $fpath)
    local -a funcs=("$dir"/*(N:t))
    (( ${#funcs} )) && autoload -Uz "${funcs[@]}"
}
_load_functions "${ZSH_CONFIG_DIR}/functions"
_load_functions "${ZSH_CONFIG_DIR}/os/${OS_TYPE}/functions"
_load_functions "${ZSH_CONFIG_DIR}/hosts/${HOST_NAME}/functions"
unfunction _load_functions

ZSH_PLUGIN_DIR="${ZSH_CONFIG_DIR}/plugins"
[[ -f "${ZSH_PLUGIN_DIR}/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "${ZSH_PLUGIN_DIR}/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -f "${ZSH_PLUGIN_DIR}/zsh-history-substring-search/zsh-history-substring-search.zsh" ]] && source "${ZSH_PLUGIN_DIR}/zsh-history-substring-search/zsh-history-substring-search.zsh"
[[ -f "${ZSH_PLUGIN_DIR}/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]] && source "${ZSH_PLUGIN_DIR}/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
if [[ -d "${ZSH_PLUGIN_DIR}/fzf/bin" ]]; then
    export PATH="${ZSH_PLUGIN_DIR}/fzf/bin:${PATH}"
fi
[[ -f "${ZSH_PLUGIN_DIR}/fzf/shell/completion.zsh" ]] && source "${ZSH_PLUGIN_DIR}/fzf/shell/completion.zsh"
[[ -f "${ZSH_PLUGIN_DIR}/fzf/shell/key-bindings.zsh" ]] && source "${ZSH_PLUGIN_DIR}/fzf/shell/key-bindings.zsh"
# fzf-tab must be sourced after compinit — loaded at the bottom

source_if_exists "${ZSH_CONFIG_DIR}/os/common/aliases.zsh"
source_if_exists "${ZSH_CONFIG_DIR}/os/${OS_TYPE}/aliases.zsh"
source_if_exists "${ZSH_CONFIG_DIR}/hosts/${HOST_NAME}/aliases.zsh"

eval "$(starship init zsh)"

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

autoload -Uz compinit && compinit -u
[[ -f "${ZSH_PLUGIN_DIR}/fzf-tab/fzf-tab.plugin.zsh" ]] && source "${ZSH_PLUGIN_DIR}/fzf-tab/fzf-tab.plugin.zsh"
