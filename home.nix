{ config, lib, pkgs, inputs, ... }:
let
  podman = pkgs.podman;
  linuxTools = import ./packages/linux-tools.nix { inherit pkgs; };
  darwinApps = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin
    (import ./packages/darwin-apps.nix { inherit pkgs inputs; });
  obsidian = if config.dotfiles.wsl then linuxTools.obsidian.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      # Same WSL driver and input-module requirements as Chrome/Chromium.
      # Remove the library path when the host driver no longer requires it.
      wrapProgram $out/bin/obsidian \
        --prefix LD_LIBRARY_PATH : /usr/lib/wsl/lib:${lib.makeLibraryPath [ pkgs.openssl ]} \
        --set GTK_IM_MODULE_FILE ${config.home.profileDirectory}/etc/gtk-3.0/immodules.cache \
        --prefix GTK_PATH : ${config.i18n.inputMethod.package}/lib/gtk-4.0
    '';
  }) else linuxTools.obsidian;
  alacritty = if config.dotfiles.wsl then pkgs.symlinkJoin {
    name = "alacritty-wsl";
    paths = [ pkgs.alacritty ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    # WSL's AMD driver dlopens libssl.so; without it GLX fails with BadConfig.
    # Remove when the host driver no longer needs this library search path.
    postBuild = ''
      wrapProgram $out/bin/alacritty --prefix LD_LIBRARY_PATH : \
        /usr/lib/wsl/lib:${lib.makeLibraryPath [ pkgs.openssl ]}
    '';
  } else pkgs.alacritty;
  chromium = if config.dotfiles.wsl then pkgs.chromium.overrideAttrs (old: {
    buildCommand = old.buildCommand + ''
      # WSL's AMD driver needs these runtime libraries, as with Alacritty.
      # Remove the library path when the host driver no longer requires it.
      # Use Home Manager's existing GTK cache even outside a Nix login shell.
      wrapProgram $out/bin/chromium \
        --prefix LD_LIBRARY_PATH : /usr/lib/wsl/lib:${lib.makeLibraryPath [ pkgs.openssl ]} \
        --set GTK_IM_MODULE_FILE ${config.home.profileDirectory}/etc/gtk-3.0/immodules.cache \
        --prefix GTK_PATH : ${config.i18n.inputMethod.package}/lib/gtk-4.0
    '';
  }) else pkgs.chromium;
  googleChrome = if config.dotfiles.wsl then pkgs.google-chrome.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      # Same WSL driver and Home Manager input-module requirements as Chromium.
      # Remove the library path when the host driver no longer requires it.
      wrapProgram $out/bin/google-chrome-stable \
        --prefix LD_LIBRARY_PATH : /usr/lib/wsl/lib:${lib.makeLibraryPath [ pkgs.openssl ]} \
        --set GTK_IM_MODULE_FILE ${config.home.profileDirectory}/etc/gtk-3.0/immodules.cache \
        --prefix GTK_PATH : ${config.i18n.inputMethod.package}/lib/gtk-4.0
    '';
  }) else pkgs.google-chrome;
