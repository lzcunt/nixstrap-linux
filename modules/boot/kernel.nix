{ config, lib, pkgs, ... }:

with lib;

let
  modulesTypeDesc = ''
    This can either be a list of modules, or an attrset. In an
    attrset, names that are set to `true` represent modules that will
    be included. Note that setting these names to `false` does not
    prevent the module from being loaded. For that, use
    {option}`boot.blacklistedKernelModules`.
  '';

  # A list of attrnames is coerced into an attrset of bools by
  # setting the values to true.
  attrNamesToTrue = types.coercedTo (types.listOf types.str) (
    enabledList: genAttrs enabledList (_attrName: true)
  ) (types.attrsOf types.bool);
in
{
  options = {
    boot.kernelModules = mkOption {
      type = attrNamesToTrue;
      default = { };
      description = ''
        The set of kernel modules to be loaded in the second stage of
        the boot process.  Note that modules that are needed to
        mount the root file system should be added to
        {option}`boot.initrd.availableKernelModules` or
        {option}`boot.initrd.kernelModules`.

        ${modulesTypeDesc}
      '';
      apply = mods: attrNames (filterAttrs (_: v: v) mods);
    };

    boot.initrd.availableKernelModules = mkOption {
      type = attrNamesToTrue;
      default = { };
      example = [
        "sata_nv"
        "ext3"
      ];
      description = ''
        The set of kernel modules in the initial ramdisk used during the
        boot process.  This set must include all modules necessary for
        mounting the root device.  That is, it should include modules
        for the physical device (e.g., SCSI drivers) and for the file
        system (e.g., ext3).  The set specified here is automatically
        closed under the module dependency relation, i.e., all
        dependencies of the modules list here are included
        automatically.  The modules listed here are available in the
        initrd, but are only loaded on demand (e.g., the ext3 module is
        loaded automatically when an ext3 filesystem is mounted, and
        modules for PCI devices are loaded when they match the PCI ID
        of a device in your system).  To force a module to be loaded,
        include it in {option}`boot.initrd.kernelModules`.

        ${modulesTypeDesc}
      '';
      apply = mods: attrNames (filterAttrs (_: v: v) mods);
    };

    boot.initrd.kernelModules = mkOption {
      type = attrNamesToTrue;
      default = { };
      description = ''
        Set of modules that are always loaded by the initrd.

        ${modulesTypeDesc}
      '';
      apply = mods: attrNames (filterAttrs (_: v: v) mods);
    };

    boot.initrd.includeDefaultModules = mkOption {
      type = types.bool;
      default = true;
      description = ''
        This option, if set, adds a collection of default kernel modules
        to {option}`boot.initrd.availableKernelModules` and
        {option}`boot.initrd.kernelModules`.
      '';
    };

    system.modulesTree = mkOption {
      type = types.listOf types.path;
      internal = true;
      default = [ ];
      description = ''
        Tree of kernel modules.  This includes the kernel, plus modules
        built outside of the kernel.  Combine these into a single tree of
        symlinks because modprobe only supports one directory.
      '';
      # Convert the list of path to only one path.
      apply =
        # let
        #   kernel-name = config.boot.kernelPackages.kernel.name or "kernel";
        # in
        modules: (pkgs.aggregateModules modules).override { name = "kernel-modules"; };
    };
  };

  config = mkMerge [
    (mkIf config.boot.initrd.enable {
      boot.initrd.availableKernelModules = optionals config.boot.initrd.includeDefaultModules (
        [
          # Some SATA/PATA stuff.
          "ahci"
          "sata_nv"
          "sata_via"
          "sata_sis"
          "sata_uli"
          "ata_piix"
          "pata_marvell"

          # NVMe
          "nvme"

          # Standard SCSI stuff.
          "sd_mod"
          "sr_mod"

          # SD cards and internal eMMC drives.
          "mmc_block"

          # Support USB keyboards, in case the boot fails and we only have
          # a USB keyboard, or for LUKS passphrase prompt.
          "uhci_hcd"
          "ehci_hcd"
          "ehci_pci"
          "ohci_hcd"
          "ohci_pci"
          "xhci_hcd"
          "xhci_pci"
          "usbhid"
          "hid_generic"
          "hid_lenovo"
          "hid_apple"
          "hid_roccat"
          "hid_logitech_hidpp"
          "hid_logitech_dj"
          "hid_microsoft"
          "hid_cherry"
          "hid_corsair"
        ]
        # ++ optionals (versionAtLeast kernel.version "7.2") [
	++ [
          # xhci-pci defers AMD 800-series chipset controllers to this driver.
          "xhci_pci_prom21"
        ]
        ++ optionals pkgs.stdenv.hostPlatform.isx86 [
          # Misc. x86 keyboard stuff.
          "pcips2"
          "atkbd"
          "i8042"
        ]
      );

      boot.initrd.kernelModules = optionals config.boot.initrd.includeDefaultModules [
        # For LVM.
        "dm_mod"
      ];
    })
  ];
}
