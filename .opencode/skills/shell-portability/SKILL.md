---
name: shell-portability
description: Use when editing Bash or Zsh startup files, shared shell helpers, aliases, completion setup, or POSIX shell scripts.
---

# Shell Portability

Keep shared shell configuration safe across Bash, Zsh, Linux, macOS, WSL, and
non-interactive execution.

- Put POSIX-compatible helpers in shared files when possible.
- Keep Bash-only features such as `shopt`, `complete`, and `${BASH_*}` guarded
  or isolated from Zsh.
- Keep Zsh-only features such as `compdef`, arrays with Zsh semantics, and
  `setopt` guarded or isolated from Bash.
- Make startup files cheap and safe when sourced more than once.
- Avoid failing startup because an optional tool, completion script, or path is
  absent.
- Quote expansions unless intentional word splitting or globbing is required.
- Use `${VAR:-default}` for optional environment values and avoid overwriting
  values supplied by the user without a clear reason.

Validate with the native shell when available:

```sh
bash -n .bashrc .bash_aliases
zsh -n .zshrc
sh -n bin/dotfiles-sync
```
