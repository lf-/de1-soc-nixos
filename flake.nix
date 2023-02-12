{
  description = "NixOS for Cyclone V DE1-SoC";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      out = system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
          crossPkgs = pkgs.pkgsCross.armv7l-hf-multiplatform;
        in
        {
          packages = {
            linux = crossPkgs.callPackage ./kernel.nix { };
            uboot = crossPkgs.callPackage ./uboot.nix { };
            sdImage = self.nixosConfigurations.${system}.fpga.config.system.build.sdImage;
            system = self.nixosConfigurations.${system}.fpga.config.system.build.toplevel;
          };

          nixosConfigurations.fpga = nixpkgs.lib.nixosSystem {
            modules = [
              ({ pkgs, config, ... }: {
                # cross compile to armv7l-hf-multiplatform
                nixpkgs.buildPlatform = { system = "x86_64-linux"; };
                nixpkgs.hostPlatform = { system = "armv7l-linux"; config = "armv7l-unknown-linux-gnueabihf"; };
                boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.callPackage ./kernel.nix { });
                nixpkgs.overlays = [ self.overlays.default ];

                system.stateVersion = "23.05";
              })
              ./sd-image.nix
              ./fpga-sdimage.nix
              ./system.nix
            ];
          };
          devShells.default = pkgs.mkShell {
            OPENOCD = pkgs.openocd;
            buildInputs = with pkgs; [
              picocom
              dnsmasq
              sshfs
              openocd
              dtc
            ];
          };

        };
    in
    flake-utils.lib.eachDefaultSystem out // {
      overlays.default = import ./overlay.nix;
    };

}
