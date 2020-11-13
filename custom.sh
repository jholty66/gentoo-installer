#!/bin/sh

# Variables defined further down the file are likely to depend on
# variables defined further up the file.

### Core settings.
# Hardware
BOOTLOADER="efistub" # "efistub", "systemd-boot", "grub2"
CORES=4
# The combination of these is the full path of the ESP, "/dev/nvme0np1".
EFI_DISK="/dev/nvme0n1"
EFI_PARTION="p1"

# Editor
EDITOR="emacs"

### /etc/porage/ files
# The following is appended to "/etc/portage/make.conf".
MAKE_CONF="EMERGE_DEFAULTOPTS=\"--ask --keep-going --jobs ${CORES} --load-average ${CORES}.0\"
FEATURES=\"parallel-fetch parallel-install\"
USE=\"systemd threads -gui -sound\" # savedconfig does not currently work for sys-kernel/linux-firmware"

# The contents are appended to "/etc/portage/package.accept_keywords".
ACCEPT_KEYWORDS="dev-util/arch-install-scripts ~amd64"

### Shell commands
# Emerge command.
EMERGE=time\ emerge\ --ask=n

# Genkernel command.
GENKERNEL=genkernel\ --makeopts=-j$CORES\ all

### Tools and services
# These could be appended to.
TOOLS="" 
SERVICES=""

### File systems.
FS="zfs" # "zfs", "btrfs"
LUKS="" # "1", "2", anything else means no LUKS encryption

case "$FS" in
    btrfs) ;;
    zfs) PACKAGE_USE="${PACKAGEUSE}
>=sys-apps/util-linux-2.30.2 static-libs"
         GENKERNEL="${GENKERNEL}; ${EMERGE} sys-fs/zfs sys-fs/zfs-kmod sys-kernel/spl; ${GENKERNEL} --zfs; genkernel initframfs"
         ACCEPT_KEYWORDS="sys-kernel/spl ~amd64
sys-fs/zfs ~amd64
sys-fs/zfs-kmod ~amd64"
         SERVICES="${SERVICES}
systemctl enable zfs-import boot
systemctl enable zfs-mount boot
systemctl enable zfs-share default
systemctl enable zfs-zed default";;
esac

#### Encryption
[ -z "$ENCRYPT" ] && PACKAGEUSE="${PACKAGEUSE}
sys-apps/systemd gnuefi cryptsetup
sys-fs/cryptsetup luks1_default
sys-kernel/dracut systemd device-mapper"

#### Bootloader
case "$BOOTLOADER" in
    efistub) dir=$(pwd)
             mkdir --parents /boot/EFI/Gentoo/
             cp  /boot/vmlinux-* /boot/EFI/Gentoo/bootx64.efi
             # efibootmgr -c -L "EFI Stub" -l '\EFI\Gentoo\bzImage-*.efi'
             INITRAMFS=(ls | grep initramfs-*-gentoo)
             efibootmgr -c -d $EFI_DISK --part ${EFI_PARTITION: -1} --label "Gentoo" --loader "\EFI\gentoo\bootx64.efi" initrd='\${INITRAMFS}' ;;
    systemd) USE="${USE} gnuefi";;
    grub2)  ;;
esac