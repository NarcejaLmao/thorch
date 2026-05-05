#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dock_updater="${root}/packages/thorch-gaming-installers/payload/usr/bin/steamos-polkit-helpers/jupiter-dock-updater"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_rc() {
  local expected="$1" rc
  shift

  set +e
  "${dock_updater}" "$@" >/dev/null 2>&1
  rc="$?"
  set -e

  [[ "${rc}" -eq "${expected}" ]] || fail "jupiter-dock-updater $* expected rc ${expected}, got ${rc}"
}

assert_rc 7 --check
assert_rc 7 check
assert_rc 7 status
assert_rc 0 --update
assert_rc 0 update
assert_rc 0 apply
assert_rc 0
assert_rc 0 --help
assert_rc 0 unsupported-command

printf 'SteamOS compatibility stub tests passed\n'
