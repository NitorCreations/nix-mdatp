{
  description = "Unofficial Microsoft Defender Advanced Threat Protection Nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachSystemPassThrough [ "x86_64-linux" ] (system: {
      nixosModules = rec {
        default = mdatp;
        mdatp = import ./nixos;
      };

      nixosConfigurations.testing = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          self.nixosModules.mdatp
          (
            { pkgs, lib, ... }:
            {
              boot.isContainer = true; # stop nix flake check complaining about missing root fs
              documentation.nixos.enable = false; # skip generating nixos docs
              virtualisation.vmVariant = {
                boot.isContainer = lib.mkForce false; # let vm variant create a virtual disk
                virtualisation.graphics = false; # connect serial console to terminal
              };
              users.users.root.initialPassword = "test";
              services.mdatp = {
                enable = true;
              };
            }
          )
        ];
      };

      overlays = {
        default = import ./overlay.nix;
      };
    })
    // flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      in
      {
        packages = rec {
          mdatp = pkgs.callPackage ./package.nix { };
          default = mdatp;
        };
        checks = {
          mdatpNixosTest = pkgs.callPackage ./nixos/tests.nix { inherit self; };
        };
      }
    );
}
