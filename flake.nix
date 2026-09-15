{
  description = "Pinned CLI tools for these dotfiles";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.home-manager = {
    url = "github:nix-community/home-manager/master";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.zacrs-src = {
    url = "git+https://github.com/oyoshot/zsh-autocomplete-rs-proto.git";
    flake = false;
  };
  inputs.herdr-agent-title-src = {
    url = "github:oyoshot/herdr-plugin-agent-title/f60fe0a2b8a7d5d9147dd4ff211de06c48f03a03";
    flake = false;
  };

  inputs.tpm = { url = "github:tmux-plugins/tpm"; flake = false; };
  inputs.zsh-defer = { url = "github:romkatv/zsh-defer"; flake = false; };
  inputs.zsh-completions = { url = "github:zsh-users/zsh-completions"; flake = false; };
  inputs.anyframe = { url = "github:mollifier/anyframe"; flake = false; };
  inputs.autosuggestions = { url = "github:zsh-users/zsh-autosuggestions"; flake = false; };
  inputs.syntax-highlighting = { url = "github:zdharma-continuum/fast-syntax-highlighting"; flake = false; };
  inputs.zsh-history = { url = "github:zsh-users/zsh-history-substring-search"; flake = false; };
  inputs.ni-zsh = { url = "github:azu/ni.zsh"; flake = false; };
  inputs.prh-rules = { url = "github:prh/rules"; flake = false; };
  inputs.alacritty-theme = { url = "github:alacritty/alacritty-theme"; flake = false; };

  outputs =
    inputs@{ self, nixpkgs, home-manager, zacrs-src, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system:
        f (import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];
        }));
      # Runtimes, Terraform versions and textlint plugins stay in mise.
      zacrsPackage = pkgs: pkgs.rustPlatform.buildRustPackage {
        pname = "zsh-autocomplete-rs";
        version = "0.1.0-${builtins.substring 0 7 zacrs-src.rev}";
        src = zacrs-src;
        cargoLock.lockFile = zacrs-src + "/Cargo.lock";
        cargoBuildFlags = [ "--package" "zsh-autocomplete-rs" ];
        # Several upstream tests require a real terminal and resize events.
        doCheck = false;
        nativeInstallCheckInputs = [ pkgs.zsh ];
        doInstallCheck = true;
        installCheckPhase = ''
          runHook preInstallCheck
          "$out/bin/zsh-autocomplete-rs" init zsh > init.zsh
          zsh -n init.zsh
          runHook postInstallCheck
        '';
        meta = {
          description = "Zsh autocomplete with a Rust popup renderer";
          homepage = "https://github.com/oyoshot/zsh-autocomplete-rs-proto";
          mainProgram = "zsh-autocomplete-rs";
          platforms = systems;
        };
      };
      cliPackages = pkgs: [
        (zacrsPackage pkgs)
        (pkgs.callPackage ./packages/herdr-agent-title.nix { src = inputs.herdr-agent-title-src; })
        pkgs.autoconf
        pkgs.automake
        pkgs.aws-vault
        pkgs.awscli2
        pkgs.bat
        pkgs.claude-code
        pkgs.cloudflared
        pkgs.codex
        pkgs.coreutils
        pkgs.delta
        pkgs.diffutils
        pkgs.dig
        pkgs.eva
        pkgs.eza
        pkgs.fcp
        pkgs.fd
        pkgs.findutils
        pkgs.fish
        pkgs.fzf
        pkgs.gawk
        pkgs.getopt
        pkgs.gh
        pkgs.ghq
        pkgs.git
        pkgs.git-wt
        pkgs.gnugrep
        pkgs.gnumake
        pkgs.gnupg
        pkgs.gnutar
        pkgs.graphviz
        pkgs.gwq
        pkgs.gzip
        pkgs.herdr
        pkgs.htop
        pkgs.hyperfine
        pkgs.jq
        pkgs.marp-cli
        pkgs.moreutils
        pkgs.ncurses
        pkgs.neovim
        pkgs.ni
        pkgs.pkg-config
        pkgs.podman-compose
        pkgs.poetry
        pkgs.rclone
        pkgs.ripgrep
        pkgs.skopeo
        pkgs.ssm-session-manager-plugin
        pkgs.starship
        pkgs.time
        pkgs.tmux
        pkgs.trash-cli
        pkgs.unzip
        pkgs.usage
        pkgs.uv
        pkgs.vim-startuptime
        pkgs.wget
        pkgs.whois
        pkgs.zoxide
        pkgs.zsh
      ] ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        # Default linker for the shared Cargo configuration and native builds.
        pkgs.gnused
        pkgs.clang
        pkgs.mold
      ] ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        # macOS scripts expect BSD sed; preserve Homebrew's gsed spelling.
        (pkgs.gnused.overrideAttrs { configureFlags = [ "--program-prefix=g" ]; })
        pkgs.gcc
        pkgs.binutils
        pkgs.pinentry_mac
      ];
    in
    {
      packages = forAllSystems (pkgs: {
        podman = pkgs.podman;
        home-manager = home-manager.packages.${pkgs.stdenv.hostPlatform.system}.home-manager;
        zsh-autocomplete-rs = zacrsPackage pkgs;
        herdr-plugin-agent-title = pkgs.callPackage ./packages/herdr-agent-title.nix {
          src = inputs.herdr-agent-title-src;
        };
        default = pkgs.buildEnv {
          name = "dotfiles-cli";
          paths = cliPackages pkgs;
          pathsToLink = [
            "/bin"
            "/share/man"
            "/share/zsh/site-functions"
          ];
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShellNoCC {
          name = "dotfiles-cli";
          packages = cliPackages pkgs;
        };
      });

      homeConfigurations = {
        oyoshot-linux = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];
          };
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./home.nix
            {
              home.username = "oyoshot";
              home.homeDirectory = "/home/oyoshot";
              dotfiles.wsl = true;
              home.packages = [ self.packages.x86_64-linux.default ];
            }
          ];
        };
        ci-linux = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];
          };
          extraSpecialArgs = { inherit inputs; };
          modules = [ ./home.nix {
            home.username = "builder";
            home.homeDirectory = "/home/builder";
            home.packages = [ self.packages.x86_64-linux.default ];
          } ];
        };
        ci-darwin = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];
          };
          extraSpecialArgs = { inherit inputs; };
          modules = [ ./home.nix {
            home.username = "runner";
            home.homeDirectory = "/Users/runner";
            home.packages = [ self.packages.aarch64-darwin.default ];
          } ];
        };
        oyoshot-darwin = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-darwin";
            config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];
          };
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./home.nix
            {
              home.username = "oyoshot";
              home.homeDirectory = "/Users/oyoshot";
              home.packages = [ self.packages.aarch64-darwin.default ];
            }
          ];
        };
      };
    };
}
