{ pkgs, ... }:
{
  # Onboard MediaTek MT7927 (MT6639, "Filogic 380") Wi-Fi 7 + Bluetooth combo.
  # This chip is newer than the in-tree mt7925e driver (which only matches PCI IDs
  # 7925/0717, not 7927), so no driver binds and there's no Wi-Fi. The BT half
  # (USB 0489:e13a) shares MediaTek's CONNINFRA subsystem with Wi-Fi and can't
  # enumerate until the Wi-Fi driver inits it — without the driver it times out
  # (error -110) and the kernel's ~64s retry storm stalls the initrd (the boot
  # hang). Both are fixed by the out-of-tree driver + extracted ASUS firmware from
  # github:cmspam/mt7927-nixos (wired in via flake.nix).
  hardware.mediatek-mt7927 = {
    enable = true;
    enableWifi = true;
    enableBluetooth = true;
    disableAspm = true; # MT7927 needs ASPM off for stability/throughput
  };

  # The out-of-tree mt76 driver targets the 6.19.x-era mac80211 API and does NOT
  # build against kernel 7.1 (IEEE80211_MIN_ACTION_SIZE / mgmt->u.action.u were
  # reworked in 7.x). Pin the system to 6.18 — the only packaged series that is
  # both >= the driver's 6.17 minimum and < 7.x. Revert to linuxPackages_latest
  # once upstream (cmspam/jetm) gains 7.x support.
  eiros.system.boot.kernel.package = pkgs.linuxPackages_6_18;
}
