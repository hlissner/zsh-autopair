# A widget that auto-inserts matching pairs in ZSH.

# TODO Match pairs more intelligently (i.e. counting? regex?)

_autopair-get-pair() {
    case "$1" in
        '"') echo -n '"' ;;
        "'") echo -n "'" ;;
        '`') echo -n '`' ;;
        '(') echo -n ')' ;;
        '[') echo -n ']' ;;
        '{') echo -n '}' ;;
        *) echo -n "";;
    esac
}

_autopair-p() {
    [[ "$LBUFFER" =~ "(^|[ 	])$1\$" && "$RBUFFER" =~ "^$2(\$|[ 	])" ]]
}

autopair-insert() {
    local char=$(_autopair-get-pair $KEYS)
    if _autopair-p;
    then
        LBUFFER+="$KEYS"
        RBUFFER="$char$RBUFFER"
    else
        zle self-insert
    fi
}

autopair-delete() {
    local lchar="${LBUFFER: -1}"
    local rchar="${RBUFFER:0:1}"
    local pair=$(_autopair-get-pair "$lchar")
    if [[ -n "$pair" && "$rchar" = "$pair" ]];
    then
        _autopair-p "$lchar" "$rchar" && zle delete-char
    fi
    zle backward-delete-char
}

zle -N autopair-insert
zle -N autopair-delete
