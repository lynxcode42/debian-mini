#!/usr/bin/bash
#
# Description: Script to automatically bootstrap debian 11.
# Author: lynxcode42
# Date: 2022.08.10
# Licence: open source / do as you please
#-------------------------------------------------------------------------------
# REQUIRES:
# (- Ventoy bootloader ->ventoy.net )
# - debian 11 (bullseye) net-install-nonfree ISO ->debian.org
# - antix-21  (Group Yorum) ISO ->antixlinux.com
#	(- sgdisk (package: gdisk), debootstrap )
#
# USAGE:
# $ sudo ./debootstrap_script.sh
# $ sudo ./debootstrap_script.sh recover  #-- eg. in case of network failure
#-------------------------------------------------------------------------------

#-- command parameter
CMD_PARAM=$1
echo -e "\n\n~~~~ SCRIPT[-${CMD_PARAM}-]:debootstrap_script.sh ... running ... ~~~~"

#==== ERROR handling ===========================================================
#-- exit script on error
set -e 
#set -e -x
trap 'CATCHERR $?' EXIT
EXITCODE=$?

CleanUp() {
	echo -e "\n<<< CleanUp(): ... cleaning up 'umount -R ${ROOT_MOUNT}'  ..."
  set +e
	umount -R ${ROOT_MOUNT} 
	sync; sync; sync;
	sleep 5
  set -e
}

CATCHERR() {
  EXITCODE=$1
  trap - EXIT
	CURRENT_TIME=$(date "+%d>> %T <<")
	echo -e "\n[==== CATCHERR() >>> $CURRENT_TIME ====]"

#	if [ "$CMD_PARAM" == "" ]; then CleanUp; fi  #-- chroot execution doesn't need to
	echo "#${EXITCODE}#"
  if [ $EXITCODE -ne 0 ]; then
		echo -e "\n\n>>> CATCHERR(): An error occured. Script execution STOPPED! error code:${EXITCODE} <<<"
		exit ${EXITCODE}
	else 
		echo -e "\n\n>>> CATCHERR(): Script executed successfully. <<<"
		exit 0
  fi
}

#==== CONFIG ===================================================================
HOSTNAME="mini"
USERNAME="debi"
BOOTSTRAP_FILE_TAG="2022-08-10-42-42-bootstrapped.TAG"
#-- required packages
REQUIRED_PACKAGES="gdisk debootstrap"
#-- repo server
#-> https://www.debian.org/mirror/list
#-> sudo netselect-apt -a amd64 -sn -c DE
SERVER_REPO="http://ftp.halifax.rwth-aachen.de/debian"
DEB_RELEASE="bullseye"
DEB_ARCH="amd64"
#-- partioning parameters --
SWAP_PART_DEV="/dev/vdb1" #- placebo
SWAP_PART_SIZE="+1024M"
SWAP_PART_NAME="STR_SWAP"
SWAP_PART_LABEL="STR_swap"
ROOT_PART_DEV="/dev/sda2" #- placebo
ROOT_PART_NAME="STR_ROOT"
ROOT_PART_LABEL="STR_root"
ROOT_PART_FS="8300"  #- ext4 --
ROOT_MOUNT="/mnt/chroot"
SYNTH_DEVS="dev sys proc"
root_uid="xxxx-yyyy-zzzz"
#-- aditional packages --
#INST_ADDONS="git neofetch htop"
INST_ADDONS="ntfs-3g git htop neofetch sudo p7zip-full"
#-- required packages --
INST_BASE="linux-image-amd64 ntp network-manager intel-microcode firmware-linux"
#-- sources.list --
SOURCE_LIST=$(cat <<-HEREDOC
deb ${SERVER_REPO} bullseye main contrib non-free
deb-src ${SERVER_REPO} bullseye main contrib non-free

deb ${SERVER_REPO} bullseye-updates main contrib non-free
deb-src ${SERVER_REPO} bullseye-updates main contrib non-free

deb http://deb.debian.org/debian-security/ bullseye-security main contrib non-free
deb-src http://deb.debian.org/debian-security/ bullseye-security main contrib non-free
HEREDOC
)
#-------------------------------------------------------------------------------


