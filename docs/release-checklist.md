# Release Checklist

Use this before publishing the repository or building public images.

## Source Tree

- Run `./scripts/audit-release.sh`.
- Confirm the source tree does not contain `build/`, `output/`, `local/`,
  synced `vendor/` trees, imported kernel artifacts, package `src/`/`pkg/`
  directories, package archives, raw images, rootfs images, logs, or caches.
- Confirm no local rootfs files such as `etc/shadow`, SSH keys, tokens, or
  personal host paths are present.
- Confirm `LICENSE`, `NOTICE.md`, `SECURITY.md`, and `CONTRIBUTING.md` are
  present.

## Build Inputs

- Sync ROCKNIX sources with a full commit SHA.
- Import kernel artifacts from a mounted or extracted upstream ROCKNIX image,
  not from local `makepkg` output.
- Verify the Arch Linux ARM rootfs through its detached signature or a pinned
  `ALARM_ROOTFS_SHA256`.
- Preserve `SOURCE_PROVENANCE`, `THORCH_FIRMWARE_PROVENANCE`, and kernel
  `PROVENANCE` in generated artifacts.

## Public Image Builds

- Confirm the intended `THORCH_PASSWORD` for the image build; it defaults to
  `1234` unless overridden.
- Run `./scripts/check-thorch-image.sh` on the generated image.
- Keep generated images and packages as release artifacts, not repository
  source files.
