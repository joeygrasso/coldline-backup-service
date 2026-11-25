# Design

> Living document. Sections marked **TBD** are open for discussion.

## Model
- **Source**: a host with data to protect. Runs `coldline` on a schedule
  (systemd timer) to produce and send backups.
- **Destination**: a host that stores backups and enforces retention.
- A host can be both. The same package and configuration format are used everywhere.
- **backup_target**: one unit of "back this up, send it there, keep it this long".
  Schema: **TBD** (next design step).

## Backup strategy
Incremental-forever, snapshot-based:
- **First run** transfers everything; **later runs transfer only changes** (rsync's
  quick check on size + mtime, then delta transfer within changed files).
- Targets declare only **stateful** data (explicit paths + excludes). Anything that can
  be regenerated, redeployed or holds no state is out of scope by design.
- Databases and other live state are captured by a **pre-hook** that produces a
  consistent dump file (e.g. `pg_dump`), which is then backed up like any other file.
- **Compression in transit:** `rsync --compress-choice=zstd` (falls back to `-z` on
  older rsync).
- Each successful run produces an **immutable, complete snapshot** on the destination.
  Restore = copy files back; no incremental chain to replay.
- **Retention** per target (e.g. `daily: 7, weekly: 4, monthly: 6`), pruned by the
  destination.

### Snapshot backends (auto-detected on the destination)
| Backend | When | Space sharing | Compression at rest | Integrity |
|---|---|---|---|---|
| `btrfs` (preferred) | destination dir is on btrfs | block-level (subvolume snapshots) | filesystem (`compress=zstd`) | per-block checksums; scrub/self-heal with RAID1 |
| `link-dest` (portable) | any POSIX filesystem | file-level (hard links, `rsync --link-dest`) | none (filesystem-dependent) | snapshot manifest + `coldline verify` |

Flow on the destination: rsync into a per-target writable *staging* tree → on
success, create a read-only snapshot (`btrfs subvolume snapshot -r`, or a hard-linked
copy) named by UTC timestamp → apply retention. A failed or interrupted transfer
never produces a snapshot.

## Transport (proposed)
SSH from source to destination, authenticated with a dedicated key that the
destination restricts with a forced command (`command="coldline receive ...",restrict`
in `authorized_keys`). That way no long-running daemon or open port is needed, and
a compromised source can only write backups, not read or delete others.

## Linux conventions
| Concern | Convention |
|---|---|
| Paths | FHS: `/usr/bin`, `/usr/lib/coldline`, `/etc/coldline`, `/var/lib/coldline`, `/run/coldline` |
| Config | `/etc/coldline/coldline.yaml` + `conf.d/*.yaml` (lexical order); `COLDLINE_CONFIG` / `--config` override |
| Scheduling | systemd timers (`coldline@<target>.timer`); cron-compatible fallback |
| Logging | stderr for interactive use; journald (`SyslogIdentifier=coldline`) or `logger -t coldline` under services |
| Exit codes | `sysexits.h` (64 usage, 65 data, 66 no input, 69 unavailable, 70 software, 73 can't create, 74 I/O, 75 temp fail, 77 no perm, 78 config) |
| Locking | `flock` on `/run/coldline/<target>.lock` |
| Privileges | Run as a dedicated `coldline` user where possible; root only for targets that need it |
| Secrets | Never in config. Referenced via files with strict permissions (e.g. `/etc/coldline/secrets/`) or systemd credentials |
| Non-root use | XDG paths (`$XDG_CONFIG_HOME/coldline`, `$XDG_STATE_HOME/coldline`) |

## Open questions (TBD)
- `backup_target` fields: identity, source spec (paths / command / database dump), schedule, retention, destination, hooks, encryption
- YAML parsing: `yq` v4 dependency vs. a restricted subset parsed in pure Bash
- Encryption at rest (e.g. `age`) and key management
- Integrity verification and restore testing
