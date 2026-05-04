# Package Layout

`linux-thorch` packages prebuilt ROCKNIX SM8550 kernel artifacts for AYN Thor.
It installs the imported ROCKNIX `/KERNEL` source payload, matching modules, a
module-tree `Image` anchor for mkinitcpio, and a mkinitcpio preset. It does not
install raw `/boot/Image`; `/boot/KERNEL` is the ABL boot payload.
Thorch does not replay ROCKNIX kernel patches in v1; it builds its own initramfs
against the imported kernel. When building `/boot/KERNEL`, Thorch repacks
ROCKNIX's imported Android boot image so the original kernel payload and
embedded Thor DTB are preserved while only the initramfs and root command line
change.

`thorch-bsp` owns the ABL boot contract, including
`thorch-rebuild-abl-kernel`, `thorch-check-boot`, the mkinitcpio firmware hook,
USB debug gadget, boot diagnostics, Thor joystick RGB control, fake-suspend and
power-key handling, dual-panel backlight helpers, gamepad/input udev rules,
Plasma Mobile action-drawer overrides, and ALSA UCM snippets. The action-drawer
override is stateful: package install/upgrade runs a sync helper so SteamOS mode
can keep its patched Plasma Mobile drawer enabled while normal desktop/mobile
sessions restore the stock QML.

`thorch-firmware-rocknix` packages the synced public ROCKNIX firmware tree into
`/usr/lib/firmware`. It also installs the matching ROCKNIX `/SYSTEM`
Turnip/Freedreno runtime imported with the kernel image: the native aarch64 host
driver, `libdisplay-info.so.2` compatibility library, ROCKNIX FEX-side Freedreno
helper, and host Vulkan ICD. The image build removes Arch's stock
`linux-firmware*` packages and relies on this package for Thor firmware,
including the Adreno firmware imported from the ROCKNIX `/SYSTEM` kernel
overlay.

`thorch-kde-defaults` installs the Plasma Desktop dependencies, SDDM defaults,
KWin display and touch seeds, virtual keyboard settings, audio user units,
touch calibration service, the F24 desktop escape helper, OLED Plasma theme and
color scheme, desktop/mobile session switchers, Firefox, and the core KDE
desktop applications. Plasma Mobile is installed for testing and SteamOS-mode
handoff, but the image builder selects Plasma Desktop by default unless
`THORCH_DEFAULT_SESSION` is changed.

`thorch-installer` provides `thorch-install-internal` and the `Expand SD Root`
desktop launcher for growing the booted SD root partition after first boot. The
root expander grows only the currently mounted ext4 `/` partition and requires a
removable device or the expected two-partition Thorch SD layout unless `--force`
is used.

`thorch-fex-bin` repackages the matching ROCKNIX `/SYSTEM` FEX runtime. It
installs FEX, Vulkan/OpenGL, audio, DRM, and Wayland thunks, binfmt
registrations, a `libfmt.so.11` compatibility library for the imported binaries,
and a Steam-compatible FEX tool under `/usr/share/steam/fex`. The package
provides and replaces the old `thorch-fex` name for upgrades.

`thorch-gamescope` builds Valve's gamescope from source with the ROCKNIX
handheld gamescope patch set consumed from the synced `vendor/rocknix-sm8550`
tree. It keeps only the Arch-specific wlroots workaround locally. It provides
and conflicts with `gamescope`, so installers and launchers can continue
invoking the standard `gamescope` command.

`thorch-rocknix-quirks` packages ROCKNIX-derived SM8550 handheld quirk metadata
for Thorch. It exports Arch-safe profile hints for touchscreen, audio path,
thermal, CPU/GPU frequency paths, modifier buttons, and MangoHud support while
preserving the original ROCKNIX quirk scripts from the synced
`vendor/rocknix-sm8550` tree under `/usr/share/thorch/rocknix-quirks/SM8550`
for provenance. It does not execute ROCKNIX's `/storage` autostart scripts
directly.

`thorch-mangohud` builds MangoHud with ROCKNIX's SM8550 GPU fdinfo patch and
installs the ROCKNIX MangoHud configuration as `/etc/MangoHud.conf`, both from
the synced `vendor/rocknix-sm8550` tree.

`thorch-gaming-installers` provides the opt-in Steam ARM64, FEX setup, gaming
stack installer, and SteamOS-mode launchers. It does not redistribute Steam
client payloads. It keeps ROCKNIX-style Steam metadata in `/usr/share/steam` for
the ARM64 Proton compatibility-tool stub, and links the packaged FEX tool from
`/usr/share/steam/fex` into the user's Steam compatibility tools during
setup/launch. The Steam launcher keeps the user Steam symlinks fresh, seeds
per-app FEX configs with DRM, Vulkan, GL, asound, and Wayland host libraries,
and leaves global FEX binfmt registrations enabled so Steam Runtime and
pressure-vessel x86_64 helper binaries are handed to FEX normally. The packaged
FEX thunk database also covers pressure-vessel's library override aliases so CS2
can use the DRM, Vulkan, GL, asound, and Wayland host-library forwarding paths
from inside Steam Linux Runtime containers. The FEX Arch rootfs remains an
x86_64 guest rootfs; when the ROCKNIX FEX-side `libvulkan_freedreno.so` is
available, the installer copies that x86_64 guest driver into the rootfs just
like ROCKNIX. It still refuses to copy the aarch64 host driver over the guest
library. Vulkan acceleration is provided by FEX's Vulkan thunk, which forwards
guest Vulkan calls to the patched native aarch64 host driver.
