{
  inputs.dotfiles.url = "github:oyoshot/dotfiles/experiment/nix-cli";
  outputs = { dotfiles, ... }: {
    homeConfigurations.home = dotfiles.lib.mkHome {
      username = "@USERNAME@";
      homeDirectory = "@HOME@";
      system = "@SYSTEM@";
      wsl = @WSL@;
    };
  };
}
