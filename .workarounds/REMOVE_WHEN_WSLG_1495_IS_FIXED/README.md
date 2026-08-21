# DELETE THIS DIRECTORY WHEN WSLg #1495 IS FIXED

This is a temporary local build of fcitx5 that avoids stale candidate
windows under WSLg.

Upstream issue: https://github.com/microsoft/wslg/issues/1495

Install:

```sh
sh ./.workarounds/REMOVE_WHEN_WSLG_1495_IS_FIXED/fcitx5-wslg-workaround install
```

Restore the official Arch package:

```sh
sh ./.workarounds/REMOVE_WHEN_WSLG_1495_IS_FIXED/fcitx5-wslg-workaround rollback
```

Once the upstream issue is fixed, restore the official package and delete
this entire directory. Nothing in this directory is permanent configuration.
