{ runCommand, undmg, src, version }:

# Keep the vendor PKG intact: its signed helpers and DriverKit extension require
# installation at their system paths. nix-darwin's service module does not yet
# support Karabiner >= 15 (nix-darwin#1041).
runCommand "karabiner-elements-installer-${version}" {
  inherit src version;
  nativeBuildInputs = [ undmg ];
} ''
  undmg "$src"
  install -Dm644 Karabiner-Elements.pkg "$out/share/karabiner-elements/Karabiner-Elements.pkg"
  mkdir -p "$out/bin"
  ln -s '/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli' "$out/bin/karabiner_cli"
''
