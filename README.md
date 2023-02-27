# NixOS for the Terasic DE1-SoC Cyclone V dev board

## Why?

I don't want to learn Yocto, and it seems like Nix is the easy way to build a
custom Linux image with patches.

## What is going on here?

This is lightly based off of the [Cyclone V SoC
GSRD](https://www.rocketboards.org/foswiki/Documentation/CycloneVSoCGSRD),
which describes how to build an image for a different board. I acquired that
image and put it on my board and it didn't output anything on serial (dammit),
so I realized I was in for just doing the whole thing myself, not that I
expected better.

The images available from the board vendor Terasic are ancient (Ubuntu 16.04 is
the latest), so they are not worth using. Thus, I am here porting a different
distro because it's the same amount of work and more reusable than doing it
with Yocto.

## Boot process

Resources:
* https://www.rocketboards.org/foswiki/Documentation/BuildingBootloaderCycloneVAndArria10

In the configuration used here (see Cyclone V Hard Processor System
Technical Reference Manual, version 20.1 page A-13 to A-14), the boot process
is using the MBR mode.

The boot ROM will find a partition of type 0xA2, which it will load 64kb of
into memory (the tiny OCRAM, not DDR3) and jump to. There are four copies of
the second phase loader/"preloader" (U-Boot SPL) in this partition.

U-Boot SPL will configure various devices, initialize the SDRAM and then start
U-Boot, which is also on the same partition.

U-Boot will execute `/boot/u-boot.scr`, enable the FPGA bridge, then load the
kernel image and initrd per `/boot/extlinux/extlinux.conf`.

> **Note**: Currently I use the device tree from U-Boot which will continue
> into Linux. This is subject to revision, since it seems annoying to put that
> into the bootloader partition that won't get updated with the NixOS system.

This is all built out using a patched version of sd-image.nix from nixpkgs.
My patches make a SD image for the device in one shot, rather than requiring
later modification to add the bootloader.

## Patches

### Linux

I patched the use of a function that was removed in 2019, leading to
linux-socfpga just not building on socfpga_defconfig. I have no idea what is
the deal there so I just fixed it.

The kconfig here is the socfpga_defconfig plus some entries required by
systemd/NixOS. It's pretty minimal.

You can hack on the kconfig with (FIXME probably shouldn't use qt5.full but
it's the one that was most obvious):

```
[acquire linux-socfpga]

$ nix-shell -p pkgsCross.armv7l-hf-multiplatform.stdenv.cc stdenv gmp mpfr libmpc ncurses qt5.full --run zsh
$ make socfpga_defconfig ARCH=arm CROSS_COMPILE="armv7l-unknown-linux-gnueabihf-"
$ make xconfig ARCH=arm CROSS_COMPILE="armv7l-unknown-linux-gnueabihf-"
```

### U-Boot

There are two critical bugs I patched in the device tree shipped by U-Boot for
DE1-SoC that render the system unusable:

* The frequency of the UART device is unspecified, which means that even the
  SPL can't output anything on serial. I found this in a forum post from
  mid-2021.
* The watchdog0 is marked "disabled" in the u-boot device tree for the
  DE1-SoC. This was done by upstream since it *should* probably be marked
  disabled for U-Boot, but Linux *needs* to enable it, and so the system would
  reboot due to watchdog after 10 seconds or so.

  This is not the best way to fix this, and it is likely that we will start
  using device trees shipped by NixOS instead.

# Usage

## Important notes

I have commented out the FPGA loading in `bootScript.nix`, since I don't have a
suitable FPGA image to offer. For this purpose I suggest starting from the
DE1-SoC GHRD [from the CD][de1-cd], as it contains various things that are not
conveniently written down such as DDR3 timings and so on, which it has
conveniently put into the qsys file for you, along with all the various wires
you have to do in the top level file.

I will note that the top level file in there does use some very old IP and
functionality. It's likely some of it could be cleaned up if one were
so motivated, but start from it since it definitely works.

[de1-cd]: https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=836&PartNo=4

See also: https://github.com/u-boot/u-boot/blob/master/doc/README.socfpga

To build a `.rbf` image which you need to program the FPGA in u-boot, use
`quartus_cpf -c whatever.sof whatever.rbf`.

### Known bugs

* I haven't done anything about the fact that the Nix setup is kinda hardcoded
  to x86_64-linux right now. Just patch it if you are building from a more fun
  architecture.

## Hardware setup

Set MSEL to `4'b0000`: all DIP switches "ON" (sic!). This enables u-boot to
program the FPGA fabric.

Per the DE1-SoC manual:

> "FPGA configured from HPS software: U-Boot, with FPPx16 image stored on the
> SD card, like LXDE Desktop or console Linux with frame buffer edition."

Source: https://forum.rocketboards.org/t/cyclonev-programming-fpga-from-u-boot/2230/24

## Program to SD

```
$ nix build .#sdImage
$ sudo dd of=/dev/YOUR_SD_CARD_PROBABLY_mmcblk0 if=result/sd-image/nixos-*.img bs=1M status=progress
```

## Connect to serial

Attach your computer to the *mini USB* on the board (*not* the USB type B; that
one is JTAG).

```
$ picocom -q -b 115200 /dev/ttyUSB0
```

## Deploying via the network

Add your ssh keys to the configuration for root:

```nix
{
  # ...
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNldAg4t13/i69TD786The+U3wbiNUdW2Kc9KNWvEhgpf4y4x4Sft0oYfkPw5cjX4H3APqfD+b7ItAG0GCbwHw6KMYPoVMNK08zBMJUqt1XExbqGeFLqBaeqDsmEAYXJRbjMTAorpOCtgQdoCKK/DvZ51zUWXxT8UBNHSl19Ryv5Ry5VVdbAE35rqs57DQ9+ma6htXnsBEmmnC+1Zv1FE956m/OpBTId50mor7nS2FguAtPZnDPpTd5zl9kZmJEuWCrmy6iinw5V4Uy1mLeZkQv+/FtozbyifCRCvps9nHpv4mBSU5ABLgnRRvXs+D41Jx7xloNADr1nNgpsNrYaTh hed-bot-ssh-tpm-rsa"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIKYljH8iPMrH00lOb3ETxRrZimdKzPPEdsJQ5D5ovtOwAAAACnNzaDpzc2hrZXk= ssh:sshkey"
    ];
  };
}
```

Then you can use `deploy your-de1-ip-address` to deploy.

This desugars to:

```
NIX_SSHOPTS="-l root" nixos-rebuild switch --target-host your-de1-ip-address --fast --flake .#fpga
```

## It works!

```
U-Boot SPL 2022.04 (Jan 01 1980 - 00:00:00 +0000)
Trying to boot from MMC1


U-Boot 2022.04 (Jan 01 1980 - 00:00:00 +0000)

CPU:   Altera SoCFPGA Platform
FPGA:  Altera Cyclone V, SE/A5 or SX/C5 or ST/D5, version 0x0
BOOT:  SD/MMC Internal Transceiver (3.0V)
       Watchdog enabled
DRAM:  1 GiB
Core:  21 devices, 12 uclasses, devicetree: separate
MMC:   dwmmc0@ff704000: 0
Loading Environment from MMC... *** Warning - bad CRC, using default environment

In:    serial
Out:   serial
Err:   serial
Model: Terasic DE1-SoC
Net:
Error: ethernet@ff702000 address not set.
No ethernet found.

=>
=> run bootcmd_mmc0
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:2...
Found /boot/extlinux/extlinux.conf
Retrieving file: /boot/extlinux/extlinux.conf
1:	NixOS - Default
Retrieving file: /boot/extlinux/../nixos/666zyfzbbm1pmnpx25pjvbp6blaw240w-initrd-linux-armv7l-unknown-linux-gnueabihf-5.15.50-initrd
Retrieving file: /boot/extlinux/../nixos/i0q6qrpxn6s9niw07zl12xiklnb82q6y-linux-armv7l-unknown-linux-gnueabihf-5.15.50-zImage
append: init=/nix/store/4l6xz4cqhk4wyamlipvhw2gz5kzrj8h1-nixos-system-nixos-23.05.20230131.e1e1b19/init console=ttyS0,115200n8 loglevel=7
Kernel image @ 0x1000000 [ 0x000000 - 0x56d200 ]
## Flattened Device Tree blob at 3bf90630
   Booting using the fdt blob at 0x3bf90630
   Loading Ramdisk to 0978f000, end 09fffa07 ... OK
   Loading Device Tree to 09787000, end 0978e88f ... OK

Starting kernel ...

Deasserting all peripheral resets
[    0.000000] Booting Linux on physical CPU 0x0
[    0.000000] Linux version 5.15.50 (nixbld@localhost) (armv7l-unknown-linux-gnueabihf-gcc (GCC) 11.3.0, GNU ld (GNU Binutils) 2.39) #1-NixOS SMP Tue Jan 1 00:00:00 UTC 1980
[    0.000000] CPU: ARMv7 Processor [413fc090] revision 0 (ARMv7), cr=10c5387d
[    0.000000] CPU: PIPT / VIPT nonaliasing data cache, VIPT aliasing instruction cache
[    0.000000] OF: fdt: Machine model: Terasic DE1-SoC
[    0.000000] Memory policy: Data cache writealloc
[    0.000000] efi: UEFI not found.
```

