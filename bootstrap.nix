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
    cmdline = "root=/dev/ram0 rw";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.enable = true;

  isoImage.file."boot/vmlinuz".source = "${config.boot.kernelPackages.kernel}/bzImage";
  isoImage.file."boot/initrd".source = config.system.build.cpioArchive.initrd;
}
