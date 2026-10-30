{
  inputs.dotfiles.url = "@DOTFILES@";
  outputs = { dotfiles, ... }: {
    homeConfigurations.home = dotfiles.lib.mkHome {
      username = "@USERNAME@";
      homeDirectory = "@HOME@";
      system = "@SYSTEM@";
      wsl = builtins.fromJSON "@WSL@";
    };
  };
}
