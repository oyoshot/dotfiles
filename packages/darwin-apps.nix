# Package supply only; Home Manager deploys 1Password separately from copyApps.
{ pkgs, inputs }:
let
  casks = inputs.brew-nix.packages.${pkgs.stdenv.hostPlatform.system};
  # brew-nix treats a PKG artifact's DMG as a xar archive. Unpack the outer
  # image first; remove when nested DMG/PKG inputs are supported upstream.
  unpackDmgPkg = unpackPkg: ''
    if ! undmg "$src"; then
      # Google Drive uses APFS features unsupported by 7zz. As in nixpkgs'
      # lmstudio-bionic, use the host disk-image reader for these images.
      (
        mountpoint=$(mktemp -d)
        trap '/usr/bin/hdiutil detach "$mountpoint" -force; rmdir "$mountpoint"' EXIT
        /usr/bin/hdiutil attach -readonly -nobrowse -mountpoint "$mountpoint" "$src"
        cp "$mountpoint"/*.pkg .
      )
    fi
    packages=( ./*.pkg )
    test "''${#packages[@]}" -eq 1
    test -f "''${packages[0]}"
    src="$PWD/''${packages[0]}"
    ${unpackPkg}
  '';
  acrobatReader = casks.adobe-acrobat-reader.overrideAttrs (old: {
    unpackPhase = unpackDmgPkg old.unpackPhase;
    # Reader's postinstall normally expands these archives and restores the
    # executable bits from setX.txt. Do that in the build, without its root-only
    # ownership changes or the separate Adobe updater installation.
    installPhase = old.installPhase + ''
      (
        cd "$out/Applications/Adobe Acrobat Reader.app/Contents"
        unzip -p 7zz.zip setX.txt > setX.txt
        for folder in MacOS AcroCEF Plugins Helpers Frameworks Plug-ins Resources Services Support; do
          7zz x -y -snld20 "$folder.7z"
        done
        find . -type d -exec chmod 0755 {} +
        find . -type f -exec chmod 0644 {} +
        while IFS= read -r executable; do
          if [[ -e "$executable" ]]; then
            chmod 0755 "$executable"
          fi
        done < setX.txt
        rm -f -- ./*.7z setX.txt 7zz.zip decompress
      )
    '';
  });
in
{
  # Keep the separately packaged Adobe updaters out of Home Manager Apps.
  "Adobe Acrobat Reader.app" = pkgs.linkFarm "adobe-acrobat-reader-app" [
    {
      name = "Applications/Adobe Acrobat Reader.app";
      path = "${acrobatReader}/Applications/Adobe Acrobat Reader.app";
    }
  ];
  "Alacritty.app" = pkgs.alacritty;
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
  "Discord.app" = casks.discord;
  "Figma.app" = casks.figma;
  # macOS 27 restricts profile data to Mozilla-signed apps (nixpkgs#535123).
  # Keep the vendor bundle until wrapped firefox-bin preserves that identity.
  "Firefox.app" = pkgs.firefox-bin-unwrapped;
  "Google Chrome.app" = pkgs.google-chrome;
  "Google Drive.app" = casks.google-drive.overrideAttrs (old: {
    src = inputs.google-drive-installer;
    unpackPhase = unpackDmgPkg old.unpackPhase;
  });
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
