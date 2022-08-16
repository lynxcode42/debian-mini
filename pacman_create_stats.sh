#!/usr/bin/bash

SUM="stats/$1_summary.log"
INST="stats/$1_installed.log"
PROC="stats/$1_processes.log"
TMP="stats/$1.tmp"

mkdir -p stats

(
echo -e "
================================================================================
>>>> top -b -n 1 | head -5 <<<
"
top -b -n 1 | head -5 >$TMP
cat $TMP
echo -e "\n
================================================================================
>>>> ps -e <<<<
"
ps -e -o "%U %P %p %c" |tail -n +2 >$PROC
echo -e "#Running processes: $(wc -l $PROC)" 
echo -e "\n
================================================================================
>>>> free -h <<<<
"
free -h 
echo -e "\n
================================================================================
>>>> du -sh <<<<
"
sudo du -sh  /usr /var /opt /boot /home
echo -e "\n
================================================================================
>>>> pacman -Q >$INST <<<<
"
LC_ALL=C pacman -Qi | awk '/^Name/{name=$3} /^Version/{ver=$3} /^Installed Size/{print name"_"ver, $4,$5}' | sort -h >$INST
echo -e "#Installed packages: $(wc -l $INST)"
awk -f ./sum_installed_pac.awk $INST

echo -e "\
================================================================================
"
) | tee $SUM


rm $TMP
