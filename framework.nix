{
  config,
  lib,
  pkgs,
  ...
}:
let
  luaLib = import ./stolen.nix { inherit lib; };
  getName = x: lib.removePrefix "vimplugin-" (lib.getName x);
in
{
  options.abs = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, config, ... }:
        {
          options = {
            package = lib.mkOption {
              type = lib.types.package;
            };

            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
            name = lib.mkOption {
              type = lib.types.str;
              default = name;
            };

            setupOpts = lib.mkOption {
              default = { };
              type = lib.types.anything;
            };

            lznOpts = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  cmd = lib.mkOption {
                    type = lib.types.oneOf [
                      (lib.types.listOf lib.types.str)
                      lib.types.str
                    ];
                    default = "";
                  };
                };
              };
            };

            textOutput = lib.mkOption {
              type = lib.types.lines;
              default = ''
                return {
                  "${getName config.package}",
                  cmd = ${lib.optionalString (config.lznOpts.cmd != "") "${luaLib.toLuaObject config.lznOpts.cmd}"},
                  after = function()
                    require('${config.name}').setup(${luaLib.toLuaObject config.setupOpts})
                  end,
                  keys = {
                    {
                      "<leader>ff",
                      function()
                        FzfLua.files()
                      end,
                      desc = "fzf files",
                    },
                  }
                }
              '';
            };
          };
        }
      )
    );
  };

  config =
    let
      enabledPlugins = lib.filterAttrs (_: value: value.enable) config.abs;
    in
    {
      initLua = ''
        require("lz.n").load("mog")
      '';

      plugins = {
        start = [
          pkgs.vimPlugins.lz-n

          (pkgs.symlinkJoin {
            name = "mog";
            paths = lib.mapAttrsToList (
              name: value: (pkgs.writeTextDir "lua/mog/${name}.lua" value.textOutput)
            ) enabledPlugins;
          })
        ];

        opt = lib.mapAttrsToList (_: value: value.package) enabledPlugins;
      };

    };
}
