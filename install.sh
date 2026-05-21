#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

git submodule update --init --recursive nvim/.config/nvim zsh/.config/zsh/plugins tmux/.config/tmux/plugins ghostty/.config/ghostty/themes ssh

PACKAGES=(
  "1Password"
  "claude"
  "curlrc"
  "git"
  "ghostty"
  "nvim"
  "starship"
  "tmux"
  "zsh"
)

usage() {
  cat <<'EOF'
Usage: ./install.sh [--dry-run] [--adopt]

Options:
  --dry-run   Show what stow would do without making changes.
  --adopt     Adopt existing files into the stow tree before linking.
EOF
}

STOW_FLAGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
  --dry-run)
    STOW_FLAGS+=("--simulate" "--verbose=2")
    shift
    ;;
  --adopt)
    STOW_FLAGS+=("--adopt")
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown option: $1" >&2
    usage
    exit 1
    ;;
  esac
done

run_stow() {
  local target_args=("$@")
  if [[ ${#STOW_FLAGS[@]} -gt 0 ]]; then
    stow "${STOW_FLAGS[@]}" "${target_args[@]}"
  else
    stow "${target_args[@]}"
  fi
}

for pkg in "${PACKAGES[@]}"; do
  if [[ -d "$pkg" ]]; then
    run_stow "$pkg"
  fi
done

if [[ -d "ssh" ]]; then
  mkdir -p "$HOME/.ssh"
  mkdir -p "$HOME/.ssh/control"
  chmod 700 "$HOME/.ssh"
  run_stow --target="$HOME/.ssh" ssh
fi

# Brew bundle — stow the common Brewfile then run bundle for common + host-specific
if [[ -d "homebrew" ]]; then
  run_stow homebrew
  if [[ ${#STOW_FLAGS[@]} -eq 0 ]] && command -v brew >/dev/null 2>&1; then
    echo "Running brew bundle (common)..."
    brew bundle --global
    HOST_NAME="$(hostname -s 2>/dev/null || hostname)"
    HOST_BREWFILE="${DOTFILES_DIR}/homebrew/hosts/${HOST_NAME}/Brewfile"
    if [[ -f "$HOST_BREWFILE" ]]; then
      echo "Running brew bundle (${HOST_NAME})..."
      brew bundle --file="$HOST_BREWFILE"
    fi
  fi
fi
