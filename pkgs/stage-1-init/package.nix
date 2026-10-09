{
  lib,
  replaceVarsWith,
  buildPackages,
  bash,
  coreutils,
  kmod,
  util-linux,

  kernelModules ? [ ],
}:

let
  inputs = [
    bash
    coreutils
    kmod
    util-linux
  ];
in
replaceVarsWith {
  src = ./init.sh;
  isExecutable = true;

  postInstall = ''
    echo checking syntax
    # check both with bash
    ${buildPackages.bash}/bin/sh -n $target
    # and with ash shell, just in case
    ${buildPackages.busybox}/bin/ash -n $target
  '';

  replacements = {
    inherit kernelModules;
    shell = lib.getExe bash;
    binPath = lib.makeBinPath inputs;
  };
}
