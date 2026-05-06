#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="${root}/packages/thorch-kde-defaults/payload/usr/bin/thorch-rgb-ambient"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

mkdir -p "${tmp}/runtime"
chmod 700 "${tmp}/runtime"

cat > "${tmp}/spectacle" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

output=""
while (($#)); do
  case "$1" in
    -o)
      output="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

[[ -n "${output}" ]] || {
  echo "missing -o output" >&2
  exit 2
}

{
  printf 'P6\n2 1\n255\n'
  printf '\377\000\000\000\000\377'
} > "${output}"
EOF
chmod 755 "${tmp}/spectacle"

cat > "${tmp}/rgb" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

[[ "${1:-}" == "apply" ]] || {
  echo "expected apply command" >&2
  exit 2
}
printf '%s\n' "$*" >> "${THORCH_RGB_AMBIENT_APPLY_LOG:?}"
EOF
chmod 755 "${tmp}/rgb"

THORCH_RGB_AMBIENT_APPLY_LOG="${tmp}/apply.log" \
THORCH_RGB_AMBIENT_RGB="${tmp}/rgb" \
THORCH_RGB_AMBIENT_SPECTACLE="${tmp}/spectacle" \
XDG_RUNTIME_DIR="${tmp}/runtime" \
  "${script}" --once --sample-stride 1

grep -qx 'apply 128 0 128' "${tmp}/apply.log" || fail "ambient RGB average was not applied"

print_output="$(
  THORCH_RGB_AMBIENT_RGB="${tmp}/rgb" \
  THORCH_RGB_AMBIENT_SPECTACLE="${tmp}/spectacle" \
  XDG_RUNTIME_DIR="${tmp}/runtime" \
    "${script}" --once --sample-stride 1 --print
)"
[[ "${print_output}" == "128 0 128" ]] || fail "print mode returned ${print_output}"

printf 'thorch-rgb ambient fake capture tests passed\n'
