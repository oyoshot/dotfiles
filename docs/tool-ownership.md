# ツールの管理方針

ユーザーランドのツールと設定は、できるだけ Nix / Home Manager で管理する。
言語バージョン切り替えや upstream の実行環境との互換性に必要な範囲は mise に任せる。
システム設定・権限・ホストの SDK / ライブラリに関わるものは OS の管理に残す。
「開発ツール」「最新版が必要」という分類だけでは mise に移さない。

## Nix

共通 CLI は `flake.nix`、mise から移した一般 CLI / LSP は
`packages/user-tools.nix`、OS 別のユーザーパッケージは `home.nix`。
macOS の Composer は PHP と、LuaRocks は両 OS で Lua 5.4 と一緒に供給する。
異なる PHP / Lua を使うプロジェクトは、その runtime に合うパッケージ管理環境を
プロジェクト単位で指定する。

macOS の GUI は `packages/darwin-apps.nix` に集約し、Home Manager の `copyApps` で
`~/Applications/Home Manager Apps` に配置する。1Password / ChatGPT / Firefox /
Chrome / Ghostty / Notion / Podman Desktop / WezTerm は nixpkgs の既存定義を使う。
Ghostty の macOS 用パッケージ名は `ghostty-bin`。
Notion Calendar と JupyterLab Desktop は [brew-nix](https://github.com/BatteredBunny/brew-nix) の
`notion-calendar` / `jupyterlab-app` を使う。Homebrew を実行するのではなく、cask の
メタデータから Nix パッケージを生成する。1Password CLI も Nix 管理。

brew-nix の変換実装と brew-api のメタデータは別 input として `flake.lock` に固定する。
アプリの更新は `nix flake update brew-api`、変換実装の更新は `nix flake update brew-nix`。
nixpkgs 由来のアプリは `nix flake update nixpkgs` で更新する。
brew-nix は experimental で、cask のインストールフックや OS サービス設定すべてを
再現するものではない。対象は確認した通常の app bundle に限定する。

macOS CI では Nix のビルドと Home Manager の適用・再適用を確認する。
アプリの起動・ログイン・OS 権限・外部サービスとの連携は、移行時に実機で確認する。
CI の成功だけで GUI の正常動作まで確認済みとは扱わない。

更新元は Nix とし、アプリに自動更新を止める設定がある場合は無効にする。
`copyApps` の配置先は書き込み可能なコピーなので、アプリによる更新を技術的に禁止するわけではない。
Home Manager の再適用で固定済み bundle を再配置する。Nix の世代を戻しても、
アプリが更新したユーザーデータまで戻るわけではない。
既存の Homebrew アプリは自動削除しない。macOS で Home Manager 側の起動と
ユーザーデータの保持を確認した後、重複する Homebrew インストールを整理する。

## mise に残す範囲

- 言語ランタイム、コンパイラ、言語用パッケージ管理、Terraform のバージョン選択。
- gopls：ビルドに使った Go と対象プロジェクトの Go の互換性があるため、Go と合わせて更新。
- cargo-expand / cargo-udeps / cargo-llvm-cov：nightly / rustup / LLVM コンポーネントとの連携。
- cargo-lambda：選択した Zig を利用するため。固定 nixpkgs のパッケージは Zig を PATH の先頭に追加する。
- flamegraph：ホストのプロファイラとの連携。
- Astro の TypeScript プラグイン、textlint とそのルール：Node のモジュール解決。
- cargo-compete / memo / atcoder-cli / mcp-hub / md-to-pdf / prh：固定 nixpkgs に対応するパッケージがないため、現時点では upstream のインストーラを維持。
  これは互換性上の恒久的な除外ではなく、独自 derivation を用意する場合の候補。

## OS 側に残す範囲

ホストのコンパイラ・リンカ・OpenSSL・pkgconf、Arch の基盤パッケージ・Fcitx・
FUSE・コンテナポリシー・ログインシェルはホスト側で揃える。
macOS の Docker Desktop は当面 Homebrew に残す。アプリ本体だけでなく CLI・socket・VM の
連携まで検証してから移行を判断する。管理者権限が常に必要という理由ではない。
Karabiner は DriverKit と launch daemon の統合があるため、Homebrew の upstream
インストーラを維持する。nix-darwin 側の対応状況も含め、通常アプリとは別に検証する。
Podman Desktop 本体とその Podman 依存は Nix のパッケージで供給する。

## Homebrew との統合

現在は standalone Home Manager と `scripts/bootstrap-host.sh` を使い、残りの
OS パッケージは Brewfile から明示的に導入する。nix-darwin はまだ導入していない。

[nix-darwin の homebrew モジュール](https://nix-darwin.github.io/nix-darwin/manual/#opt-homebrew.enable)
を使うと cask/formula を Nix で宣言できるが、実際の導入・更新は Homebrew が担当する。
[nix-homebrew](https://github.com/zhaofengli/nix-homebrew) は Homebrew 本体と tap を
管理する別モジュールで、パッケージ一覧は nix-darwin の `homebrew.*` で管理する。
これらは Nix store 内にアプリを格納する今回の方式とは管理主体が異なる。

## 既存 mise 設定の移行

Home Manager 適用時に、移行対象のグローバル設定が従来の `"latest"` のままであれば削除する。
元ファイルは同じディレクトリの `config.toml.before-nix-*` に保存する。
バージョン固定・追加オプション・プロジェクトローカル設定は変更しない。
インストール済みの mise ツールも削除しない。
ユーザーが固定したグローバル設定は引き続き Nix より優先されるため、Nix に切り替える際は
該当項目を明示的に削除する。
