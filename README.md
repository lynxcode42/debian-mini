## ATTENTION
* * *
![](https://github.com/lynxcode42/debian-mini/raw/main/images/attention_warn.png)

# debian-mini
Minimal *Debian* preseed install on USB disk (*Ventoy*: headless, dwm, Xfce, LXQt, KDE; nonfree-netinst-cd)
## requirements
* [Ventoy](https://www.ventoy.net) bootloader
* **Debian 11** bullseye nonfree ([firmware-11.4.0-amd64-netinst.iso](https://cdimage.debian.org/cdimage/unofficial/non-free/cd-including-firmware/current/amd64/iso-cd/))
* *fast* USB drive
<br><br>
# folders and files
*.TAG: sh256sum of debian-net-inst CD to tag repo
```
debian-mini
├── README.md
├── d490a35d36030592839f24e468a5b818c919943967012037d6ab3d65d030ef7f.TAG
├── 00_setup_passwd.sh: change root and user(debi) password
├── 01_setup_base.sh: install xorg, sound, mc, librewolf and neovim
├── 02_setup_suckless.sh: build dwm, dmenu, st
├── .config: packer.vim config files
│   └── nvim
│       ├── init.vim
│       ├── lua
│       │   ├── nvimtree.lua
│       │   └── plugins.lua
│       └── plugin
├── .local
│   ├── bin
│   └── share
│       └── mc
│           └── skins
│               └── dracula256.ini
├── suckless: suckless.org git cloned with applied /patches
│   ├── dmenu
│   │   ├── patches
│   ├── dwm
│   │   ├── patches
│   └── st
│       ├── patches
├── ventoy_root_dir: files to be copied to root dir of Ventoy
│   ├── _ISOs_vrventoy: put isos here; will be referenced eg. in ventoy.json
│   ├── scripts
│   │   ├── example-preseed.txt: ->https://www.debian.org/releases/bullseye/example-preseed.txt
│   │   ├── preseed_bull_DE.cfg
│   │   └── preseed_bull_EN.cfg
│   ├── ventoy_grub.cfg: example grub config
│   └── ventoy.json: configure preseeding options
└── Xresources: dracula theme -> https://github.com/dracula/dracula-theme
```
