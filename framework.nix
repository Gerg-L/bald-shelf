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
                  enabled = lib.mkOption {
                    type = lib.types.oneOf [
                      lib.types.str
                      lib.types.bool
                    ];
                    default = "";
                  };
                  beforeAll = lib.mkOption {
                    type = lib.types.str;
                    default = "";
                  };
                  before = lib.mkOption {
                    type = lib.types.str;
                    default = "";
                  };
                  after = lib.mkOption {
                    type = lib.types.str;
                    default = "require('${config.name}').setup(${luaLib.toLuaObject config.setupOpts})";
                  };
                  event = lib.mkOption {
                    type = lib.types.oneOf [
                      (lib.types.listOf lib.types.str)
                      lib.types.str
                    ];
                    default = [ ];
                  };
                  cmd = lib.mkOption {
                    type = lib.types.oneOf [
                      (lib.types.listOf lib.types.str)
                      lib.types.str
                    ];
                    default = [ ];
                  };
                  ft = lib.mkOption {
                    type = lib.types.oneOf [
                      (lib.types.listOf lib.types.str)
                      lib.types.str
                    ];
                    default = [ ];
                  };
                  keys = lib.mkOption {
                    type = lib.types.listOf (
                      lib.types.oneOf [
                        (lib.types.listOf lib.types.anything)
                        lib.types.str
                      ]
                    );
                  };
                  colorscheme = lib.mkOption {
                    type = lib.types.oneOf [
                      (lib.types.listOf lib.types.str)
                      lib.types.str
                    ];
                    default = [ ];
                  };
                  lazy = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                  };
                  priority = lib.mkOption {
                    type = lib.types.int;
                    default = 50;
                  };
                  load = lib.mkOption {
                    type = lib.types.str;
                    default = "";
                  };
                };
              };
            };

            textOutput = lib.mkOption {
              type = lib.types.lines;
              default =
                let
                  cfg = config.lznOpts;
                in

                ''
                  return {
                    "${getName config.package}",
                    ${lib.optionalString (cfg.enabled != "") ''
                      enabled = 
                         ${
                           if builtins.isBool cfg.enabled then
                             luaLib.toLuaObject cfg.enabled
                           else
                             ''
                               function()
                               ${luaLib.toLuaObject (lib.mkLuaInline cfg.enabled)}
                                  end
                             ''
                         },
                    ''}
                    ${lib.optionalString (cfg.beforeAll != "") ''
                      beforeAll = function()
                          ${luaLib.toLuaObject (lib.mkLuaInline cfg.beforeAll)}
                      end,
                    ''}
                    ${lib.optionalString (cfg.before != "") ''
                      before = function()
                          ${luaLib.toLuaObject (lib.mkLuaInline cfg.before)}
                      end,
                    ''}
                    ${lib.optionalString (cfg.after != "") ''
                      after = function()
                          ${luaLib.toLuaObject (lib.mkLuaInline cfg.after)}
                      end,
                    ''}
                    ${lib.optionalString (cfg.event != [ ]) "event = ${luaLib.toLuaObject cfg.event},"}
                    ${lib.optionalString (cfg.cmd != [ ]) "cmd = ${luaLib.toLuaObject cfg.cmd},"}
                    ${lib.optionalString (cfg.ft != [ ]) "ft = ${luaLib.toLuaObject cfg.ft},"}
                    ${lib.optionalString (cfg.keys != [ ]) "keys = ${luaLib.toLuaObject cfg.keys},"}
                    ${lib.optionalString (
                      cfg.colorscheme != [ ]
                    ) "colorscheme = ${luaLib.toLuaObject cfg.colorscheme},"}
                    lazy = ${luaLib.toLuaObject cfg.lazy},
                    priority = ${luaLib.toLuaObject cfg.priority},
                    ${lib.optionalString (cfg.load != "") "load = ${luaLib.toLuaObject (lib.mkLuaInline cfg.lazy)},"}
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
