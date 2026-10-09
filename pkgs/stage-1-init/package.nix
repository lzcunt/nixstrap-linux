{
  lib,
  replaceVarsWith,
  buildPackages,
  bash,
  coreutils,
  eudev,
  kmod,
  util-linux,

  kernelModules ? [ ],
  verbose ? true,
}:

let
  inputs = [
    bash
    coreutils
    eudev
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
    inherit kernelModules verbose;
    shell = lib.getExe bash;
    binPath = lib.makeBinPath inputs;
  };
}
