{ config, lib, pkgs, ... }:

let
  cfg = config.boot.initrd;

  modulesClosure = pkgs.makeModulesClosure {
    rootModules = cfg.availableKernelModules ++ cfg.kernelModules;
    kernel = config.system.modulesTree;
    firmware = pkgs.emptyDirectory;
  };

  stage-1-init = pkgs.stage-1-init.override {
    kernelModules = cfg.kernelModules;
  };
in
{
  options.boot.initrd = {
    enable = lib.mkEnableOption "Linux initrd generation";

    compression = lib.mkOption {
      default = "zstd";
      type = lib.types.nullOr (
        lib.types.enum [
          "gzip"
          "xz"
          "zstd"
        ]
      );
      description = ''
        The compression to apply to the generated initrd, or `null` for none.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    cpioArchive."initrd" = {
      closurePaths = [
        modulesClosure
        stage-1-init
        pkgs.udev-rules
      ];
      compression = cfg.compression;
      file."/init".symlink = toString stage-1-init;
      file."/etc/udev/rules.d".symlink = toString pkgs.udev-rules;
      file."/lib".symlink = "${modulesClosure}/lib";
    };
  };
}
