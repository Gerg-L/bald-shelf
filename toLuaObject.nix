lib:
let
  toLuaObject =
    args:
    {
      int = toString args;
      float = toString args;

      # quotes and escapes backslashes
      string = builtins.toJSON args;
      path = builtins.toJSON args;

      bool = lib.boolToString args;
      null = "nil";

      list = "{${lib.concatMapStringsSep ",\n" toLuaObject args}}";

      set =
        if lib.isDerivation args then
          ''"${args}"''
        else if (args._type or null) == "lua-inline" then
          args.expr
        else
          "{${
            lib.pipe args [
              (lib.filterAttrs (_: v: v != null))
              (builtins.mapAttrs (
                n: v: if lib.hasPrefix "@" n then toLuaObject v else "[${toLuaObject n}] = ${toLuaObject v}"
              ))
              builtins.attrValues
              (lib.concatStringsSep ",\n")
            ]
          }}";
    }
    .${builtins.typeOf args}
    or (builtins.throw "Could not convert object of type `${builtins.typeOf args}` to lua object");
in
toLuaObject
