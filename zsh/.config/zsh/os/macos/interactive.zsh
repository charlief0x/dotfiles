# macOS-specific interactive zsh settings go here.

# Ghostty sets TERM=xterm-ghostty which breaks ZLE width in sudo/child shells
[[ "$TERM" == "xterm-ghostty" && -n "$SUDO_USER" ]] && export TERM=xterm-256color

[[ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]] && . "$(brew --prefix)/etc/profile.d/bash_completion.sh"

fpath=($(brew --prefix)/share/zsh/site-functions $fpath)
