{
  runCommand,
  eudev,
  lvm2,
  extraUdevRulesCommands ? "",
}:

runCommand "udev-rules" { } ''
  mkdir -p $out

  cp -v ${eudev}/var/lib/udev/rules.d/60-cdrom_id.rules $out/
  cp -v ${eudev}/var/lib/udev/rules.d/60-persistent-storage.rules $out/
  cp -v ${eudev}/var/lib/udev/rules.d/75-net-description.rules $out/
  cp -v ${eudev}/var/lib/udev/rules.d/80-drivers.rules $out/
  cp -v ${lvm2}/lib/udev/rules.d/*.rules $out/
  ${extraUdevRulesCommands}

  # Work around a bug in QEMU, which doesn't implement the "READ
  # DISC INFORMATION" SCSI command:
  #   https://bugzilla.redhat.com/show_bug.cgi?id=609049
  # As a result, `cdrom_id' doesn't print
  # ID_CDROM_MEDIA_TRACK_COUNT_DATA, which in turn prevents the
  # /dev/disk/by-label symlinks from being created.  We need these
  # in the NixOS installation CD, so use ID_CDROM_MEDIA in the
  # corresponding udev rules for now.  This was the behaviour in
  # udev <= 154.  See also
  #   https://www.spinics.net/lists/hotplug/msg03935.html
  substituteInPlace $out/60-persistent-storage.rules \
    --replace-fail ID_CDROM_MEDIA_TRACK_COUNT_DATA ID_CDROM_MEDIA
''
