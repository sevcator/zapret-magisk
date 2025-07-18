#!/system/bin/sh
set +e

MODPATH="/data/adb/modules/zapret"
WGETCMD=$(cat "$MODPATH/wgetpath" 2>/dev/null || echo "wget")
DNSCRYPTLISTSDIR="$MODPATH/dnscrypt"
ZAPRETLISTSDIR="$MODPATH/list"
ZAPRETIPSETSDIR="$MODPATH/ipset"
CLOAKINGUPDATE=$(cat "$MODPATH/config/dnscrypt-cloaking-rules-update" 2>/dev/null || echo "0")
BLOCKEDUPDATE=$(cat "$MODPATH/config/dnscrypt-blocked-names-update" 2>/dev/null || echo "0")
DNSCRYPTFILES_cloaking_rules=$(cat "$MODPATH/config/dnscrypt-cloaking-rules-link" 2>/dev/null || echo "https://raw.githubusercontent.com/sevcator/dnscrypt-proxy-stuff/refs/heads/main/cloaking-rules.txt")
DNSCRYPTFILES_blocked_names=$(cat "$MODPATH/config/dnscrypt-blocked-names-link" 2>/dev/null || echo "https://raw.githubusercontent.com/sevcator/dnscrypt-proxy-stuff/refs/heads/main/blocked-yandex.txt")
CUSTOMLINKIPSETV4=$(cat "$MODPATH/config/ipset-v4-link" 2>/dev/null || echo "https://raw.githubusercontent.com/sevcator/zapret-lists/refs/heads/main/ipset-v4.txt")
CUSTOMLINKIPSETV6=$(cat "$MODPATH/config/ipset-v6-link" 2>/dev/null || echo "https://raw.githubusercontent.com/sevcator/zapret-lists/refs/heads/main/ipset-v6.txt")
CUSTOMLINKREESTR=$(cat "$MODPATH/config/reestr-link" 2>/dev/null || echo "https://raw.githubusercontent.com/sevcator/zapret-lists/refs/heads/main/reestr_filtered.txt")

PREDEFINED_LIST_FILES="reestr.txt default.txt google.txt"
PREDEFINED_IPSET_FILES="ipset-v4.txt ipset-v6.txt"
ZAPRETLISTSDEFAULTLINK="https://raw.githubusercontent.com/sevcator/zapret-magisk/refs/heads/main/module/list/"
ZAPRETIPSETSDEFAULTLINK="https://raw.githubusercontent.com/sevcator/zapret-magisk/refs/heads/main/module/ipset/"
IGNORE_FILES="custom.txt exclude.txt"
get_overwrite_url() {
    file="$1"
    case "$file" in
        "reestr.txt") echo "$CUSTOMLINKREESTR" ;;
        "ipset-v4.txt") echo "$CUSTOMLINKIPSETV4" ;;
        "ipset-v6.txt") echo "$CUSTOMLINKIPSETV6" ;;
        *) echo "" ;;
    esac
}

update_file() {
    file="$1"
    url="$2"
    name=$(basename "$file")

    remote_size=$(busybox wget --spider -S "$url" 2>&1 | awk 'BEGIN{IGNORECASE=1}/Content-Length:/ {print $2}' | tr -d '\r')
    if [ -z "$remote_size" ] || [ "$remote_size" = "0" ]; then
        return 0
    fi

    local_size=0
    if [ -f "$file" ]; then
        local_size=$(stat -c%s "$file" 2>/dev/null || echo 0)
    fi

    diff=$(( remote_size - local_size ))
    [ "$diff" -lt 0 ] && diff=$(( -diff ))

    if [ "$diff" -gt 2 ]; then
        echo "[ $local_size/$remote_size; $name ] Downloading"
        $WGETCMD -q -O "$file" "$url"
    else
        echo "[ $local_size/$remote_size; $name ] Keeping"
    fi
}

update_dir() {
    dir="$1"
    base_url="$2"
    predefined_files="$3"

    mkdir -p "$dir"
    updated_files=""

    for file_path in "$dir"/*; do
        [ -f "$file_path" ] || continue
        file_name=$(basename "$file_path")

        case " $IGNORE_FILES " in
            *" $file_name "*) continue ;;
        esac
        case " $updated_files " in
            *" $file_name "*) continue ;;
        esac

        if [ "$dir" = "$ZAPRETIPSETSDIR" ]; then
            url=$(get_overwrite_url "$file_name")
            url="${url:-${base_url}${file_name}}"
        else
            url="${base_url}${file_name}"
        fi

        update_file "$file_path" "$url"
        updated_files="$updated_files $file_name"
    done

    for file_name in $predefined_files; do
        case " $IGNORE_FILES " in
            *" $file_name "*) continue ;;
        esac
        case " $updated_files " in
            *" $file_name "*) continue ;;
        esac

        file_path="$dir/$file_name"
        if [ "$dir" = "$ZAPRETIPSETSDIR" ]; then
            url=$(get_overwrite_url "$file_name")
            url="${url:-${base_url}${file_name}}"
        else
            url="${base_url}${file_name}"
        fi

        update_file "$file_path" "$url"
        updated_files="$updated_files $file_name"
    done
}

. $MODPATH/dnscrypt/custom-cloaking-rules.sh disappend > /dev/null 2>&1 &
sleep 2

update_dir "$ZAPRETLISTSDIR" "$ZAPRETLISTSDEFAULTLINK" "$PREDEFINED_LIST_FILES"
update_dir "$ZAPRETIPSETSDIR" "$ZAPRETIPSETSDEFAULTLINK" "$PREDEFINED_IPSET_FILES"

[ "$CLOAKINGUPDATE" = "1" ] && update_file "$DNSCRYPTLISTSDIR/cloaking-rules.txt" "$DNSCRYPTFILES_cloaking_rules"
[ "$BLOCKEDUPDATE" = "1" ] && update_file "$DNSCRYPTLISTSDIR/blocked-names.txt" "$DNSCRYPTFILES_blocked_names"

. $MODPATH/dnscrypt/custom-cloaking-rules.sh append > /dev/null 2>&1 &
sleep 2
