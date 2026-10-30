{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  xdg.configFile = {
    "tmux/plugins/tpm" = {
      source = inputs.tpm;
      recursive = true;
    };
    "zsh/plugins/zsh-defer" = {
      source = inputs.zsh-defer;
      recursive = true;
    };
    "zsh/plugins/zsh-completions" = {
      source = inputs.zsh-completions;
      recursive = true;
    };
    "zsh/plugins/anyframe" = {
      source = inputs.anyframe;
      recursive = true;
    };
    "zsh/plugins/autosuggestions" = {
      source = inputs.autosuggestions;
      recursive = true;
    };
    "zsh/plugins/syntax-highlighting" = {
      source = inputs.syntax-highlighting;
      recursive = true;
    };
    "zsh/plugins/zsh-history-substring-search" = {
      source = inputs.zsh-history;
      recursive = true;
    };
    "zsh/plugins/ni.zsh".source = "${inputs.ni-zsh}/ni.zsh";
    "zsh/fpath/aws_zsh_completer.sh".source = "${pkgs.awscli2.src}/bin/aws_zsh_completer.sh";
    "prh-rules/media/WEB+DB_PRESS.yml".source = "${inputs.prh-rules}/media/WEB+DB_PRESS.yml";
    "alacritty/alacritty-theme" = {
      source = inputs.alacritty-theme;
      recursive = true;
    };
  };
  home.file.".local/bin/win32yank.exe" = lib.mkIf config.dotfiles.wsl {
    source =
      let
        manifest = builtins.fromJSON (builtins.readFile "${inputs.scoop-main}/bucket/win32yank.json");
        release = manifest.architecture."64bit";
        src = pkgs.fetchurl {
          inherit (release) url;
          sha256 = release.hash;
        };
      in
      pkgs.runCommand "win32yank-${manifest.version}.exe" { nativeBuildInputs = [ pkgs.unzip ]; } ''
        unzip -p ${src} win32yank.exe > "$out"
        chmod +x "$out"
      '';
  };
}
