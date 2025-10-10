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
                    type = lib.types.lines;
                    default = "";
                  };
                };
              };
            };

            textOutput = lib.mkOption {
              type = lib.types.lines;
              readOnly = true;
            };
            objOutput = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              readOnly = true;
            };
          };
          config = {
            lznOpts.before = lib.mkIf (config.loadBefore != [ ]) (
              lib.concatLines (
                map (x: "LZN.trigger_load(\"${getName config'.abs.${x}.package}\") ") config.loadBefore
              )
            );

            objOutput =
              let
                cfg = config.lznOpts;
                mkFunc =
                  string:
                  lib.mkLuaInline ''
                    function()
                      ${string}
                    end'';
              in
              {
                "@1" = getName config.package;
                enabled = lib.mkIf (cfg.enabled != "") (
                  if builtins.isBool cfg.enabled then cfg.enabled else mkFunc cfg.enabled
                );
                load = lib.mkIf (cfg.load != "") (
                  lib.mkLuaInline ''
                    function(name)
                      ${cfg.load}
                    end''
                );
                inherit (cfg)
                  lazy
                  priority
                  ;
              }
              // (lib.genAttrs [
                "event"
                "cmd"
                "ft"
                "keys"
                "colorscheme"
              ] (name: lib.mkIf (cfg.${name} != [ ]) cfg.${name}))
              // (lib.genAttrs [
                "beforeAll"
                "before"
                "after"
              ] (name: lib.mkIf (cfg.${name} != "") (mkFunc cfg.${name})));

            textOutput = "return " + toLuaObject config.objOutput;

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
              ${lib.pipe enabledPlugins [
                builtins.attrValues
                (map (x: ''cat ${pkgs.writeText "${x.name}.lua" x.textOutput} > "$out/lua/mog/${x.name}.lua"''))
                lib.concatLines
              ]}
              stylua --indent-type Spaces --indent-width 2 -g "*.lua" "$out/lua/mog" || true
            '';

          })
        ];

        opt = lib.mapAttrsToList (_: value: value.package) enabledPlugins;
      };

    };
}
