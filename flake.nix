{
  description = "Hardware configuration for my desktop";
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
