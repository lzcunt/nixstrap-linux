{ config, hostPkgs, lib, pkgs, ... }:

let
  linux = hostPkgs.linux_latest;

  stage-1-init = pkgs.stage-1-init.override {
    kernelModules = config.boot.initrd.kernelModules ++ config.boot.initrd.availableKernelModules;
  };
in
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

  boot.initrd.enable = true;
  isoImage.file."boot/vmlinuz".source = "${linux}/bzImage";
  isoImage.file."boot/initrd".source = config.system.build.cpioArchive.initrd;
  cpioArchive."initrd".compression = "zstd";
  cpioArchive."initrd".closurePaths = [ stage-1-init ];
  cpioArchive."initrd".file = {
    "/lib/modules".source = "${linux.modules}/lib/modules";
    "/init".symlink = builtins.toString stage-1-init;
  };
}
