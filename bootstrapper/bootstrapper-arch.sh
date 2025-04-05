#!/bin/sh

set -e
#Bootstrap config:

if [ -z "$BOOT_TYPE" ]
then
	if [ -d /sys/firmware/efi ]
	then
		BOOT_TYPE=efi
	else
		BOOT_TYPE=bios
	fi
fi

if [ -z "$BOOT_SIZE" ]
then
	BOOT_SIZE=2
fi

if [ -z "$KEYMAP" ]
then
	KEYMAP=de
fi

if [ -z "$MIRRORLIST_COUNTRY" ]
then
	MIRRORLIST_COUNTRY=DE
fi

if [ -z "$SWAP_SIZE" ]
then
	MEMTOTAL=$(cat /proc/meminfo | grep MemTotal | sed -e "s|[^0-9]||g")
	SWAP_SIZE=$(( ( $MEMTOTAL / ( 1024 * 1024 ) ) + 1 ))
fi

function printhelp {
	echo \
"Usage: $(basename $0) <bootstraptype> <blockdevice> [NEW_HOSTNAME]

Types:

partition   create partition scheme while DELETING ALL CONTENTS of given device
bare        complete installation from bare metal while DELETING ALL CONTENTS of given device, expects NEW_HOSTNAME
install	    expects the structure partition creates and does a complete install, expects NEW_HOSTNAME
mount       mounts working structure in /mnt, does nothing else
umount      umounts working structure in /mnt, does nothing else
loader      only (re)installs the bootloader, expects system as created by bare or install
config      only (re)configure the system as created by bare or install

Directories for keyfiles:
  <workingdir>/*.pub              used for admin auth and remote initrd unlock keys
  <workingdir>/authkeys/*.pub     additional keys for admin auth
  <workingdir>/remotekeys/*.pub   additional keys for remote initrd unlock

Environment variables:
  ADMIN_PASSWORD          sets a single password hash for the admin user, prevents interactively asking for that password
  LUKS_PASSWORD           sets LUKS password, prevents interactively asking for that password
  BOOT_TYPE               sets boot type, bios or efi, prevents autodetection of current boot mode
  ADMIN_AUTHORIZED_KEYS   sets a list of newline separated ssh public keys for admin user, prevents reading of keyfiles
  REMOTE_UNLOCK_KEYS      sets a list of newline separated ssh public keys for root user, for unlocking in initrd, prevents reading of keyfiles
  SWAP_SIZE               set a size for the swap partition in GB, default is RAM size
  BOOT_SIZE               set a size for the boot/efi partition in GB
  KEYMAP                  set a keymap for the console
  MIRRORLIST_COUNTRY      set a country for the mirrorlist download
  DONT_ENCRYPT            set any value to prevent encryption
  SKIP_NETWORK            set any value to skip installing and enabling NetworkManager

Example commands to run on installer environments for remote install
  loadkeys de             # change to whatever keyboard layout you like
  passwd                  # set a root password 
  systemctl start sshd    # start ssh to copy over the bootstrapper script
  ip addr                 # get the ip for that

  iwctl                   # launch a configuration console for wifi
	device list
	station <device> scan
	station <device> get-networks
	station <device> connect <SSID>
"
}

if [ -z "$1" ]
then
	printhelp
	echo -e "\nType missing"
	exit 1
fi

case $1 in
b*)
	STEP_INSTALLERSUPPORT=YES
	STEP_BARE=YES
	STEP_MOUNT=YES
	STEP_INSTALL=YES
	STEP_BOOTLOADER=YES
	STEP_CONFIG=YES
	;;
p*)
	STEP_INSTALLERSUPPORT=YES
	STEP_BARE=YES
	;;
i*)
	STEP_INSTALLERSUPPORT=YES
	STEP_MOUNT=YES
	STEP_INSTALL=YES
	STEP_BOOTLOADER=YES
	STEP_CONFIG=YES
	;;
m*)	STEP_MOUNT=YES
	;;
u*)	STEP_UMOUNT=YES
	;;
l*)
	STEP_INSTALLERSUPPORT=YES
	STEP_MOUNT=YES
	STEP_BOOTLOADER=YES
	;;
c*)
	STEP_INSTALLERSUPPORT=YES
	STEP_MOUNT=YES
	STEP_CONFIG=YES
	;;
*)
	printhelp
	echo -e "\nUnknown bootstrap type $1"
	exit 1
	;;
esac

if [ -z "$DONT_ENCRYPT" ]
then
	while [ -z "$LUKS_PASSWORD" -a \( -n "$STEP_BARE" -o -n "$STEP_MOUNT" \) ]
	do
		echo Enter LUKS password:
		read -s LUKS_PASSWORD1
		echo again:
		read -s LUKS_PASSWORD2
		if [ "$LUKS_PASSWORD1" = "$LUKS_PASSWORD2" ]
		then
			LUKS_PASSWORD="$LUKS_PASSWORD1"
		else
			echo Passwords did not match
		fi
	done
fi

while [ -z "$ADMIN_PASSWORD" -a -n "$STEP_CONFIG" ]
do
	echo Enter admin password:
	read -s ADMIN_PASSWORD1
	echo again:
	read -s ADMIN_PASSWORD2
	if [ "$ADMIN_PASSWORD1" = "$ADMIN_PASSWORD2" ]
	then
		ADMIN_PASSWORD="$ADMIN_PASSWORD1"
	else
		echo Passwords did not match
	fi
done

echo \
"Settings:
ADMIN_PASSWORD          $ADMIN_PASSWORD
LUKS_PASSWORD           $LUKS_PASSWORD
BOOT_TYPE               $BOOT_TYPE
ADMIN_AUTHORIZED_KEYS   $ADMIN_AUTHORIZED_KEYS
REMOTE_UNLOCK_KEYS      $REMOTE_UNLOCK_KEYS
SWAP_SIZE               $SWAP_SIZE
BOOT_SIZE               $BOOT_SIZE
KEYMAP                  $KEYMAP
MIRRORLIST_COUNTRY      $MIRRORLIST_COUNTRY
"

read -p "Proceed? (y/n) " -n 1 -r
if [ ! "$REPLY" = y ]
then
    echo Canceled
	exit 1
fi

echo

loadkeys $KEYMAP

if [ -z "$2" -a \( -n "$STEP_MOUNT" -o -n "$STEP_UMOUNT"  -o -n "$STEP_INSTALL" \) ]
then
	printhelp
	echo "Device missing"
	exit 1
else
	DEVICE=$(realpath "$2")

	PREFIX=

	if echo "$DEVICE" | grep nvme
	then
		PREFIX=p
	fi

	if [ "$BOOT_TYPE" = "efi" ]
	then
		EFI=${DEVICE}${PREFIX}1
		SWAP=${DEVICE}${PREFIX}2
		ROOT=${DEVICE}${PREFIX}3
	else
		BIOSBOOT=${DEVICE}${PREFIX}1
		BOOT=${DEVICE}${PREFIX}2
		SWAP=${DEVICE}${PREFIX}3
		ROOT=${DEVICE}${PREFIX}4
	fi

	UUID_ROOT=$(blkid "$ROOT" | cut -d ' ' -f 2 | sed -e "s|\"||g" | cut -d '=' -f 2)
	UUID_SWAP=$(blkid "$SWAP" | cut -d ' ' -f 2 | sed -e "s|\"||g" | cut -d '=' -f 2)


	if [ -z "$DONT_ENCRYPT" ]
	then
		ROOT_TARGET="/dev/mapper/luks-$UUID_ROOT"
		SWAP_TARGET="/dev/mapper/luks-$UUID_SWAP"
	else
		ROOT_TARGET="$ROOT"
		SWAP_TARGET="$SWAP"
	fi
fi

if [ -n "$STEP_CONFIG" -a -z "$3" ]
then
	printhelp
	echo "NEW_HOSTNAME missing"
	exit 1
else
	NEW_HOSTNAME=$3
fi

function openLuks {
	[ -n "$DONT_ENCRYPT" ] && return

	if [ -e /dev/mapper/luks-$UUID_ROOT ]
	then
		echo /dev/mapper/luks-$UUID_ROOT already mapped
	else
		echo -n "$LUKS_PASSWORD" | cryptsetup open "$ROOT" luks-$UUID_ROOT
	fi
	if [ -e /dev/mapper/luks-$UUID_SWAP ]
	then
		echo /dev/mapper/luks-$UUID_SWAP already mapped
	else
		echo -n "$LUKS_PASSWORD" | cryptsetup open "$SWAP" luks-$UUID_SWAP
	fi
}

function closeLuks {
	[ -n "$DONT_ENCRYPT" ] && return

	set +e
	cryptsetup close luks-$UUID_ROOT
	cryptsetup close luks-$UUID_SWAP
	set -e
}

timedatectl set-ntp true

curl -o /etc/pacman.d/mirrorlist "https://archlinux.org/mirrorlist/?country=${MIRRORLIST_COUNTRY}&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist

pacman -Sy

if [ -n "$STEP_INSTALLERSUPPORT" ]
then
	if pacman -Qs arch-install-scripts > /dev/null
	then
		echo Install scripts already available
	else
		pacman -S arch-install-scripts
	fi
fi

if [ -n "$STEP_BARE" ]
then
	wipefs -a -f "$DEVICE"

	sleep 2

	#Disable halt on error, sometimes the booting stick sees changes for whatever reason
	set +e
	partprobe
	set -e


	if [ "$BOOT_TYPE" = "efi" ]
	then
	sgdisk \
	  --new 1::+${BOOT_SIZE}G --typecode 1:ef00 --change-name 1:'ESP' \
	  --new 2::+${SWAP_SIZE}G --typecode 2:8200 --change-name 2:'SWAP' \
	  --new 3::-0 --typecode 3:8300 --change-name 3:'ROOT' \
	  "$DEVICE"

	else
	sgdisk \
	  --new 1::+1M --typecode 1:ef02 --change-name 1:'BIOSBOOT' \
	  --new 2::+${BOOT_SIZE}G --typecode 2:8300 --change-name 2:'BOOT' \
	  --new 3::+${SWAP_SIZE}G --typecode 3:8200 --change-name 3:'SWAP' \
	  --new 4::-0 --typecode 4:8300 --change-name 4:'ROOT' \
	  "$DEVICE"
	fi

	sleep 2

	#Disable halt on error, sometimes the booting stick sees changes for whatever reason
	set +e
	partprobe
	set -e

	wipefs -a "$ROOT"
	[ -z "$DONT_ENCRYPT" ] && echo -n "$LUKS_PASSWORD" | cryptsetup luksFormat "$ROOT"

	wipefs -a "$SWAP"
	[ -z "$DONT_ENCRYPT" ] && echo -n "$LUKS_PASSWORD" | cryptsetup luksFormat "$SWAP"

	openLuks

	if [ "$BOOT_TYPE" = "efi" ]
	then
		wipefs -a "$EFI"
		mkfs.fat -F32 "$EFI"
	else
		wipefs -a "$BIOSBOOT"
		wipefs -a "$BOOT"
		mkfs.ext4 "$BOOT"
	fi

	mkswap "$SWAP_TARGET"

	mkfs.btrfs "$ROOT_TARGET"

	mount "$ROOT_TARGET" /mnt

	mkdir /mnt/boot
	mkdir /mnt/var
	btrfs subvolume create /mnt/var/cache
	btrfs subvolume create /mnt/home

	closeLuks
fi

if [ -n "$STEP_MOUNT" ]
then
	openLuks

	if mount | grep "/mnt " | grep "$ROOT_TARGET" > /dev/null
	then
		echo "$ROOT_TARGET" already mounted at /mnt
	else
		mount "$ROOT_TARGET" /mnt
	fi

	if [ "$BOOT_TYPE" = "efi" ]
	then
		if mount | grep "/mnt/boot " | grep $(realpath $EFI) > /dev/null
		then
			echo $EFI already mounted at /mnt/boot
		else
			mount "$EFI" /mnt/boot
		fi
	else
		if mount | grep "/mnt/boot " | grep $(realpath $BOOT) > /dev/null
		then
			echo $BOOT already mounted at /mnt/boot
		else
			mount "$BOOT" /mnt/boot
		fi

	fi


	if swapon | grep $(realpath "$SWAP_TARGET") > /dev/null
	then
		echo "$SWAP_TARGET" already used as swap
	else
		swapon "$SWAP_TARGET"
	fi
fi

if [ -n "$STEP_INSTALL" ]
then
	pacman -Sy
	pacstrap /mnt base linux-lts btrfs-progs linux-firmware
fi

if [ -n "$STEP_BOOTLOADER" ]
then
	genfstab -U /mnt > /mnt/etc/fstab

	CPU_VENDOR=$(cat /proc/cpuinfo | grep vendor_id | sed "s|[[:blank:]]*||g" | cut -d ':' -f 2 | sort -u)

	case $CPU_VENDOR in
		GenuineIntel)
			MICROCODE="initrd /intel-ucode.img"
			arch-chroot /mnt pacman --noconfirm -S intel-ucode
		;;
		AuthenticAMD)
			MICROCODE="initrd /amd-ucode.img"
			arch-chroot /mnt pacman --noconfirm -S amd-ucode
		;;
	esac

	if [ $BOOT_TYPE = efi ]
	then
		arch-chroot /mnt bootctl install
		mkdir -p /mnt/etc/cmdline.d

		tee /mnt/cmdline.d/network.conf << EOF
ip=::::${NEW_HOSTNAME}:eth0:dhcp: netconf_timeout=5
EOF

		if [ -z "$DONT_ENCRYPT" ]
		then
			tee /mnt/cmdline.d/luks.conf << EOF
luks.uuid=${UUID_ROOT}
luks.uuid=${UUID_SWAP}
luks.options=allow-discards
root=/dev/mapper/luks-${UUID_ROOT}
resume=/dev/mapper/luks-${UUID_SWAP} rw
EOF
		fi

		tee /mnt/etc/mkinitcpio.d/linux-lts.preset << EOF
ALL_kver="/boot/vmlinuz-linux-lts"
PRESETS=('default' 'fallback')
default_uki="/boot/EFI/Linux/arch-linux-lts.efi"
fallback_uki="/boot/EFI/Linux/arch-linux-lts-fallback.efi"
fallback_options="-S autodetect"
EOF

	else
		arch-chroot /mnt pacman --noconfirm -S grub
		arch-chroot /mnt grub-install --target=i386-pc "$DEVICE"

		LUKS_PARAMS=""
		[ -z "$DONT_ENCRYPT" ] && LUKS_PARAMS="luks.uuid=${UUID_ROOT} luks.uuid=${UUID_SWAP} root=/dev/mapper/luks-${UUID_ROOT} resume=/dev/mapper/luks-${UUID_SWAP} "

		tee /mnt/etc/default/grub << EOF
GRUB_DEFAULT=0
GRUB_TIMEOUT=2
GRUB_DISTRIBUTOR="Arch"
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
GRUB_CMDLINE_LINUX="ip=::::${NEW_HOSTNAME}:eth0:dhcp: netconf_timeout=5 ${LUKS_PARAMS} rw"
GRUB_PRELOAD_MODULES="part_gpt part_msdos"
GRUB_TIMEOUT_STYLE=menu
GRUB_TERMINAL_INPUT=console
GRUB_GFXMODE=auto
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_DISABLE_RECOVERY=true
EOF

		arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
	fi

	echo "KEYMAP=${KEYMAP}" > /mnt/etc/vconsole.conf

	arch-chroot /mnt pacman --noconfirm -S mkinitcpio-utils mkinitcpio-systemd-tool busybox openssh python tinyssh cryptsetup

	mkdir -p /mnt/root/.ssh

	[ ! -e /mnt/etc/ssh/ssh_host_ed25519_key ] && ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key

	if [ -z "$REMOTE_UNLOCK_KEYS" ]
	then
		if [ -n "$( find . -maxdepth 1 -name "*.pub" -print -quit )" ]
		then
			cat *.pub >> /mnt/etc/mkinitcpio-systemd-tool/config/authorized_keys
		fi
		if [ -d unlockkeys ]
		then
			for C in unlockkeys/*
			do
				cat $C >> /mnt/etc/mkinitcpio-systemd-tool/config/authorized_keys
			done
		fi
	else
		echo "$REMOTE_UNLOCK_KEYS" > /mnt/etc/mkinitcpio-systemd-tool/config/authorized_keys
	fi

	tee /mnt/etc/mkinitcpio.conf << EOF
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base kms systemd autodetect microcode modconf block keyboard sd-vconsole filesystems fsck systemd-tool)
EOF

	arch-chroot /mnt systemctl enable initrd-cryptsetup.path initrd-tinysshd.service initrd-network.service initrd-sysroot-mount.service

	touch /mnt/etc/mkinitcpio-systemd-tool/config/authorized_keys

	arch-chroot /mnt mkinitcpio -p linux-lts
fi

if [ -n "$STEP_CONFIG" ]
then
	tee /mnt/etc/hosts << EOF
127.0.0.1	$NEW_HOSTNAME
::1		$NEW_HOSTNAME
127.0.1.1	$NEW_HOSTNAME.localdomain $NEW_HOSTNAME
EOF

	echo "$NEW_HOSTNAME" > /mnt/etc/hostname
	set +e

	if [ -n "$SKIP_NETWORK" ]
	then
		arch-chroot /mnt pacman --noconfirm -S networkmanager
		arch-chroot /mnt systemctl enable NetworkManager
	fi

	#configure everything for ansible
	arch-chroot /mnt pacman --noconfirm -S openssh
	arch-chroot /mnt systemctl enable sshd

	arch-chroot /mnt pacman --noconfirm -S sudo python

	arch-chroot /mnt useradd --create-home admin
	arch-chroot /mnt usermod -aG wheel admin

	#reinstall sudo
	arch-chroot /mnt pacman --noconfirm -S sudo

	arch-chroot /mnt sh -c "echo admin:$ADMIN_PASSWORD | chpasswd"

	arch-chroot /mnt su -c "mkdir -p .ssh; ssh-keygen -f .ssh/id_rsa -N \"\" -C \"admin@$NEW_HOSTNAME\"" --login admin 

	if [ -z "$ADMIN_AUTHORIZED_KEYS" ]
	then
		if [ -n "$( find . -maxdepth 1 -name "*.pub" -print -quit )" ]
		then
			cat *.pub >> /mnt/home/admin/.ssh/authorized_keys
		fi
		if [ -d authkeys ]
		then
			for C in authkeys/*
			do
				cat $C >> /mnt/home/admin/.ssh/authorized_keys
			done
		fi
	else
		echo "$ADMIN_AUTHORIZED_KEYS" > /mnt/home/admin/.ssh/authorized_keys
	fi

	tee /mnt/etc/sudoers << EOF
root ALL=(ALL) ALL
%wheel ALL=(ALL) ALL
#includedir /etc/sudoers.d
EOF
	set -e
fi

if [ -n "$STEP_UMOUNT" ]
then
	set +e
	umount /mnt/boot
	umount /mnt

	swapoff "$SWAP_TARGET"
	closeLuks
fi

echo 'All done :)'
