# Builds jetm's COMPLETE MediaTek MT7927 (MT6639) driver — the full 20-patch
# mt76 WiFi series + 10-patch btusb/btmtk BT series (the revision tested on the
# ASUS ROG Crosshair X870E) — and installs the modules via `modules_install` so
# they land in lib/modules/<ver>/updates/ and get indexed by depmod (this is the
# fix vs cmspam's manual extra/mt76/ install, which depmod never indexed).
#
# Patches + Kbuild/compat files come from the jetm DKMS repo (flake input
# `mt7927-dkms`). They are applied to a standalone linux-7.0 mt76 source tree
# (same as cmspam); the *-compat-*-for-pre-7.0-kernels patches let that tree build
# against our 6.18 kernel. Firmware is already shipped by linux-firmware, so no
# ASUS-zip extraction is needed here.
{ mt7927-dkms }:
{ config, pkgs, lib, ... }:
let
  repoSrc = mt7927-dkms;

  # Standalone mt76 source (linux-7.0 snapshot), patched and built out-of-tree.
  linuxDrivers = pkgs.fetchzip {
    url = "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/snapshot/linux-7.0.tar.gz";
    hash = "sha256-7TjYHhJdD67P3lquusrjjVtUIUzhLPtA5Oy7tc82gYA=";
  };

  wifiPatchNames = [
    "mt7902-wifi-6.19.patch"
    "mt7927-wifi-01-fix-stale-pointer-comparisons-in-changev.patch"
    "mt7927-wifi-02-add-320mhz-bandwidth-to-bssrlmtlv.patch"
    "mt7927-wifi-03-handle-320mhz-bandwidth-in-rxv-and-txs.patch"
    "mt7927-wifi-04-populate-eht-320mhz-mcs-map-in-starec.patch"
    "mt7927-wifi-05-advertise-eht-320mhz-capabilities-for-6g.patch"
    "mt7927-wifi-06-add-mt7927-chip-id-helpers.patch"
    "mt7927-wifi-07-add-mt7927-firmware-paths.patch"
    "mt7927-wifi-08-use-irqmap-for-chip-specific-interrupt-h.patch"
    "mt7927-wifi-09-add-chip-specific-dma-configuration.patch"
    "mt7927-wifi-10-add-mt7927-hardware-initialization.patch"
    "mt7927-wifi-11-fix-bandidx-for-stable-5ghz6ghz-operatio.patch"
    "mt7927-wifi-12-disable-aspm-and-runtime-pm-for-mt7927.patch"
    "mt7927-wifi-13-enable-mt7927-pci-device-ids.patch"
    "mt7927-wifi-14-fix-reported-txpower-always-showing-3-db.patch"
    "mt7927-wifi-15-add-missing-he-ap-phy-capabilities.patch"
    "mt7927-wifi-16-add-starecmuru-tlv-for-ap-mode.patch"
    "mt7927-wifi-17-add-starectxproc-tlv.patch"
    "mt7927-wifi-18-fix-tx-power-reporting-in-ap-mode.patch"
    "mt7927-wifi-19-add-sta-fallback-recovery-in-tx-free-pat.patch"
    "mt7927-wifi-compat-kzalloc_flex-for-pre-7.0-kernels.patch"
  ];
  btPatchNames = [
    "mt6639-bt-01-add-mt6639-mt7927-bluetooth-support.patch"
    "mt6639-bt-02-fix-iso-interface-setup-for-single-alt-s.patch"
    "mt6639-bt-03-add-mt7927-id-for-asus-rog-crosshair-x87.patch"
    "mt6639-bt-04-add-mt7927-id-for-lenovo-legion-pro-7-16.patch"
    "mt6639-bt-05-add-mt7927-id-for-gigabyte-z790-aorus-ma.patch"
    "mt6639-bt-06-add-mt7927-id-for-msi-x870e-ace-max.patch"
    "mt6639-bt-07-add-mt7927-id-for-tp-link-archer-tbe550e.patch"
    "mt6639-bt-08-add-mt7927-id-for-asus-x870e--proart-x87.patch"
    "mt6639-bt-09-add-mt7902-bluetooth-support.patch"
    "mt6639-bt-compat-kmalloc_obj-for-pre-7.0-kernels.patch"
  ];
  wifiPatches = map (n: "${repoSrc}/${n}") wifiPatchNames;
  btPatches = map (n: "${repoSrc}/${n}") btPatchNames;

  kernel = config.boot.kernelPackages.kernel;
  kernelBuild = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";
  isClang = kernel.stdenv.cc.isClang or false;
  makeFlags = lib.optionals isClang [ "LLVM=1" "CC=clang" ];

  wifi = kernel.stdenv.mkDerivation {
    pname = "mt7927-mt76";
    version = "2.1";
    src = "${linuxDrivers}/drivers/net/wireless/mediatek/mt76";
    nativeBuildInputs = kernel.moduleBuildDependencies ++ [ pkgs.python3 pkgs.perl pkgs.kmod ];
    patches = wifiPatches;
    postPatch = ''
      cp ${repoSrc}/mt76.Kbuild Kbuild
      cp ${repoSrc}/mt7921.Kbuild mt7921/Kbuild
      cp ${repoSrc}/mt7925.Kbuild mt7925/Kbuild
      mkdir -p compat/include/linux/soc/airoha
      cp ${repoSrc}/compat-airoha-offload.h compat/include/linux/soc/airoha/airoha_offload.h
    '';
    buildPhase = ''
      runHook preBuild
      make -C ${kernelBuild} M=$(pwd) ${lib.escapeShellArgs makeFlags} modules
      runHook postBuild
    '';
    # Install via modules_install -> $out/lib/modules/<ver>/updates/, which depmod
    # indexes (and updates/ takes precedence over the stock in-tree mt76).
    installPhase = ''
      runHook preInstall
      make -C ${kernelBuild} M=$(pwd) INSTALL_MOD_PATH=$out ${lib.escapeShellArgs makeFlags} modules_install
      runHook postInstall
    '';
    meta.license = lib.licenses.gpl2Only;
  };

  bluetooth = kernel.stdenv.mkDerivation {
    pname = "mt7927-bluetooth";
    version = "2.1";
    src = "${linuxDrivers}/drivers/bluetooth";
    nativeBuildInputs = kernel.moduleBuildDependencies ++ [ pkgs.kmod ];
    patches = btPatches;
    buildPhase = ''
      runHook preBuild
      echo "obj-m += btusb.o btmtk.o" > Makefile
      make -C ${kernelBuild} M=$(pwd) ${lib.escapeShellArgs makeFlags} modules
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      make -C ${kernelBuild} M=$(pwd) INSTALL_MOD_PATH=$out ${lib.escapeShellArgs makeFlags} modules_install
      runHook postInstall
    '';
    meta.license = lib.licenses.gpl2Only;
  };
in
{
  boot.extraModulePackages = [ wifi bluetooth ];

  # Autoload at boot (the PCI alias also matches now, but be explicit).
  boot.kernelModules = [ "mt7925e" "btusb" "btmtk" ];
}
