{ lib, ... }:

{
  options.boot.dinit.enable = lib.mkEnableOption "dinit, used as the stage 2 init system" // {
    default = true;
  };
}
