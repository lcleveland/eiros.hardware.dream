{ ... }:
{
  nix.registry.eiros_hardware = {
    from = {
      type = "github";
      owner = "lcleveland";
      repo = "eiros.hardware";
    };
    to = {
      type = "github";
      owner = "lcleveland";
      repo = "eiros.hardware.dream";
    };
  };
}
