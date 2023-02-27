# Based on https://github.com/nixos/nixpkgs/blob/6bfaed9b2c691a93933ce3bc4a9f3c41c45becf2/nixos/modules/installer/sd-card/sd-image-armv7l-multiplatform.nix#L1-L52
{ config, lib, pkgs, modulesPath, ... }:

{
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible = {
    enable = true;
    # use the device tree from the bootloader, since the generation does not
    # likely have the right device tree (there is no de1-soc one in the
    # kernel)?
    useGenerationDeviceTree = false;
  };

  boot.consoleLogLevel = lib.mkDefault 7;
  boot.kernelParams = [ "console=ttyS0,115200n8" ];

  sdImage = {
    compressImage = false;
    # expand the rootfs on initial boot
    expandOnBoot = true;
    bootloaderSpl = "${pkgs.u-boot-socfpga}/u-boot-with-spl.sfp";
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };
}
