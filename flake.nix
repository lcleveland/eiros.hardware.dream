{
  description = "Hardware configuration for my Framework 16";
  inputs.mt7927-dkms = {
    url = "github:jetm/mediatek-mt7927-dkms";
    flake = false;
  };
  outputs =
    { self, mt7927-dkms, ... }:
    {
      nixosModules.default = {
        imports = [
          ./hardware-configuration.nix
          (import ./resources/nix/mt7927.nix { inherit mt7927-dkms; })
        ]
        ++ (import ./resources/nix/import_modules.nix ./settings);
      };
    };
}
