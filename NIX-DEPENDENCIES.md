# Nixpkgs 依存カバレッジ調査

調査日: 2026-09-09。対象は、このリポジトリの mise / Homebrew / Arch のパッケージ宣言。

## 結果

| 管理元 | 宣言数 | 対象 OS で直接候補あり |
| --- | ---: | ---: |
| mise | 80 | 70 |
| Homebrew formula | 54 | 54 |
| Homebrew cask | 14 | 11 |
| Arch | 54 | 50 |
| 合計（管理元間の重複を含む） | 202 | 185（91.6%） |

mise の残り 10 件のうち 2 件は別パッケージに同梱されている。これを含めると 187/202 件（92.6%）に候補がある。ただし、これは**パッケージ候補のカバレッジであり、環境の完全再現率ではない**。

## 確認方法と限界

- `flake.lock` の [Nixpkgs `58973d74f189`](https://github.com/NixOS/nixpkgs/tree/58973d74f1893afe13f5902919803a0e99da0ca4) を使用。最新版への追従状況の評価ではない。
- mise は `x86_64-linux` と `aarch64-darwin` の両方、Homebrew は後者、Arch は前者を対象にした。
- 候補の属性が存在し、`lib.meta.availableOn` が真で、`meta.broken` ではなく、`drvPath` の評価が成功することを確認。別名候補も照合した。
- 調査時のみ `config.allowUnfree = true` を指定。現行 flake にこの設定を追加したわけではない。表の「非自由」は導入時に許可設定が必要な候補。
- 全候補のダウンロード・ビルド・起動試験はしていない。試行済みなのは先行導入の Linux 上の ripgrep / fd / jq。
- 現在インストール済みのバージョンとの一致、プラグイン群、サービス、認証、設定ファイル、OS 統合は件数に含めない。
- 「直接候補なし」はこの固定リビジョンで対応する定義を見つけられなかったという意味。他の flake や独自定義での導入が不可能という意味ではない。

## 追加対応が必要なもの

- mise: `cargo-compete`、`mattn/memo`、`atcoder-cli`、`mcp-hub`、`md-to-pdf`、`prh`、`textlint-rule-preset-jtf-style` は Nixpkgs に直接候補を確認できなかった。`zsh-autocomplete-rs-proto` は、このリポジトリの flake で公開 Git リビジョンと Cargo 依存を固定する独自パッケージに移した。`mcphub-nvim` はクライアントであり `mcp-hub` サーバーの代替として数えていない。
- `@astrojs/ts-plugin` は `astro-language-server` に同梱。エディターからパッケージ内の配置先を参照する設定が必要。
- `@textlint/textlint-plugin-markdown` は `textlint` に同梱。追加ルールの解決には `textlint.withPackages` 等での構成が必要。`textlint-rule-prh` と単独の `prh` CLI は別扱い。
- cask: Docker Desktop、JupyterLab Desktop、Notion Calendar の直接候補を確認できなかった。Docker CLI や Python の JupyterLab サーバーを Desktop アプリの代替として数えていない。
- Arch: `base-devel` はパッケージグループなので必要なビルドツールを個別に選ぶ。`downgrade` と `reflector` は Arch 管理用。`podman-docker` の互換コマンド・ソケット統合は別途構成が必要。

## 候補があっても完全一致しない例

- Terraform は現在 `1.0.11`、`1.5.7`、`latest` の複数指定。今回の `pkgs.terraform` は `1.16.0` で、旧 2 バージョンはこれだけでは再現できない。別リビジョンの固定や独自定義、mise の併用が必要。
- Node 22 と Python 3.13 は該当系列の属性がある。一方 `latest` 指定は、Nixpkgs の固定バージョンに置き換わる。例えば既定の `jdk` は 21 系で、元の `java latest` との一致を保証しない。
- Git URL から導入するものとリリース版の Nixpkgs パッケージではコミットが異なりうる。`markdown-oxide` などは同一プロジェクトの候補として数えた。
- `herdr`、`git-wt`、`gwq` は対応する上流のパッケージが存在する。自作 CLI 全般が未収録というわけではない。
- Ghostty は Linux の `ghostty` と Mac の `ghostty-bin` を使い分ける。
- GUI アプリの存在は `/Applications` への登録、権限、ログイン起動、ドライバー設定までの自動再現を意味しない。特に Karabiner は OS 側の設定も必要。
- Arch の `noto-fonts-cjk` 相当には Sans と Serif の両方を検討する。表の候補は Sans。`pinentry` も用途に応じた GUI / TTY 版の選択が必要。
- Rustup の導入と、Rust のツールチェーン・コンポーネントの固定は別。`pkgs.rustup` を入れるだけでは後者は固定されない。
- Fcitx5 の WSLg 向けパッチやサービス、`/usr/bin` を直接参照する既存設定は別途移植が必要。
- `.chezmoiexternal.toml` の取得物、Neovim / tmux / Zsh のプラグイン、言語パッケージの全推移的依存は、この宣言数には含めていない。

## 移行判断

CLI 本体の多くは Nixpkgs に寄せられる。未収録の CLI と旧 Terraform は当面 mise、GUI と OS 統合は Homebrew / Arch を残す構成なら、段階的に進めやすい。全パッケージを置き換える前に、PATH、プラグイン探索先、サービスの実行パスを確認する。

## 宣言ごとの候補

属性名は `pkgs.` を省略。バージョンは固定 Nixpkgs の値。両 OS の欄があるものでも実機動作確認済みを意味しない。

### mise

| 元の宣言 | Linux x86_64 | macOS ARM64 |
| --- | --- | --- |
| `aws-cli` | `awscli2` 2.35.11 | `awscli2` 2.35.11 |
| `bun` | `bun` 1.3.13 | `bun` 1.3.13 |
| `claude` | `claude-code` 2.1.260 ※非自由 | `claude-code` 2.1.260 ※非自由 |
| `codex` | `codex` 0.153.4 | `codex` 0.153.4 |
| `cspell` | `cspell` 9.7.0 | `cspell` 9.7.0 |
| `deno` | `deno` 2.9.5 | `deno` 2.9.5 |
| `elixir` | `beamPackages.elixir` 1.18.5 | `beamPackages.elixir` 1.18.5 |
| `erlang` | `beamPackages.erlang` 28.5.0.6 | `beamPackages.erlang` 28.5.0.6 |
| `go` | `go` 1.26.7 | `go` 1.26.7 |
| `gradle` | `gradle` 8.14.4 | `gradle` 8.14.4 |
| `helm` | `kubernetes-helm` 4.2.4 | `kubernetes-helm` 4.2.4 |
| `herdr` | `herdr` 0.8.2 | `herdr` 0.8.2 |
| `java` | `jdk` 21.0.12+8 | `jdk` 21.0.11 |
| `julia` | `julia` 1.12.7 | `julia` 1.12.7 |
| `kotlin` | `kotlin` 2.4.10 | `kotlin` 2.4.10 |
| `lua-language-server` | `lua-language-server` 3.19.1 | `lua-language-server` 3.19.1 |
| `ni` | `ni` 30.3.0 | `ni` 30.3.0 |
| `node` | `nodejs_22` 22.23.2 | `nodejs_22` 22.23.2 |
| `opentofu` | `opentofu` 1.12.6 | `opentofu` 1.12.6 |
| `pnpm` | `pnpm` 11.25.0 | `pnpm` 11.25.0 |
| `prettier` | `prettier` 3.9.6 | `prettier` 3.9.6 |
| `pulumi` | `pulumi` 3.255.0 | `pulumi` 3.255.0 |
| `python` | `python313` 3.13.15 | `python313` 3.13.15 |
| `ruby` | `ruby` 3.4.9 | `ruby` 3.4.9 |
| `rye` | `rye` 0.44.0 | `rye` 0.44.0 |
| `scala` | `scala` 3.3.8 | `scala` 3.3.8 |
| `shellcheck` | `shellcheck` 0.11.0 | `shellcheck` 0.11.0 |
| `shfmt` | `shfmt` 3.14.0 | `shfmt` 3.14.0 |
| `terraform` | `terraform` 1.16.0 ※非自由 | `terraform` 1.16.0 ※非自由 |
| `terraform-ls` | `terraform-ls` 0.39.0 | `terraform-ls` 0.39.0 |
| `tflint` | `tflint` 0.64.0 | `tflint` 0.64.0 |
| `tfsec` | `tfsec` 1.28.14 | `tfsec` 1.28.14 |
| `uv` | `uv` 0.12.5 | `uv` 0.12.5 |
| `zig` | `zig` 0.16.0 | `zig` 0.16.0 |
| `cargo:cargo-audit` | `cargo-audit` 0.22.2 | `cargo-audit` 0.22.2 |
| `cargo:cargo-chef` | `cargo-chef` 0.1.78 | `cargo-chef` 0.1.78 |
| `cargo:cargo-compete` | 直接候補なし | 直接候補なし |
| `cargo:cargo-crev` | `cargo-crev` 0.27.1 | `cargo-crev` 0.27.1 |
| `cargo:cargo-deny` | `cargo-deny` 0.20.2 | `cargo-deny` 0.20.2 |
| `cargo:cargo-expand` | `cargo-expand` 1.0.126 | `cargo-expand` 1.0.126 |
| `cargo:cargo-features-manager` | `cargo-features-manager` 0.12.0 | `cargo-features-manager` 0.12.0 |
| `cargo:cargo-generate` | `cargo-generate` 0.23.9 | `cargo-generate` 0.23.9 |
| `cargo:cargo-lambda` | `cargo-lambda` 1.9.2 | `cargo-lambda` 1.9.2 |
| `cargo:cargo-llvm-cov` | `cargo-llvm-cov` 0.9.0 | `cargo-llvm-cov` 0.9.0 |
| `cargo:cargo-machete` | `cargo-machete` 0.9.2 | `cargo-machete` 0.9.2 |
| `cargo:cargo-make` | `cargo-make` 0.37.24 | `cargo-make` 0.37.24 |
| `cargo:cargo-nextest` | `cargo-nextest` 0.9.143 | `cargo-nextest` 0.9.143 |
| `cargo:cargo-sort` | `cargo-sort` 2.1.4 | `cargo-sort` 2.1.4 |
| `cargo:cargo-udeps` | `cargo-udeps` 0.1.61 | `cargo-udeps` 0.1.61 |
| `cargo:cargo-update` | `cargo-update` 22.1.1 | `cargo-update` 22.1.1 |
| `cargo:typos-lsp` | `typos-lsp` 0.1.56 | `typos-lsp` 0.1.56 |
| `cargo:https://github.com/oyoshot/zsh-autocomplete-rs-proto.git` | 直接候補なし | 直接候補なし |
| `cargo:https://github.com/Feel-ix-343/markdown-oxide.git` | `markdown-oxide` 0.25.12 | `markdown-oxide` 0.25.12 |
| `cargo:stylua` | `stylua` 2.5.2 | `stylua` 2.5.2 |
| `cargo:usage-cli` | `usage` 6.6.1 | `usage` 6.6.1 |
| `go:github.com/d-kuro/gwq/cmd/gwq` | `gwq` 0.1.1 | `gwq` 0.1.1 |
| `go:github.com/k1LoW/git-wt` | `git-wt` 0.29.1 | `git-wt` 0.29.1 |
| `go:github.com/mattn/memo` | 直接候補なし | 直接候補なし |
| `go:github.com/rhysd/vim-startuptime` | `vim-startuptime` 1.3.2 | `vim-startuptime` 1.3.2 |
| `go:golang.org/x/tools/gopls` | `gopls` 0.23.0 | `gopls` 0.23.0 |
| `npm:@astrojs/language-server` | `astro-language-server` 2.16.10 | `astro-language-server` 2.16.10 |
| `npm:@astrojs/ts-plugin` | 直接候補なし | 直接候補なし |
| `npm:@fsouza/prettierd` | `prettierd` 0.28.0 | `prettierd` 0.28.0 |
| `npm:@marp-team/marp-cli` | `marp-cli` 4.5.0 | `marp-cli` 4.5.0 |
| `npm:@textlint/textlint-plugin-markdown` | 直接候補なし | 直接候補なし |
| `npm:@vtsls/language-server` | `vtsls` 0.3.0 | `vtsls` 0.3.0 |
| `npm:atcoder-cli` | 直接候補なし | 直接候補なし |
| `npm:bash-language-server` | `bash-language-server` 5.6.0 | `bash-language-server` 5.6.0 |
| `npm:mcp-hub` | 直接候補なし | 直接候補なし |
| `npm:md-to-pdf` | 直接候補なし | 直接候補なし |
| `npm:prh` | 直接候補なし | 直接候補なし |
| `npm:textlint` | `textlint` 15.7.1 | `textlint` 15.7.1 |
| `npm:textlint-rule-preset-ja-spacing` | `textlint-rule-preset-ja-spacing` 2.4.3 | `textlint-rule-preset-ja-spacing` 2.4.3 |
| `npm:textlint-rule-preset-ja-technical-writing` | `textlint-rule-preset-ja-technical-writing` 10.0.1 | `textlint-rule-preset-ja-technical-writing` 10.0.1 |
| `npm:textlint-rule-preset-jtf-style` | 直接候補なし | 直接候補なし |
| `npm:textlint-rule-prh` | `textlint-rule-prh` 6.0.0 | `textlint-rule-prh` 6.0.0 |
| `npm:textlint-rule-terminology` | `textlint-rule-terminology` 5.2.16 | `textlint-rule-terminology` 5.2.16 |
| `pipx:poetry` | `poetry` 2.4.2 | `poetry` 2.4.2 |
| `npm:pyright` | `pyright` 1.1.412 | `pyright` 1.1.412 |
| `pipx:ruff` | `ruff` 0.16.5 | `ruff` 0.16.5 |

### brew

| 元の宣言 | Linux x86_64 | macOS ARM64 |
| --- | --- | --- |
| `ansible` | 対象外 | `ansible` 2.21.3 |
| `automake` | 対象外 | `automake` 1.18.1 |
| `aws-vault` | 対象外 | `aws-vault` 7.13.6 |
| `bat` | 対象外 | `bat` 0.26.1 |
| `binutils` | 対象外 | `binutils` 2.46 |
| `chezmoi` | 対象外 | `chezmoi` 2.72.1 |
| `cloudflared` | 対象外 | `cloudflared` 2026.8.2 |
| `composer` | 対象外 | `phpPackages.composer` 2.10.3 |
| `coreutils` | 対象外 | `coreutils` 9.11 |
| `diffutils` | 対象外 | `diffutils` 3.12 |
| `eva` | 対象外 | `eva` 0.3.1 |
| `eza` | 対象外 | `eza` 0.23.5 |
| `fcp` | 対象外 | `fcp` 0.2.2 |
| `fd` | 対象外 | `fd` 10.5.0 |
| `findutils` | 対象外 | `findutils` 4.11.0 |
| `fish` | 対象外 | `fish` 4.9.2 |
| `fzf` | 対象外 | `fzf` 0.74.3 |
| `gawk` | 対象外 | `gawk` 5.4.1 |
| `gcc` | 対象外 | `gcc` 15.3.0 |
| `ghq` | 対象外 | `ghq` 1.10.1 |
| `git` | 対象外 | `git` 2.55.0 |
| `git-delta` | 対象外 | `delta` 0.19.2 |
| `gnu-getopt` | 対象外 | `getopt` 1.1.6 |
| `gnu-sed` | 対象外 | `gnused` 4.10 |
| `gnu-tar` | 対象外 | `gnutar` 1.35 |
| `gnu-time` | 対象外 | `time` 1.10 |
| `gnupg` | 対象外 | `gnupg` 2.4.9 |
| `graphviz` | 対象外 | `graphviz` 15.1.1 |
| `grep` | 対象外 | `gnugrep` 3.12 |
| `gzip` | 対象外 | `gzip` 1.14 |
| `hyperfine` | 対象外 | `hyperfine` 1.20.0 |
| `jq` | 対象外 | `jq` 1.8.2 |
| `kubernetes-cli` | 対象外 | `kubectl` 1.37.0 |
| `luarocks` | 対象外 | `luarocks` 3.13.0-1 |
| `mas` | 対象外 | `mas` 7.0.0 |
| `mise` | 対象外 | `mise` 2026.8.6 |
| `moreutils` | 対象外 | `moreutils` 0.70 |
| `ncurses` | 対象外 | `ncurses` 6.6 |
| `neovim` | 対象外 | `neovim` 0.12.5 |
| `odo-dev` | 対象外 | `odo` 3.16.1 |
| `openshift-cli` | 対象外 | `openshift` 4.22.0-202605222050 |
| `pinentry-mac` | 対象外 | `pinentry_mac` 1.1.1.1 |
| `podman-compose` | 対象外 | `podman-compose` 1.6.0 |
| `ripgrep` | 対象外 | `ripgrep` 15.2.0 |
| `skopeo` | 対象外 | `skopeo` 1.24.0 |
| `starship` | 対象外 | `starship` 1.26.0 |
| `tektoncd-cli` | 対象外 | `tektoncd-cli` 0.46.0 |
| `tmux` | 対象外 | `tmux` 3.7c |
| `trash-cli` | 対象外 | `trash-cli` 0.24.5.26 |
| `tree-sitter-cli` | 対象外 | `tree-sitter` 0.26.11 |
| `unzip` | 対象外 | `unzip` 6.0 |
| `wget` | 対象外 | `wget` 1.25.0 |
| `zoxide` | 対象外 | `zoxide` 0.10.0 |
| `zsh` | 対象外 | `zsh` 5.9.2 |

### cask

| 元の宣言 | Linux x86_64 | macOS ARM64 |
| --- | --- | --- |
| `1password` | 対象外 | `_1password-gui` 8.12.34 ※非自由 |
| `1password-cli` | 対象外 | `_1password-cli` 2.39.0 ※非自由 |
| `chatgpt` | 対象外 | `chatgpt` 26.803.81509 ※非自由 |
| `docker` | 対象外 | 直接候補なし |
| `firefox` | 対象外 | `firefox` 155.0.1 |
| `font-hack-nerd-font` | 対象外 | `nerd-fonts.hack` 3.5.0+3.003 |
| `ghostty` | 対象外 | `ghostty-bin` 1.3.1 |
| `google-chrome` | 対象外 | `google-chrome` 152.0.7977.83 ※非自由 |
| `jupyterlab` | 対象外 | 直接候補なし |
| `karabiner-elements` | 対象外 | `karabiner-elements` 15.7.0 |
| `notion` | 対象外 | `notion-app` 7.25.1 ※非自由 |
| `notion-calendar` | 対象外 | 直接候補なし |
| `podman-desktop` | 対象外 | `podman-desktop` 1.29.1 |
| `wezterm` | 対象外 | `wezterm` 0-unstable-2026-08-31 |

### arch

| 元の宣言 | Linux x86_64 | macOS ARM64 |
| --- | --- | --- |
| `alacritty` | `alacritty` 0.17.0 | 対象外 |
| `ansible` | `ansible` 2.21.3 | 対象外 |
| `aws-session-manager-plugin` | `ssm-session-manager-plugin` 1.2.792.0 | 対象外 |
| `base-devel` | 直接候補なし | 対象外 |
| `bash` | `bash` 5.3p15 | 対象外 |
| `bat` | `bat` 0.26.1 | 対象外 |
| `bind` | `bind` 9.20.26 | 対象外 |
| `chezmoi` | `chezmoi` 2.72.1 | 対象外 |
| `clang` | `clang` 21.1.8 | 対象外 |
| `downgrade` | 直接候補なし | 対象外 |
| `eva` | `eva` 0.3.1 | 対象外 |
| `eza` | `eza` 0.23.5 | 対象外 |
| `fcitx5` | `fcitx5` 5.1.21 | 対象外 |
| `fcitx5-configtool` | `qt6Packages.fcitx5-configtool` 5.1.14 | 対象外 |
| `fcitx5-gtk` | `fcitx5-gtk` 5.1.7 | 対象外 |
| `fcitx5-mozc` | `fcitx5-mozc` 2.30.5544.102 | 対象外 |
| `fd` | `fd` 10.5.0 | 対象外 |
| `fuse3` | `fuse3` 3.18.2 | 対象外 |
| `fzf` | `fzf` 0.74.3 | 対象外 |
| `ghq` | `ghq` 1.10.1 | 対象外 |
| `git` | `git` 2.55.0 | 対象外 |
| `git-delta` | `delta` 0.19.2 | 対象外 |
| `ghostty` | `ghostty` 1.3.1 | 対象外 |
| `gnupg` | `gnupg` 2.4.9 | 対象外 |
| `htop` | `htop` 3.5.3 | 対象外 |
| `hyperfine` | `hyperfine` 1.20.0 | 対象外 |
| `jdk-openjdk` | `jdk` 21.0.12+8 | 対象外 |
| `logrotate` | `logrotate` 3.22.0 | 対象外 |
| `luarocks` | `luarocks` 3.13.0-1 | 対象外 |
| `man-db` | `man-db` 2.13.1 | 対象外 |
| `man-pages` | `man-pages` 6.19 | 対象外 |
| `mise` | `mise` 2026.8.6 | 対象外 |
| `mold` | `mold` 2.42.0 | 対象外 |
| `nfs-utils` | `nfs-utils` 2.9.2 | 対象外 |
| `noto-fonts-cjk` | `noto-fonts-cjk-sans` 2.004 | 対象外 |
| `noto-fonts-emoji` | `noto-fonts-color-emoji` 2.051 | 対象外 |
| `nvim` | `neovim` 0.12.5 | 対象外 |
| `pinentry` | `pinentry-qt` 1.3.2 | 対象外 |
| `podman` | `podman` 5.8.6 | 対象外 |
| `podman-compose` | `podman-compose` 1.6.0 | 対象外 |
| `podman-docker` | 直接候補なし | 対象外 |
| `rclone` | `rclone` 1.75.1 | 対象外 |
| `reflector` | 直接候補なし | 対象外 |
| `ripgrep` | `ripgrep` 15.2.0 | 対象外 |
| `starship` | `starship` 1.26.0 | 対象外 |
| `tmux` | `tmux` 3.7c | 対象外 |
| `ttf-jetbrains-mono-nerd` | `nerd-fonts.jetbrains-mono` 3.5.0+2.304 | 対象外 |
| `trash-cli` | `trash-cli` 0.24.5.26 | 対象外 |
| `tree-sitter-cli` | `tree-sitter` 0.26.11 | 対象外 |
| `unzip` | `unzip` 6.0 | 対象外 |
| `vim` | `vim` 9.2.0782 | 対象外 |
| `whois` | `whois` 5.6.6 | 対象外 |
| `zoxide` | `zoxide` 0.10.0 | 対象外 |
| `zsh` | `zsh` 5.9.2 | 対象外 |

## 同梱判定の根拠

- [Astro language server のビルド定義](https://github.com/NixOS/nixpkgs/blob/58973d74f1893afe13f5902919803a0e99da0ca4/pkgs/by-name/as/astro-language-server/package.nix)
- [textlint のビルド定義と withPackages](https://github.com/NixOS/nixpkgs/blob/58973d74f1893afe13f5902919803a0e99da0ca4/pkgs/by-name/te/textlint/package.nix)
- [textlint 15.7.1 の依存宣言](https://github.com/textlint/textlint/blob/v15.7.1/packages/textlint/package.json): Markdown プラグインは通常依存。JTF ルールは開発用依存なので同梱候補として数えていない。
