{ pkgs, ... }:
let
  # Disable the dead/unpopulated internal port (port 8) on the onboard ASUS xHCI
  # controller at the stable PCI address 0000:0d:00.0. Bus-number-agnostic glob.
  disablePort8 = pkgs.writeShellScript "disable-usb-port8" ''
    for f in /sys/bus/pci/devices/0000:0d:00.0/usb*/*-0:1.0/*-port8/disable; do
      [ -e "$f" ] && echo 1 > "$f"
    done
  '';
in
{
  # NOTE: The initrd boot-hang fix (capping systemd-udevd TimeoutStopSec to 5s in the
  # initrd) was removed to test whether the ~65s switch-root hang is fixed upstream.
  # If the long white screen returns at boot, restore the
  # boot.initrd.systemd.services.systemd-udevd drop-in (see git history).

  # Stop the kernel retry storm in the running system (silences the USB error spam
  # and stops the controller being hammered). Keyed on the udev-processed root hub of the
  # stable controller; the script writes the dead port's disable attribute. Non-blocking.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", KERNEL=="usb[0-9]*", KERNELS=="0000:0d:00.0", RUN+="${disablePort8}"
  '';
}
