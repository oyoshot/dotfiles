# DELETE WHEN WSLg #1495 IS FIXED

The patch prevents stale Fcitx candidate windows under WSLg.
Upstream issue: https://github.com/microsoft/wslg/issues/1495

`services.nix` applies it to the Nix Fcitx package. The former Arch package
build/install/rollback scripts have been removed after verifying the Nix migration.

Once the upstream issue is fixed, remove the patch reference from `services.nix`
and delete this directory after checking candidate rendering on WSLg.
