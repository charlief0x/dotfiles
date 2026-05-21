add_to_path "/snap/bin"
add_to_path "/var/lib/flatpak/exports/bin"
add_to_path "/usr/local/bin"
add_to_path "/usr/local/sbin"

# WSL-specific Windows tool paths
WIN_VSCODE_BIN="/mnt/c/Users/${USER}/AppData/Local/Programs/Microsoft VS Code/bin"
add_to_path "$WIN_VSCODE_BIN"
