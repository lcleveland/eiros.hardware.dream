{
  description = "Hardware configuration for my Framework 16";
  outputs =
    { self, ... }:
    {
      nixosModules.default = {
        imports = [
          ./hardware-configuration.nix
        ]
        ++ (import ./resources/nix/import_modules.nix ./settings);
      };
    };
}
