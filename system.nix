{ pkgs, kernel, lib, config, ... }:
{
  boot.initrd.includeDefaultModules = false;
  # due to all-hardware.nix being included, we have to ignore what it has to say
  # TODO: this is outdated, all-hardware.nix no longer there; need to verify
  # this is not required.
  boot.initrd.availableKernelModules = lib.mkForce [ "ext2" "ext4" ];

  # XXX: extremely evil hack to inject code into the bootloader install
  # process. This is not an activation script: it should be installed for
  # nixos-rebuild boot as well. system.build.installBootLoader is a
  # unique-definition option so it's not possible to override it, to my
  # knowledge? at least not with the previous value...
  #
  # This also breaks the generation system, but there's not much we can do
  # about that. The alternative to this villainy is to vendor
  # generic-extlinux-compatible, but that's more work.
  system.systemBuilderArgs = {
    installBootLoader = pkgs.writeShellScript "install-bootloader.sh" ''
      ${config.system.build.installBootLoader} $1
      cp ${pkgs.bootScript} /boot/u-boot.scr
    '';
  };

  environment.systemPackages = with pkgs; [
    (vim-full.override {
      features = "tiny";
      luaSupport = false;
      pythonSupport = false;
      rubySupport = false;
      cscopeSupport = false;
      netbeansSupport = false;
      ximSupport = false;
      guiSupport = false;
    })
  ];

  users.users.root = {
    initialPassword = "root";
  };

  documentation.enable = false;
}
