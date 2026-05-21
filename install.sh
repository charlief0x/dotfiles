#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# Authenticate gh CLI and configure it as the git credential helper before
# cloning submodules, so HTTPS remotes work on fresh machines without SSH keys.
# We write the credential helper to .gitconfig.local (not via gh auth setup-git,
# which hardcodes the absolute path to gh and pollutes the tracked .gitconfig).
if command -v gh >/dev/null 2>&1; then
  if ! gh auth status >/dev/null 2>&1; then
    echo "GitHub CLI is not authenticated. Running gh auth login..."
    gh auth login
  fi
  GITCONFIG_LOCAL="$HOME/.gitconfig.local"
  if ! grep -qs "gh auth git-credential" "$GITCONFIG_LOCAL" 2>/dev/null; then
    git config --file "$GITCONFIG_LOCAL" --add "credential.https://github.com.helper" ""
    git config --file "$GITCONFIG_LOCAL" --add "credential.https://github.com.helper" "!gh auth git-credential"
    git config --file "$GITCONFIG_LOCAL" --add "credential.https://gist.github.com.helper" ""
    git config --file "$GITCONFIG_LOCAL" --add "credential.https://gist.github.com.helper" "!gh auth git-credential"
  fi
fi

git submodule sync --recursive
git submodule update --init --recursive nvim/.config/nvim zsh/.config/zsh/plugins tmux/.config/tmux/plugins ghostty/.config/ghostty/themes ssh

# Ensure stow is available
if ! command -v stow >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    echo "Installing stow via apt..."
    sudo apt-get install -y stow
  else
    echo "Error: stow is not installed. Please install it and re-run." >&2
    exit 1
  fi
fi

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
Usage: ./install.sh [--dry-run] [--adopt [<path>...]]

Options:
  --dry-run          Show what stow would do without making changes.
  --adopt [<path>…]  Adopt existing files before linking. Paths are files or
                     directories under ~ or ~/.config (e.g. ~/.config/ghostty,
                     ~/.zshrc). If no paths are given, all packages are adopted.

Examples:
  ./install.sh
  ./install.sh --dry-run
  ./install.sh --adopt ~/.config/ghostty ~/.zshrc
  ./install.sh --adopt
EOF
}

DRY_RUN=0
ADOPT=0
ADOPT_PATHS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
  --dry-run)
    DRY_RUN=1
    shift
    ;;
  --adopt)
    ADOPT=1
    shift
    # Collect any following non-flag arguments as paths
    while [[ $# -gt 0 && "$1" != --* ]]; do
      ADOPT_PATHS+=("$1")
      shift
    done
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

if [[ $DRY_RUN -eq 1 && $ADOPT -eq 1 ]]; then
  echo "Error: --dry-run and --adopt are mutually exclusive." >&2
  exit 1
fi

# Reverse-map a ~ path to the stow package that owns it.
# Strips $HOME/ prefix, then finds which package dir contains that relative path.
find_package_for_path() {
  local target_path="$1"
  # Normalise to absolute path
  target_path="$(cd "$(dirname "$target_path")" && pwd)/$(basename "$target_path")"
  local rel="${target_path#"$HOME/"}"
  for pkg in "${PACKAGES[@]}" ssh homebrew; do
    if [[ -e "${DOTFILES_DIR}/${pkg}/${rel}" ]]; then
      echo "$pkg"
      return 0
    fi
  done
  echo "Error: no package found for '${target_path}'" >&2
  return 1
}

# Build set of packages to adopt (empty = all)
ADOPT_PACKAGES=()
if [[ $ADOPT -eq 1 && ${#ADOPT_PATHS[@]} -gt 0 ]]; then
  for path in "${ADOPT_PATHS[@]}"; do
    pkg="$(find_package_for_path "$path")"
    # Avoid duplicates
    for existing in "${ADOPT_PACKAGES[@]+"${ADOPT_PACKAGES[@]}"}"; do
      [[ "$existing" == "$pkg" ]] && continue 2
    done
    ADOPT_PACKAGES+=("$pkg")
  done
fi

run_stow() {
  local extra_flags=()
  local pkg="${@: -1}"  # last argument is the package

  if [[ $DRY_RUN -eq 1 ]]; then
    extra_flags+=("--simulate" "--verbose=2")
  elif [[ $ADOPT -eq 1 ]]; then
    # Adopt if no specific paths given, or if this package is in the adopt list
    if [[ ${#ADOPT_PACKAGES[@]} -eq 0 ]]; then
      extra_flags+=("--adopt")
    else
      for adopt_pkg in "${ADOPT_PACKAGES[@]}"; do
        if [[ "$adopt_pkg" == "$pkg" ]]; then
          extra_flags+=("--adopt")
          break
        fi
      done
    fi
  fi

  if [[ ${#extra_flags[@]} -gt 0 ]]; then
    stow "${extra_flags[@]}" "$@"
  else
    stow "$@"
  fi
}

for pkg in "${PACKAGES[@]}"; do
  if [[ -d "$pkg" ]]; then
    run_stow "$pkg"
  fi
done

# Create local override stubs if they don't exist
[[ -f "$HOME/.gitconfig.local" ]] || touch "$HOME/.gitconfig.local"
[[ -f "$HOME/.config/curlrc.local" ]] || touch "$HOME/.config/curlrc.local"

if [[ -d "ssh" ]]; then
  mkdir -p "$HOME/.ssh"
  mkdir -p "$HOME/.ssh/control"
  chmod 700 "$HOME/.ssh"
  run_stow --target="$HOME/.ssh" ssh
fi

# Brew bundle — stow the common Brewfile then run bundle for common + host-specific
if [[ -d "homebrew" ]]; then
  run_stow homebrew
  if [[ $DRY_RUN -eq 0 ]] && command -v brew >/dev/null 2>&1; then
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
