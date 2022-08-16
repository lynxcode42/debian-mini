#!/usr/bin/awk -f

# $1    $2      $3
# a     123     KiB|MiB

BEGIN {
    #print "Started here."
    #KIB=0; MIB=0; TOTAL=0;
}
{
    if ($3 == "KiB") KIB = KIB + $2;
    else MIB = MIB + $2;
    #print KIB ":" MIB
}
END {
    #print "Stopped there!"
    TOTAL_MB = KIB/1024 + MIB;
    TOTAL_GB = TOTAL_MB / 1024
    print "in TOTAL:            " TOTAL_MB " MiB / " TOTAL_GB " GiB";
}
