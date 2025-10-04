{ pkgs, lib, ... }:
{
  appName = "gerg";

  providers = {
    ruby.enable = true;
    python3.enable = true;
    nodeJs.enable = true;
    perl.enable = true;
  };
  initLua = lib.mkBefore ''
    vim.g.mapleader = " "
  '';

  desktopEntry = false;

  abs.fzf-lua = {
    package = pkgs.vimPlugins.fzf-lua;
    lznOpts.cmd = "FzfLua";
    setupOpts = [
      "telescope"
      "hide"
    ];
  };
}
