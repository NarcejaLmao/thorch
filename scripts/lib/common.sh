#!/usr/bin/env bash
set -euo pipefail

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

load_thorch_config() {
  local root
  root="$(repo_root)"
  # shellcheck source=../../config/thorch.conf
  source "${root}/config/thorch.conf"
}

log() {
  printf '==> %s\n' "$*" >&2
}

warn() {
  printf 'warning: %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  local missing=0 cmd
  for cmd in "$@"; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
      printf 'missing required command: %s\n' "${cmd}" >&2
      missing=1
    fi
  done
  [[ "${missing}" -eq 0 ]] || exit 1
}

require_root() {
  [[ "${EUID}" -eq 0 ]] || die "this command must run as root"
}

abspath() {
  local path="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath -m "${path}"
    return
  fi
  if [[ -d "${path}" ]]; then
    (cd "${path}" && pwd)
  else
    local parent base
    parent="$(dirname "${path}")"
    base="$(basename "${path}")"
    mkdir -p "${parent}"
    printf '%s/%s\n' "$(cd "${parent}" && pwd)" "${base}"
  fi
}

parse_size_bytes() {
  local size="$1"
  numfmt --from=iec "${size}"
}

verify_alarm_rootfs() {
  local rootfs_tar="$1"
  local sig_file="${rootfs_tar}.sig"

  if [[ -n "${ALARM_ROOTFS_SHA256:-}" ]]; then
    require_cmd sha256sum
    printf '%s  %s\n' "${ALARM_ROOTFS_SHA256}" "${rootfs_tar}" | sha256sum -c -
    return
  fi

  [[ "${ALARM_ROOTFS_URL}" == https://* ]] || \
    die "ALARM_ROOTFS_URL must use https unless ALARM_ROOTFS_SHA256 is set"
  [[ -n "${ALARM_ROOTFS_SIG_URL:-}" ]] || \
    die "ALARM_ROOTFS_SIG_URL is required unless ALARM_ROOTFS_SHA256 is set"

  require_cmd pacman-key
  curl -fL --retry 3 -o "${sig_file}" "${ALARM_ROOTFS_SIG_URL}"
  pacman-key --verify "${sig_file}" "${rootfs_tar}"
}

download_alarm_rootfs() {
  local rootfs_tar="$1"

  log "downloading Arch Linux ARM rootfs"
  install -d "$(dirname "${rootfs_tar}")"
  curl -fL --retry 3 -o "${rootfs_tar}" "${ALARM_ROOTFS_URL}"
}

ensure_alarm_rootfs() {
  local rootfs_tar="$1"

  if [[ ! -f "${rootfs_tar}" ]]; then
    download_alarm_rootfs "${rootfs_tar}"
  fi

  if verify_alarm_rootfs "${rootfs_tar}"; then
    return
  fi

  die "failed to verify Arch Linux ARM rootfs; install/populate the Arch Linux ARM keyring or set ALARM_ROOTFS_SHA256"
}

configure_alarm_pacman() {
  local rootfs="$1"
  local mirror

  install -d "${rootfs}/etc/pacman.d"
  : > "${rootfs}/etc/pacman.d/mirrorlist"
  for mirror in ${ALARM_MIRRORS:-${ALARM_MIRROR:-http://mirror.archlinuxarm.org}}; do
    printf 'Server = %s/$arch/$repo\n' "${mirror%/}" >> "${rootfs}/etc/pacman.d/mirrorlist"
  done

  if ! grep -q '^DisableSandbox' "${rootfs}/etc/pacman.conf"; then
    sed -i '/^\[options\]/a DisableSandbox' "${rootfs}/etc/pacman.conf"
  fi
}

configure_chroot_resolver() {
  local rootfs="$1"
  local source="/etc/resolv.conf"

  if grep -Eq '^nameserver[[:space:]]+127\.' /etc/resolv.conf 2>/dev/null && [[ -r /run/systemd/resolve/resolv.conf ]]; then
    source="/run/systemd/resolve/resolv.conf"
  fi

  rm -f "${rootfs}/etc/resolv.conf"
  cp -L "${source}" "${rootfs}/etc/resolv.conf"
}

mask_chroot_stock_kernel_hooks() {
  local rootfs="$1"

  install -d "${rootfs}/etc/pacman.d/hooks"
  ln -sf /dev/null "${rootfs}/etc/pacman.d/hooks/60-mkinitcpio-remove.hook"
  ln -sf /dev/null "${rootfs}/etc/pacman.d/hooks/90-mkinitcpio-install.hook"
}

extract_alarm_rootfs_without_stock_kernel_firmware() {
  local rootfs_tar="$1"
  local dest="$2"

  bsdtar -xpf "${rootfs_tar}" -C "${dest}" \
    --exclude './boot/*' \
    --exclude 'boot/*' \
    --exclude './etc/mkinitcpio.d/linux-aarch64.preset' \
    --exclude 'etc/mkinitcpio.d/linux-aarch64.preset' \
    --exclude './usr/lib/firmware/*' \
    --exclude 'usr/lib/firmware/*' \
    --exclude './usr/lib/modules/*' \
    --exclude 'usr/lib/modules/*' \
    --exclude './usr/share/licenses/linux-aarch64*' \
    --exclude 'usr/share/licenses/linux-aarch64*' \
    --exclude './usr/share/licenses/linux-firmware*' \
    --exclude 'usr/share/licenses/linux-firmware*' \
    --exclude './var/lib/pacman/local/linux-aarch64-*' \
    --exclude 'var/lib/pacman/local/linux-aarch64-*' \
    --exclude './var/lib/pacman/local/linux-firmware*' \
    --exclude 'var/lib/pacman/local/linux-firmware*'
}

validate_rocknix_kernel_provenance() {
  local kernel_dir="$1"
  local provenance="${kernel_dir}/PROVENANCE"

  if [[ ! -f "${provenance}" ]]; then
    warn "missing ROCKNIX kernel provenance at ${provenance}"
    return 0
  fi

  if grep -Eq '(^ROCKNIX_REF=smoke-test-existing-kernel-tree$|^SOURCE_(BOOT|ROOT)_DIR=.*/packages/[^/]+/pkg($|/)|^SOURCE_(IMAGE|DTB|MODULES)=packages/[^/]+/pkg/)' "${provenance}"; then
    die "ROCKNIX kernel provenance points at a local makepkg/smoke-test output; re-import from a mounted or extracted ROCKNIX image"
  fi
}

validate_rocknix_runtime_provenance() {
  local runtime_dir="$1"
  local provenance="${runtime_dir}/PROVENANCE"

  if [[ ! -f "${provenance}" ]]; then
    warn "missing ROCKNIX runtime provenance at ${provenance}"
    return 0
  fi

  if grep -Eq '(^ROCKNIX_REF=smoke-test-existing-kernel-tree$|^SOURCE_(ROOT_DIR|RUNTIME_ROOT)=.*/packages/[^/]+/(pkg|src)($|/))' "${provenance}"; then
    die "ROCKNIX runtime provenance points at a local makepkg/smoke-test output; re-import from a mounted or extracted ROCKNIX image"
  fi
}
