#!/usr/bin/env bash
# Font manager — installs/upgrades Nerd Fonts from GitHub releases.
#
# Usage:
#   fonts.sh [--upgrade] [--dry-run]
#
# --upgrade  Re-download all fonts even if already installed
# --dry-run  Print what would be done without changing anything
set -euo pipefail

# ── Font list ─────────────────────────────────────────────────────────────────
# Format: "<NerdFonts release asset prefix>:<display name>"
# Asset names on https://github.com/ryanoasis/nerd-fonts/releases are
# "<prefix>.tar.xz" (e.g. FiraCode.tar.xz).
FONTS=(
  "FiraCode:FiraCode Nerd Font"
  "FiraMono:FiraMono Nerd Font"
  "ZedMono:ZedMono Nerd Font"
)

# ── Platform font directory ───────────────────────────────────────────────────
case "$(uname -s)" in
  Darwin)
    FONT_DIR="$HOME/Library/Fonts" ;;
  Linux)
    FONT_DIR="$HOME/.fonts" ;;
  *)
    echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

# ── Arg parsing ───────────────────────────────────────────────────────────────
UPGRADE=0
DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --upgrade)  UPGRADE=1; shift ;;
    --dry-run)  DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ── Color helpers (stdout only, disabled when not a TTY) ──────────────────────
if [[ -t 1 ]]; then
  GRN=$'\e[32m' YLW=$'\e[33m' DIM=$'\e[2m' RST=$'\e[0m'
else
  GRN='' YLW='' DIM='' RST=''
fi

_ok()   { printf "  ${GRN}✓${RST} %s\n" "$1"; }
_skip() { printf "  ${DIM}–${RST} %s\n" "$1"; }
_warn() { printf "  ${YLW}!${RST} %s\n" "$1"; }

# ── Fetch latest release tag from GitHub ──────────────────────────────────────
_latest_tag() {
  # Returns the latest release tag for nerd-fonts, e.g. "v3.4.0"
  curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" \
  | grep '"tag_name"' \
  | head -1 \
  | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/'
}

# ── Install one font ──────────────────────────────────────────────────────────
_install_font() {
  local prefix="$1" label="$2" tag="$3"
  local marker_dir="${FONT_DIR}/${prefix}NerdFont"
  local marker="${marker_dir}/.installed_version"

  # Already installed at this version?
  if [[ $UPGRADE -eq 0 && -f "$marker" && "$(cat "$marker")" == "$tag" ]]; then
    _skip "${label} (${tag}, up to date)"
    return
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    if [[ -f "$marker" ]]; then
      _warn "${label}: would upgrade $(cat "$marker") → ${tag}"
    else
      _warn "${label}: would install ${tag}"
    fi
    return
  fi

  local url="https://github.com/ryanoasis/nerd-fonts/releases/download/${tag}/${prefix}.tar.xz"
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  curl -fsSL --progress-bar "$url" -o "${tmp}/${prefix}.tar.xz"
  mkdir -p "$marker_dir"
  tar -xJf "${tmp}/${prefix}.tar.xz" -C "$marker_dir"
  printf '%s' "$tag" > "$marker"
  _ok "${label} (${tag})"
}

# ── Main ──────────────────────────────────────────────────────────────────────
printf "\n  Fetching latest Nerd Fonts release tag…\n"
TAG="$(_latest_tag)"
printf "  Release: %s\n\n" "$TAG"

mkdir -p "$FONT_DIR"

for entry in "${FONTS[@]}"; do
  prefix="${entry%%:*}"
  label="${entry#*:}"
  _install_font "$prefix" "$label" "$TAG"
done

# Refresh font cache on Linux
if [[ "$(uname -s)" == Linux ]] && command -v fc-cache >/dev/null 2>&1; then
  if [[ $DRY_RUN -eq 0 ]]; then
    fc-cache -f "$FONT_DIR"
    _ok "font cache refreshed"
  fi
fi

printf "\n"
