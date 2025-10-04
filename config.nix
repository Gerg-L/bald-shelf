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

  abs = {
    oil = {
      lznOpts.after = "-- do nothing";
      package = pkgs.vimPlugins.oil-nvim;
    };
    fzf-lua = {
      loadBefore = [ "oil" ];
      package = pkgs.vimPlugins.fzf-lua;
      lznOpts = {
        cmd = "FzfLua";
        keys = [
          [
            "<Leader>ff"
            (lib.mkLuaInline "function() FzfLua.files() end")
            { desc = "fzf files"; }
          ]
        ];
      };

      setupOpts = [
        "telescope"
        "hide"
      ];
    };
  };
}
