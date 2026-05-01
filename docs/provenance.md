# Provenance

Thorch is meant to be public and standalone. Hardware enablement is synchronized
from public upstreams and recorded with provenance files.

## ROCKNIX

The public ROCKNIX distribution repository and ROCKNIX image artifacts provide
the SM8550 kernel, AYN Thor DTB, input mappings, and firmware used by Thorch:

https://github.com/ROCKNIX/distribution

Use a pinned commit or labelled ROCKNIX image build for release builds:

```bash
./scripts/sync-rocknix-sources.sh --ref <commit-sha> --with-firmware
./scripts/import-rocknix-kernel.sh --boot-dir /mnt/rocknix-boot --root-dir /mnt/rocknix-root --ref <rocknix-build-label>
```

The sync and import scripts write provenance files into `vendor/rocknix-sm8550`
and `vendor/rocknix-kernel` so generated builds can be traced back to the exact
upstream source and image artifact.

Image and package builds refuse kernel provenance that points back at local
`makepkg` output or smoke-test imports. Re-import kernel artifacts from a mounted
or extracted ROCKNIX image before preparing release artifacts.

## Firmware

Thor firmware is sourced from the public ROCKNIX SM8550 firmware tree and
packaged as `thorch-firmware-rocknix`. Thorch preserves upstream provenance, but
does not claim new licensing rights over those blobs.

## Arch Linux ARM

The base root filesystem and distro packages come from Arch Linux ARM aarch64
repositories. Thorch packages are layered on top as a local pacman repository
during image creation.

## Local Thorch Code

Thorch-specific scripts, package recipes, installer guardrails, KDE defaults, and
boot validation live in this repository.
