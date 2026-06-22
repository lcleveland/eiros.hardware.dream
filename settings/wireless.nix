{ pkgs, ... }:
{
  # Onboard MediaTek MT7927 (MT6639, "Filogic 380") Wi-Fi 7 + Bluetooth combo.
  # Newer than the in-tree mt7925e driver (which matches PCI IDs 7925/0717, not
  # 7927), so nothing binds and there's no Wi-Fi. github:clemenscodes/linux-mt7927
  # rebuilds the kernel's own mt76 + btusb/btmtk with a small 7927 patch and
  # installs them at the in-tree module path (replacing the stock ones), and
  # extracts the ASUS WLAN/BT firmware.
  mt7927.enable = true;

  # The mt76 patch targets a 6.x tree; 6.18 is the closest packaged series (>= the
  # driver's 6.17 floor, < 7.x where mac80211's action-frame API changed and the
  # out-of-tree build broke).
  eiros.system.boot.kernel.package = pkgs.linuxPackages_6_18;

  # Kill the ~64s boot hang SAFELY (do NOT strip initrd modules — that drops the
  # includeDefaultModules set the initrd needs to mount root and lands in emergency
  # mode). The onboard BT on usb1-port8 can't enumerate until the Wi-Fi driver
  # inits MediaTek's CONNINFRA in stage-2, so the initrd's systemd-udevd gets stuck
  # on its USB coldplug worker. Bound that wait: systemd SIGKILLs udevd after 5s and
  # proceeds with switch-root (root is already mounted; stage-2 re-runs coldplug).
  boot.initrd.systemd.services.systemd-udevd = {
    overrideStrategy = "asDropin";
    serviceConfig.TimeoutStopSec = "5s";
  };

  # MT7927 needs PCIe ASPM off for stability/throughput; clemenscodes has no toggle
  # for it, so disable it on the device directly.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x14c3", ATTR{device}=="0x7927", ATTR{link/l1_aspm}="0"
  '';
}
