{ ... }:
{
  # usb1-port8 is the onboard MediaTek Bluetooth radio (0489:e13a, the BT half of
  # the MT7927 Wi-Fi 7 card). Kernel 7.1.0 regressed its USB enumeration: the
  # controller times out (device descriptor read/64, error -110), resets, and
  # retries for ~64s during the initrd, which stalls systemd-udevd and blocks
  # switch-root (the ~65s white screen). Kernels 7.0.x enumerated it fine.
  #
  # old_scheme_first changes the enumeration ordering (set address before reading
  # the full descriptor) and is the canonical fix for -110 descriptor-read
  # timeouts. A kernel cmdline param applies in the initrd too, which is where the
  # hang occurs. See plan: ~/.claude/plans/this-is-still-broke-effervescent-hennessy.md
  # Fallbacks if this is insufficient: add "usbcore.autosuspend=-1", then "pcie_aspm=off".
  boot.kernelParams = [ "usbcore.old_scheme_first=1" ];
}
