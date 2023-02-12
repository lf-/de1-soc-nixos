# from nixpkgs: https://github.com/nixos/nixpkgs/blob/6c46f55495fcb048e624e18862db8422e4c70ee3/pkgs/os-specific/linux/kernel/linux-rpi.nix
{ stdenv, hostPlatform, lib, buildPackages, fetchFromGitHub, perl, buildLinux, linuxKernel, ... } @ args:

let
  modDirVersion = "5.15.50";
  tag = "de45b8accd27747b1f4db4cc5e2522ee338e3eee";

base = buildLinux (args // {
  version = "${modDirVersion}";
  inherit modDirVersion;
  extraMeta.branch = "5.15";

  src = fetchFromGitHub {
    owner = "altera-opensource";
    repo = "linux-socfpga";
    rev = tag;
    hash = "sha512-1HQhFMxYoDKVeJuNXygHSFAwC0Vjlv9GmSYJ034v5e+Z16oofmXfR+4/g44crT2qyL+QBVA0twzqtJfj9mliaQ==";
  };

  kernelPatches = [{
    name = "fix-nocache";
    patch = ./patches/linux/0001-Fix-compilation-_nocache-variants-are-gone-since-201.patch;
  }];

  defconfig = "socfpga_defconfig";

  features = {
    efiBootStub = false;
    iwlwifi = false;
  } // (args.features or { });
} // args.argsOverride or { });
in
linuxKernel.manualConfig {
  inherit stdenv;
  inherit (base) src version;
  configfile = ./socfpga_kconfig;
  allowImportFromDerivation = true;
}
