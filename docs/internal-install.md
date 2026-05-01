# Internal Install Notes

Thorch treats SD as staging and recovery media. The intended performance path is
internal UFS storage.

The safest in-image installer flow uses explicit target partitions:

```bash
sudo thorch-install-internal --boot-device /dev/<boot-partition> --root-device /dev/<root-partition>
```

With no device arguments, the installer may auto-detect exactly one existing
internal ROCKNIX/Thorch Linux target and ask for confirmation before formatting
that target. It will not create new partitions or shrink Android userdata in the
default flow.

Creating a target by shrinking Android `userdata` is an explicit advanced flow:

```bash
sudo thorch-install-internal --create-from-userdata
```

That mode wipes Android userdata, recreates it smaller, creates the Thorch boot
and root partitions, and requires the typed confirmation `SHRINK USERDATA`
before repartitioning.

Safety behavior:

- Refuses to run unless the current root filesystem appears to be on removable
  media.
- Requires explicit boot/root block devices, one auto-detected existing
  ROCKNIX/Thorch target, or the explicit `--create-from-userdata` mode.
- Refuses common Android partition labels such as `boot_a`, `boot_b`, `vendor`,
  `system`, `super`, `userdata`, `abl`, `dtbo`, `vbmeta`, and `modem`.
- Requires the typed confirmation `INSTALL THORCH`.
- Backs up readable existing boot files under `/var/lib/thorch-installer`.
- Formats the selected boot partition as FAT32 label `ROCKNIX`.
- Formats the selected root partition as ext4 label `THORCH_ROOT`.
- Copies the running SD system, writes `fstab`, regenerates initramfs, rebuilds
  `/boot/KERNEL`, and validates the boot directory.

The installer never flashes ABL. The device must already have a Linux-capable ABL
path.
