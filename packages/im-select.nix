{ lib, stdenv, fetchFromGitHub }:

# Not packaged in nixpkgs. Replace with pkgs.im-select when available.
stdenv.mkDerivation {
  pname = "im-select";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "daipeihust";
    repo = "im-select";
    rev = "bb3a603ee83c8a754ffc9ac7e6d425d6928faa3c"; # 1.0.1
    hash = "sha256-XIx0RDXr5I5rnnIDnbmqqbJw1bZ9NhqYW/Durpfa8U4=";
  };

  dontConfigure = true;
  buildPhase = ''
    runHook preBuild
    $CC -fobjc-arc -framework Foundation -framework Carbon \
      im-select-mac/im-select/im-select/main.m -o im-select
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    install -Dm755 im-select "$out/bin/im-select"
    runHook postInstall
  '';

  meta = {
    description = "Switch the macOS input method from the command line";
    homepage = "https://github.com/daipeihust/im-select";
    license = lib.licenses.mit;
    mainProgram = "im-select";
    platforms = lib.platforms.darwin;
  };
}
