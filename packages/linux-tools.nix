{ pkgs }:
{
  # Use the official static release until nixpkgs provides Pandoc >= 3.11.
  # Updating the old Haskell package set would also require pandoc-lua-engine/server.
  # https://github.com/jgm/pandoc/releases/tag/3.11
  pandoc = if pkgs.lib.versionAtLeast pkgs.pandoc.version "3.11" then pkgs.pandoc else pkgs.stdenvNoCC.mkDerivation {
    pname = "pandoc-bin";
    version = "3.11";
    src = pkgs.fetchurl {
      url = "https://github.com/jgm/pandoc/releases/download/3.11/pandoc-3.11-linux-amd64.tar.gz";
      hash = "sha256-N+2zu89yL5IaAJlBv1h04uDAkmMibJtKLZgHiMsGKrY=";
    };
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r bin share $out/
      runHook postInstall
    '';
    nativeInstallCheckInputs = [ pkgs.versionCheckHook ];
    doInstallCheck = true;
    versionCheckProgram = "${placeholder "out"}/bin/pandoc";
    meta = pkgs.pandoc.meta // { platforms = [ "x86_64-linux" ]; };
  };
  # Remove this override once nixpkgs provides kislyuk/yq >= 4.4.0.
  # v4 uses Hatch; preserve nixpkgs' explicit jq dependency with the new layout.
  # https://github.com/kislyuk/yq/releases/tag/v4.4.0
  yq = if pkgs.lib.versionAtLeast pkgs.yq.version "4.4.0" then pkgs.yq else pkgs.yq.overridePythonAttrs (_: {
    version = "4.4.0";
    src = pkgs.fetchPypi { pname = "yq"; version = "4.4.0"; hash = "sha256-usZN8DMr6/Bc1v8rvTXkIaeb/inXxX7gIQM6Es2CAs0="; };
    patches = [ ];
    postPatch = ''
      substituteInPlace yq/__init__.py yq/parser.py test/test.py \
        --replace-fail '"jq"' '"${pkgs.jq}/bin/jq"'
    '';
    build-system = [ pkgs.python3Packages.hatchling pkgs.python3Packages.hatch-vcs ];
  });
  # Remove this override once nixpkgs provides rsync >= 3.5.1.
  # https://github.com/RsyncProject/rsync/releases/tag/v3.5.1
  rsync = if pkgs.lib.versionAtLeast pkgs.rsync.version "3.5.1" then pkgs.rsync else pkgs.rsync.overrideAttrs (old: {
    version = "3.5.1";
    src = pkgs.fetchurl { url = "https://download.samba.org/pub/rsync/src/rsync-3.5.1.tar.gz"; hash = "sha256-xV+cncEPuL7Dl7OZoP3e1TzJotjjCJG7DWNyTSXDe+8="; };
    buildInputs = old.buildInputs ++ [ pkgs.libidn2 ];
    # configure otherwise finds /usr/bin/fakeroot in unsandboxed CI builds.
    nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.fakeroot ];
    # New test creates a shell script with a /usr/bin/env shebang.
    preBuild = old.preBuild + ''
      substituteInPlace testsuite/rsync-ssl-type-option_test.py \
        --replace-fail '#!/usr/bin/env bash' '#!${pkgs.runtimeShell}'
    '';
    # Nix Linux sandboxes cannot chgrp to the unmapped supplementary GID 65534.
    # Keep the remaining upstream suite enabled.
    preCheck = old.preCheck + pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
      export RSYNC_EXCLUDE="$RSYNC_EXCLUDE,chgrp,daemon-groupmap-wild,ownership-depth"
    '';
  });
  # Backport the upstream nixpkgs update until it reaches the pinned channel.
  # https://github.com/NixOS/nixpkgs/commit/76ff714fa1b71bacbf2d3f01e31ca5617d679b0e
  # Remove once nixpkgs provides Obsidian >= 1.14.4.
  obsidian = if pkgs.lib.versionAtLeast pkgs.obsidian.version "1.14.4" then pkgs.obsidian else pkgs.obsidian.overrideAttrs {
    version = "1.14.4";
    src = pkgs.fetchurl { url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v1.14.4/obsidian-1.14.4.tar.gz"; hash = "sha256-5wt81jeH5/eYqE/sRT9cRGuRh3vT9hLo+5jpt2zIESA="; };
  };
}
