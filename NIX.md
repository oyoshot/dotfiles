# Nix CLI 環境

Linux x86_64 と macOS Apple Silicon の CLI 64 パッケージを、`flake.lock` で固定したソースから導入する。
設定ファイルは引き続き chezmoi で管理する。

## 今回の分担

- Nix: mise から移した 48 件の CLI・LSP・フォーマッターと、bat / fzf / Neovim / tmux など日常用の 16 パッケージ。zacrs は公開済み Git リビジョンと Cargo の依存を固定してソースからビルドする。
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
chezmoi apply
exec zsh -l
```

chezmoi の before スクリプトが、設定ファイルの更新前に CLI 一式をビルドする。
成功すると専用プロファイル `~/.local/state/nix/profiles/dotfiles` を切り替える。
ビルド失敗時には、現在のプロファイルと適用前の設定を保持して処理を止める。
Nix 用のディレクトリは `XDG_STATE_HOME` があればその下を使う。

CLI のビルドと切り替えだけを再実行する場合:

```sh
sh script_nix-apply.sh
```

個人の既存 Nix プロファイルとは別に世代を管理する。元の mise / Brew / Arch のインストール済みパッケージは削除しない。

## コマンドの選択

Zsh の基本の順序は `~/.local/bin` → Nix の dotfiles プロファイル → 個人の Nix プロファイル → OS のコマンド → mise shims。
mise の有効化後は、プロジェクトで明示されたバージョンが優先される。
Neovim はこの順序を引き継ぎ、mise shims を先頭に割り込ませない。
Nix の man ページと Zsh 補完も読み込む。

```sh
command -v rg nvim herdr pyright
rg --version
nvim --version
```

Nix で移したコマンドは、通常 `~/.local/state/nix/profiles/dotfiles/bin/` が選ばれる。
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
nix --extra-experimental-features 'nix-command flakes' flake update nixpkgs
git diff -- flake.lock
chezmoi apply
```

通常の適用ではロックファイルを更新しない。`flake.nix`、`flake.lock`、適用スクリプトが変わると、chezmoi がビルドと切り替えを再実行する。

## 戻す

2 世代目以降の更新を戻す場合:

```sh
nix-env --profile "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/dotfiles" --list-generations
nix-env --profile "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/dotfiles" --rollback
```

これは CLI の世代だけを戻す。設定も戻す場合は、動作確認済みの `flake.nix`、`flake.lock` と設定ファイルに戻し、`chezmoi apply` を実行する。
移行全体を取り消す場合は、移行前の mise / Brew / Arch の宣言とシェル設定を復元する。

## 今回の検証（2026-09-10）

- Linux: 64 パッケージの実ビルドと、各パッケージの代表コマンドによるバージョン表示またはヘルプ起動。
- Linux: 専用プロファイルへの登録、Zsh のコマンド選択、mise 有効化後の Node / Terraform との共存、現在の設定による Neovim の起動と pyright の参照先。
- ビルド失敗時に既存プロファイルを維持し、一時ディレクトリを片付けること。
- Linux / macOS: flake の定義評価。ShellCheck、actionlint、chezmoi before テンプレートの描画・構文確認。

macOS の実ビルド・実機動作と、更新した CI 全体の実行は未確認。CI には Nix 導入と代表 CLI の起動確認を追加した。
