#!/usr/bin/bash
#
# Description: Installs xorg base and sound system without any windows manager.
#              Additional packages: mc, librewolf, neovim and some dracula theming.
# Author: lynxcode42
# Date: 2022.08.10
# Licence: open source / do as you please
#-------------------------------------------------------------------------------
# REQUIRES:
# - lynxcode42/debian-mini git repo
#
# USAGE:
# $ ./01_setup_base.sh
#-------------------------------------------------------------------------------

USER=`whoami`
DEBMINIDIR="$HOME/debian-mini"
GITDIRTAG="d490a35d36030592839f24e468a5b818c919943967012037d6ab3d65d030ef7f.TAG"

echo -e "======================================================================="
echo -e "01_setup_base.sh"
echo -e "======================================================================="
echo -e "[_BEGIN_] >>> :" $(date "+%d>> %T <<") "\n"


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

echo -e "\n[ 01 ]==== install xorg ============================================="
echo -e "sudo apt install xserver-xorg-core xinit x11-xserver-utils -y"
sudo apt install xserver-xorg-core xinit x11-xserver-utils -y

echo -e "\n[ 02 ]==== install sound ============================================"
echo -e "sudo apt install alsa-utils pulseaudio pavucontrol -y"
sudo apt install alsa-utils pulseaudio pavucontrol -y

echo -e "\n[ 03 ]===== install mc (midnight commander) ========================="
echo -e "sudo apt install mc -y"
sudo apt install mc -y

echo -e "\n[ 04 ]==== install librewolf ========================================"
echo -e "reference: -> https://librewolf.net/installation/debian/"
echo -e "sudo apt install gpg -y"
sudo apt install gpg -y

# Change this command to choose a distro manually.
distro=$(if echo " bullseye focal impish jammy uma una " | \
	grep -q " $(lsb_release -sc) "; then echo $(lsb_release -sc); else echo focal; fi)

sudo rm -f /usr/share/keyrings/librewolf.gpg
wget -O- https://deb.librewolf.net/keyring.gpg | \
	sudo gpg --dearmor -o /usr/share/keyrings/librewolf.gpg

sudo tee /etc/apt/sources.list.d/librewolf.sources << EOF > /dev/null
Types: deb
URIs: https://deb.librewolf.net
Suites: $distro
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/librewolf.gpg
EOF

sudo apt update
sudo apt install librewolf -y

rm -f nvim-linux64.deb
echo -e "\n[ 05 ]==== install neovim ==========================================="
echo -e "reference: -> https://github.com/neovim/neovim/releases/tag/v0.7.2"
echo -e "wget https://github.com/neovim/neovim/releases/download/v0.7.2/nvim-linux64.deb"
wget https://github.com/neovim/neovim/releases/download/v0.7.2/nvim-linux64.deb
RET=`sha256sum ./nvim-linux64.deb | awk '{print $1}'`
if [  $RET =  "dce77cae95c2c115e43159169e2d2faaf93bce6862d5adad7262f3aa3cf60df8" ]; \
then echo "... sha256sum PASSED."; \
else \
	echo "... sha256sum: ABORT!"; \
	exit -3; \
fi;
echo -e "sudo apt install ./nvim-linux64.deb -y"
sudo apt install ./nvim-linux64.deb -y

echo -e "\n-- add packer.nvim --"
echo -e "reference: -> https://github.com/wbthomason/packer.nvim"
echo -e "git clone --depth 1 https://github.com/wbthomason/packer.nvim \
~/.local/share/nvim/site/pack/packer/start/packer.nvim"
git clone --depth 1 https://github.com/wbthomason/packer.nvim \
$HOME/.local/share/nvim/site/pack/packer/start/packer.nvim

echo -e "\n-- copy packer.nvim and mc configs --"
cd $DEBMINIDIR
yes | cp -Rpfv .config $HOME
yes | cp -Rpfv .local $HOME

nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerInstall'


echo -e "\n[ 06 ]==== dracula theming =========================================="
echo -e "reference: -> https://github.com/dracula/dracula-theme"

echo -e "\n-- mc theme --"
echo -e "\nLaunching mc to generate ini file. Please exit mc with key F10 to proceed."
read -rsn1 | echo -ne '\n\nHit any key to continue ....'
rm -rf $HOME/.config/mc
mc
sed -i -E 's/skin=.+/skin=dracula256/g'  $HOME/.config/mc/ini

echo -e "\n-- Xresources theme --"
cp Xresources $HOME/.Xresources

echo -e "_______________________________________________________________________"
echo -e "\n[_END___] <<< :" $(date "+%d>> %T <<")
echo -e "_______________________________________________________________________"
