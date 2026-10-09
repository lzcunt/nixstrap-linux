{ lib, ... }:

{
  options.boot.initrd = {
    enable = lib.mkEnableOption "Linux initrd generation";
  };
}
