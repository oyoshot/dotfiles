{ lib, ... }:
{
  imports = [ ./dotfiles.nix ./externals.nix ./services.nix ];
  options.dotfiles.wsl = lib.mkEnableOption "WSLg desktop integration";
  config = {
    programs.home-manager.enable = true;
    home.stateVersion = "25.11";
  };
}
