{ config, lib, ... }:
{
  config.eiros.system.hardware.cpu = {
    vendor = "amd";
    iommu.enable = true;
  };
}
