#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"
_START=$SECONDS

# ── Colors (disabled when not a TTY) ─────────────────────────────────────────
if [[ -t 1 ]]; then
  BOLD=$'\e[1m' DIM=$'\e[2m' RST=$'\e[0m'
  GRN=$'\e[32m' RED=$'\e[31m' YLW=$'\e[33m' CYN=$'\e[36m'
else
  BOLD='' DIM='' RST='' GRN='' RED='' YLW='' CYN=''
fi

# ── Spinner & output helpers ──────────────────────────────────────────────────
_SPID='' _SMSG=''
_LOG=$(mktemp)
trap '_spin_stop; rm -f "$_LOG"' EXIT

_spin_stop() {
  [[ -z "$_SPID" ]] && return
  kill "$_SPID" 2>/dev/null; wait "$_SPID" 2>/dev/null || true
  _SPID=''
}

_spin_start() {
  _SMSG="$1"
  printf "  ${DIM}·${RST} %s" "$_SMSG"
  (
    while :; do
      for f in '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏'; do
        printf "\r  ${CYN}%s${RST} %s\033[K" "$f" "$_SMSG"
        sleep 0.08
      done
    done
  ) &
  _SPID=$!
}

ok()   { _spin_stop; printf "\r  ${GRN}✓${RST} %s\033[K\n" "${1:-$_SMSG}"; }
skip() { _spin_stop; printf "\r  ${DIM}–${RST} %s\033[K\n" "${1:-$_SMSG}"; }
warn() { _spin_stop; printf "  ${YLW}!${RST} %s\n" "$1"; }
die()  {
  _spin_stop
  printf "\r  ${RED}✗${RST} %s\033[K\n" "${_SMSG:+$_SMSG — }${1}" >&2
  exit 1
}

# run: spinner + capture; dumps output on failure
run() {
  local msg="$1"; shift
  _spin_start "$msg"
  if "$@" >"$_LOG" 2>&1; then
    ok
  else
    local rc=$?; _spin_stop
    printf "\r  ${RED}✗${RST} %s\033[K\n" "$msg" >&2
    sed 's/^/    /' "$_LOG" >&2
    exit $rc
  fi
}

# ── Config ────────────────────────────────────────────────────────────────────
PACKAGES=(1Password claude curlrc ghostty nvim starship tmux zsh)
SSH_REPOS=(
  "personal:https://github.com/charlief0x/dotfiles-ssh.git"
  "work:https://github.com/charlief0x/dotfiles-ssh-work.git"
)
ENV_FILE="$HOME/.dotfiles-env"

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
${BOLD}Usage:${RST} ./install.sh [options]

${BOLD}Options:${RST}
  -e, --env <env>        Environment: personal or work (saved to ~/.dotfiles-env)
  -n, --dry-run          Preview stow changes without applying
  -f, --force            Delete conflicting files/symlinks, then link
  -a, --adopt [path...]  Adopt existing files before linking
  -h, --help             Show this help

${BOLD}Examples:${RST}
  ./install.sh --env personal
  ./install.sh --dry-run
  ./install.sh --force
  ./install.sh --adopt ~/.config/ghostty ~/.zshrc
  ./install.sh --adopt
EOF
}

# ── Option parsing ────────────────────────────────────────────────────────────
DRY_RUN=0 ADOPT=0 FORCE=0 ENV=''
ADOPT_PATHS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--env)
      [[ $# -ge 2 && "$2" != -* ]] || die "--env requires an argument (personal|work)"
      ENV="$2"; shift 2 ;;
    -n|--dry-run)
      DRY_RUN=1; shift ;;
    -f|--force)
      FORCE=1; shift ;;
    -a|--adopt)
      ADOPT=1; shift
      while [[ $# -gt 0 && "$1" != -* ]]; do
        ADOPT_PATHS+=("$1"); shift
      done ;;
    -h|--help)
      usage; exit 0 ;;
    --)
      shift; break ;;
    -*)
      die "unknown option: $1" ;;
    *)
      die "unexpected argument: $1" ;;
  esac
done

[[ $DRY_RUN -eq 1 && $ADOPT -eq 1 ]] && die "--dry-run and --adopt are mutually exclusive"
[[ $FORCE   -eq 1 && $ADOPT -eq 1 ]] && die "--force and --adopt are mutually exclusive"
[[ $FORCE   -eq 1 && $DRY_RUN -eq 1 ]] && die "--force and --dry-run are mutually exclusive"

