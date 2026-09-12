{ config, lib, pkgs, ... }:
{
  imports = [ ./dotfiles.nix ./externals.nix ./services.nix ];
  options.dotfiles.wsl = lib.mkEnableOption "WSLg desktop integration";
  config = {
    programs.home-manager.enable = true;
    home.stateVersion = "25.11";
    programs.mise = {
      enable = true;
      enableMutableConfig = true;
      # The existing .zshrc coordinates mise and direnv with one deferred hook.
      enableZshIntegration = false;
      enableBashIntegration = false;
      enableFishIntegration = false;
      globalConfig.settings = {
        experimental = true;
        idiomatic_version_file_enable_tools = [ "terraform" "node" "python" "rust" ];
        npm.bun = true;
      };
    };
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = false;
      enableBashIntegration = false;
      enableFishIntegration = false;
      stdlib = ''
        # A broken shell must not silently keep the previous toolchain.
        nix_direnv_disallow_fallback
      '';
    };
    # linkGeneration removes the previous HM-managed config.toml symlink.
    # Seed only missing files; subsequent switches preserve mise use --global.
    home.activation.miseInitialTools = lib.hm.dag.entryBetween
      [ "miseMutableConfig" ] [ "linkGeneration" ] ''
        if [[ ! -e ${lib.escapeShellArg "${config.xdg.configHome}/mise/config.toml"} && ! -L ${lib.escapeShellArg "${config.xdg.configHome}/mise/config.toml"} ]]; then
          run ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg "${config.xdg.configHome}/mise"}
          run ${pkgs.coreutils}/bin/install -m 600 ${./config/mise/config.toml} ${lib.escapeShellArg "${config.xdg.configHome}/mise/config.toml"}
        fi
      '';
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
