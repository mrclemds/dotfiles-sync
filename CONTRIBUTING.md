# Contributing

## Before You Start

Open an issue before significant work so the proposed change can be discussed.
Do not report vulnerabilities in an issue; follow [SECURITY.md](SECURITY.md).

## Development

- Keep updater code POSIX shell unless a platform-specific requirement is
  explicitly documented.
- Never add credentials, private keys, tokens, or machine-local state.
- Preserve the staged update lifecycle and rollback guarantees.
- Use Conventional Commit subjects: `type(optional-scope): short imperative description`.
- Implement changes on `main` first. Use `Backport-To: release/vMAJOR[.MINOR]`
  only for compatible maintenance fixes that have already reached `main`.

Run the checks before opening a pull request:

```sh
sh -n bin/dotfiles-sync tests/test_dotfiles_sync.sh
shellcheck bin/dotfiles-sync tests/test_dotfiles_sync.sh
sh tests/test_dotfiles_sync.sh
```

## Pull Requests

Open pull requests against `main` unless the change is an approved maintenance
fix for a `release/*` branch. Keep each pull request focused, describe user
visible behavior and validation, and resolve every review conversation.

`main` and `release/*` require a passing CI run and one approving review before
merge. Maintainers release only commits that have merged through those protected
branches.
