# Global defaults owned by Nix. Keys identify the former mise defaults.
# Project-local mise configurations can still select different versions.
pkgs: {
  "ansible" = pkgs.ansible;
  "helm" = pkgs.kubernetes-helm;
  "kubectl" = pkgs.kubectl;
  "oc" = pkgs.openshift;
  "odo" = pkgs.odo;
  "opentofu" = pkgs.opentofu;
  "pulumi" = pkgs.pulumi;
  "tekton" = pkgs.tektoncd-cli;
  "terraform-ls" = pkgs.terraform-ls;
  "tflint" = pkgs.tflint;
  "tfsec" = pkgs.tfsec;
  "npm:pyright" = pkgs.pyright;
  "ruff" = pkgs.ruff;
  "prettier" = pkgs.prettier;
  "npm:@fsouza/prettierd" = pkgs.prettierd;
  "stylua" = pkgs.stylua;
  "npm:bash-language-server" = pkgs.bash-language-server;
  "lua-language-server" = pkgs.lua-language-server;
  "npm:@vtsls/language-server" = pkgs.vtsls;
  "cspell" = pkgs.cspell;
  "shellcheck" = pkgs.shellcheck;
  "shfmt" = pkgs.shfmt;
  "tree-sitter" = pkgs.tree-sitter;
  "cargo:cargo-audit" = pkgs.cargo-audit;
  "cargo:cargo-chef" = pkgs.cargo-chef;
  "cargo:cargo-crev" = pkgs.cargo-crev;
  "cargo:cargo-deny" = pkgs.cargo-deny;
  "cargo:cargo-features-manager" = pkgs.cargo-features-manager;
  "cargo:cargo-generate" = pkgs.cargo-generate;
  "cargo:cargo-machete" = pkgs.cargo-machete;
  "cargo:cargo-make" = pkgs.cargo-make;
  "cargo:cargo-nextest" = pkgs.cargo-nextest;
  "cargo:cargo-sort" = pkgs.cargo-sort;
  "cargo:cargo-update" = pkgs.cargo-update;
  "cargo:typos-lsp" = pkgs.typos-lsp;
  "cargo:typos-cli" = pkgs.typos;
  "cargo:https://github.com/Feel-ix-343/markdown-oxide.git" = pkgs.markdown-oxide;
  "npm:@astrojs/language-server" = pkgs.astro-language-server;
}
