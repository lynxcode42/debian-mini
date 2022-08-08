#!/usr/bin/bash
# REQUIRES:
#	sgdisk (package: gdisk), debootstrap
# 
#

echo -e "\n\n~~~~ SCRIPT:debootstrap_script.sh ... running ... ~~~~"

#==== ERROR handling ===========================================================
#-- exit script on error
set -e 
#set -e -x
trap 'CATCHERR $?' EXIT

CleanUp() {
	echo -e "\n<<< CleanUp(): ... cleaning up 'umount -R ${ROOT_MOUNT}'  ..."
  set +e
	umount -R ${ROOT_MOUNT} 
	sync; sync; sync;
	sleep 5
  set -e
}

CATCHERR() {
  trap - EXIT
	CURRENT_TIME=`date`
	echo -e "\n[==== CATCHERR() >>> $CURRENT_TIME ====]"

	if [ "$CMD_PARAM" == "" ]; then CleanUp; fi  #-- chroot execution doesn't need to
	
  if [ "$?" != "0" ]; then
		echo -e "\n\n>>> CATCHERR(): An error occured. Script execution STOPPED! error code:$1 <<<"
		exit $1
	else 
		echo -e "\n\n>>> CATCHERR(): Script executed successfully. <<<"
		exit 0
  fi
}

#==== CONFIG ===================================================================
HOSTNAME="mini"
USERNAME="debi"
BOOTSTRAP_FILE_TAG="2022-08-05-15-54-bootstrapped.TAG"
#-- command parameter
CMD_PARAM=$1
#-- required packages
REQUIRED_PACKAGES="gdisk debootstrap"
#-- repo server
SERVER_REPO="http://ftp.halifax.rwth-aachen.de/debian"
DEB_RELEASE="bullseye"
DEB_ARCH="amd64"
#-- partioning parameters --
SWAP_PART_DEV="/dev/vdb1" #- placebo
SWAP_PART_SIZE="+1024M"
SWAP_PART_NAME="STRAP_SWAP"
SWAP_PART_LABEL="STRAP_swap"
ROOT_PART_DEV="/dev/vdb2" #- placebo
ROOT_PART_NAME="STRAP_ROOT"
ROOT_PART_LABEL="STRAP_root"
ROOT_PART_FS="8300"  #- ext4 --
ROOT_MOUNT="/mnt/chroot"
SYNTH_DEVS="dev sys proc"
#-- aditional packages --
INST_ADDONS="git"
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

install_addons() {
  echo -e "\n
==== INSTALL: additional packages =============================================="
	_StartTime_
	echo -e "\n>>> apt install -y $INST_ADDONS"
	apt install -y $INST_ADDONS
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

#==== HELPER functions =========================================================
_StartTime_() {
  CURRENT_TIME=`date`
	echo -e "____TIMESTAMP_START_: ${CURRENT_TIME}____" 
}
_EndTime_() {
  CURRENT_TIME=`date`
	echo -e "____TIMESTAMP_END___: ${CURRENT_TIME}____" 
}
#-------------------------------------------------------------------------------

instal_required_packages() {
	echo -e "\n<<< instal_required_packages(): ..."
	echo -e "\n>>> apt install -y $REQUIRED_PACKAGES"
	apt install -y $REQUIRED_PACKAGES
}

partion_disk() {
  echo -e "\n
==== partion_disk =============================================================="
	read -p ">>> Which drive should be used for installation? [sdX]: " INSTR
	#- ALL input chars to lower case
	DEVICE="/dev/${INSTR,,}"

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
	sgdisk --clear \
		--new 1::${SWAP_PART_SIZE} --typecode=1:8200 --change-name=1:${SWAP_PART_NAME} \
		--new 2::-0 --typecode=2:${ROOT_PART_FS} --change-name=2:${ROOT_PART_NAME} \
		${DEVICE}
	
	SWAP_PART_DEV=${DEVICE}1
	ROOT_PART_DEV=${DEVICE}2
	
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

enter_chroot_env() {
	echo -e "\n<<< enter_chroot_env(): ... entering chroot environment ..."
  
	#-- mount synthetic devices
	for d in ${SYNTH_DEVS}; do mount --bind /$d ${ROOT_MOUNT}/$d; done

  #-- entering chroot 
  echo -e ">>> chroot ${ROOT_MOUNT} /root/debootstrap_script_chroot.sh"
  chroot ${ROOT_MOUNT} /root/debootstrap_script.sh chroot
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

#----MAIN----MAIN----MAIN----MAIN----MAIN----MAIN----MAIN----MAIN.----MAIN -----

echo "\$1:#${1}#"
CURRENT_TIME=`date`
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
	
	CURRENT_TIME=`date`
	echo -e "\n\n[====CHROOT: debootstrap_script.sh >>> END_TIME:$CURRENT_TIME ====]\n"
	exit 0
#-- in host environment --------------------------------------------------------
else
	echo -e "\n\n[==== debootstrap_script.sh >>> START_TIME:$CURRENT_TIME ====]\n"

	echo "MAIN::>>> apt update #-> update cd package list"
	apt update 
	
	instal_required_packages
	partion_disk
	mount_chroot
	debootstrap_func
	enter_chroot_env
	echo -e "MAIN::>>>RETURNED from chroot!"
	configure_network
	generate_fstab

	CURRENT_TIME=`date`
	echo -e "\n\n[==== debootstrap_script.sh >>> END_TIME:$CURRENT_TIME ====]\n"
	exit 0
fi

#___________________________________ MAIN ______________________________________

exit 0
