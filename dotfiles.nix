{ config, lib, pkgs, ... }:

{
  xdg.configFile = {
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
    "ghostty" = {
      source = ./config/ghostty;
      recursive = true;
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
    "homebrew" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      source = ./config/homebrew;
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
    "ripgrep" = {
      source = ./config/ripgrep;
      recursive = true;
    };
    "ruff" = {
      source = ./config/ruff;
      recursive = true;
    };
    "rye" = {
      source = ./config/rye;
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
    "gnupg/gpg-agent.conf".text =
      lib.optionalString pkgs.stdenv.hostPlatform.isDarwin
        "pinentry-program ${pkgs.pinentry_mac}/bin/pinentry-mac\n";
    "textlint/textlintrc".text = builtins.replaceStrings
      [ "@homeDirectory@" ] [ config.home.homeDirectory ]
      (builtins.readFile ./config/textlint/textlintrc.tmpl);
  };

  home.file = {
    ".zshenv".source = ./config/zsh/.zshenv;
    ".textlintrc".source = config.xdg.configFile."textlint/textlintrc".source;
    ".local/bin/acm" = { source = ./local/bin/acm; };
    ".local/bin/ghostty" = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && config.dotfiles.wsl) {
      executable = true;
      text = builtins.replaceStrings [ "@ghostty@" "@fcitxGtk@" ]
        [ "${pkgs.ghostty}" "${pkgs.fcitx5-gtk}" ] (builtins.readFile ./local/bin/ghostty);
    };
    ".local/bin/nvim-lsp-logrotate.sh" = { source = ./local/bin/nvim-lsp-logrotate.sh; };
    ".local/bin/pbcopy" = { source = ./local/bin/pbcopy; };
    ".local/bin/pbpaste" = { source = ./local/bin/pbpaste; };
    ".local/share/cargo/config.toml" = { source = ./local/share/cargo/config.toml; };
    ".local/bin/explorer.exe" = lib.mkIf config.dotfiles.wsl {
      source = config.lib.file.mkOutOfStoreSymlink "/mnt/c/Windows/explorer.exe";
    };
    ".local/bin/rundll32.exe" = lib.mkIf config.dotfiles.wsl {
      source = config.lib.file.mkOutOfStoreSymlink "/mnt/c/Windows/System32/rundll32.exe";
    };
    ".local/share/applications/com.mitchellh.ghostty.desktop" = lib.mkIf config.dotfiles.wsl {
      # WSLg receives a copy during activation; keep its paths stable across updates.
      text = builtins.replaceStrings
        [ "@homeDirectory@" "@ghosttyIcon@" ]
        [ config.home.homeDirectory "${config.home.profileDirectory}/share/icons/hicolor/256x256/apps/com.mitchellh.ghostty.png" ]
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
