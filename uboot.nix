{ buildUBoot, fetchFromGitHub }:
buildUBoot {
  src = fetchFromGitHub {
    owner = "altera-opensource";
    repo = "u-boot-socfpga";
    rev = "639a1ac83230d569ce5c6ed9960e40fc52b4d7fe";
    sha256 = "sha256-Yfjq+k7MRc5BuXdxqOUI1vp1vrE0AlgIe8ZHnooDy6o=";
  };
  version = "socfpga_22.04";

  defconfig = "socfpga_de1_soc_defconfig";
  filesToInstall = [ "spl/u-boot-spl" "u-boot" "u-boot-with-spl.sfp" ];
  extraConfig = ''
    CONFIG_USE_BOOTCOMMAND=y
    CONFIG_BOOTCOMMAND="if ext4load mmc 0:2 ''${scriptaddr} /boot/u-boot.scr; then source ''${scriptaddr}; fi; bridge enable; run distro_bootcmd"
  '';

  extraPatches = [
    # https://lists.denx.de/pipermail/u-boot/2023-February/508674.html
    ./patches/u-boot/0001-socfpga-fix-the-serial-console-on-DE1-SoC.patch
    # Linux was rebooting after a few seconds. This is unclear whether it
    # should actually be in u-boot, since it's only relevant to Linux, and
    # perhaps Linux should transition to a different device tree. It's done
    # this way because it's Easier(tm) but we might change it.
    ./patches/u-boot/0002-Enable-the-watchdog-is-this-a-good-idea.patch
  ];
}

