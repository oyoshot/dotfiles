{ config, lib, pkgs, ... }:
{
  imports = [ ./dotfiles.nix ./externals.nix ./services.nix ];
  options.dotfiles.wsl = lib.mkEnableOption "WSLg desktop integration";
  config = {
    programs.home-manager.enable = true;
    home.stateVersion = "25.11";
    home.activation.herdrIntegrations = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      if [ "${lib.boolToString pkgs.stdenv.hostPlatform.isDarwin}" = true ] && [ -e "$HOME/.nix-profile" ]; then
        ${pkgs.coreutils}/bin/mkdir -p "${config.xdg.stateHome}/nix/profiles/home-manager"
        ${pkgs.coreutils}/bin/ln -sfn "$HOME/.nix-profile" "${config.xdg.stateHome}/nix/profiles/home-manager/home-path"
      fi
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
