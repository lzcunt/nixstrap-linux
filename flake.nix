{
  description = "Linux distro meant to showcase nixstrap";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:lzcunt/nixpkgs/mlibc/init";
    nixstrap = {
      url = "github:lzcunt/nixstrap";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixstrap, self, ... }: let
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems f;

    overlay = import ./overlay.nix;

    mkConfiguration = hostPkgs: cross: nixstrap.lib.nixstrapConfiguration {
      inherit hostPkgs;
      modules = [
        ({ ... }: {
          nixpkgs.crossSystem.config = cross;
          nixpkgs.overlays = [ overlay ];
        })
        ./bootstrap.nix
      ];
    };
  in {
    overlays.default = overlay;

    nixstrapConfigurations = forEachSupportedSystem (
      system:
      let
        hostPkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        x86_64-gnu = mkConfiguration hostPkgs "x86_64-unknown-linux-gnu";
        x86_64-mlibc = mkConfiguration hostPkgs "x86_64-unknown-linux-mlibc";
        x86_64-musl = mkConfiguration hostPkgs "x86_64-unknown-linux-musl";
      }
    );

    optionsDoc = forEachSupportedSystem (system: (import nixpkgs { inherit system; }).nixosOptionsDoc { inherit (self.nixstrapConfigurations.${system}.x86_64-gnu) options; });
  };
}
