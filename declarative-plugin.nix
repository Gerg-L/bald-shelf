{
  lib,
  pkgs,
  config,
  ...
}:
{
  options = {
    decPlugin = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          {
            name,
            config,
            options,
            ...
          }:
          {
            options = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Whether to enable this file.";
              };
              target = lib.mkOption {
                type = lib.types.str;
                default = name;
              };
              text = lib.mkOption {
                default = null;
                type = lib.types.nullOr lib.types.lines;
                description = "Text of the file.";
              };
              source = lib.mkOption {
                type = lib.types.path;
                description = "Path of the source file.";
              };
            };
            config = {
              source = lib.mkIf (config.text != null) (
                let
                  name' = "mnw-" + lib.replaceStrings [ "/" ] [ "-" ] name;
                in
                lib.mkDerivedConfig options.text (pkgs.writeText name')
              );
            };

          }
        )
      );
      default = { };

    };

  };
  config = {
    plugins.start = lib.pipe config.decPlugin [
      builtins.attrValues
      (builtins.filter (x: x.enable))
      (map (x: "install -D '${x.source}' \"$out/${x.target}\""))
      lib.concatLines
      (pkgs.runCommand "mnw-declarative-plugin" { })
      lib.singleton
    ];
  };
}
