# /etc/zprofile runs path_helper for login shells, which resets PATH and puts
# /usr/bin before Homebrew. Source OS-specific profile to restore correct order.
source_if_exists "${ZSH_CONFIG_DIR}/os/${OS_TYPE}/profile.zsh"