# ── Resolve environment ───────────────────────────────────────────────────────
if [[ -n "$ENV" ]]; then
  [[ "$ENV" == personal || "$ENV" == work ]] || die "--env must be 'personal' or 'work'"
  printf '%s' "$ENV" > "$ENV_FILE"
elif [[ -f "$ENV_FILE" ]]; then
  ENV="$(cat "$ENV_FILE")"
else
  die "no environment set — run with --env personal or --env work"
fi

# ── Header ────────────────────────────────────────────────────────────────────
_tags="${DIM}${ENV}${RST}"
[[ $DRY_RUN -eq 1 ]] && _tags+="  ${DIM}dry-run${RST}"
[[ $FORCE   -eq 1 ]] && _tags+="  ${DIM}force${RST}"
[[ $ADOPT   -eq 1 ]] && _tags+="  ${DIM}adopt${RST}"
printf "\n  ${BOLD}dotfiles${RST}  %b\n\n" "$_tags"

# ── GitHub CLI ────────────────────────────────────────────────────────────────
if command -v gh >/dev/null 2>&1; then
  if ! gh auth status >/dev/null 2>&1; then
    warn "GitHub CLI not authenticated — launching gh auth login"
    gh auth login
  fi
  if ! git config --global --get-all credential.https://github.com.helper | grep -qs "gh auth git-credential"; then
    git config --global --add "credential.https://github.com.helper" ""
    git config --global --add "credential.https://github.com.helper" "!gh auth git-credential"
    git config --global --add "credential.https://gist.github.com.helper" ""
    git config --global --add "credential.https://gist.github.com.helper" "!gh auth git-credential"
  fi
fi

# ── Submodules ────────────────────────────────────────────────────────────────
_sync_submodules() {
  git submodule sync --recursive
  git submodule update --init --recursive \
    nvim/.config/nvim zsh/.config/zsh/plugins tmux/.config/tmux/plugins ghostty/.config/ghostty/themes
}
run "submodules" _sync_submodules

# ── Ensure stow is available ──────────────────────────────────────────────────
if ! command -v stow >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    run "installing stow" sudo apt-get install -y stow
  else
    die "stow is not installed — install it and re-run"
  fi
fi

# ── Reverse-map a ~/… path to its stow package ───────────────────────────────
find_package_for_path() {
  local target
  target="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
  local rel="${target#"$HOME/"}"
  for pkg in "${PACKAGES[@]}" homebrew; do
    [[ -e "${DOTFILES_DIR}/${pkg}/${rel}" ]] && { printf '%s' "$pkg"; return; }
  done
  die "no package found for '${target}'"
}

