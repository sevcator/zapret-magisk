#!/bin/bash
# zapret-discord-youtube by Flowseal (https://github.com/Flowseal/zapret-discord-youtube)

# Values
hostlist="--hostlist=$MODPATH/list.txt"

# Zapret Configuration
config="--filter-udp=443 $hostlist --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$MODPATH/quic-google.bin --new"
config="$config --filter-udp=50000-50100 --ipset=$MODPATH/ipset-discord.txt --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new"
config="$config --filter-tcp=80 $hostlist --dpi-desync=fake,split2 --dpi-desync-autottl=2 --dpi-desync-fooling=md5sig --new"
config="$config --filter-tcp=443 $hostlist --dpi-desync=fake,split --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-fake-tls=$MODPATH/tls-google.bin"
