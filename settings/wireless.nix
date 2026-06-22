{ pkgs, ... }:
{
  # Onboard MediaTek MT7927 (MT6639, "Filogic 380") Wi-Fi 7 + Bluetooth combo.
  # The driver itself (jetm's full patch set, built to load correctly) is wired in
  # via resources/nix/mt7927.nix from flake.nix. This file holds the supporting
  # hardware config that doesn't need the flake input.

  # Testing on the latest kernel (7.1). The jetm driver builds a linux-7.0-era
  # mt76 tree, so this may fail to compile against 7.1's mac80211 — if the rebuild
  # errors on the mt7927-mt76 derivation, pin back to pkgs.linuxPackages_6_18.
  eiros.system.boot.kernel.package = pkgs.linuxPackages_latest;

  # Bound the initrd udevd stop at 5s so the onboard BT failing to enumerate in
  # stage-1 (Wi-Fi/CONNINFRA only comes up in stage-2) can't stall switch-root for
  # ~64s. Safe: never strips root-mount modules; stage-2 re-runs udev coldplug.
  boot.initrd.systemd.services.systemd-udevd = {
    overrideStrategy = "asDropin";
    serviceConfig.TimeoutStopSec = "5s";
  };

  # MT7927 needs PCIe ASPM off for stability/throughput; disable it on the device.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x14c3", ATTR{device}=="0x7927", ATTR{link/l1_aspm}="0"
  '';

  # The MT7927's registers read 0x0000 (ASIC revision/CHIPID), because an ACPI
  # device (AMDIF031) collides with the chipset bridge window, forcing the kernel
  # to reassign every BAR down the deep PCIe switch chain to the WiFi — which
  # breaks the driver's register remap. Force a clean reallocation of bridge
  # windows so the BARs land somewhere the register window actually reaches.
  # If CHIPID still reads 0x0000 after this, swap "pci=realloc" for "pci=nocrs"
  # (more aggressive: ignores the BIOS resource map entirely).
  boot.kernelParams = [ "pci=realloc" ];
}
