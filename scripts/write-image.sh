#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${script_dir}/lib/common.sh"

usage() {
  cat >&2 <<'EOF'
usage: scripts/write-image.sh [--yes] IMAGE DEVICE

Writes a Thorch raw image to a removable whole-disk block device.

This script does not mount or unmount anything. It refuses to run if DEVICE or
any child partition is mounted.
EOF
}

assume_yes=0
args=()
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --yes|-y)
      assume_yes=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

[[ "${#args[@]}" -eq 2 ]] || {
  usage
  exit 2
}

image="${args[0]}"
device="${args[1]}"

require_root
require_cmd blockdev dd findmnt lsblk stat sync

[[ -f "${image}" ]] || die "image not found: ${image}"
[[ -b "${device}" ]] || die "device is not a block device: ${device}"

device="$(readlink -f "${device}")"
image="$(readlink -f "${image}")"

type="$(lsblk -dnro TYPE "${device}")"
[[ "${type}" == "disk" ]] || die "${device} is not a whole disk"

rm_flag="$(lsblk -dnro RM "${device}")"
[[ "${rm_flag}" == "1" ]] || die "${device} is not marked removable"

ro_flag="$(lsblk -dnro RO "${device}")"
[[ "${ro_flag}" == "0" ]] || die "${device} is read-only"

mounted=()
while read -r node; do
  if findmnt --source "${node}" >/dev/null 2>&1; then
    targets="$(findmnt -nr -o TARGET --source "${node}" | paste -sd, -)"
    mounted+=("${node} mounted at ${targets}")
  fi
done < <(lsblk -nrpo NAME "${device}")

if [[ "${#mounted[@]}" -gt 0 ]]; then
  printf 'error: refusing to write while mounted:\n' >&2
  printf '  %s\n' "${mounted[@]}" >&2
  exit 1
fi

device_bytes="$(blockdev --getsize64 "${device}")"
image_bytes="$(stat -c '%s' "${image}")"
if (( device_bytes < image_bytes )); then
  die "${device} is too small for ${image}: device has ${device_bytes} bytes, image needs ${image_bytes} bytes"
fi

size="$(lsblk -dnro SIZE "${device}")"
model="$(lsblk -dnro MODEL "${device}" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
image_size="$(du -h "${image}" | awk '{print $1}')"

cat >&2 <<EOF
About to overwrite:
  device: ${device}
  model:  ${model:-unknown}
  size:   ${size}
  image:  ${image} (${image_size})
EOF

if [[ "${assume_yes}" -eq 0 ]]; then
  printf 'Type %s to continue: ' "${device}" >&2
  read -r confirmation
  [[ "${confirmation}" == "${device}" ]] || die "confirmation did not match"
fi

log "writing ${image} to ${device}"
dd if="${image}" of="${device}" bs=16M conv=fsync status=progress
sync
log "write complete"
