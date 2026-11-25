#!/usr/bin/env bats
# CLI basics: help, version, exit codes (sysexits).

setup() {
  COLDLINE="$BATS_TEST_DIRNAME/../bin/coldline"
}

@test "--help prints usage and exits 0" {
  run "$COLDLINE" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: coldline"* ]]
}

@test "--version prints a version" {
  run "$COLDLINE" --version
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^coldline\ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "no command is a usage error (64)" {
  run "$COLDLINE"
  [ "$status" -eq 64 ]
}

@test "unknown command is a usage error (64)" {
  run "$COLDLINE" frobnicate
  [ "$status" -eq 64 ]
  [[ "$output" == *"unknown command: frobnicate"* ]]
}

@test "unknown option is a usage error (64)" {
  run "$COLDLINE" --nope
  [ "$status" -eq 64 ]
}

@test "--config requires an argument (64)" {
  run "$COLDLINE" --config
  [ "$status" -eq 64 ]
}

@test "planned commands report unavailable (69)" {
  run "$COLDLINE" run example
  [ "$status" -eq 69 ]
  [[ "$output" == *"not implemented yet"* ]]
}

@test "NO_COLOR output has no escape codes" {
  NO_COLOR=1 run "$COLDLINE" frobnicate
  [[ "$output" != *$'\e['* ]]
}

@test "make install honors DESTDIR and PREFIX" {
  tmp="$(mktemp -d)"
  run make -C "$BATS_TEST_DIRNAME/.." install DESTDIR="$tmp" PREFIX=/usr
  [ "$status" -eq 0 ]
  [ -x "$tmp/usr/bin/coldline" ]
  [ -f "$tmp/usr/lib/coldline/common.sh" ]
  [ -f "$tmp/usr/share/man/man1/coldline.1" ]
  run env -u COLDLINE_LIBDIR "$tmp/usr/bin/coldline" --version
  # installed binary points at /usr/lib/coldline, which isn't there; it falls back
  # to the relative path inside DESTDIR, so it still works
  [ "$status" -eq 0 ]
  rm -rf "$tmp"
}
