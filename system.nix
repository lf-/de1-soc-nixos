{ pkgs, kernel, lib, ... }:
{
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
