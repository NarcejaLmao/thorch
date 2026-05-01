# Contributing

Thorch is experimental hardware bring-up code. Keep changes small,
traceable, and easy to reproduce.

Before opening a change:

- Run `./scripts/audit-release.sh`.
- Keep generated artifacts out of the source tree and out of commits.
- Pin ROCKNIX refs with full commits for release builds.
- Preserve upstream license notices and provenance files.
- Do not add proprietary firmware, Steam client payloads, private keys, tokens,
  local root filesystems, package caches, or raw images.
- For installer or block-device changes, document the safety guard being added
  or preserved.

Useful validation:

```bash
./scripts/audit-release.sh
./scripts/check-thorch-image.sh output/thorch-arch-aarch64.img
```

The top-level `Makefile` wraps the common script entry points. Keep behavior in
`scripts/`; add Make targets only as short aliases for common workflows.
