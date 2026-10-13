{ config, hostPkgs, lib, pkgs, ... }:

{
  imports = [
    ./modules
  ];

  system.label = "Nixstrap-Linux";

  boot.loader.timeout = 3;
  boot.loader.limine.enable = true;
  boot.entry."Nixstrap Linux" = {
    protocol = "linux";
    kernelPath = "boot():/boot/vmlinuz";
    modulePaths = [ "boot():/boot/initrd" ];
    cmdline = "console=ttyS0 console=tty0 init=${pkgs.stage-2-dinit}";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.enable = true;

  isoImage.file."boot/vmlinuz".source = "${config.boot.kernelPackages.kernel}/bzImage";
  isoImage.file."boot/initrd".source = config.system.build.cpioArchive.initrd;
  isoImage.file."nix-store.squashfs".source = pkgs.makeSquashfs {
    name = "nix-store.squashfs";
    storeContents = [ pkgs.stage-2-dinit config.system.build.initrdModulesClosure ];
  };

  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "mode=0755" ];
    # neededForBoot = true; # FIXME should be automatic
  };
}
