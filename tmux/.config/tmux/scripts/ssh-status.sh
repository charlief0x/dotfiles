#!/bin/sh
SHOWENV=$(tmux showenv SSH_CLIENT 2>/dev/null)
if echo "$SHOWENV" | grep -qv '^-'; then
    tmux set -g @ssh_active 1
else
    tmux set -gu @ssh_active
fi
tmux refresh-client -S
