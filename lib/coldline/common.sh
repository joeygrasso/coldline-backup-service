# shellcheck shell=bash
# Coldline Backup Service: shared helpers (logging, exit codes, errors).
# Sourced by bin/coldline; not executable on its own.

# sysexits.h exit codes. Part of the library API for commands; not all are used yet.
# shellcheck disable=SC2034
readonly CL_EX_OK=0
readonly CL_EX_USAGE=64
readonly CL_EX_DATAERR=65
readonly CL_EX_NOINPUT=66
readonly CL_EX_UNAVAILABLE=69
readonly CL_EX_SOFTWARE=70
readonly CL_EX_CANTCREAT=73
readonly CL_EX_IOERR=74
readonly CL_EX_TEMPFAIL=75
readonly CL_EX_NOPERM=77
readonly CL_EX_CONFIG=78

# Verbosity: 0 quiet, 1 normal, 2 verbose, 3 debug
CL_VERBOSITY="${CL_VERBOSITY:-1}"

_cl_color() {
  # Honor NO_COLOR (https://no-color.org) and only color terminals.
  [[ -z "${NO_COLOR:-}" && -t 2 ]]
}

# cl_log <level> <message...>   level: error|warn|info|verbose|debug
cl_log() {
  local level="$1"
  shift
  local min prefix color reset=""
  case "$level" in
    error) min=0 prefix="error" color=$'\e[31m' ;;
    warn) min=1 prefix="warning" color=$'\e[33m' ;;
    info) min=1 prefix="" color="" ;;
    verbose) min=2 prefix="" color="" ;;
    debug) min=3 prefix="debug" color=$'\e[2m' ;;
    *) min=1 prefix="$level" color="" ;;
  esac
  ((CL_VERBOSITY >= min)) || [[ "$level" == error ]] || return 0
  if _cl_color && [[ -n "$color" ]]; then reset=$'\e[0m'; else color=""; fi
  if [[ -n "$prefix" ]]; then
    printf '%scoldline: %s: %s%s\n' "$color" "$prefix" "$*" "$reset" >&2
  else
    printf 'coldline: %s\n' "$*" >&2
  fi
  # Under systemd, stderr already goes to the journal; elsewhere optionally mirror to syslog.
  if [[ "${CL_SYSLOG:-0}" == 1 ]] && command -v logger >/dev/null 2>&1; then
    logger -t coldline -p "user.${level/verbose/info}" -- "$*" 2>/dev/null || true
  fi
}

# cl_die <exit-code> <message...>
cl_die() {
  local code="$1"
  shift
  cl_log error "$*"
  exit "$code"
}

# cl_require_cmd <command...>: exit EX_UNAVAILABLE if a dependency is missing
cl_require_cmd() {
  local c
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || cl_die "$CL_EX_UNAVAILABLE" "required command not found: $c"
  done
}

# Report unexpected failures with location (set -E propagates the ERR trap).
cl_on_error() {
  local rc=$? line="${BASH_LINENO[0]}" src="${BASH_SOURCE[1]:-?}"
  cl_log error "unexpected failure (exit $rc) at ${src##*/}:${line}"
  exit "$CL_EX_SOFTWARE"
}
