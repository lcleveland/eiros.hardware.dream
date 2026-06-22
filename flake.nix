{
  description = "Hardware configuration for my Framework 16";
  inputs.mt7927.url = "github:clemenscodes/linux-mt7927";
  outputs =
    { self, mt7927, ... }:
    {
      nixosModules.default = {
        imports = [
          ./hardware-configuration.nix
          mt7927.nixosModules.default
        ]
        ++ (import ./resources/nix/import_modules.nix ./settings);
      };
    };
}
