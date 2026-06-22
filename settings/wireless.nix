{ ... }:
{
  # Boot-hang fix for the onboard MediaTek MT7927 Bluetooth (usb1-port8).
  #
  # On the current kernel the onboard MT7927 Wi-Fi 7 / BT combo has no working
  # driver (the chip's registers read 0x0000 on this X870E Extreme even with
  # jetm's full out-of-tree driver — a board-level PCIe bring-up issue, not a
  # config one). Because the BT can't enumerate, the initrd's systemd-udevd gets
  # stuck on its USB coldplug worker for ~64s, stalling switch-root.
  #
  # Bound that wait so boot stays fast. Safe: never strips root-mount modules;
  # systemd SIGKILLs the stuck udevd after 5s and proceeds (root already mounted,
  # stage-2 re-runs coldplug). Wi-Fi/BT use 5GbE Ethernet + a USB BT dongle until
  # MT7927 support lands in a mainline kernel.
  boot.initrd.systemd.services.systemd-udevd = {
    overrideStrategy = "asDropin";
    serviceConfig.TimeoutStopSec = "5s";
  };
}
