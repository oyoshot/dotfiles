{
  # Each machine locks a revision of the shared configuration. Its dependencies
  # remain pinned by the shared repository's lock file.
  inputs.dotfiles.url = "github:oyoshot/dotfiles/experiment/nix-cli";

  outputs = { dotfiles, ... }: {
    homeConfigurations.home = dotfiles.lib.mkHome (import ./machine.nix);
  };
}
