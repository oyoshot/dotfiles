{ config, lib, pkgs, ... }:
{
  imports = [ ./dotfiles.nix ./externals.nix ./services.nix ];
  options.dotfiles.wsl = lib.mkEnableOption "WSLg desktop integration";
  config = {
    programs.home-manager.enable = true;
    home.stateVersion = "25.11";
    nix.package = pkgs.nix;
    nix.settings.use-xdg-base-directories = true;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    # The new nix.conf is linked after package installation on the first switch.
    home.activation.nixXdg = lib.hm.dag.entryBetween [ "installPackages" "linkGeneration" ] [ "writeBoundary" ] ''
      export XDG_STATE_HOME=${lib.escapeShellArg config.xdg.stateHome}
      unset NIX_PROFILE
      export NIX_CONFIG="''${NIX_CONFIG-}
      use-xdg-base-directories = true"
      run ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg "${config.xdg.stateHome}/nix/profiles"}
    '';
    home.activation.herdrIntegrations = lib.hm.dag.entryAfter [ "linkGeneration" "installPackages" ] ''
      run ${pkgs.coreutils}/bin/env \
        XDG_CONFIG_HOME=${lib.escapeShellArg config.xdg.configHome} \
        XDG_DATA_HOME=${lib.escapeShellArg config.xdg.dataHome} \
        XDG_STATE_HOME=${lib.escapeShellArg config.xdg.stateHome} \
        CODEX_HOME=${lib.escapeShellArg "${config.xdg.configHome}/codex"} \
        CLAUDE_CONFIG_DIR=${lib.escapeShellArg "${config.xdg.configHome}/claude"} \
        PATH=${config.home.path}/bin:${lib.makeBinPath [ pkgs.coreutils pkgs.gnugrep ]}:$PATH \
        ${pkgs.runtimeShell} ${./scripts/setup-herdr.sh}
    '';
  };
}
