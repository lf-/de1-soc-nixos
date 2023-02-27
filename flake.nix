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
            sdImage = self.nixosConfigurations.fpga.config.system.build.sdImage;
            system = self.nixosConfigurations.fpga.config.system.build.toplevel;
            deploy = pkgs.writeShellScriptBin "deploy" ''
              if [[ $# != 1 ]]; then
                echo "Usage: $0 IP_ADDR"
                exit 1
              fi
              NIX_SSHOPTS="-l root" ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --target-host $1 --fast --flake .#fpga
            '';
          };

          devShells.default = pkgs.mkShellNoCC {
            OPENOCD = pkgs.openocd;
            buildInputs = with pkgs; [
              picocom
              dnsmasq
              sshfs
              openocd
              dtc

              clang-tools
              ubootTools
              gdb
              nixos-rebuild
              self.packages.${system}.deploy
            ];
          };

        };
    in
    flake-utils.lib.eachDefaultSystem out // {
      overlays.default = import ./overlay.nix;

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
    };

}
