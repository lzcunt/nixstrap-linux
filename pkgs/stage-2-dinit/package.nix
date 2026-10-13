{
  lib,
  replaceVarsWith,
  buildPackages,
  bash,
  coreutils,
  dinit,
  eudev,
  kmod,
  util-linux,
  writeShellScript,

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

  # dinit runs services with stdin on /dev/null, so setsid(1) cannot
  # acquire the console as its controlling terminal on its own; redirect
  # its stdin to the target tty.
  getty = writeShellScript "getty" ''
    tty=$1
    exec ${lib.getExe' util-linux "setsid"} -c -w ${lib.getExe bash} -c "exec ${lib.getExe bash} < /dev/$tty >/dev/$tty 2>/dev/$tty" < /dev/$tty
  '';

  shellService = tty: ''
    type = process
    command = ${getty} ${tty}
    restart = true
  '';

  servicesDir = buildPackages.runCommand "dinit-services" { } ''
    mkdir -p $out

    cat > $out/boot <<EOF
    type = internal
    depends-on = shell-tty0
    depends-on: shell-ttyS0
    EOF

    cat > $out/shell-tty0 <<EOF
    ${shellService "tty0"}
    EOF

    cat > $out/shell-ttyS0 <<EOF
    ${shellService "ttyS0"}
    EOF
  '';
in
replaceVarsWith {
  src = ./stage-2-dinit.sh;
  isExecutable = true;

  postInstall = ''
    echo checking syntax
    # check both with bash
    ${buildPackages.bash}/bin/sh -n $target
    # and with ash shell, just in case
    ${buildPackages.busybox}/bin/ash -n $target
  '';

  replacements = {
    inherit verbose;
    shell = lib.getExe bash;
    binPath = lib.makeBinPath inputs;
    dinit = lib.getExe dinit;
    inherit servicesDir;
  };
}
