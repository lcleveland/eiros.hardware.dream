{ ... }:
let
  # Dead/unpopulated internal port on the onboard ASUS USB controller
  # (PCI 0000:0d:00.0). Its phantom device never enumerates; the kernel retries
  # for ~60s during the initrd, stalling systemd-udevd shutdown / switch-root and
  # producing a ~68s white-screen hang before the greeter. Disabling the port stops
  # the enumeration entirely. Keyed on the stable PCI address so it survives USB
  # bus renumbering (the only *-port8 under that controller is always the dead port).
  # Applied in the initrd (where the hang is) and in stage-2.
  disablePort8 = ''
    ACTION=="add", KERNELS=="0000:0d:00.0", DRIVERS=="xhci_hcd", KERNEL=="*-port8", ATTR{disable}="1", ATTR{early_stop}="1"
  '';
in
{
  boot.initrd.services.udev.rules = disablePort8;
  services.udev.extraRules = disablePort8;
}
