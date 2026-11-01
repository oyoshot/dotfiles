{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  ghosttyConfig = pkgs.writeText "ghostty-config" (
    builtins.readFile ./config/ghostty/config
    + "\n"
    + (
      if isDarwin then
        ''
          command = shell:/bin/sh -c "/bin/wait4path /nix/store && exec /bin/zsh -lc 'unset HERDR_ENV; exec herdr'"
        ''
      else
        ''
          command = zsh -lc "unset HERDR_ENV; exec herdr"
        ''
    )
  );
in
{
  # Restored macOS apps can start before the encrypted Nix volume is mounted.
  # Keep Ghostty's startup config readable then; its command waits before zsh.
  # Remove this copy when startup config can safely depend on the Nix store.
  home.activation.ghosttyConfig = lib.mkIf isDarwin (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      copyGhosttyConfig() (
        set -e
        target=${lib.escapeShellArg "${config.xdg.configHome}/ghostty/config"}
        source=${lib.escapeShellArg ghosttyConfig}
        if [[ ! -L "$target" ]] && ${pkgs.diffutils}/bin/cmp -s "$source" "$target"; then
          exit 0
        fi
        ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$target")"
        temporary=$(${pkgs.coreutils}/bin/mktemp "$target.XXXXXXXX")
        trap '${pkgs.coreutils}/bin/rm -f "$temporary"' EXIT
        ${pkgs.coreutils}/bin/install -m 0444 "$source" "$temporary"
        ${pkgs.coreutils}/bin/mv -fT "$temporary" "$target"
      )
      run copyGhosttyConfig
      unset -f copyGhosttyConfig
    ''
  );

  xdg.configFile = {
    # Follow the active generation without requiring a new login shell.
    "dotfiles/source".source = inputs.self.outPath;
    "alacritty" = {
      source = ./config/alacritty;
      recursive = true;
    };
    "atcoder-cli-nodejs" = {
      source = ./config/atcoder-cli-nodejs;
      recursive = true;
    };
    "claude" = {
      source = ./config/claude;
      recursive = true;
    };
    "codex" = {
      source = ./config/codex;
      recursive = true;
    };
    "cspell" = {
      source = ./config/cspell;
      recursive = true;
    };
    "ghostty/config" = lib.mkIf (!isDarwin) {
      source = ghosttyConfig;
    };
    "git" = {
      source = ./config/git;
      recursive = true;
    };
    "gwq" = {
      source = ./config/gwq;
      recursive = true;
    };
    "herdr" = {
      source = ./config/herdr;
      recursive = true;
    };
    "keras" = {
      source = ./config/keras;
      recursive = true;
    };
    "mcphub" = {
      source = ./config/mcphub;
      recursive = true;
    };
    "memo" = {
      source = ./config/memo;
      recursive = true;
    };
    "npm" = {
      source = ./config/npm;
      recursive = true;
    };
    "nvim" = {
      source = ./config/nvim;
      recursive = true;
    };
    "ripgrep/config" = {
      source = ./config/ripgrep/config;
    };
    "ruff" = {
      source = ./config/ruff;
      recursive = true;
    };
    "skhd" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      source = ./config/skhd;
      recursive = true;
    };
    "starship.toml" = {
      source = ./config/starship.toml;
    };
    "tmux" = {
      source = ./config/tmux;
      recursive = true;
    };
    "typos" = {
      source = ./config/typos;
      recursive = true;
    };
    "yabai" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      source = ./config/yabai;
      recursive = true;
    };
    "yay" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      source = ./config/yay;
      recursive = true;
    };
    "yazi" = {
      source = ./config/yazi;
      recursive = true;
    };
    "zacrs" = {
      source = ./config/zacrs;
      recursive = true;
    };
    "zsh" = {
      source = ./config/zsh;
      recursive = true;
    };
    "fcitx5" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      source = ./config/fcitx5;
      recursive = true;
    };
    # Nix gnupg looks for pinentry in its own output, which ships none.
    "gnupg/gpg-agent.conf".text =
      if pkgs.stdenv.hostPlatform.isDarwin then
        "pinentry-program ${pkgs.pinentry_mac}/bin/pinentry-mac\n"
      else
        "pinentry-program ${pkgs.pinentry-curses}/bin/pinentry-curses\n";
    "textlint/textlintrc".text =
      builtins.replaceStrings [ "@homeDirectory@" ] [ config.home.homeDirectory ]
        (builtins.readFile ./config/textlint/textlintrc.tmpl);
  };

  home.file = {
    ".zshenv".source = ./config/zsh/.zshenv;
    ".textlintrc".source = config.xdg.configFile."textlint/textlintrc".source;
    ".local/bin/acm" = {
      source = ./local/bin/acm;
    };
    ".local/bin/ghostty" = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && config.dotfiles.wsl) {
      executable = true;
      text =
        builtins.replaceStrings [ "@ghostty@" "@fcitxGtk@" ] [ "${pkgs.ghostty}" "${pkgs.fcitx5-gtk}" ]
          (builtins.readFile ./local/bin/ghostty);
    };
    ".local/bin/pbcopy" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      source =
        if config.dotfiles.wsl then
          pkgs.writeShellScript "pbcopy" ''
            exec ${config.home.file.".local/bin/win32yank.exe".source} -i --crlf
          ''
        else
          ./local/bin/pbcopy;
    };
    ".local/bin/pbpaste" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      source =
        if config.dotfiles.wsl then
          pkgs.writeShellScript "pbpaste" ''
            exec ${config.home.file.".local/bin/win32yank.exe".source} -o --lf
          ''
        else
          ./local/bin/pbpaste;
    };
    ".local/share/cargo/config.toml" = {
      source = ./local/share/cargo/config.toml;
    };
    ".local/bin/explorer.exe" = lib.mkIf config.dotfiles.wsl {
      source = config.lib.file.mkOutOfStoreSymlink "/mnt/c/Windows/explorer.exe";
    };
    ".local/bin/rundll32.exe" = lib.mkIf config.dotfiles.wsl {
      source = config.lib.file.mkOutOfStoreSymlink "/mnt/c/Windows/System32/rundll32.exe";
    };
    ".local/share/applications/com.mitchellh.ghostty.desktop" = lib.mkIf config.dotfiles.wsl {
      # WSLg receives a copy during activation; keep its paths stable across updates.
      text =
        builtins.replaceStrings
          [ "@homeDirectory@" "@ghosttyIcon@" ]
          [
            config.home.homeDirectory
            "${config.home.profileDirectory}/share/icons/hicolor/256x256/apps/com.mitchellh.ghostty.png"
          ]
          (builtins.readFile ./local/share/applications/com.mitchellh.ghostty.desktop.tmpl);
    };
    "Library/Preferences/atcoder-cli" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      source = ./config/atcoder-cli-nodejs;
      recursive = true;
    };
    "Library/Application Support/ruff/pyproject.toml" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      source = ./config/ruff/pyproject.toml;
    };
  };
}
