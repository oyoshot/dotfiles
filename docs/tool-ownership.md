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

macOS の ChatGPT / Firefox / Chrome / Notion は Home Manager 管理。
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
macOS の 1Password と CLI、Docker、Karabiner、Podman Desktop はホスト統合を維持。
Ghostty は固定 nixpkgs の macOS 非対応、JupyterLab Desktop と Notion Calendar は
対応する macOS パッケージがないため Homebrew に残す。

## 既存 mise 設定の移行

Home Manager 適用時に、移行対象のグローバル設定が従来の `"latest"` のままであれば削除する。
元ファイルは同じディレクトリの `config.toml.before-nix-*` に保存する。
バージョン固定・追加オプション・プロジェクトローカル設定は変更しない。
インストール済みの mise ツールも削除しない。
ユーザーが固定したグローバル設定は引き続き Nix より優先されるため、Nix に切り替える際は
該当項目を明示的に削除する。
