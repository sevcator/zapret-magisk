#!/bin/bash
# Flowseal General ALT2 Configuration from https://github.com/Flowseal/zapret-discord-youtube

# Zapret Configuration
# <-- -->

# list.txt
config="--filter-tcp=80 --hostlist=$MODPATH/list/list.txt --dpi-desync=fakeddisorder --dpi-desync-ttl=1 --dpi-desync-autottl=2 --dpi-desync-split-pos=method+2 --new"
config="$config --filter-tcp=443 --hostlist=$MODPATH/list/list.txt --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern=$MODPATH/fake/tls_clienthello_www_google_com.bin --new"
config="$config --filter-udp=80,443 --hostlist=$MODPATH/list/list.txt --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=$MODPATH/fake/quic_initial_www_google_com.bin --new"

# list-auto.txt
config="$config --filter-tcp=80 --hostlist-auto=$MODPATH/list/list-auto.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --dpi-desync=fakeddisorder --dpi-desync-ttl=1 --dpi-desync-autottl=2 --dpi-desync-split-pos=method+2 --new"
config="$config --filter-tcp=443 --hostlist-auto=$MODPATH/list/list-auto.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern=$MODPATH/fake/tls_clienthello_www_google_com.bin --new"
config="$config --filter-udp=80,443 --hostlist-auto=$MODPATH/list/list-auto.txt --hostlist-exclude=$MODPATH/list/list-exclude.txt --dpi-desync=fake --dpi-desync-repeats=6 --new"

# ipset.txt
config="$config --filter-tcp=80 --ipset=$MODPATH/ipset/ipset.txt --dpi-desync=fakeddisorder --dpi-desync-ttl=1 --dpi-desync-autottl=2 --dpi-desync-split-pos=method+2 --new"
config="$config --filter-tcp=443 --ipset=$MODPATH/ipset/ipset.txt --dpi-desync=split2 --dpi-desync-split-seqovl=652 --dpi-desync-split-pos=2 --dpi-desync-split-seqovl-pattern=$MODPATH/fake/tls_clienthello_www_google_com.bin --new"
config="$config --filter-udp=80,443 --ipset=$MODPATH/ipset/ipset.txt --dpi-desync=fake --dpi-desync-repeats=6 --new"

# Discord RTC
config="$config --filter-udp=50000-50100 --filter-l7=discord --dpi-desync=fake --dpi-desync-cutoff=n2 --dpi-desync-ttl=4"
