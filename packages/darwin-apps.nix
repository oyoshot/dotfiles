# Package supply only; Home Manager deploys 1Password separately from copyApps.
{ pkgs, inputs }:
let
  casks = inputs.brew-nix.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  # Avoid downgrading the existing installation during migration.
  # Remove this override once pinned nixpkgs supplies 8.12.42 or later.
  "1Password.app" =
    if pkgs.lib.versionAtLeast pkgs._1password-gui.version "8.12.42" then
      pkgs._1password-gui
    else
      pkgs._1password-gui.overrideAttrs {
        version = "8.12.42";
        src = pkgs.fetchurl {
          url = "https://downloads.1password.com/mac/1Password-8.12.42-aarch64.zip";
          hash = "sha256-TN+8YPp8tdQyGBd/uIt89AnH9Y9LMJLyzajwNMXuz5o=";
        };
      };
  "ChatGPT.app" = casks.chatgpt;
  # macOS 27 restricts profile data to Mozilla-signed apps (nixpkgs#535123).
  # Keep the vendor bundle until wrapped firefox-bin preserves that identity.
  "Firefox.app" = pkgs.firefox-bin-unwrapped;
  "Google Chrome.app" = pkgs.google-chrome;
  "Ghostty.app" = pkgs.ghostty-bin;
  "Notion.app" = casks.notion;
  "Podman Desktop.app" = casks.podman-desktop;
  "WezTerm.app" = pkgs.wezterm;
  # Cask metadata is pinned independently through the brew-api input.
  "Notion Calendar.app" = casks.notion-calendar;
  "JupyterLab.app" = casks.jupyterlab-app;
  # Docker Desktop owns first-run setup, contexts and optional privileged helpers.
  "Docker.app" = casks.docker-desktop;
}
