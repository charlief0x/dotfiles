export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export ZSH_CONFIG_DIR="${XDG_CONFIG_HOME}/zsh"

source_if_exists() {
  [[ -f "$1" ]] && source "$1"
}

# Keep PATH entries unique — prevents duplicates when .zshenv is re-sourced
typeset -U path PATH

add_to_path() {
  [[ -d "$1" ]] && path=("$1" $path)
}

source_if_exists "${ZSH_CONFIG_DIR}/os/detect.zsh"
source_if_exists "${ZSH_CONFIG_DIR}/os/common/env.zsh"
source_if_exists "${ZSH_CONFIG_DIR}/os/${OS_TYPE}/env.zsh"
source_if_exists "${ZSH_CONFIG_DIR}/os/common/paths.zsh"
source_if_exists "${ZSH_CONFIG_DIR}/os/${OS_TYPE}/paths.zsh"

export HOST_NAME="$(hostname -s 2>/dev/null || hostname)"
source_if_exists "${ZSH_CONFIG_DIR}/hosts/${HOST_NAME}/env.zsh"
source_if_exists "${ZSH_CONFIG_DIR}/hosts/${HOST_NAME}/paths.zsh"
source_if_exists "$HOME/.zshenv.local"
