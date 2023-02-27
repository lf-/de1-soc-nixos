{ buildPackages, writeText, runCommandLocal }:
let
  # rbfFile = ./myconfig.rbf;

  # Extremely useful forum thread that helped so much with this:
  # https://forum.rocketboards.org/t/cyclonev-programming-fpga-from-u-boot/2230/23
  scriptSource = writeText "boot.txt" ''
    echo "NOT LOADING FPGA IMAGE, GO UNCOMMENT STUFF IN bootScript.nix";
  '' /*
    echo "loading fpga image from ${rbfFile}";
    ext4load mmc 0:2 ''${loadaddr} ${rbfFile};
    echo "size:";
    printenv filesize;
    fpga load 0 ''${loadaddr} ''${filesize}
    '' */;
in
runCommandLocal "u-boot.scr" { } ''
  ${buildPackages.ubootTools}/bin/mkimage -A arm -T script -d ${scriptSource} $out
''
