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
- mise: プロジェクトによってバージョンが変わる開発ツール。ランタイムだけでなく Terraform 等の CLI も含む。本体と共通設定は Home Manager が管理する。
- Homebrew / Arch: GUI、OS 統合、シェル、コンパイラー等。

Linux / macOS とも `nix.settings.use-xdg-base-directories = true` を使う。ユーザーのパッケージプロファイルは `~/.local/state/nix/profile`、その世代は `~/.local/state/nix/profiles/profile-*-link` に保存する。Home Manager 自身の世代は同じ `profiles` 内の `home-manager-*-link`。シェルは `nix/profile/bin` を参照し、`~/.nix-profile` への互換リンクは作らない。初回 switch では nix.conf の配置前からこの設定を有効にする。旧 `~/.nix-profile` と旧世代は削除しない。

新規端末の OS パッケージ・Rustup・mise 管理ツールは、Home Manager 適用後に `sh scripts/bootstrap-host.sh` で導入する。mise 本体はこの時点ですでに Home Manager が提供する。この処理はホストのパッケージをインストールし、Arch ではシステム更新も行うため、通常の Home Manager activation からは呼ばない。

### mise の設定と段階移行

`home.nix` の `programs.mise` は共通設定を `~/.config/mise/conf.d/50-home-manager.toml` に配置する。`~/.config/mise/config.toml` は書き込み可能とし、初回のみ `config/mise/config.toml` のツール指定をコピーする。以後の `mise use --global` による変更は再適用で上書きしない。共通設定と同じキーを mutable な設定に重複して書かない。以前の HM 管理リンクは切り替え時に除去してから初期化し、既存の通常ファイルは保持する。

`.tool-versions` に加え、Terraform・Node・Python・Rust の idiomatic version files を有効にする。既存 repo の指定を優先し、未導入のバージョンはその repo で `mise install` する。

既存 `.zshrc` が mise と direnv を一つの遅延 hook で調停するため、両者の HM `enableZshIntegration` は無効。最初のコマンド実行時に `project-environment.zsh` を読み込み、以後はディレクトリ移動・プロンプト表示時に反映する。起動時に mise/direnv を実行したり `$commands` 全体を構築したりしない。以前の「Nix の直後に shims を挿入する」補正は削除した。

最終的な分担は machine/user scope → Nix/Home Manager、project scope → mise。repo が正式な devShell を提供する場合のみ、その repo の開発環境を Nix に任せる。単に `flake.nix` があるだけでは切り替えない。

切り替えの事前検証（Linux、mise 2026.8.6 / direnv 2.37.1 / nix-direnv 3.2.0）では、両方の標準 hook を動かすと、Nix の executable が選ばれていても devShell の環境変数を mise が上書きした。一時環境で mise を解除してから direnv を反映し、`IN_NIX_SHELL` がない場合だけ mise を有効にする順序を試すと、出入り・繰り返し実行・通常環境への復帰が成功した。flake の存在だけでは切り替えず、`use flake` の成功で実際に得られた環境を使う。検証では `nix_direnv_disallow_fallback` により失敗時の旧 devShell 再利用を無効にした。

直接 `nix develop` / `nix shell` する場合は、小さな zsh 関数が子プロセス内で mise を解除してから実行する。オプションは `nix develop --offline ...` のようにサブコマンドの後に置く。`command nix` や Nix バイナリの絶対パス呼び出しはこの関数を通らない。Nix 環境内の子 zsh は引き継いだ PATH と `CARGO_TARGET_DIR` を尊重する。Neovim も shims を追加せず、GUI 起動時に不足する共通ツールのプロファイルだけを通常環境で末尾へ補う。

正式な devShell がある repo では、README・既存 `.envrc` の指示を確認し、未設定なら `.envrc` に `use flake` を書いて `direnv allow` する。この dotfiles は repo の `.envrc` を自動作成・自動許可しない。Home Manager の nix-direnv 設定は、ビルド失敗時の古い devShell への fallback を無効にする。

段階移行の例外として、手動 rustup 等の Cargo・Deno・Gem 用 PATH は通常環境でのみ残し、Nix に渡す前に除く。Helm・OpenTofu・Pulumi・terraform-ls・TFLint・tfsec は mise に移した。その他の開発用 CLI の移行はまだ残っている。GUI Neovim の project toolchain は、環境を有効にした端末から起動して渡す。すでに起動済みの Neovim 内での別 project への切り替えは、この shell integration の対象外。

この6ツールは移行前の運用に合わせて `latest` を既定とする。Node・Python・Terraform の既存の明示バージョンは維持する。repo にバージョン指定があればそちらで解決する。

既存端末の mutable config は再適用で変更しないため、今回の変更を別端末に適用する際は、先に以下で6ツールを導入してから Home Manager を switch する（個別に固定したいものは指定を変更する）:

```sh
mise use --global helm@latest opentofu@latest pulumi@latest terraform-ls@latest tflint@latest tfsec@latest
```

新規端末では初期設定に含まれるため、従来どおり Home Manager 適用後の `scripts/bootstrap-host.sh` が導入する。バージョン指定が `latest` でも既存の導入済みバイナリが自動更新されるわけではない。更新時は `mise upgrade` を使う。

Neovim 用の pyright・gopls・Ruff・Prettier/prettierd・StyLua・Bash/Lua/TypeScript LSP・cspell・ShellCheck・shfmt・tree-sitter も mise に移した。既存端末では switch 前に次を実行する:

```sh
mise use --global npm:pyright@latest go:golang.org/x/tools/gopls@latest \
  pipx:ruff@latest prettier@latest npm:@fsouza/prettierd@latest stylua@latest \
  npm:bash-language-server@latest lua-language-server@latest npm:@vtsls/language-server@latest \
  cspell@latest shellcheck@latest shfmt@latest tree-sitter@latest
```

Ruff は移行前と同じ `pipx:ruff` を使う。今回の Aqua 配布経路では署名検証に失敗したため、検証を無効化せず、[mise の pipx backend](https://mise.jdx.dev/dev-tools/backends/pipx.html) で PyPI パッケージを導入した。uv は引き続き現在の Nix パッケージが提供する。Markdown Oxide と typos-lsp は Cargo 経由の導入を Rust/Cargo の段階で確認してから移す。

Neovim は起動元の project 環境を使い、pyright の `.venv` 優先と Deno 判定は維持する。非対話スクリプトや GUI から開く場合も、その repo で `mise exec -- nvim` を使えば明示的に環境を渡せる。正式な devShell のある repo では、その環境から起動する。

2026-09-12 の Linux 検証では、実装した hook による devShell への出入り・繰り返し・子 zsh・読み込み失敗・直接 `nix develop` 後の親環境保持を確認した。起動時間は適用前後の設定を同じ条件の一時 ZDOTDIR から読み、`hyperfine -w 100 -m 500` で比較。計測順を反転した比較は `zsh -ic exit` が 6.8 → 6.9 ms、`zsh -lic exit` が 13.3 → 13.4 ms。実機への switch 前の計測であり、最初のコマンドで遅延実行する mise/direnv の処理時間は含まない。

同日の Arch WSL 実機への switch も成功。mutable な mise 設定、Nix のバイナリ参照先、Neovim、herdr 統合、zacrs daemon を確認した。適用後の同じ起動ベンチマークは 6.7 / 13.4 ms（ログイン側に一度 199 ms の外れ値あり）。Tab / Enter による補完選択の操作確認は別途行う。

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
