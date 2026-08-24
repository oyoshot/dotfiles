# DELETE THIS DIRECTORY WHEN WSLg #1495 IS FIXED

This is a temporary local build of fcitx5 that avoids stale candidate
windows under WSLg.

Upstream issue: https://github.com/microsoft/wslg/issues/1495

On Arch WSLg machines, `chezmoi apply` installs the patched package
automatically while the installed fcitx5 version matches this pinned recipe.
The onchange setup script skips unknown newer versions instead of downgrading
them or failing the rest of the apply.

Manual install:

```sh
sh ./.workarounds/REMOVE_WHEN_WSLG_1495_IS_FIXED/fcitx5-wslg-workaround install
```

Restore the official Arch package:

```sh
sh ./.workarounds/REMOVE_WHEN_WSLG_1495_IS_FIXED/fcitx5-wslg-workaround rollback
```

Once the upstream issue is fixed, restore the official package and delete
this entire directory. Nothing in this directory is permanent configuration.
