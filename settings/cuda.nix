{ config, lib, ... }:
let
  eiros_nvidia = config.eiros.system.hardware.graphics.nvidia;
in
{
  eiros_nvidia.cuda.enable = true;
}
