#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
session_name=$(echo "$input" | jq -r '.session_name // empty')

# Colors (using ANSI codes)
RED='\033[38;2;191;97;106m'
BLUE='\033[38;2;129;161;193m'
GRAY='\033[38;2;108;108;108m'
GREEN='\033[38;2;163;190;140m'
PURPLE='\033[38;2;180;142;173m'
CYAN='\033[38;2;136;192;208m'
PINK='\033[38;2;255;175;215m'
RESET='\033[0m'

output=""

# Session indicator + username@hostname
username=$(whoami)
hostname=$(hostname -s)
ssh_indicator=""
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ]; then
    ssh_indicator="󰣀 "
fi
output="${output}$(printf "${RED}${ssh_indicator}${username}@${hostname} ${RESET}")"

# Path
output="${output}$(printf "${BLUE}${cwd} ${RESET}")"

# AWS Profile and Region
if [ -n "$AWS_PROFILE" ]; then
    aws_region="${AWS_REGION:-}"
    aws_display=" ${AWS_PROFILE}"
    if [ -n "$aws_region" ]; then
        aws_display="${aws_display}@${aws_region}"
    fi
    output="${output}${aws_display}"
fi

# Git information (if in a git repository)
if git -c core.useBuiltinFSMonitor=false rev-parse --git-dir > /dev/null 2>&1; then
    output="${output}\n"
    
    # Get current branch
    branch=$(git -c core.useBuiltinFSMonitor=false symbolic-ref --short HEAD 2>/dev/null || git -c core.useBuiltinFSMonitor=false rev-parse --short HEAD 2>/dev/null)
    
    # Get upstream status
    upstream_icon=""
    if git -c core.useBuiltinFSMonitor=false rev-parse --abbrev-ref @{upstream} > /dev/null 2>&1; then
        ahead=$(git -c core.useBuiltinFSMonitor=false rev-list --count @{upstream}..HEAD 2>/dev/null || echo 0)
        behind=$(git -c core.useBuiltinFSMonitor=false rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
        
        if [ "$ahead" -gt 0 ]; then
            upstream_icon="$(printf "${CYAN}⇡ ${RESET}")"
        fi
        if [ "$behind" -gt 0 ]; then
            upstream_icon="${upstream_icon}$(printf "${CYAN}⇣ ${RESET}")"
        fi
    fi
    
    # Working and staging changes
    working=""
    staging=""
    
    # Count changes
    working_count=$(git -c core.useBuiltinFSMonitor=false status --porcelain 2>/dev/null | grep -c "^.[^ ]" || echo 0)
    staging_count=$(git -c core.useBuiltinFSMonitor=false status --porcelain 2>/dev/null | grep -c "^[^ ]" || echo 0)
    
    if [ "$working_count" -gt 0 ]; then
        working="$(printf "${PINK}*${RESET}") ${working_count}"
    fi
    
    if [ "$staging_count" -gt 0 ]; then
        if [ -n "$working" ]; then
            working="${working} |"
        fi
        staging=" 󰐕 ${staging_count}"
    fi
    
    # Stash count
    stash_count=$(git -c core.useBuiltinFSMonitor=false stash list 2>/dev/null | wc -l | tr -d ' ')
    stash_display=""
    if [ "$stash_count" -gt 0 ]; then
        stash_display=" 󰜦 ${stash_count}"
    fi
    
    git_info="$(printf "${GRAY}${upstream_icon}${branch}${working}${staging}${stash_display} ${RESET}")"
    output="${output}${git_info}"
fi

# Session name (Claude Code specific)
if [ -n "$session_name" ]; then
    output="${output}\n$(printf "${GREEN}󰭹 ${session_name} ${RESET}")"
fi

# Output the status line
echo -e "$output"