#==== HELPER functions =========================================================
_StartTime_() {
  CURRENT_TIME=$(date "+%d>> %T <<")
	echo -e "____TIMESTAMP_START_: ${CURRENT_TIME}____" 
}
_EndTime_() {
  CURRENT_TIME=$(date "+%d>> %T <<")
	echo -e "____TIMESTAMP_END___: ${CURRENT_TIME}____" 
}
#-------------------------------------------------------------------------------

install_localization() {
  echo -e "\n
==== INSTALL: localization ====================================================="
	_StartTime_

	echo -e "\n<<< install_localization(): ... locales, timezone and keyboard ..."
	echo -e "... please standby. Some interactions are needed."
  read -p "... press ENTER to continue."
	
  echo -e ">>> apt install locales -y && dpkg-reconfigure"
	apt install locales -y
	dpkg-reconfigure locales #-> en_US.UTF-8 UTF-8
	dpkg-reconfigure tzdata  #-> Europe/Berlin

  echo -e ">>> apt install console-setup console-setup-linux -y && dpkg-reconfigure"
	apt install console-setup -y
	dpkg-reconfigure keyboard-configuration

	_EndTime_
}

install_base() {
  echo -e "\n
==== INSTALL: debian base packages ============================================="
	_StartTime_
	echo -e "\n<<< install_base(): ... required base and additional packages ..."

	echo ">>> tasksel install standard"
  _StartTime_
	tasksel install standard
	_EndTime_
	
	echo ">>> tasksel install ssh-server"
	tasksel install ssh-server
	_EndTime_

	echo ">>> apt install -y $INST_BASE"
	apt install -y $INST_BASE
	_EndTime_
}

install_addons() {
  echo -e "\n
==== INSTALL: additional packages =============================================="
	_StartTime_
	echo -e "\n>>> apt install -y $INST_ADDONS"
	apt install -y $INST_ADDONS
	_EndTime_
}

add_user() {
  echo -e "\n
==== ADD_USER =================================================================="
	echo -e "\n>>> add_user(): ...  CHANGE root passwd ..."
  passwd
  echo -e "\n>>> add_user(): ... '$USERNAME' - please enter password ..."
  
  useradd -mG sudo $USERNAME
  passwd $USERNAME
  usermod -aG sudo $USERNAME
  usermod --shell /bin/bash $USERNAME
}

install_required_packages() {
	echo -e "\n<<< install_required_packages(): ..."
	echo -e "\n>>> apt install -y $REQUIRED_PACKAGES"
	apt install -y $REQUIRED_PACKAGES
}

partition_disk() {
  echo -e "\n
==== partition_disk ============================================================"
	read -p ">>> Which drive should be used for installation? [sdX]: " INSTR
	#- ALL input chars to lower case
	DEVICE="/dev/${INSTR,,}"

	SWAP_PART_DEV=${DEVICE}1
	ROOT_PART_DEV=${DEVICE}2
	
	RET=42

	if [ "$CMD_PARAM" == "recover" ]; then
		echo ">>> recover option requested ..."
		echo ">>> check if $ROOT_PART_DEV is already mounted ..."
		#---- mount root
		set +e
		RET=`mount |grep ${ROOT_PART_DEV}`
		if [ "$RET" != "" ]; then
			echo ">>> ALREADY MOUNTED: mount ${ROOT_PART_DEV} ${ROOT_MOUNT}"
			RET=0
		else
			echo ">>> trying ... mount ${ROOT_PART_DEV} ${ROOT_MOUNT}"
			mount ${ROOT_PART_DEV} ${ROOT_MOUNT}
			if [ $? -eq 0 ]; then RET=0; fi
		fi
		set -e
	fi
	
	if [ $RET -eq 0 ]; then
		echo ">>> NO re-paritioning needed. Trying to recover ..."
		return 0
	else
		echo ">>> Can't recover as requested. ${ROOT_PART_DEV} will be re-partionioned!!!"
	fi

	sgdisk -p  ${DEVICE}
	RET=$?

	if [ $RET -eq 0  ]; then 
		echo -e -n "\n\nThis device data will be wiped out. Are you sure? [y,N]: "
		read INSTR
		if [ "${INSTR,,}" != "y" ]; then
			echo ">>> user ABORT. exit."
			exit -2;
		fi
	else
		echo ">>> NO device ${DEVICE} found. ABORTING!";
		exit -1;
	fi;

	echo ">>>partitions 1:${DEVICE}1:${SWAP_PART_SIZE} \swap; 2:${DEVICE}2: ${ROOT_PART_FS};"
  
  #-- unmount all partitions, if actually mounted
  set +e
  umount  ${DEVICE}* >/dev/null 2>&1
  swapoff ${DEVICE}* >/dev/null 2>&1
  set -e

	#---- do it -> 1. partion as SWAP; 2. partiton as $ROOT_PART_FS
	sgdisk --clear --mbrtogpt \
		--new 1::${SWAP_PART_SIZE} --typecode=1:8200 --change-name=1:${SWAP_PART_NAME} \
		--new 2::-0 --typecode=2:${ROOT_PART_FS} --change-name=2:${ROOT_PART_NAME} \
		${DEVICE}
	
	#---- create file systems
	mkswap -L ${SWAP_PART_LABEL} ${SWAP_PART_DEV}
	mkfs.ext4 -F -L ${ROOT_PART_LABEL} ${ROOT_PART_DEV}
  echo -e "\n>>> Finished partionioning.
--------------------------------------------------------------------------------"
  }

