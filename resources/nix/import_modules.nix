dir:
let
  inherit (builtins)
    readDir
    attrNames
    filter
    match
    concatLists
    ;
  collectImports =
    relPath:
    let
      fullPath = if relPath == "" then dir else dir + "/${relPath}";
      entries = readDir fullPath;
      processEntry =
        name:
        let
          subRelPath = if relPath == "" then name else "${relPath}/${name}";
          entryPath = dir + "/${subRelPath}";
          entryType = entries.${name};
        in
        if entryType == "directory" then
          collectImports subRelPath
        else if entryType == "regular" && match ".*\\.nix" name != null then
          [ (import entryPath) ]
        else
          [ ];
    in
    concatLists (map processEntry (attrNames entries));
in
collectImports ""
