{ pkgs, ... }:
{
  # Onboard MediaTek MT7927 (MT6639, "Filogic 380") Wi-Fi 7 + Bluetooth combo.
  # The driver itself (jetm's full patch set, built to load correctly) is wired in
  # via resources/nix/mt7927.nix from flake.nix. This file holds the supporting
  # hardware config that doesn't need the flake input.

  # Pinned to 6.18: the jetm driver builds a linux-7.0-era mt76 tree that does NOT
  # compile against 7.1's reworked mac80211 (IEEE80211_MIN_ACTION_SIZE became a
  # macro, the ieee80211_mgmt action union changed). 6.18 is the closest packaged
  # series the driver builds against. Bump to latest only after MT7927 support is
  # upstream (then no out-of-tree driver is needed).
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

  # The MT7927's registers read 0x0000 (ASIC revision/CHIPID): an ACPI device
  # (AMDIF031) collides with the chipset bridge window, so the kernel can't claim
  # the BIOS PCIe layout and reassigns the WiFi's BARs. pci=realloc didn't help, so
  # try pci=nocrs: ignore the BIOS _CRS resource map entirely and let the kernel
  # allocate the whole PCIe tree from scratch, hopefully avoiding the conflict.
  # NOTE: aggressive — can disturb other devices; sanity-check USB/GPU/NVMe on boot.
  boot.kernelParams = [ "pci=nocrs" ];
}
