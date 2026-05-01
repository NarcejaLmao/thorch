#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${script_dir}/lib/common.sh"
load_thorch_config

usage() {
  cat >&2 <<'EOF'
usage: scripts/sync-rocknix-firmware.sh [--ref <commit-or-branch>] [--dest <dir>]

Downloads the public ROCKNIX SM8550/AYN Thor firmware files needed by Thorch into
vendor/rocknix-sm8550/firmware by default. Release builds should pass a full ROCKNIX
commit SHA through --ref or ROCKNIX_REF.
EOF
}

ref="${ROCKNIX_REF}"
dest="${THORCH_FIRMWARE_DIR}"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --ref)
      ref="${2:-}"
      [[ -n "${ref}" ]] || die "--ref requires a value"
      shift 2
      ;;
    --dest)
      dest="${2:-}"
      [[ -n "${dest}" ]] || die "--dest requires a value"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      die "unknown argument: $1"
      ;;
  esac
done

require_cmd curl install

root="$(repo_root)"
if [[ "${dest}" == /* ]]; then
  dest_abs="$(abspath "${dest}")"
else
  dest_abs="$(abspath "${root}/${dest}")"
fi
base_url="https://raw.githubusercontent.com/ROCKNIX/distribution/${ref}/projects/ROCKNIX/devices/SM8550/filesystem/usr/lib/kernel-overlays/base/lib/firmware"

required=(
  qcom/sm8550/ayn/cdsp.mbn
  qcom/sm8550/ayn/cdsp_dtb.mbn
  qcom/sm8550/ayn/thor/adsp.mbn
  qcom/sm8550/ayn/thor/adsp_dtb.mbn
  qcom/sm8550/ayn/thor/adspr.jsn
  qcom/sm8550/ayn/thor/adsps.jsn
  qcom/sm8550/ayn/thor/adspua.jsn
  qcom/sm8550/ayn/thor/aw883xx_acf.bin
  qcom/sm8550/ayn/thor/battmgr.jsn
)

optional=(
  ath12k/WCN7850/hw2.0/amss.bin
  ath12k/WCN7850/hw2.0/board-2.bin
  ath12k/WCN7850/hw2.0/m3.bin
  ath12k/WCN7850/hw2.0/regdb.bin
  qca/hmtbtfw20.tlv
  qcom/sm8550/a740_zap.mbn
  qcom/a740_sqe.fw
  qcom/gmu_gen70200.bin
  qcom/vpu/vpu30_p4.mbn
  renesas_usb_fw.mem
)

download_one() {
  local rel="$1" mode="$2" url out
  url="${base_url}/${rel}"
  out="${dest_abs}/${rel}"
  install -d "$(dirname "${out}")"
  if curl -fL --retry 3 --retry-delay 2 -o "${out}.tmp" "${url}"; then
    mv "${out}.tmp" "${out}"
    printf '%s  %s\n' "${mode}" "${rel}"
    return 0
  fi
  rm -f "${out}.tmp"
  [[ "${mode}" == required ]] && return 1
  warn "optional firmware not found at ${rel}"
  return 0
}

log "syncing ROCKNIX firmware ref ${ref}"
rm -rf "${dest_abs}"
install -d "${dest_abs}"
missing=0
for rel in "${required[@]}"; do
  download_one "${rel}" required || missing=1
done

for rel in "${optional[@]}"; do
  download_one "${rel}" optional || true
done

if [[ "${missing}" -ne 0 ]]; then
  die "one or more required ROCKNIX firmware files were missing"
fi

{
  printf 'ROCKNIX_REPO=%s\n' "${ROCKNIX_REPO}"
  printf 'ROCKNIX_REF=%s\n' "${ref}"
  printf 'ROCKNIX_FIRMWARE_BASE=%s\n' "${base_url}"
  date -u '+SYNCED_AT=%Y-%m-%dT%H:%M:%SZ'
} > "${dest_abs}/THORCH_FIRMWARE_PROVENANCE"
chmod 0644 "${dest_abs}/THORCH_FIRMWARE_PROVENANCE"

log "firmware synced to ${dest_abs}"
