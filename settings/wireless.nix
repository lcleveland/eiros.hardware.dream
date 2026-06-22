{ pkgs, ... }:
{
  # Onboard MediaTek MT7927 (MT6639, "Filogic 380") Wi-Fi 7 + Bluetooth combo.
  # The driver itself (jetm's full patch set, built to load correctly) is wired in
  # via resources/nix/mt7927.nix from flake.nix. This file holds the supporting
  # hardware config that doesn't need the flake input.

  # The mt76 patch set builds against a 6.x base; 6.18 is the closest packaged
  # series (>= the driver's floor, < 7.x where the mac80211 action-frame API
  # changed). Revert to linuxPackages_latest once MT7927 lands in a mainline kernel.
  eiros.system.boot.kernel.package = pkgs.linuxPackages_6_18;

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
}
