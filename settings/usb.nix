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
  # (1) Boot-hang fix (deterministic, race-free).
  # The dead port's USB enumeration retry storm keeps the initrd's systemd-udevd from
  # stopping for ~65s, which blocks switch-root and shows as a long white screen before
  # the greeter. Bound that wait: systemd SIGKILLs udevd after the timeout and proceeds.
  # Safe — root is already mounted at this point and stage-2 re-runs udev coldplug.
  boot.initrd.systemd.services.systemd-udevd = {
    overrideStrategy = "asDropin";
    serviceConfig.TimeoutStopSec = "5s";
  };

  # (2) Stop the kernel retry storm in the running system (silences the USB error spam
  # and stops the controller being hammered). Keyed on the udev-processed root hub of the
  # stable controller; the script writes the dead port's disable attribute. Non-blocking.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", KERNEL=="usb[0-9]*", KERNELS=="0000:0d:00.0", RUN+="${disablePort8}"
  '';
}
