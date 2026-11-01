{
  config,
  lib,
  pkgs,
  ...
}:
let
  nvimLogrotateArgs = [
    "${pkgs.logrotate}/bin/logrotate"
    "-s"
    "${config.xdg.cacheHome}/logrotate.status"
    "${config.xdg.configHome}/logrotate.d/nvim"
  ];
  nvimLogrotate = pkgs.writeShellScript "nvim-logrotate" ''
    set -eu
    ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg config.xdg.cacheHome}
    exec ${lib.escapeShellArgs nvimLogrotateArgs}
  '';
in
{
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.yabai ];
  services.skhd = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    errorLogFile = "${config.home.homeDirectory}/Library/Logs/skhd.err.log";
    outLogFile = "${config.home.homeDirectory}/Library/Logs/skhd.out.log";
  };
  launchd.agents = {
    skhd = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      restartTriggers = [ ./config/skhd/skhdrc ];
      config.EnvironmentVariables = {
        PATH = "${config.home.profileDirectory}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        XDG_CONFIG_HOME = config.xdg.configHome;
      };
    };
    yabai = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      restartTriggers = [ ./config/yabai/yabairc ];
      config = {
        ProgramArguments = [
          "${pkgs.yabai}/bin/yabai"
          "--config"
          "${config.xdg.configHome}/yabai/yabairc"
        ];
        EnvironmentVariables.PATH = "${config.home.profileDirectory}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        ProcessType = "Interactive";
        KeepAlive = true;
        RunAtLoad = true;
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/yabai.err.log";
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/yabai.out.log";
      };
    };
    nvim-lsp-logrotate = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      config = {
        Label = "com.oyoshot.nvim-lsp-logrotate";
        ProgramArguments = [ "${nvimLogrotate}" ];
        StartCalendarInterval = {
          Hour = 3;
          Minute = 0;
        };
        RunAtLoad = true;
        StandardOutPath = "/dev/null";
        StandardErrorPath = "/dev/null";
      };
    };
  };
  i18n.inputMethod = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = [ pkgs.fcitx5-mozc ];
      # Keep the existing WSLg unit and its frontend restrictions.
      systemd.enable = lib.mkIf config.dotfiles.wsl false;
      fcitx5-with-addons = lib.mkIf config.dotfiles.wsl (
        pkgs.qt6Packages.fcitx5-with-addons.override {
          fcitx5 = pkgs.fcitx5.overrideAttrs (old: {
            # Preserve the existing workaround until microsoft/wslg#1495 is fixed.
            patches = (old.patches or [ ]) ++ [
              ./.workarounds/REMOVE_WHEN_WSLG_1495_IS_FIXED/wslg-keep-candidate-window-mapped.patch
            ];
          });
        }
      );
    };
  };
  xdg.configFile."logrotate.d/nvim".text =
    builtins.replaceStrings
      [ "@stateHome@" "@dateSeparator@" ]
      [
        config.xdg.stateHome
        (if pkgs.stdenv.hostPlatform.isDarwin then "." else "-")
      ]
      (builtins.readFile ./config/logrotate/nvim.conf.tmpl);

  systemd = {
    user.services = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      logrotate-nvim = {
        Unit.Description = "Logrotate for Neovim LSP";
        Service = {
          Type = "oneshot";
          ExecStart = "${nvimLogrotate}";
        };
      };
      fcitx5-wslg = lib.mkIf config.dotfiles.wsl {
        Unit = {
          Description = "Fcitx 5 input method for WSLg";
          ConditionPathExists = "/dev/dxg";
          Wants = [ "wslg-session.service" ];
          After = [ "wslg-session.service" ];
        };
        Service = {
          Type = "simple";
          Environment = [
            "DISPLAY=:0"
            "GALLIUM_DRIVER=d3d12"
            "XMODIFIERS=@im=fcitx"
            "GTK_IM_MODULE=fcitx"
            "QT_IM_MODULE=fcitx"
          ];
          ExecStart = "${config.i18n.inputMethod.package}/bin/fcitx5 --disable=waylandim,wayland,clipboard --replace";
          Restart = "always";
          RestartSec = "2s";
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
    user.timers.logrotate-nvim = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit.Description = "Daily logrotate for Neovim LSP";
      Timer = {
        OnCalendar = "daily";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
