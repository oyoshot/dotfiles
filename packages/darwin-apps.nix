# Package supply only; Home Manager copyApps deploys the bundles.
{ pkgs, inputs }:
let
  casks = inputs.brew-nix.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  "1Password.app" = pkgs._1password-gui;
  "ChatGPT.app" = pkgs.chatgpt;
  "Firefox.app" = pkgs.firefox-bin;
  "Google Chrome.app" = pkgs.google-chrome;
  "Ghostty.app" = pkgs.ghostty-bin;
  "Notion.app" = pkgs.notion-app;
  "Podman Desktop.app" = pkgs.podman-desktop;
  "WezTerm.app" = pkgs.wezterm;
  # Cask metadata is pinned independently through the brew-api input.
  "Notion Calendar.app" = casks.notion-calendar;
  "JupyterLab.app" = casks.jupyterlab-app;
}
