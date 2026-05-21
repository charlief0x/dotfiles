# Zsh Modular Layout

Load order is managed by `~/.zshenv` and `~/.zshrc`:

1. `os/common/*`
2. `os/$OS_TYPE/*`
3. `hosts/$HOST_NAME/*`
4. `~/.zshenv.local` / `~/.zshrc.local`

`$OS_TYPE` is auto-detected as `macos`, `linux`, `wsl`, or `unknown`.

Use:

- `env.zsh` and `paths.zsh` for environment and path changes
- `interactive.zsh` for prompt/keybind/alias behavior
- `plugins/` for zsh plugin checkouts (backed by git submodules in this repo)