mount_chroot() {
	echo -e "\n<<< mount_chroot(): ... mount root and copy chroot script ..."
	mkdir -p ${ROOT_MOUNT} 
	#---- mount root
  set +e
  RET=`mount |grep ${ROOT_PART_DEV}`
  if [ "$RET" == "" ]; then
    echo ">>> mount ${ROOT_PART_DEV} ${ROOT_MOUNT}"
    mount ${ROOT_PART_DEV} ${ROOT_MOUNT}
  else
    echo ">>> ALREADY MOUNTED: mount ${ROOT_PART_DEV} ${ROOT_MOUNT}"
  fi
	set -e
  
  mkdir -p ${ROOT_MOUNT}/root
  cp -uv ./debootstrap_script.sh ${ROOT_MOUNT}/root/
}

debootstrap_func() {
  echo -e "\n
==== DEBOOTSTRAPPING ==========================================================="
	echo -e "\n<<< debootstrap_func(): checking  ..."
  if [ -f "$ROOT_MOUNT/$BOOTSTRAP_FILE_TAG" ]; then
    echo ">>> device already bootstrapped. skipping debootstrap.";
  else
    echo ">>> debootstrap into $ROOT_MOUNT with this parameters:"
    echo -e "\
arch:         ${DEB_ARCH}
release:      ${DEB_RELEASE}
chroot folder:${ROOT_MOUNT}
server repo:  ${SERVER_REPO}
>>> debootstrap --arch ${DEB_ARCH} ${DEB_RELEASE} ${ROOT_MOUNT} ${SERVER_REPO} <<<
"
   	_StartTime_
    debootstrap --arch ${DEB_ARCH} ${DEB_RELEASE} ${ROOT_MOUNT} ${SERVER_REPO}
    _EndTime_
    
    touch $ROOT_MOUNT/$BOOTSTRAP_FILE_TAG
  fi
}

enter_chroot_env() {
	echo -e "\n<<< enter_chroot_env(): ... entering chroot environment ..."
  
	#-- mount synthetic devices
	for d in ${SYNTH_DEVS}; do mount --bind /$d ${ROOT_MOUNT}/$d; done

  #-- entering chroot 
  echo -e ">>> chroot ${ROOT_MOUNT} /root/debootstrap_script_chroot.sh"
  chroot ${ROOT_MOUNT} /root/debootstrap_script.sh chroot
}

configure_network() {
  echo -e "\n
==== CONFIGURE: network files =================================================="
	echo -e "\n<<< configure_network(): ... /etc/{hostname, hosts} ..."
  echo "$HOSTNAME" > $ROOT_MOUNT/etc/hostname

  cat > $ROOT_MOUNT/etc/hosts << HEREDOC
127.0.0.1 localhost
127.0.1.1 $HOSTNAME

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
HEREDOC
}

