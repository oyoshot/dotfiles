{ lib, stdenvNoCC, fetchurl, perl }:

# Not packaged in the pinned nixpkgs. Replace with pkgs.man-pages-ja when available.
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "man-pages-ja";
  version = "20260915";
  src = fetchurl {
    url = "https://github.com/linux-jm/manual/releases/download/v${finalAttrs.version}/man-pages-ja-${finalAttrs.version}.tar.gz";
    hash = "sha256-MwMUJuHkF52cQzTHIKHl22xL+JQ/J7h0pSRx9LZROFc=";
  };
  nativeBuildInputs = [ perl ];
  dontBuild = true;
  configurePhase = ''
    runHook preConfigure
    # Use upstream's default package priorities and conflict resolution without
    # interactive prompts. man-db supplies its own translated manuals.
    sed -i -E 's/^(man|man-db)([[:space:]]+)Y/\1\2N/' script/pkgs.list
    substituteInPlace script/configure.perl \
      --replace-fail '/usr/share/man/$LANG' "$out/share/man/ja" \
      --replace-fail '<STDIN>' '"\n"' \
      --replace-fail 'until ($ans =~' 'until (1 || $ans =~'
    perl script/configure.perl
    # Store files belong to the Nix builder; upstream defaults to root ownership.
    sed -i -E 's/chown [^;]+//; s/install -o [^ ]+ -g [^ ]+ /install /' installman.sh
    runHook postConfigure
  '';
  meta = {
    description = "Japanese translations of Linux manual pages";
    homepage = "https://linuxjm.sourceforge.io/";
    # Each manual retains its own upstream license and translation notices.
    license = lib.licenses.free;
    platforms = lib.platforms.linux;
  };
})
