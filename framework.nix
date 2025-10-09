{
  config,
  lib,
  pkgs,
  ...
}:
let
  config' = config;
  toLuaObject = import ./toLuaObject.nix lib;
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
            loadBefore = lib.mkOption {
              default = [ ];
              type = lib.types.listOf lib.types.str;
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
                    type = lib.types.lines;
                    default = "";
                  };
                  before = lib.mkOption {
                    type = lib.types.lines;
                    default = "";
                  };
                  after = lib.mkOption {
                    type = lib.types.lines;
                    default = "require('${config.name}').setup(${toLuaObject config.setupOpts})";
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
                    default = [ ];
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
                  func =
                    name:
                    let
                      val = builtins.getAttr name cfg;
                    in
                    lib.optionalString (val != "") ''
                      ${name} = function()
                          ${toLuaObject (lib.mkLuaInline val)}
                        end'';
                  obj =
                    name:
                    let
                      val = builtins.getAttr name cfg;
                    in
                    lib.optionalString (val != [ ]) "${name} = ${toLuaObject val}";
                in
                ''
                  return {
                    ${lib.concatStringsSep ",\n  " (
                      builtins.filter (x: x != "") [
                        "\"${getName config.package}\""
                        (lib.optionalString (cfg.enabled != "")
                          ''enabled = ${
                            if builtins.isBool cfg.enabled then
                              toLuaObject cfg.enabled
                            else
                              ''
                                function()
                                ${toLuaObject (lib.mkLuaInline cfg.enabled)}
                                   end''
                          }''
                        )
                        (func "beforeAll")
                        (func "before")
                        (func "after")
                        (obj "event")
                        (obj "cmd")
                        (obj "ft")
                        (obj "keys")
                        (obj "colorscheme")
                        "lazy = ${toLuaObject cfg.lazy}"
                        "priority = ${toLuaObject cfg.priority}"
                        (lib.optionalString (cfg.load != "") "load = ${toLuaObject (lib.mkLuaInline cfg.lazy)}")
                      ]
                    )}
                  }
                '';
            };
          };
          config = {
            lznOpts.before = lib.mkIf (config.loadBefore != [ ]) (
              lib.concatLines (
                map (x: "LZN.trigger_load(\"${getName config'.abs.${x}.package}\") ") config.loadBefore
              )
            );
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
        LZN = require("lz.n")
        LZN.load("mog")
      '';

      plugins = {
        start = [
          pkgs.vimPlugins.lz-n
          (pkgs.stdenvNoCC.mkDerivation {
            name = "mog";
            dontUnpack = true;
            strictDeps = true;
            dontFixup = true;
            nativeBuildInputs = [ pkgs.stylua ];
            buildCommand = ''
              mkdir -p "$out/lua/mog"
            ''
            + (lib.concatLines (
              lib.mapAttrsToList (
                name: value: "cat ${pkgs.writeText "${name}.lua" value.textOutput} > \"$out/lua/mog/${name}.lua\""
              ) enabledPlugins
            ))
            + ''
              stylua --indent-type Spaces --indent-width 2 -g "*.lua" "$out/lua/mog" || true
            '';

          })
        ];

        opt = lib.mapAttrsToList (_: value: value.package) enabledPlugins;
      };

    };
}
