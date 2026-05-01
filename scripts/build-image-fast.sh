#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${script_dir}/lib/common.sh"
load_thorch_config

usage() {
  cat >&2 <<'EOF'
usage: scripts/build-image-fast.sh [--with-kernel]

Fast rebuild path for Thorch image iteration. It rebuilds local Thorch packages,
reinstalls them into the cached build/image-rootfs, regenerates boot artifacts,
and reassembles the raw image without reinstalling Arch/KDE.

Run scripts/build-image.sh once first to create build/image-rootfs.

  --with-kernel   also rebuild linux-thorch; default skips it for userspace
                  package/default/service iterations.
EOF
}

with_kernel=0
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --with-kernel)
      with_kernel=1
      shift
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

require_root

root="$(repo_root)"
rootfs_dir="${root}/${THORCH_BUILD_DIR}/image-rootfs"
[[ -x "${rootfs_dir}/usr/bin/pacman" && -d "${rootfs_dir}/var/lib/pacman" ]] || \
  die "missing reusable rootfs at ${rootfs_dir}; run scripts/build-image.sh once first"

read -r -a image_packages <<< "${THORCH_IMAGE_PACKAGES}"
[[ "${#image_packages[@]}" -gt 0 ]] || die "THORCH_IMAGE_PACKAGES must contain at least one package"
if [[ "${with_kernel}" -eq 0 ]]; then
  userspace_packages=()
  for pkg in "${image_packages[@]}"; do
    [[ "${pkg}" == "linux-thorch" ]] && continue
    userspace_packages+=("${pkg}")
  done
  image_packages=("${userspace_packages[@]}")
fi
image_packages_csv="$(IFS=,; printf '%s' "${image_packages[*]}")"

if [[ "${with_kernel}" -eq 1 ]]; then
  "${script_dir}/build-packages.sh" --packages "${image_packages_csv}"
else
  "${script_dir}/build-packages.sh" --packages "${image_packages_csv}"
fi

"${script_dir}/build-image.sh" --skip-package-build --reuse-rootfs
