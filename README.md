# Coldline Backup Service

[![CI](https://github.com/joeygrasso/coldline-backup-service/actions/workflows/ci.yml/badge.svg)](https://github.com/joeygrasso/coldline-backup-service/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Coldline** is a small, dependable backup tool written in Bash. One package is
installed on every machine; each host acts as a **source** (sends backups), a
**destination** (receives and retains them), or both, using the same `coldline`
command. What gets backed up, where it goes, and how long it's kept are declared
in a YAML configuration file as a list of **backup targets**.

```
coldline <command> [options]
```

> **Status: early design.** The CLI skeleton, packaging, and conventions are in
> place; the `backup_target` schema and the backup/restore engine are being
> designed. See [docs/design.md](docs/design.md). Feedback welcome.

## Principles
- **Boring and inspectable.** Plain Bash and standard tools (`ssh`, `rsync`,
  `tar`, coreutils). No daemons you can't read in an afternoon.
- **One tool, two roles.** Sources and destinations run the same code; behavior is
  chosen by configuration and command.
- **Behaves like a Linux system tool.** FHS paths, systemd units, journald/syslog
  logging, `sysexits` exit codes, man page, `make install` with `PREFIX`/`DESTDIR`.
- **Secure by default.** Least privilege, no secrets in configuration files,
  SSH-based transport with restricted keys.
- **Restores are the product.** Every backup must be verifiable and restorable.

## Installing (from source)
```sh
make test                         # optional: lint + tests
sudo make install                 # PREFIX=/usr/local by default
sudo make install PREFIX=/usr     # distro-style
make install DESTDIR=./pkgroot PREFIX=/usr   # for packagers
```

| Installed path | Purpose |
|---|---|
| `$PREFIX/bin/coldline` | CLI |
| `$PREFIX/lib/coldline/` | Shell libraries |
| `$PREFIX/share/man/man1/coldline.1` | Man page |
| `/etc/coldline/coldline.yaml` | Configuration (`/etc/coldline/conf.d/*.yaml` drop-ins) |
| `/var/lib/coldline/` | State |
| `/run/coldline/` | Runtime (locks) |
| journald / syslog | Logs (tag `coldline`) |

## Requirements
- Bash ≥ 4.4, GNU coreutils
- `ssh`, `rsync` (transport, planned)
- A YAML parser: [`yq`](https://github.com/mikefarah/yq) v4 (planned; see design)

## Contributing
Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and the
[Code of Conduct](CODE_OF_CONDUCT.md). Report security issues privately per
[SECURITY.md](SECURITY.md).

## License
[MIT](LICENSE)
