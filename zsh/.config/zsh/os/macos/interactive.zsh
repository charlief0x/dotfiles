# macOS-specific interactive zsh settings go here.

# Ghostty sets TERM=xterm-ghostty which breaks ZLE width in sudo/child shells
[[ "$TERM" == "xterm-ghostty" && -n "$SUDO_USER" ]] && export TERM=xterm-256color

[[ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]] && . "$(brew --prefix)/etc/profile.d/bash_completion.sh"

fpath=($(brew --prefix)/share/zsh/site-functions $fpath)

# Root shells (sudo -s) see user-owned Homebrew completions as "insecure"; Homebrew's
# _google_cloud_sdk/_bun call a bare compinit, which prompts. Run compinit -u early so
# compdef exists and they skip it.
(( EUID == 0 )) && autoload -Uz compinit && compinit -u
