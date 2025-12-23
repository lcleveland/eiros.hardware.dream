{
  description = "Hardware configuration for my Framework 16";
  outputs =
    { self, ... }@inputs:
    let
      import_modules = import ./resources/nix/import_modules.nix;
    in
    {
      inputs = inputs;
      nixosModules.default = {
        imports = [
          ./hardware-configuration.nix
        ]
        ++ (import_modules ./settings);
      };
    };
  inputs = {
  };
}
