# Package supply only; Home Manager deploys 1Password separately from copyApps.
{ pkgs, inputs }:
let
  casks = inputs.brew-nix.packages.${pkgs.stdenv.hostPlatform.system};

in
{
  "Alacritty.app" = pkgs.alacritty;
  "1Password.app" = pkgs._1password-gui;
  "ChatGPT.app" = casks.chatgpt;
  "Discord.app" = casks.discord;
  "Figma.app" = casks.figma;
  # macOS 27 restricts profile data to Mozilla-signed apps (nixpkgs#535123).
  # Keep the vendor bundle until wrapped firefox-bin preserves that identity.
  "Firefox.app" = pkgs.firefox-bin-unwrapped;
  "Google Chrome.app" = pkgs.google-chrome;
  # The installer also contains Microsoft AutoUpdate; deploy only Teams.
  "Microsoft Teams.app" = pkgs.linkFarm "microsoft-teams-app" [
    {
      name = "Applications/Microsoft Teams.app";
      path = "${casks.microsoft-teams}/Applications/Microsoft Teams.app";
    }
  ];
  "Ghostty.app" = pkgs.ghostty-bin;
  "Notion.app" = casks.notion;
  "Obsidian.app" = casks.obsidian;
  "OneDrive.app" = casks.onedrive;
  "Podman Desktop.app" = casks.podman-desktop;
  "Slack.app" = casks.slack;
  "Steam.app" = casks.steam.overrideAttrs {
    src = inputs.steam-installer;
  };
  "Visual Studio Code.app" = casks.visual-studio-code;
  "WezTerm.app" = pkgs.wezterm;
  "zoom.us.app" = pkgs.zoom-us;
  # Cask metadata is pinned independently through the brew-api input.
  "Notion Calendar.app" = casks.notion-calendar;
  "JupyterLab.app" = casks.jupyterlab-app;
  # Docker Desktop owns first-run setup, contexts and optional privileged helpers.
  "Docker.app" = casks.docker-desktop;
}
