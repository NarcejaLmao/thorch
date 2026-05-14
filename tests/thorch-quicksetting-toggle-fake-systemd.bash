#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="${root}/packages/thorch-bsp/payload/usr/bin/thorch-quicksetting-toggle"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat > "${tmp}/systemctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

state="${FAKE_SYSTEMCTL_STATE:?}"
cmd="$1"
shift

service_path() {
  printf '%s/%s/%s\n' "${state}" "$1" "$2"
}

case "${cmd}" in
  is-active)
    [[ "${1:-}" == "--quiet" ]] && shift
    [[ -e "$(service_path active "$1")" ]]
    ;;
  enable)
    mkdir -p "${state}/enabled"
    for service in "$@"; do
      touch "$(service_path enabled "${service}")"
    done
    ;;
  disable)
    for service in "$@"; do
      rm -f "$(service_path enabled "${service}")"
    done
    ;;
  start)
    mkdir -p "${state}/active"
    for service in "$@"; do
      touch "$(service_path active "${service}")"
    done
    ;;
  stop)
    for service in "$@"; do
      rm -f "$(service_path active "${service}")"
    done
    ;;
  *)
    echo "unexpected fake systemctl command: ${cmd}" >&2
    exit 2
    ;;
esac
EOF
chmod 755 "${tmp}/systemctl"

cat > "${tmp}/rgb" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

state="${FAKE_RGB_STATE:?}"
mkdir -p "${state}"
mode_file="${state}/mode"
static_file="${state}/static"
[[ -e "${mode_file}" ]] || printf 'battery\n' > "${mode_file}"
[[ -e "${static_file}" ]] || printf '0 128 255\n' > "${static_file}"

mode="$(< "${mode_file}")"
read -r red green blue < "${static_file}"

case "${1:-}" in
  status)
    printf 'config: fake\n'
    printf 'mode: %s\n' "${mode}"
    printf 'brightness: 255\n'
    printf 'static: %s %s %s\n' "${red}" "${green}" "${blue}"
    ;;
  off)
    printf 'off\n' > "${mode_file}"
    ;;
  battery)
    printf 'battery\n' > "${mode_file}"
    ;;
  set)
    [[ "$#" -eq 4 ]] || exit 2
    printf 'static\n' > "${mode_file}"
    printf '%s %s %s\n' "$2" "$3" "$4" > "${static_file}"
    ;;
  *)
    echo "unexpected fake rgb command: ${1:-}" >&2
    exit 2
    ;;
esac
EOF
chmod 755 "${tmp}/rgb"

cat > "${tmp}/hardwarectl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

rgb="${THORCH_QUICKSETTING_RGB:?}"

case "${1:-}" in
  set)
    case "${2:-}" in
      rgb-mode)
        case "${3:-}" in
          off) "${rgb}" off ;;
          battery) "${rgb}" battery ;;
          static) exit 0 ;;
          *) exit 2 ;;
        esac
        ;;
      rgb-color)
        "${rgb}" set "$3" "$4" "$5"
        ;;
      *)
        exit 2
        ;;
    esac
    ;;
  *)
    exit 2
    ;;
esac
EOF
chmod 755 "${tmp}/hardwarectl"

run_helper() {
  FAKE_SYSTEMCTL_STATE="${tmp}/systemctl-state" \
  FAKE_RGB_STATE="${tmp}/rgb-state" \
  THORCH_QUICKSETTING_SKIP_PKEXEC=1 \
  THORCH_QUICKSETTING_SYSTEMCTL="${tmp}/systemctl" \
  THORCH_QUICKSETTING_RGB="${tmp}/rgb" \
  THORCH_QUICKSETTING_HARDWARECTL="${tmp}/hardwarectl" \
  THORCH_QUICKSETTING_STATE_DIR="${tmp}/quicksetting-state" \
    "${script}" "$@"
}

assert_status() {
  local target="$1" expected="$2" actual

  actual="$(run_helper "${target}" status)"
  [[ "${actual}" == "${expected}" ]] || fail "${target} status expected ${expected}, got ${actual}"
}

assert_service_active() {
  local service="$1"

  [[ -e "${tmp}/systemctl-state/active/${service}" ]] || fail "${service} is not active"
  [[ -e "${tmp}/systemctl-state/enabled/${service}" ]] || fail "${service} is not enabled"
}

assert_service_inactive() {
  local service="$1"

  [[ ! -e "${tmp}/systemctl-state/active/${service}" ]] || fail "${service} is still active"
  [[ ! -e "${tmp}/systemctl-state/enabled/${service}" ]] || fail "${service} is still enabled"
}

assert_rgb_mode() {
  local expected="$1" actual

  actual="$(< "${tmp}/rgb-state/mode")"
  [[ "${actual}" == "${expected}" ]] || fail "RGB mode expected ${expected}, got ${actual}"
}

assert_status usb off
run_helper usb toggle
assert_status usb on
assert_service_active thorch-usb-gadget.service
assert_service_active thorch-usb-network.service
run_helper usb toggle
assert_status usb off
assert_service_inactive thorch-usb-gadget.service
assert_service_inactive thorch-usb-network.service

assert_status ssh off
run_helper ssh toggle
assert_status ssh on
assert_service_active sshd.service
run_helper ssh toggle
assert_status ssh off
assert_service_inactive sshd.service

assert_status rgb on
run_helper rgb toggle
assert_status rgb off
assert_rgb_mode off
grep -qx 'battery' "${tmp}/quicksetting-state/rgb-mode" || fail "RGB previous battery mode was not saved"
run_helper rgb toggle
assert_status rgb on
assert_rgb_mode battery

FAKE_RGB_STATE="${tmp}/rgb-state" "${tmp}/rgb" set 9 8 7
run_helper rgb toggle
assert_status rgb off
grep -qx 'static' "${tmp}/quicksetting-state/rgb-mode" || fail "RGB previous static mode was not saved"
run_helper rgb toggle
assert_status rgb on
assert_rgb_mode static
grep -qx '9 8 7' "${tmp}/rgb-state/static" || fail "RGB static color was not preserved"

printf 'thorch quicksetting toggle fake systemd tests passed\n'
