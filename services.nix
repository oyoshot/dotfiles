{ config, lib, pkgs, ... }:
{
  xdg.configFile."logrotate.d/nvim".text = ''
    ${config.xdg.stateHome}/nvim/lsp.log {
      size 16M
      rotate 7
      compress
      copytruncate
      missingok
      notifempty
      dateext
      dateformat -%Y%m%d-%H%M%S
    }
  '';

  systemd.user.services = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    logrotate-nvim = {
      Unit.Description = "Logrotate for Neovim LSP";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.logrotate}/bin/logrotate -s %h/.cache/logrotate.status %h/.config/logrotate.d/nvim";
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
        Environment = [ "DISPLAY=:0" "GALLIUM_DRIVER=d3d12" "XMODIFIERS=@im=fcitx" "GTK_IM_MODULE=fcitx" "QT_IM_MODULE=fcitx" ];
        ExecStart = "/usr/bin/fcitx5 --disable=waylandim,wayland,clipboard --replace";
        Restart = "always";
        RestartSec = "2s";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
  systemd.user.timers.logrotate-nvim = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    Unit.Description = "Daily logrotate for Neovim LSP";
    Timer = { OnCalendar = "daily"; Persistent = true; };
    Install.WantedBy = [ "timers.target" ];
  };
  launchd.agents.nvim-lsp-logrotate = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      Label = "com.oyoshot.nvim-lsp-logrotate";
      ProgramArguments = [ "/bin/bash" "-lc" "${config.home.homeDirectory}/.local/bin/nvim-lsp-logrotate.sh" ];
      StartCalendarInterval = { Hour = 3; Minute = 0; };
      RunAtLoad = true;
      StandardOutPath = "/dev/null";
      StandardErrorPath = "/dev/null";
    };
  };
}
