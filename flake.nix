{
  description = "Pinned CLI tools for these dotfiles";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.home-manager = {
    url = "github:nix-community/home-manager/master";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.zacrs-src = {
    url = "github:oyoshot/zsh-autocomplete-rs-proto/e0a41c3c46d0c8f36b1fbd7bc27b31bf14e6d575";
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
        pkgs.awscli2
        pkgs.bash-language-server
        pkgs.bat
        pkgs.cargo-audit
        pkgs.cargo-chef
        pkgs.cargo-crev
        pkgs.cargo-deny
        pkgs.cargo-expand
        pkgs.cargo-features-manager
        pkgs.cargo-generate
        pkgs.cargo-lambda
        pkgs.cargo-llvm-cov
        pkgs.cargo-machete
        pkgs.cargo-make
        pkgs.cargo-nextest
        pkgs.cargo-sort
        pkgs.cargo-udeps
        pkgs.cargo-update
        pkgs.claude-code
        pkgs.codex
        pkgs.cspell
        pkgs.delta
        pkgs.eva
        pkgs.eza
        pkgs.fd
        pkgs.fzf
        pkgs.gh
        pkgs.ghq
        pkgs.git-wt
        pkgs.gopls
        pkgs.gwq
        pkgs.herdr
        pkgs.hyperfine
        pkgs.jq
        pkgs.kubernetes-helm
        pkgs.lua-language-server
        pkgs.markdown-oxide
        pkgs.marp-cli
        pkgs.neovim
        pkgs.ni
        pkgs.opentofu
        pkgs.poetry
        pkgs.prettier
        pkgs.prettierd
        pkgs.pulumi
        pkgs.pyright
        pkgs.ripgrep
        pkgs.ruff
        pkgs.shellcheck
        pkgs.shfmt
        pkgs.starship
        pkgs.stylua
        pkgs.terraform-ls
        pkgs.tflint
        pkgs.tfsec
        pkgs.tmux
        pkgs.trash-cli
        pkgs.tree-sitter
        pkgs.typos-lsp
        pkgs.usage
        pkgs.uv
        pkgs.vim-startuptime
        pkgs.vtsls
        pkgs.zoxide
      ];
    in
    {
      packages = forAllSystems (pkgs: {
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
