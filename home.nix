{ config, lib, pkgs, inputs, ... }:
let
  podman = pkgs.podman;
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
in
{
  imports = [ ./dotfiles.nix ./externals.nix ./services.nix ];
  options.dotfiles.wsl = lib.mkEnableOption "WSLg desktop integration";
  config = {
    programs.home-manager.enable = true;
    home.stateVersion = "25.11";
    targets.genericLinux.gpu.enable = pkgs.stdenv.hostPlatform.isLinux;
    fonts.fontconfig.enable = pkgs.stdenv.hostPlatform.isLinux;
    home.packages = [
      # LuaRocks and its interpreter must agree on the Lua ABI.
      pkgs.lua5_4
      pkgs.lua54Packages.luarocks
      pkgs.nerd-fonts.jetbrains-mono
    ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      alacritty
      pkgs.ghostty
      podman
      (pkgs.runCommand "podman-docker-compat" { } ''
        mkdir -p $out/bin
        ln -s ${podman}/bin/podman $out/bin/docker
      '')
      pkgs.man-pages
      pkgs.man-pages-posix
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
      (builtins.attrValues (import ./packages/darwin-apps.nix { inherit pkgs inputs; }));
    # Preserve the rootless API socket convention formerly supplied by podman-docker.
    home.sessionVariables = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      DOCKER_HOST = "unix://\${XDG_RUNTIME_DIR}/podman/podman.sock";
    };
    xdg.configFile = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      "containers/policy.json".source = "${pkgs.skopeo.policy}/default-policy.json";
      "containers/containers.conf.d/10-nix.conf".source = (pkgs.formats.toml { }).generate "containers-nix.conf" {
        containers.seccomp_profile = "${podman.src}/vendor/go.podman.io/common/pkg/seccomp/seccomp.json";
      };
      "systemd/user/podman.service".source = "${podman}/share/systemd/user/podman.service";
      "systemd/user/podman.socket".source = "${podman}/share/systemd/user/podman.socket";
    };
    programs.mise = {
      enable = true;
      enableMutableConfig = true;
      # The existing .zshrc coordinates mise and direnv with one deferred hook.
      enableZshIntegration = false;
      enableBashIntegration = false;
      enableFishIntegration = false;
      # Host Clang can link Nix OpenSSL without using a Nix compiler wrapper.
      globalConfig.env = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        PKG_CONFIG_PATH = "${lib.getDev pkgs.openssl}/lib/pkgconfig";
      };
      globalConfig.settings = {
        experimental = true;
        idiomatic_version_file_enable_tools = [ "terraform" "node" "python" "rust" ];
        npm.bun = true;
      };
    };
    # Keep cc/c++ as Apple Clang, while providing Homebrew-style GCC names.
    home.file = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      ".local/bin/gcc-${lib.versions.major pkgs.gcc.version}".source = "${pkgs.gcc}/bin/gcc";
      ".local/bin/g++-${lib.versions.major pkgs.gcc.version}".source = "${pkgs.gcc}/bin/g++";
      ".local/bin/gfortran-${lib.versions.major pkgs.gfortran.version}".source = "${pkgs.gfortran}/bin/gfortran";
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
    # linkGeneration removes the previous HM-managed config.toml symlink.
    # Seed only missing files; subsequent switches preserve mise use --global.
    home.activation.miseInitialTools = lib.hm.dag.entryBetween
      [ "miseMutableConfig" ] [ "linkGeneration" ] ''
        if [[ ! -e ${lib.escapeShellArg "${config.xdg.configHome}/mise/config.toml"} && ! -L ${lib.escapeShellArg "${config.xdg.configHome}/mise/config.toml"} ]]; then
          run ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg "${config.xdg.configHome}/mise"}
          run ${pkgs.coreutils}/bin/install -m 600 ${./config/mise/config.toml} ${lib.escapeShellArg "${config.xdg.configHome}/mise/config.toml"}
        fi
      '';
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
    home.activation.wslgDesktop = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && config.dotfiles.wsl)
      (lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        if [[ -e /dev/dxg ]]; then
          if [[ "$(${pkgs.coreutils}/bin/readlink /run/opengl-driver || true)" != "${config.targets.genericLinux.gpu.drivers}" ]]; then
            run /usr/bin/sudo ${lib.getExe config.targets.genericLinux.gpu.setupPackage}
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
