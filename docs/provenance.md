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

The sync and import scripts write provenance files into `vendor/rocknix-sm8550`,
`vendor/rocknix-kernel`, and `vendor/rocknix-runtime` so generated builds can be
traced back to the exact upstream source and image artifact.

Image and package builds refuse kernel provenance that points back at local
`makepkg` output or smoke-test imports. Re-import kernel artifacts from a mounted
or extracted ROCKNIX image before preparing release artifacts.

## AYN Linux

AYN also publishes the kernel work that underpins the SM8550 handheld ports:

https://github.com/AYNTechnologies/linux

The important public branches are:

- `sm8550/v6.17.5`: AYN's SM8550 kernel branch with the shared QCS8550 device
  tree, Odin 2, Odin 2 Mini, Odin 2 Portal, Thor, RSInput gamepad, panel,
  backlight, RGB LED, SD, USB, and audio enablement.
- `ayn/v7.0`: AYN's newer Linux 7.0 branch. As of 2026-05-04 it keeps the Thor
  DTS equivalent to `sm8550/v6.17.5`, carries small SM8550 common cleanup, and
  adds the separate CQ8725S/SM8750 Odin 3 device tree stack.

Thorch still imports the packaged ROCKNIX kernel/runtime artifacts for builds,
but AYN's branches should be treated as source-level provenance and review
material when updating kernel, DTS, firmware paths, ALSA card aliases, gamepad
handling, or RGB support.

## Firmware

Thor firmware is sourced from the public ROCKNIX SM8550 firmware tree and
packaged as `thorch-firmware-rocknix`. Thorch preserves upstream provenance, but
does not claim new licensing rights over those blobs.

Some Adreno firmware and runtime graphics files are imported from the ROCKNIX
image `/SYSTEM` payload together with the kernel import. Those image-derived
files are recorded in kernel/runtime provenance rather than in the public source
overlay provenance.

## FEX Runtime

The FEX runtime packaged as `thorch-fex-bin` is imported from the matching
ROCKNIX `/SYSTEM` payload. Runtime provenance is written to
`vendor/rocknix-runtime/PROVENANCE` and installed into package license metadata
with the imported binaries.

## Arch Linux ARM

The base root filesystem and distro packages come from Arch Linux ARM aarch64
repositories. Thorch packages are layered on top as a local pacman repository
during image creation.

## Local Thorch Code

Thorch-specific scripts, package recipes, installer guardrails, KDE defaults, and
boot validation live in this repository.
