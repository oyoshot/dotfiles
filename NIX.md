# Nix / Home Manager CLI 環境

Linux x86_64 と macOS Apple Silicon の CLI 64 パッケージを、`flake.lock` で固定したソースから導入する。
CLI と設定ファイルを Home Manager の同じ世代で管理する。

## 今回の分担

- Nix + Home Manager: mise から移した 48 件の CLI・LSP・フォーマッターと、bat / fzf / Neovim / tmux など日常用の 16 パッケージ。zacrs は公開済み Git リビジョンと Cargo の依存を固定してソースからビルドする。Home Manager が CLI の世代と切り替えを管理する。
- mise: 言語ランタイム、Terraform の複数バージョン、未収録の CLI、textlint のルール一式、Astro の言語サーバーと TypeScript プラグイン。
- Homebrew / Arch: GUI、OS 統合、シェル、コンパイラー、残りの CLI。今回 Brew から 16 件、Arch から 15 件の重複宣言を除いた。
- Rustup: Rust のツールチェーンとコンポーネント。

パッケージの一覧は `flake.nix`、移行前の依存調査は [NIX-DEPENDENCIES.md](NIX-DEPENDENCIES.md) を参照。
Nixpkgs の非自由パッケージ許可は、今回必要な `claude-code` に限定している。

## 導入

Nix 自体が必要。新しい端末には、先に [Nix 公式の導入手順](https://nix.dev/manual/nix/2.33/installation/installing-binary.html) でインストールする。
このリポジトリは Nix 本体を自動インストールしない。CI のみ、バージョンと SHA-256 を固定した公式インストーラーを使用する。

リポジトリのルートで:

```sh
sh script_home-apply.sh
exec zsh -l
```

`script_home-apply.sh` は OS に合う `homeConfigurations` を選び、CLI 一式をビルドして Home Manager の世代を切り替える。
成功すると `~/.local/state/nix/profiles/home-manager/home-path` からコマンドを使える。
ビルドや衝突確認に失敗した場合、Home Manager は現在の世代を維持して処理を止める。
同じ activation で Zsh、Neovim などの設定ファイルも反映するため、`chezmoi apply` は不要。

以後、CLI のビルドと切り替えは次のコマンドだけでよい:

```sh
sh script_home-apply.sh
```

個人の既存 Nix プロファイルとは別に世代を管理する。元の mise / Brew / Arch のインストール済みパッケージは削除しない。

## コマンドの選択

Zsh の基本の順序は `~/.local/bin` → Home Manager のプロファイル → 個人の Nix プロファイル → OS のコマンド → mise shims。
mise の有効化後は、プロジェクトで明示されたバージョンが優先される。
Neovim はこの順序を引き継ぎ、mise shims を先頭に割り込ませない。
Nix の man ページと Zsh 補完も読み込む。

```sh
command -v rg nvim herdr pyright
rg --version
nvim --version
```

Nix で移したコマンドは、通常 `~/.local/state/nix/profiles/home-manager/home-path/bin/` が選ばれる。
`~/.local/bin` に同名のラッパーがある場合や、プロジェクトの mise 設定に明示した場合はそちらが優先される。
すでに起動中のアプリやサーバーは、再起動するまで既存の実行ファイルを使い続ける。

## 評価・ビルド・更新

Nix が現在のシェルの PATH にない場合は `export PATH="$HOME/.nix-profile/bin:$PATH"` を先に実行する。

```sh
nix --extra-experimental-features 'nix-command flakes' flake check --all-systems --no-build
nix --extra-experimental-features 'nix-command flakes' build
./result/bin/rg --version
```

`flake check --no-build` は定義の評価。実際のビルド・起動確認は各 OS 上で別途行う。
`nix develop` でも同じ CLI 一式を使える。

```sh
nix --extra-experimental-features 'nix-command flakes' flake update nixpkgs home-manager
git diff -- flake.lock
sh script_home-apply.sh
```

通常の適用ではロックファイルを更新しない。`nixpkgs` と Home Manager は同じ `flake.lock` で固定され、Home Manager はこの flake の `nixpkgs` を共有する。

## 戻す

過去の世代を表示する:

```sh
home-manager generations
```

一覧に表示された過去の世代の `activate` を実行すると、その CLI 世代へ戻せる。
設定も戻す場合は、動作確認済みの `flake.nix`、`flake.lock` と設定ファイルに戻し、`sh script_home-apply.sh` を実行する。
移行全体を取り消す場合は、移行前の mise / Brew / Arch の宣言とシェル設定を復元する。

## 今回の検証（2026-09-10）

- Linux: 64 パッケージの実ビルドと、各パッケージの代表コマンドによるバージョン表示またはヘルプ起動。
- Linux: Home Manager の activation、Zsh のコマンド選択、mise 有効化後の Node / Terraform との共存、現在の設定による Neovim の起動と pyright の参照先。
- Linux / macOS: Home Manager 構成を含む flake の定義評価。ShellCheck、actionlint、シェル構文確認。

macOS の実ビルド・実機動作と、更新した CI 全体の実行は未確認。CI には Nix 導入と代表 CLI の起動確認を追加した。
