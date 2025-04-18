#!/system/bin/sh

sleep 9

SCRIPT_PIDS=$(pgrep -f "zapret.sh")
NFQWS_PIDS=$(pgrep nfqws)

ALL_PIDS="$SCRIPT_PIDS $NFQWS_PIDS"

if [ -z "$ALL_PIDS" ]; then
    exit
fi

for pid in $ALL_PIDS; do
    if [ -d "/proc/$pid" ]; then
        renice -n -20 -p "$pid" 2>/dev/null
    fi
done
