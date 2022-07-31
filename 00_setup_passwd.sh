#!/usr/bin/bash

USER=`whoami`
DEBMINIDIR="$HOME/debian-mini"
GITDIRTAG="d490a35d36030592839f24e468a5b818c919943967012037d6ab3d65d030ef7f.TAG"

echo -e "======================================================================="
echo -e "00_setup_passwd.sh"
echo -e "======================================================================="
echo -e "[_BEGIN_] >>> :" `date` "\n"


echo -e "\n[ 00 ]==== !!!! CHANGE root and $USER user password !!! =============="
echo -e "Please enter current root password (r00tme) >>>"

su -p root -c ' \
\
apt update && \
apt upgrade && \
\
echo -e "\n-- change root pwd (r00tme)--:"; \
echo -e "passwd root >>>"; \
passwd root && \
echo -e "\n-- change $USER pwd (r00tme)--:"; \
echo -e "passwd $USER >>>"; \
passwd $USER && \
echo -e "\n-- add user $USER to sudo --"; \
echo -e "apt install sudo -y && usermod -aG sudo $USER"; \
apt install sudo -y && /sbin/usermod -aG sudo $USER; \
'
RET=$?
if [ $RET -eq 0  ]; then 
	echo -e "\n\n... SUCCESS! Please relogin with user:$USER and new password";
	echo "and proceed with next script: 01_setup_base.sh"
else echo "... failed. ABORT!";
	exit -1;
fi;


echo -e "_______________________________________________________________________"
echo -e "\n[_END___] <<< :" `date`
echo -e "_______________________________________________________________________"
read -rsn1 | echo -ne '\n\nHit any key to continue ....'
exit 0
