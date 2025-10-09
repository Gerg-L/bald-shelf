lib:
let
  toLuaObject =
    args:
    {
      bool = lib.boolToString args;
      float = toString args;
      int = toString args;
      list = "{${lib.concatMapStringsSep "," toLuaObject args}}";
      null = "nil";
      path = ''"${args}"'';
      set =
        if lib.isDerivation args then
          ''"${args}"''
        else if (args._type or null) == "lua-inline" then
          args.expr
        else
          "{${
            # TODO: null is ugly here
            lib.pipe args [
              (builtins.mapAttrs (
                n: v:
                if v == null then
                  null
                else if (lib.hasPrefix "@" n) then
                  toLuaObject v
                else
                  "[${toLuaObject n}] = ${toLuaObject v}"
              ))
              builtins.attrValues
              (builtins.filter (v: v != null))
              (lib.concatStringsSep ",")
            ]
          }}";

      string = ''"${args}"'';
    }
    .${builtins.typeOf args}
    or (builtins.throw "Could not convert object of type `${builtins.typeOf args}` to lua object");
in
toLuaObject
