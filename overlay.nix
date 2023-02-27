final: prev: {
  u-boot-socfpga = final.callPackage ./uboot.nix { };
  bootScript = final.callPackage ./bootScript.nix { };
}
