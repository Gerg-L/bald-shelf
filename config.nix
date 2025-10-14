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

  lz-n.specs = {
    #    oil = {
    #      lznOpts.after = "-- do nothing";
    #      package = pkgs.vimPlugins.oil-nvim;
    #    };
    fzf-lua = {
      # oil is a bad example here
      #loadBefore = [ "oil" ];
      package = pkgs.vimPlugins.fzf-lua;
      lznOpts = {
        #  beforeAll = "--";
        #  before = "--";
        #  # setting after overrides the default
        #  #after = "";
        event = "DeferredUIEnter";
        #  ft = "nix";
        #colorscheme = "blue";
        lazy = true;
        #  priority = 50;
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
