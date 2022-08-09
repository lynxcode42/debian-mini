#!/usr/bin/bash

BINDIR="$HOME/.local/bin"
DEBMINIDIR="$HOME/debian-mini"
GITDIRTAG="d490a35d36030592839f24e468a5b818c919943967012037d6ab3d65d030ef7f.TAG"

echo -e "======================================================================="
echo -e "02_setup_suckless.sh"
echo -e "======================================================================="
echo -e "[_BEGIN_] >>> :" `date` "\n"


echo -e "\n[ 00 ]==== check git lynxcode42/debian-mini exists =================="
if [ -f "$DEBMINIDIR/$GITDIRTAG" ]; then
	echo "... ok, git repo is in place.";
else
	echo "debian-mini repo cloning ...";
	cd $HOME;
	echo "git clone https://github.com/lynxcode42/debian-mini.git";
	git clone https://github.com/lynxcode42/debian-mini.git;
	cd $DEBMINIDIR;
fi

echo -e "\n[ 01 ]==== install build-essential =================================="
echo -e "sudo apt install build-essential git -y"
sudo apt install build-essential git -y

echo -e "\n[ 02 ]==== install dev libs ========================================="
echo -e "sudo apt install libxft-dev libx11-dev libxinerama-dev -y"
sudo apt install libxft-dev libx11-dev libxinerama-dev -y

echo -e "\n[ 03 ]==== build suckless tools ====================================="
echo -e "\n-- make dwm --"
echo -e "cd $DEBMINIDIR/suckless/dwm && make"
cd $DEBMINIDIR/suckless/dwm && make clean
make

echo -e "\n-- make dmenu --"
echo -e "cd ../dmenu && make"
cd ../dmenu && make clean
make

echo -e "\n-- make st --"
echo -e "cd ../st && make"
cd ../st && make clean
make

echo -e "\n-- copying binaries --"
mkdir -p ${BINDIR}
yes | cp -pfv ${DEBMINIDIR}/suckless/st/st ${BINDIR}
yes | cp -pfv ${DEBMINIDIR}/suckless/dmenu/{dmenu,dmenu_path,dmenu_run,stest} ${BINDIR}
yes | cp -pfv ${DEBMINIDIR}/suckless/dwm/dwm ${BINDIR}

echo -e "\n-- copying xinitrc --"
tee $HOME/.xinitrc << EOF > /dev/null

xrandr -s 1680x1050
exec ${BINDIR}/dwm

EOF



echo -e "_______________________________________________________________________"
echo -e "\n[_END___] <<< :" `date`
echo -e "_______________________________________________________________________"
echo -e "\n\nFinished all setups. Please make a clean REBOOT before usage."
echo -e "Have fun. cya.\n\n"