ADOPT_PACKAGES=()
if [[ $ADOPT -eq 1 && ${#ADOPT_PATHS[@]} -gt 0 ]]; then
  for path in "${ADOPT_PATHS[@]}"; do
    pkg="$(find_package_for_path "$path")"
    for existing in "${ADOPT_PACKAGES[@]+"${ADOPT_PACKAGES[@]}"}"; do
      [[ "$existing" == "$pkg" ]] && continue 2
    done
    ADOPT_PACKAGES+=("$pkg")
  done
fi

# ── run_stow: apply flags then delegate to stow ───────────────────────────────
run_stow() {
  local flags=()
  local pkg="${*: -1}"
  [[ "$pkg" == 1Password ]] && flags+=("--no-folding")
  if [[ $DRY_RUN -eq 1 ]]; then
    flags+=("--simulate" "--verbose=2")
  elif [[ $FORCE -eq 1 ]]; then
    # Adopt conflicting files into the package and override wrong symlinks,
    # then restore the repo's versions so our config wins.
    stow --adopt --override='.*' "${flags[@]+"${flags[@]}"}" "$@"
    git checkout -- "$pkg/"
    return
  elif [[ $ADOPT -eq 1 ]]; then
    local adopt=0
    if [[ ${#ADOPT_PACKAGES[@]} -eq 0 ]]; then
      adopt=1
    else
      for ap in "${ADOPT_PACKAGES[@]}"; do [[ "$ap" == "$pkg" ]] && adopt=1; done
    fi
    [[ $adopt -eq 1 ]] && flags+=("--adopt")
  fi
  stow "${flags[@]+"${flags[@]}"}" "$@"
}

# ── Dry-run: show stow output directly and exit ───────────────────────────────
if [[ $DRY_RUN -eq 1 ]]; then
  for pkg in "${PACKAGES[@]}"; do
    [[ -d "$pkg" ]] || continue
    printf "  ${BOLD}%s${RST}\n" "$pkg"
    run_stow "$pkg" 2>&1 | sed 's/^/    /'
  done
  if [[ -d "homebrew" ]]; then
    printf "  ${BOLD}homebrew${RST}\n"
    run_stow homebrew 2>&1 | sed 's/^/    /'
  fi
  printf "\n  ${DIM}dry-run complete${RST}\n\n"
  exit 0
fi

# ── Stow packages ─────────────────────────────────────────────────────────────
for pkg in "${PACKAGES[@]}"; do
  [[ -d "$pkg" ]] || continue
  if run_stow "$pkg" >"$_LOG" 2>&1; then
    ok "$pkg"
  else
    rc=$?
    printf "  ${RED}✗${RST} %s\n" "$pkg" >&2
    sed 's/^/    /' "$_LOG" >&2
    exit $rc
  fi
done

# ── git config stub ───────────────────────────────────────────────────────────
[[ -f "$HOME/.gitconfig.local" ]] || touch "$HOME/.gitconfig.local"

# ── SSH config ────────────────────────────────────────────────────────────────
SSH_REPO_URL=''
for entry in "${SSH_REPOS[@]}"; do
  [[ "${entry%%:*}" == "$ENV" ]] && { SSH_REPO_URL="${entry#*:}"; break; }
done

if [[ -n "$SSH_REPO_URL" ]]; then
  mkdir -p "$HOME/.ssh/control"
  chmod 700 "$HOME/.ssh"
  [[ -L "$HOME/.ssh/.git" ]] && rm -f "$HOME/.ssh/.git"
  # Derive SSH URL as a fallback (git@github.com:org/repo.git)
  _ssh_url() {
    echo "$1" | sed 's|https://github.com/|git@github.com:|'
  }
  if [[ -d "$HOME/.ssh/.git" ]]; then
    _pull_ssh() { GIT_TERMINAL_PROMPT=0 git -C "$HOME/.ssh" pull --ff-only; }
    run "SSH config" _pull_ssh
  else
    _clone_ssh() {
      local ssh_url; ssh_url="$(_ssh_url "$SSH_REPO_URL")"
      # Ensure github.com host key is in known_hosts so SSH doesn't prompt
      local kh="$HOME/.ssh/known_hosts"
      if ! ssh-keygen -F github.com -f "$kh" >/dev/null 2>&1; then
        ssh-keyscan -H github.com >> "$kh" 2>/dev/null
      fi
      local tmp
      for url in "$ssh_url" "$SSH_REPO_URL"; do
        tmp="$(mktemp -d)"
        if GIT_TERMINAL_PROMPT=0 git clone "$url" "$tmp"; then
          cp -rn "$tmp/." "$HOME/.ssh/"
          rm -rf "$tmp"
          return 0
        fi
        rm -rf "$tmp"
      done
      echo "Could not clone — ensure 'gh auth login' or a GitHub SSH key is configured" >&2
      return 1
    }
    run "SSH config ($ENV)" _clone_ssh
  fi
fi

# ── Homebrew ──────────────────────────────────────────────────────────────────
if [[ -d "homebrew" ]]; then
  if run_stow homebrew >"$_LOG" 2>&1; then
    ok "homebrew"
  else
    rc=$?
    printf "  ${RED}✗${RST} homebrew\n" >&2
    sed 's/^/    /' "$_LOG" >&2
    exit $rc
  fi
  if command -v brew >/dev/null 2>&1; then
    run "brew bundle (common)" brew bundle --global
    HOST_NAME="$(hostname -s 2>/dev/null || hostname)"
    HOST_BREWFILE="${DOTFILES_DIR}/homebrew/hosts/${HOST_NAME}/Brewfile"
    if [[ -f "$HOST_BREWFILE" ]]; then
      run "brew bundle ($HOST_NAME)" brew bundle --file="$HOST_BREWFILE"
    fi
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────
printf "\n  ${DIM}done in %ds${RST}\n\n" $(( SECONDS - _START ))
