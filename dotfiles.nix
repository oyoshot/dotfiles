{ config, lib, pkgs, ... }:

let
  inherit (lib) hasPrefix hasSuffix removePrefix removeSuffix;

  decodeName = name:
    if hasPrefix "dot_" name then ".${removePrefix "dot_" name}"
    else if hasPrefix "private_" name then removePrefix "private_" name
    else if hasPrefix "executable_" name then removePrefix "executable_" name
    else name;

  decodePath = path:
    lib.concatStringsSep "/" (map decodeName (lib.splitString "/" path));

  collectFiles = sourceRoot: targetRoot:
    let
      walk = relative: dir:
        lib.concatMap
          (name:
            let
              kind = (builtins.readDir dir).${name};
              source = dir + "/${name}";
              child = if relative == "" then name else "${relative}/${name}";
            in
            if kind == "directory" then walk child source
            else if hasSuffix ".tmpl" name || hasPrefix "symlink_" name then [ ]
            else [ {
              name = "${targetRoot}/${decodePath child}";
              value = {
                inherit source;
                force = true;
                executable = hasPrefix "executable_" name;
              };
            } ])
          (builtins.attrNames (builtins.readDir dir));
    in
    walk "" sourceRoot;

  commonFiles =
    collectFiles ./dot_config ".config"
    ++ collectFiles ./dot_local ".local";
  darwinFiles = collectFiles ./private_Library "Library";

  fcitxProfile = pkgs.writeText "fcitx5-profile" (builtins.replaceStrings
    [ ''{{ "\n" -}}'' ]
    [ "" ]
    (builtins.readFile ./dot_config/private_fcitx5/private_profile.tmpl));
  gpgAgentConfig = pkgs.writeText "gpg-agent.conf"
    (lib.optionalString pkgs.stdenv.hostPlatform.isDarwin
      "pinentry-program /opt/homebrew/bin/pinentry-mac\n");

  keepForPlatform = entry:
    let target = entry.name;
    in
    if pkgs.stdenv.hostPlatform.isDarwin then
      !(hasPrefix ".config/fcitx5/" target
        || hasPrefix ".config/systemd/" target
        || hasPrefix ".config/yay/" target
        || hasPrefix ".local/share/applications/" target)
    else
      !(hasPrefix ".config/homebrew/" target
        || hasPrefix ".config/skhd/" target
        || hasPrefix ".config/yabai/" target);

  generatedFiles = {
    ".zshenv" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/zsh/.zshenv";
      force = true;
    };
    ".textlintrc" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/textlint/textlintrc";
      force = true;
    };
    ".config/fcitx5/profile" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      source = fcitxProfile;
      force = true;
    };
    ".config/gnupg/gpg-agent.conf" = {
      source = gpgAgentConfig;
      force = true;
    };
    ".config/textlint/textlintrc" = {
      text = builtins.replaceStrings
        [ "{{ .chezmoi.homeDir }}" ]
        [ config.home.homeDirectory ]
        (builtins.readFile ./dot_config/textlint/textlintrc.tmpl);
      force = true;
    };
    ".local/share/applications/com.mitchellh.ghostty.desktop" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      text = builtins.replaceStrings
        [ "{{ .chezmoi.homeDir }}" ]
        [ config.home.homeDirectory ]
        (builtins.readFile ./dot_local/share/applications/com.mitchellh.ghostty.desktop.tmpl);
      force = true;
    };
    "Library/LaunchAgents/com.oyoshot.nvim-lsp-logrotate.plist" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      source = ./private_Library/LaunchAgents/com.oyoshot.nvim-lsp-logrotate.plist.tmpl;
      force = true;
    };
    "Library/Preferences/atcoder-cli" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/atcoder-cli-nodejs";
      force = true;
    };
    "Library/Application Support/ruff/pyproject.toml" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/ruff/pyproject.toml";
      force = true;
    };
  };
in
{
  home.file = builtins.listToAttrs
    (builtins.filter keepForPlatform (commonFiles ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin darwinFiles))
    // generatedFiles;

  home.activation.dotfilePermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    chmod 700 "$HOME/.config/gnupg" "$HOME/.config/memo" 2>/dev/null || true
    install -m 600 ${./dot_config/private_memo/config.toml} "$HOME/.config/memo/config.toml"
    install -m 600 ${gpgAgentConfig} "$HOME/.config/gnupg/gpg-agent.conf"
    ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
      install -m 600 ${fcitxProfile} "$HOME/.config/fcitx5/profile"
    ''}
  '';
}
