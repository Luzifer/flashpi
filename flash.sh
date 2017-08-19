#!/bin/bash

set -xe

SDCARD_DEVICE=$2
SOURCE_IMAGE=${SOURCE_IMAGE:-none}
STORAGE_DIR=${STORAGE_DIR:-/tmp}
SYSTEM_NAME=$1

if ( test "$(uname)" != "Linux" ); then
  echo "This script will only work on Linux. OSX is not capable of writing ext4 filesystems"
  exit 1
fi

if ( test "$(whoami)" != "root" ); then
  echo "Please execute me as user root or using sudo for flashing / mounting SDCARD"
  exit 1
fi

if [ -z "$SYSTEM_NAME" ]; then
  echo "You need to provide a system name!"
  exit 1
fi

if [ -z "$SDCARD_DEVICE" ]; then
  echo "You need to provide a device to modify!"
  exit 1
fi

if ! [ -f "${SOURCE_IMAGE}" ]; then
  echo "Did not find SOURCE_IMAGE, downloading / detecting once"
  if ( test $(ls -1tr ${STORAGE_DIR}/*raspbian-*-lite.img | wc -l) -lt 1 ); then
    curl -L https://downloads.raspberrypi.org/raspbian_lite_latest -o /tmp/raspbian.zip
    unzip /tmp/raspbian.zip -d ${STORAGE_DIR}
    rm /tmp/raspbian.zip
  fi
  SOURCE_IMAGE=$(ls -1tr ${STORAGE_DIR}/*raspbian-*-lite.img | head -n1)
fi

echo "Flashing Raspian image"
dd if=${SOURCE_IMAGE} of=${SDCARD_DEVICE} bs=1048576

echo "Adjusting root filesystem"
PART_START=$(parted ${SDCARD_DEVICE} -ms unit s p | grep "^2" | cut -f 2 -d: | sed "s/s$//")
[ "$PART_START" ] || return 1

fdisk ${SDCARD_DEVICE} <<EOF
p
d
2
n
p
2
$PART_START

p
w
$(sleep 5)
EOF

e2fsck -f "${SDCARD_DEVICE}2"
resize2fs "${SDCARD_DEVICE}2"
e2fsck -f "${SDCARD_DEVICE}2"

HERE=$(pwd)

echo "Mounting SDCard"
mkdir /tmp/pi
mount "${SDCARD_DEVICE}2" /tmp/pi/
cd /tmp/pi

echo "Configuring network"
cp "${HERE}/interfaces.txt" etc/network/interfaces

echo "Setting hostname to ${SYSTEM_NAME}"
echo "${SYSTEM_NAME}" > etc/hostname

echo "Configuring SSH-key"
mkdir -p home/pi/.ssh
cp "${HERE}/pubkey.txt" home/pi/.ssh/authorized_keys

echo "Fixing permissions"
chown -R 1000:1000 home/pi/.ssh/
chmod 0700 home/pi/.ssh
chmod 0600 home/pi/.ssh/authorized_keys

echo "Enabling SSH"
ln -s /lib/systemd/system/ssh.socket etc/systemd/system/sockets.target.wants/ssh.socket

echo "Unmounting"
cd ~
umount /tmp/pi
rmdir /tmp/pi

echo "Done."
