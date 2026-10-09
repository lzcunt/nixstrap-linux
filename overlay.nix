final: prev:

let
  inherit (prev) lib;
  pkgsDir = ./pkgs;

  # Read all entries inside ./pkgs
  entries = builtins.readDir pkgsDir;

  # Filter for subdirectories containing a default.nix
  packageDirs = lib.filterAttrs (name: type:
    type == "directory" && builtins.pathExists (pkgsDir + "/${name}/package.nix")
  ) entries;
in

lib.mapAttrs (name: _:
  final.callPackage (pkgsDir + "/${name}/package.nix") { }
) packageDirs
