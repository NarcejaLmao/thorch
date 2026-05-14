#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="${root}/packages/thorch-bsp/payload/usr/bin/thorch-hw-defaults"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

mkdir -p \
  "${tmp}/sys/devices/system/cpu/cpufreq" \
  "${tmp}/sys/devices/system/cpu/cpufreq/policy0" \
  "${tmp}/sys/devices/system/cpu/cpufreq/policy4"

printf '0\n' > "${tmp}/sys/devices/system/cpu/cpufreq/boost"
printf '0\n' > "${tmp}/sys/devices/system/cpu/cpufreq/policy0/boost"
printf '0\n' > "${tmp}/sys/devices/system/cpu/cpufreq/policy4/boost"

THORCH_HW_DEFAULTS_SYSFS_ROOT="${tmp}/sys" THORCH_CPU_BOOST=1 "${script}" apply

[[ "$(cat "${tmp}/sys/devices/system/cpu/cpufreq/boost")" == "1" ]] || fail "global boost was not enabled"
[[ "$(cat "${tmp}/sys/devices/system/cpu/cpufreq/policy0/boost")" == "1" ]] || fail "policy0 boost was not enabled"
[[ "$(cat "${tmp}/sys/devices/system/cpu/cpufreq/policy4/boost")" == "1" ]] || fail "policy4 boost was not enabled"

printf '0\n' > "${tmp}/sys/devices/system/cpu/cpufreq/boost"
printf '0\n' > "${tmp}/sys/devices/system/cpu/cpufreq/policy0/boost"
printf '0\n' > "${tmp}/sys/devices/system/cpu/cpufreq/policy4/boost"

THORCH_HW_DEFAULTS_SYSFS_ROOT="${tmp}/sys" THORCH_CPU_BOOST=0 "${script}" apply

[[ "$(cat "${tmp}/sys/devices/system/cpu/cpufreq/boost")" == "0" ]] || fail "global boost was not disabled"
[[ "$(cat "${tmp}/sys/devices/system/cpu/cpufreq/policy0/boost")" == "0" ]] || fail "policy0 boost was not disabled"
[[ "$(cat "${tmp}/sys/devices/system/cpu/cpufreq/policy4/boost")" == "0" ]] || fail "policy4 boost was not disabled"

printf '42\n' > "${tmp}/sys/devices/system/cpu/cpufreq/policy0/boost"
status_output="$(THORCH_HW_DEFAULTS_SYSFS_ROOT="${tmp}/sys" THORCH_CPU_BOOST=0 "${script}" status)"
grep -q 'policy0/boost=42' <<< "${status_output}" || fail "status did not report current runtime state"

printf 'ok\n'
