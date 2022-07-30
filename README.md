## ATTENTION
* * *
<span style="color:red">Be extremely carefull, if you intend to use the option to fully automate the base install with the preseed files ***preseed_bull_{DE|EN}.cfg***. Reconsider only use them in a VM as shown in the video. If you don't fully grasp the part '**d-i partman-auto/choose_recipe** ' in those files then it is best to skip this option. Otherwise your data can be potentioly get lost. You've been warned.</span>

# debian-mini
Minimal Debian installs

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