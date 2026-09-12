# Home Manager 環境

CLI と設定ファイルは Home Manager で管理する。chezmoi と適用ラッパーは不要。
設定の内容は `config/` と `local/` の普通のファイルとして保持し、`dotfiles.nix` の `xdg.configFile`・`home.file` で配置先を宣言する。

## 適用

このリポジトリで実行する:

```sh
# Linux / WSL (oyoshot)
home-manager switch --flake '.#oyoshot-linux'

# macOS Apple Silicon (oyoshot)
home-manager switch --flake '.#oyoshot-darwin'
```

新しい端末では先に Nix を導入し、Home Manager 本体がまだなければ次で初回適用できる:

```sh
export NIX_CONFIG='experimental-features = nix-command flakes'
nix run '.#home-manager' -- switch --flake '.#oyoshot-linux'
```

macOS では末尾を `.#oyoshot-darwin` にする。ユーザー名・ホームディレクトリが異なる場合は `flake.nix` にその端末の構成を追加する。
初回に既存ファイルとの衝突が出たら、差分を確認して `home-manager -b before-home-manager switch --flake '.#oyoshot-linux'` で退避する。通常の定義に `force = true` は入れない。

反映後にシェルを開き直すか `exec zsh -l` を実行する。
設定を編集するときはホームの管理リンクではなく、このリポジトリの `config/`・`local/` を編集して再適用する。
Neovim の lazy.nvim は初回起動時に配布用ロックを `~/.local/state/nvim/lazy-lock.json` へコピーし、以後そこへ更新を保存する。更新結果を他の端末にも配布する場合は、このファイルを `config/nvim/lazy-lock.json` へ取り込んでコミットする。通常の再適用・再起動では更新済みロックを上書きしない。

## 分担

- `flake.nix`: 共有 CLI、プラットフォーム、ユーザー。
- `home.nix`: Home Manager のモジュールと互換性バージョン。
- `dotfiles.nix`: 設定ファイルの配置。OS 別の配置先とホーム依存のテンプレートもここで指定する。
- `externals.nix`: Zsh プラグイン、tmux plugin manager、Alacritty テーマ、校正ルール、WSL クリップボード。ソースは `flake.lock` またはハッシュで固定する。
- `services.nix`: Neovim ログローテーションと WSLg fcitx の systemd／launchd 定義。
- mise: ランタイム、Terraform の複数バージョン、未移行 CLI、textlint のルール等。
- Homebrew / Arch: GUI、OS 統合、シェル、コンパイラー等。

Linux / macOS とも `nix.settings.use-xdg-base-directories = true` を使う。ユーザーのパッケージプロファイルは `~/.local/state/nix/profile`、その世代は `~/.local/state/nix/profiles/profile-*-link` に保存する。Home Manager 自身の世代は同じ `profiles` 内の `home-manager-*-link`。シェルは `nix/profile/bin` を参照し、`~/.nix-profile` への互換リンクは作らない。初回 switch では nix.conf の配置前からこの設定を有効にする。旧 `~/.nix-profile` と旧世代は削除しない。

新規端末の OS パッケージ・Rustup・mise は、Home Manager 適用後に `sh scripts/bootstrap-host.sh` で導入する。この処理はホストのパッケージをインストールし、Arch ではシステム更新も行うため、通常の Home Manager activation からは呼ばない。

herdr のタイトルプラグインは固定したソースと Cargo.lock から Nix でビルドする。Home Manager は CLI と設定の配置後に、`CODEX_HOME` と `CLAUDE_CONFIG_DIR` を明示してタイトルフックと herdr 統合を登録する。初回起動や mise / Rustup は不要。設定ファイルは他のフックを保持したまま更新するため、書き込み可能なユーザー設定として残す。プラグインの機能はフックのみなので、`herdr plugin install` のビルド・登録経路は使わず、Nix のバイナリから `install-hooks` を実行する。
WSLg のパッチ適用と Windows ランチャー登録は `scripts/setup-wslg.sh` に残している。

GPG agent・memo・fcitx のリポジトリ内設定は認証情報を含まない通常の設定として管理する。`private_` という旧ファイル名だけを根拠とする権限変更は廃止した。Nix store のファイルは読み取り可能なので、今後秘密鍵・トークンをこの構成に埋め込まない。

## 更新と検証

```sh
nix flake update nixpkgs home-manager
# 外部プラグインも更新する場合は nix flake update
git diff -- flake.lock
home-manager switch --flake '.#oyoshot-linux'
```

お知らせを見る場合も、このリポジトリの構成を指定する:

```sh
home-manager news --flake '.#oyoshot-linux'
```

この Zsh 設定では `#` がパターンとして解釈されるため、flake の指定を引用符で囲む。`--flake` を省略すると Home Manager は標準の設定場所を探すため、このリポジトリの構成は選ばれない。

更新前の世代は `home-manager generations` で確認し、表示された過去のストアパスの `activate` を実行して戻せる。

```sh
nix flake check --all-systems --no-build
nix build '.#homeConfigurations.oyoshot-linux.activationPackage' --no-link
```

`flake check` だけでは任意の `homeConfigurations` 全体を評価しないため、CI では4構成それぞれの `activationPackage.drvPath` も評価する。Linux と macOS の新規環境は、それぞれ `ci-linux`（builder）と `ci-darwin`（runner）を適用し、ホストのセットアップと CLI 起動を検証する。

CI でも個人端末と同じ Home Manager activation で herdr の Codex / Claude 統合を実行し、両方の設定先とタイトルフックを検証する。

zacrs とタイトルプラグインは、Nix でビルドした実行時依存一式を `nix-store --export` で保存し、次回 `--import` する。GitHub Actions キャッシュは OS・アーキテクチャ・flake とパッケージ定義のハッシュで分け、定義が変わった場合も以前のキャッシュを復元して Nix が一致する成果物だけを再利用する。保存はホストセットアップより前に行う。公式パッケージは引き続き `cache.nixos.org` を使う。このキャッシュは CI 用で、個人端末へのバイナリ配布は行わない。

Home Manager の基本操作は [公式マニュアル](https://nix-community.github.io/home-manager/usage/configuration.html) を参照。

## この移行で確認した範囲

- Linux 実機への初回切り替えと、バックアップ指定なしの再適用。
- CLI の参照先、Zsh と zacrs、fcitx とログローテーションの systemd 有効化・稼働状態。
- Linux CI 用世代のビルドと、空のホーム向け世代内の設定・外部ソース・実行権限。
- macOS を含む4構成の評価、ShellCheck、Zsh 構文、actionlint。

macOS 実機での適用と GitHub Actions 全体の実行は、この作業環境では未実施。
