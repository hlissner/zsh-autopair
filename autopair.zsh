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

autopair-insert() {
    local char=$(_autopair-get-pair $KEYS)
    if [ "$LBUFFER" =~ "(^|[ 	])$" ] && [ "$RBUFFER" =~ "^($|[ 	])" ]; then
        LBUFFER+="$KEYS"
        RBUFFER="$char$RBUFFER"
    else
        zle self-insert
    fi
}

autopair-delete() {
    local lchar="${LBUFFER: -1}"
    local pair=$(_autopair-get-pair "$lchar")
    if [ -n "$pair" ]; then
        [ "${RBUFFER:0:1}" == "$pair" ] && zle delete-char
    fi
    zle backward-delete-char
}

zle -N autopair-insert
zle -N autopair-delete
