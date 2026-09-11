{ lib, rustPlatform, pkg-config, sqlite, src }:
rustPlatform.buildRustPackage {
  pname = "herdr-plugin-agent-title";
  version = "0.1.0-${builtins.substring 0 7 src.rev}";
  inherit src;
  cargoLock.lockFile = src + "/Cargo.lock";
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ sqlite ];
  meta = {
    description = "Native Codex and Claude session titles for Herdr";
    homepage = "https://github.com/oyoshot/herdr-plugin-agent-title";
    license = lib.licenses.mit;
    mainProgram = "herdr-plugin-agent-title";
    platforms = [ "x86_64-linux" "aarch64-darwin" ];
  };
}
