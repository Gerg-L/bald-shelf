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
                  after = lib.mkOption {
                    type = lib.types.str;
                    default = "require('${config.name}').setup(${luaLib.toLuaObject config.setupOpts})";
                  };
                  keys = lib.mkOption {
                    type = lib.types.listOf (
                      lib.types.oneOf [
                        (lib.types.listOf lib.types.anything)
                        lib.types.str
                      ]
                    );
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
                    ${lib.optionalString (config.lznOpts.after != "")
                      "${luaLib.toLuaObject (lib.mkLuaInline config.lznOpts.after)}"
                    }
                  end,
                  keys = ${luaLib.toLuaObject config.lznOpts.keys},
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
