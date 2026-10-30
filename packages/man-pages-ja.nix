{
  lib,
  stdenvNoCC,
  perl,
  src,
}:

# Not packaged in the pinned nixpkgs. Replace with pkgs.man-pages-ja when available.
stdenvNoCC.mkDerivation {
  pname = "man-pages-ja";
  version = "unstable-${src.shortRev}";
  inherit src;
  nativeBuildInputs = [ perl ];
  dontConfigure = true;
  buildPhase = ''
    runHook preBuild
    perl bin/mkdist.perl . released
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    # Preserve upstream's package order and implicit inclusion of unlisted
    # packages. man-db already provides its own translated pages.
    while read -r package; do
      for page in released/manual/"$package"/man*/*; do
        [[ -f "$page" ]] || continue
        target="$out/share/man/ja/''${page#released/manual/$package/}"
        [[ -e "$target" ]] || install -Dm644 "$page" "$target"
      done
    done < <(awk '
      FNR == NR {
        enabled[$1] = $2
        if ($1 !~ /^#/ && $2 == "Y" && $1 != "man" && $1 != "man-db") order[++count] = $1
        next
      }
      { sub(/^.*\//, ""); if (!($0 in enabled)) print }
      END { for (i = 1; i <= count; i++) print order[i] }
    ' dist/script/pkgs.list <(printf '%s\n' released/manual/*))
    runHook postInstall
  '';
  meta = {
    description = "Japanese translations of Linux manual pages";
    homepage = "https://linuxjm.sourceforge.io/";
    # Each manual retains its own upstream license and translation notices.
    license = lib.licenses.free;
    platforms = lib.platforms.linux;
  };
}
