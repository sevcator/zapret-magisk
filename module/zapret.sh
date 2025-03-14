# If you don't know what you're doing, don't touch anything on this script

boot_wait() {
    while [[ -z $(getprop sys.boot_completed) ]]; do sleep 2; done
}

boot_wait

MODPATH=/data/adb/modules/zapret
MODUPDATEPATH=/data/adb/modules_update/zapret

for FILE in "$MODPATH/tactics"/*.sh; do
  if [[ -f "$FILE" ]]; then
    sed -i 's/\r$//' "$FILE"
  fi
done

if [ ! -f "$MODPATH/current-tactic" ]; then
    exit
fi

CURRENTTACTIC=$(cat $MODPATH/current-tactic)
. "$MODPATH/tactics/$CURRENTTACTIC.sh"

iptables -I OUTPUT -p udp --dport 853 -j DROP
iptables -I OUTPUT -p tcp --dport 853 -j DROP
iptables -I FORWARD -p udp --dport 853 -j DROP
iptables -I FORWARD -p tcp --dport 853 -j DROP
iptables -t nat -I OUTPUT -p udp --dport 53 -j DNAT --to 1.1.1.1:53
iptables -t nat -I OUTPUT -p tcp --dport 53 -j DNAT --to 1.1.1.1:53
iptables -t nat -I PREROUTING -p udp --dport 53 -j DNAT --to 1.1.1.1:53
iptables -t nat -I PREROUTING -p tcp --dport 53 -j DNAT --to 1.1.1.1:53
ip6tables -I OUTPUT -p udp --dport 853 -j DROP
ip6tables -I OUTPUT -p tcp --dport 853 -j DROP
ip6tables -I FORWARD -p udp --dport 853 -j DROP
ip6tables -I FORWARD -p tcp --dport 853 -j DROP
ip6tables -t nat -I OUTPUT -p udp --dport 53 -j DNAT --to-destination [2606:4700:4700::1111]:53
ip6tables -t nat -I OUTPUT -p tcp --dport 53 -j DNAT --to-destination [2606:4700:4700::1111]:53
ip6tables -t nat -I PREROUTING -p udp --dport 53 -j DNAT --to-destination [2606:4700:4700::1111]:53
ip6tables -t nat -I PREROUTING -p tcp --dport 53 -j DNAT --to-destination [2606:4700:4700::1111]:53

# Disable IPv6, if zapret still not works, try this.
# sysctl net.ipv6.conf.all.disable_ipv6=1 > /dev/null;
# sysctl net.ipv6.conf.default.disable_ipv6=1 > /dev/null;
# sysctl net.ipv6.conf.lo.disable_ipv6=1 > /dev/null;
sysctl net.netfilter.nf_conntrack_tcp_be_liberal=1 > /dev/null;

tcp_ports="$(echo $config | grep -oE 'filter-tcp=[0-9,-]+' | sed -e 's/.*=//g' -e 's/,/\n/g' -e 's/ /,/g' | sort -un)";
udp_ports="$(echo $config | grep -oE 'filter-udp=[0-9,-]+' | sed -e 's/.*=//g' -e 's/,/\n/g' -e 's/ /,/g' | sort -un)";

iptAdd() {
    iptDPort="$iMportD $2"; iptSPort="$iMportS $2";
    iptables -t mangle -I POSTROUTING -p $1 $iptDPort $iCBo $iMark -j NFQUEUE --queue-num 200 --queue-bypass;
    iptables -t mangle -I PREROUTING -p $1 $iptSPort $iCBr $iMark -j NFQUEUE --queue-num 200 --queue-bypass;
    ip6tables -t mangle -I POSTROUTING -p $1 $iptDPort $iCBo $iMark -j NFQUEUE --queue-num 200 --queue-bypass;
    ip6tables -t mangle -I PREROUTING -p $1 $iptSPort $iCBr $iMark -j NFQUEUE --queue-num 200 --queue-bypass;
}

iptMultiPort() {
    for current_port in $2; do
        if [[ $current_port == *-* ]]; then
            for i in $(seq ${current_port%-*} ${current_port#*-}); do
                iptAdd "$1" "$i";
            done
        else
            iptAdd "$1" "$current_port";
        fi
    done
}

if [ "$(cat /proc/net/ip_tables_targets | grep -c 'NFQUEUE')" == "0" ]; then
    exit
else
    if [ "$(cat /proc/net/ip_tables_matches | grep -c 'multiport')" != "0" ]; then
        iMportS="-m multiport --sports"
        iMportD="-m multiport --dports"
    else
        iMportS="--sport"
        iMportD="--dport"
    fi

    if [ "$(cat /proc/net/ip_tables_matches | grep -c 'connbytes')" != "0" ]; then
        iCBo="-m connbytes --connbytes-dir=original --connbytes-mode=packets --connbytes 1:12"
        iCBr="-m connbytes --connbytes-dir=reply --connbytes-mode=packets --connbytes 1:3"
    else
        iCBo=""
        iCBr=""
    fi

    if [ "$(cat /proc/net/ip_tables_matches | grep -c 'mark')" != "0" ]; then
        iMark="-m mark ! --mark 0x40000000/0x40000000"
    else
        iMark=""
    fi

    iptMultiPort "tcp" "$tcp_ports";
    iptMultiPort "udp" "$udp_ports";
fi

while true; do
    if ! pgrep -x "nfqws" > /dev/null; then
	    "$MODPATH/nfqws" --uid=0:0 --bind-fix4 --bind-fix6 --qnum=200 $config > /dev/null
    fi
    sleep 5
done