in
{
  imports = [ ./dotfiles.nix ./externals.nix ./services.nix ];
  options.dotfiles.wsl = lib.mkEnableOption "WSLg desktop integration";
  config = {
    programs.home-manager.enable = true;
    programs.man.generateCaches = pkgs.stdenv.hostPlatform.isLinux;
    programs.nh.enable = true;
    programs.chromium = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      enable = true;
      package = chromium;
    };
    home.stateVersion = "25.11";
    targets.genericLinux.enable = pkgs.stdenv.hostPlatform.isLinux;
    targets.genericLinux.gpu.enable = pkgs.stdenv.hostPlatform.isLinux;
    fonts.fontconfig.enable = pkgs.stdenv.hostPlatform.isLinux;
    home.packages = [
      # LuaRocks and its interpreter must agree on the Lua ABI.
      pkgs.lua5_4
      pkgs.lua54Packages.luarocks
      pkgs.nerd-fonts.jetbrains-mono
    ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      alacritty
      googleChrome
      obsidian
      linuxTools.yq
      linuxTools.rsync
      linuxTools.pandoc
      linuxTools.xwininfo
      pkgs.ghostty
      # Cargo's global linker settings also work outside nix develop.
      # Rust versions remain mise-owned; project libraries belong in dev shells.
      pkgs.clang
      pkgs.mold
      pkgs.docker-compose
      pkgs.vim
      pkgs.nano
      pkgs.strace
      pkgs.perf
      pkgs.opensshWithKerberos
      pkgs.traceroute
      pkgs.ipafont
      # Pandoc PDF output, including Japanese documents with LuaLaTeX.
      (pkgs.texliveSmall.withPackages (ps: with ps; [
        collection-langjapanese
        collection-luatex
        luatexja
        selnolig
      ]))
      podman
      (pkgs.runCommand "podman-docker-compat" { } ''
        mkdir -p $out/bin
        ln -s ${podman}/bin/podman $out/bin/docker
      '')
      pkgs.man-pages
      pkgs.man-pages-posix
      (pkgs.callPackage ./packages/man-pages-ja.nix { })
      pkgs.noto-fonts
      pkgs.noto-fonts-cjk-sans
      pkgs.noto-fonts-cjk-serif
      pkgs.noto-fonts-color-emoji
    ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      pkgs.openssl
      pkgs.pkgconf
      pkgs.docker-client
      pkgs.docker-credential-helpers
      pkgs.php
      pkgs.phpPackages.composer
      pkgs.nerd-fonts.hack
      pkgs.mas
      pkgs._1password-cli
    ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin
      (builtins.attrValues (builtins.removeAttrs darwinApps [ "1Password.app" ]));
    home.sessionVariables = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      # Preserve the rootless API socket convention formerly supplied by podman-docker.
      DOCKER_HOST = "unix://\${XDG_RUNTIME_DIR}/podman/podman.sock";
    };
    xdg.configFile = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      "containers/policy.json".source = "${pkgs.skopeo.policy}/default-policy.json";
      "containers/containers.conf.d/10-nix.conf".source = (pkgs.formats.toml { }).generate "containers-nix.conf" {
        containers.seccomp_profile = "${podman.src}/vendor/go.podman.io/common/pkg/seccomp/seccomp.json";
        engine.compose_providers = [ "${pkgs.docker-compose}/bin/docker-compose" ];
      };
      "systemd/user/podman.service".source = "${podman}/share/systemd/user/podman.service";
      "systemd/user/podman.socket".source = "${podman}/share/systemd/user/podman.socket";
      "systemd/user/sockets.target.wants/podman.socket".source = "${podman}/share/systemd/user/podman.socket";
    };
    xdg.dataFile."applications/Alacritty.desktop" = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && config.dotfiles.wsl) {
      source = pkgs.substitute {
        src = "${alacritty}/share/applications/Alacritty.desktop";
        substitutions = [
          # Keep launchers valid across upgrades, including the New Terminal action.
          "--replace-fail" "TryExec=alacritty" "TryExec=${config.home.profileDirectory}/bin/alacritty"
          "--replace-fail" "Exec=alacritty" "Exec=${config.home.profileDirectory}/bin/alacritty"
          "--replace-fail" "Icon=Alacritty" "Icon=${config.home.profileDirectory}/share/icons/hicolor/scalable/apps/Alacritty.svg"
        ];
      };
    };
    programs.mise = {
      enable = true;
      # The repository-managed .zshrc loads the standard shell hooks.
      enableZshIntegration = false;
      enableBashIntegration = false;
      enableFishIntegration = false;
      globalConfig = lib.mkMerge [
        (lib.importTOML ./config/mise/config.toml)
        (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
          # Host Clang can link Nix OpenSSL without using a Nix compiler wrapper.
          env.PKG_CONFIG_PATH = "${lib.getDev pkgs.openssl}/lib/pkgconfig";
        })
      ];
    };
    # Keep cc/c++ as Apple Clang, while providing Homebrew-style GCC names.
    home.file = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      ".local/bin/gcc-${lib.versions.major pkgs.gcc.version}".source = "${pkgs.gcc}/bin/gcc";
      ".local/bin/g++-${lib.versions.major pkgs.gcc.version}".source = "${pkgs.gcc}/bin/g++";
      ".local/bin/gfortran-${lib.versions.major pkgs.gfortran.version}".source = "${pkgs.gfortran}/bin/gfortran";
      # Keep the vendor CLI tied to the copied app, including after updates.
      ".local/bin/code".source = config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}/Visual Studio Code.app/Contents/Resources/app/bin/code";
      ".local/bin/code-tunnel".source = config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/${config.targets.darwin.copyApps.directory}/Visual Studio Code.app/Contents/Resources/app/bin/code-tunnel";
    };
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = false;
      enableBashIntegration = false;
      enableFishIntegration = false;
      stdlib = ''
        # A broken shell must not silently keep the previous toolchain.
        nix_direnv_disallow_fallback
      '';
    };
    nix.package = pkgs.nix;
    nix.settings.use-xdg-base-directories = true;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    # The new nix.conf is linked after package installation on the first switch.
    home.activation.nixXdg = lib.hm.dag.entryBetween [ "installPackages" "linkGeneration" ] [ "writeBoundary" ] ''
      export XDG_STATE_HOME=${lib.escapeShellArg config.xdg.stateHome}
      unset NIX_PROFILE
      export NIX_CONFIG="''${NIX_CONFIG-}
      use-xdg-base-directories = true"
      run ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg "${config.xdg.stateHome}/nix/profiles"}
    '';
    # 1Password requires /Applications/1Password.app (nixpkgs#254944).
    # Follow nix-darwin's dedicated copier without retaining Nix store timestamps
    # (nix-darwin#1842). Remove this when copyApps supports per-app destinations.
    home.activation.onePassword = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
      (lib.hm.dag.entryAfter [ "copyApps" ] ''
        onePasswordSource=${lib.escapeShellArg "${darwinApps."1Password.app"}/Applications/1Password.app"}
        onePasswordTarget=/Applications/1Password.app
        onePasswordRsyncFlags=(
          --recursive --checksum --perms --links --copy-unsafe-links
          --specials --delete --chmod=-w
        )
        onePasswordChanges=$(${lib.getExe pkgs.rsync} --dry-run --itemize-changes \
          "''${onePasswordRsyncFlags[@]}" "$onePasswordSource/" "$onePasswordTarget/")
        if [[ -n "$onePasswordChanges" ]]; then
          run /usr/bin/sudo /usr/bin/install -o root -g wheel -m0555 -d "$onePasswordTarget"
          run /usr/bin/sudo ${lib.getExe pkgs.rsync} \
            "''${onePasswordRsyncFlags[@]}" "$onePasswordSource/" "$onePasswordTarget/"
        fi
      '');
    home.activation.wslgDesktop = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && config.dotfiles.wsl)
      (lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        if [[ -e /dev/dxg ]]; then
          if [[ "$(${pkgs.coreutils}/bin/readlink /run/opengl-driver || true)" != "${config.targets.genericLinux.gpu.drivers}" ]]; then
            run /usr/bin/sudo ${lib.getExe config.targets.genericLinux.gpu.setupPackage}
          fi

          # WSLg scans /usr/local/share/applications, but not Home Manager profiles.
          # Remove these exports when WSLg supports the profile's XDG_DATA_DIRS.
          if ! ${pkgs.diffutils}/bin/cmp -s \
              ${config.xdg.dataFile."applications/Alacritty.desktop".source} \
              /usr/local/share/applications/Alacritty.desktop; then
            run /usr/bin/sudo ${pkgs.coreutils}/bin/install -Dm0644 \
              ${config.xdg.dataFile."applications/Alacritty.desktop".source} \
              /usr/local/share/applications/Alacritty.desktop
          fi

          if ! ${pkgs.diffutils}/bin/cmp -s \
              ${config.home.file.".local/share/applications/com.mitchellh.ghostty.desktop".source} \
              /usr/local/share/applications/com.mitchellh.ghostty.desktop; then
            run /usr/bin/sudo ${pkgs.coreutils}/bin/install -Dm0644 \
              ${config.home.file.".local/share/applications/com.mitchellh.ghostty.desktop".source} \
              /usr/local/share/applications/com.mitchellh.ghostty.desktop
          fi
        fi
      '');
    home.activation.wslgFonts = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && config.dotfiles.wsl)
      (lib.hm.dag.entryAfter [ "linkGeneration" "installPackages" ] ''
        run ${pkgs.coreutils}/bin/env \
          XDG_STATE_HOME=${lib.escapeShellArg config.xdg.stateHome} \
          PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.systemd ]}:$PATH \
          ${pkgs.runtimeShell} ${./scripts/setup-wslg.sh}
      '');
    home.activation.herdrIntegrations = lib.hm.dag.entryAfter [ "linkGeneration" "installPackages" ] ''
      run ${pkgs.coreutils}/bin/env \
        XDG_CONFIG_HOME=${lib.escapeShellArg config.xdg.configHome} \
        XDG_DATA_HOME=${lib.escapeShellArg config.xdg.dataHome} \
        XDG_STATE_HOME=${lib.escapeShellArg config.xdg.stateHome} \
        CODEX_HOME=${lib.escapeShellArg "${config.xdg.configHome}/codex"} \
        CLAUDE_CONFIG_DIR=${lib.escapeShellArg "${config.xdg.configHome}/claude"} \
        PATH=${config.home.path}/bin:${lib.makeBinPath [ pkgs.coreutils pkgs.gnugrep ]}:$PATH \
        ${pkgs.runtimeShell} ${./scripts/setup-herdr.sh}
    '';
  };
}