generate_fstab() {
  echo -e "\n
==== GENERATE: /etc/fstab ======================================================"
	echo -e "\n<<< generate_fstab(): ... /etc/fstab: link swap and root ..."
  
	swap_uid=`blkid -o value --match-tag UUID ${SWAP_PART_DEV}`
	root_uid=`blkid -o value --match-tag UUID ${ROOT_PART_DEV}`
	
	ETC_FSTAB="\
# <file system>                           <mount point>  <type>  <options>  <dump>  <pass>
UUID=${root_uid} /              ext4    defaults,noatime 0 1
UUID=${swap_uid} none           swap    defaults 0 0
#tmpfs                                     /tmp           tmpfs   defaults,noatime,mode=1777 0 0
"
	echo "$ETC_FSTAB" > $ROOT_MOUNT/etc/fstab
}

generate_ventoy_grub_cfg() {
	echo -e "\n>>> generate_ventoy_grub_cfg(): ...
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	#---- mount ventoy partition
  set +e
  umount  ${ROOT_PART_DEV} >/dev/null 2>&1 
	set -e
  VENTOY_MOUNT=$(mktemp -d -p "/mnt")
  echo -e ">>> temp mount point $VENTOY_MOUNT created."
  echo -e ">>> mounting ... mount ${ROOT_PART_DEV} ${VENTOY_MOUNT}"
  mount ${ROOT_PART_DEV} ${VENTOY_MOUNT}
	
	mkdir -p "$VENTOY_MOUNT/ventoy/" #-- assert dir exists
	if [ -f "$VENTOY_MOUNT/ventoy/ventoy_grub.cfg" ]; then
		#back it up
		cp -uv "$VENTOY_MOUNT/ventoy/ventoy_grub.cfg" "$VENTOY_MOUNT/ventoy/ventoy_grub-ORIG.cfg"
	fi
	
	#root_uid=`blkid -o value --match-tag UUID ${ROOT_PART_DEV}`

	echo -e ">>> replacing UUID=${root_uid} of root partiton ${ROOT_PART_DEV} in generic grub.cfg ..."
	echo -e "sed \"s/AAAA-BBBB-CCCC-DDDD-EEEE/${root_uid}/g\" X Y" 
	sed "s/AAAA-BBBB-CCCC-DDDD-EEEE/${root_uid}/g" \
"./ventoy_root_dir/ventoy/ventoy_grub.cfg" > "$VENTOY_MOUNT/ventoy/ventoy_grub.cfg"
	
	echo -e "
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}

#----MAIN----MAIN----MAIN----MAIN----MAIN----MAIN----MAIN----MAIN.----MAIN -----

CURRENT_TIME=$(date "+%d>> %T <<")
#-- in CHROOT environment ------------------------------------------------------
if [ "$CMD_PARAM" == "chroot" ]; then
	echo -e "\n>>> chrooting ...";
	PATH=$PATH:/sbin:/usr/sbin
	echo -e "\n\n[====CHROOT: debootstrap_script.sh >>> START_TIME:$CURRENT_TIME ====]\n"

	echo "MAIN::>>> echo SOURCE_LIST > /etc/apt/sources.list"
	echo "${SOURCE_LIST}" > /etc/apt/sources.list

	echo -e "\n\
MAIN::>>> apt update && apt upgrade -y -----------------------------------------"
	apt update && apt upgrade -y
	echo -e "[====CHROOT: debootstrap_script.sh >>> apt upgrade FINISHED:$CURRENT_TIME ====]\n"

	install_localization
	install_base
	install_addons
	add_user
	
	CURRENT_TIME=$(date "+%d>> %T <<")
	echo -e "\n\n[====CHROOT: debootstrap_script.sh >>> END_TIME:$CURRENT_TIME ====]\n"
	exit 0
#-- in host environment --------------------------------------------------------
else
	echo -e "\n\n[==== debootstrap_script.sh >>> START_TIME:$CURRENT_TIME ====]\n"

	echo "MAIN::>>> apt update #-> update cd package list"
	apt update 
	
	install_required_packages
	partition_disk
	mount_chroot
	debootstrap_func
	enter_chroot_env
	#...
	echo -e "MAIN::>>>RETURNED from chroot!"
	configure_network
	generate_fstab

	generate_ventoy_grub_cfg
	

	CURRENT_TIME=$(date "+%d>> %T <<")
	echo -e "\n\n[==== debootstrap_script.sh >>> END_TIME:$CURRENT_TIME ====]\n"
	exit 0
fi

#___________________________________ MAIN ______________________________________

exit 0
