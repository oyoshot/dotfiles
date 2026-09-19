{ config, lib, pkgs, inputs, ... }:
{
  xdg.configFile = {
    "tmux/plugins/tpm" = { source = inputs.tpm; recursive = true; };
    "zsh/plugins/zsh-defer" = { source = inputs.zsh-defer; recursive = true; };
    "zsh/plugins/zsh-completions" = { source = inputs.zsh-completions; recursive = true; };
    "zsh/plugins/anyframe" = { source = inputs.anyframe; recursive = true; };
    "zsh/plugins/autosuggestions" = { source = inputs.autosuggestions; recursive = true; };
    "zsh/plugins/syntax-highlighting" = { source = inputs.syntax-highlighting; recursive = true; };
    "zsh/plugins/zsh-history-substring-search" = { source = inputs.zsh-history; recursive = true; };
    "zsh/plugins/ni.zsh".source = "${inputs.ni-zsh}/ni.zsh";
    "zsh/fpath/aws_zsh_completer.sh".source = "${pkgs.awscli2.src}/bin/aws_zsh_completer.sh";
    "prh-rules/media/WEB+DB_PRESS.yml".source = "${inputs.prh-rules}/media/WEB+DB_PRESS.yml";
    "alacritty/alacritty-theme" = { source = inputs.alacritty-theme; recursive = true; };
  };
  home.file.".local/bin/win32yank.exe" = lib.mkIf config.dotfiles.wsl {
    source = pkgs.runCommand "win32yank.exe" { nativeBuildInputs = [ pkgs.unzip ]; } ''
      unzip -p ${pkgs.fetchurl {
        url = "https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip";
        hash = "sha256-JHyaBblDh6iEtJ09sT+AaxZ338OAIPlV9xm+aQImDNY=";
      }} win32yank.exe > "$out"
      chmod +x "$out"
    '';
  };
}
