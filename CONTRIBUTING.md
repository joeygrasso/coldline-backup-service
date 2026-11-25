# Contributing to Coldline Backup Service

Thanks for your interest! Bug reports, design feedback, and pull requests are welcome.

## Ground rules
- Be kind; see the [Code of Conduct](CODE_OF_CONDUCT.md).
- For anything non-trivial, open an issue first to discuss the approach.
- Security issues: **do not** open a public issue; see [SECURITY.md](SECURITY.md).

## Development
Requirements: `bash` ≥ 4.4, [`shellcheck`](https://www.shellcheck.net/),
[`shfmt`](https://github.com/mvdan/sh), [`bats-core`](https://github.com/bats-core/bats-core).

```sh
make lint     # shellcheck + shfmt --diff
make fmt      # format in place
make test     # bats tests
```

## Shell style
- `#!/usr/bin/env bash` and `set -Eeuo pipefail` in executables.
- Quote expansions; prefer `[[ ]]`, `local`, `readonly`; no `eval` on user input.
- Functions in `lib/coldline/*.sh` are namespaced (`cl_<area>_<verb>`).
- Messages go to **stderr**; only requested output goes to stdout.
- Exit with `sysexits.h` codes (see `lib/coldline/common.sh`).
- 2-space indentation (`shfmt -i 2 -ci -bn`). CI enforces ShellCheck and shfmt.
- Every user-visible change: add/adjust a bats test and a `CHANGELOG.md` entry.

## Commits and pull requests
- Small, focused PRs with a clear description and test notes.
- Commit messages: imperative mood, concise subject (≤ 72 chars), body explains *why*.
- By contributing, you agree your contribution is licensed under the [MIT License](LICENSE).
