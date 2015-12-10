# A widget that auto-inserts matching pairs in ZSH.

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

# TODO Better balance checks
_autopair-p() {
    [ -n "$1" ] && local l="."
    [ -n "$2" ] && local r="."
    if [[ "$LBUFFER" =~ "(^|[^${1:-[({}])$l\$" && "$RBUFFER" =~ "^$r(\$|[^a-zA-Z])" ]];
    then
        [[ -n "$1" && "${LBUFFER: -1}" != "$1" ]] && return 1
        [[ -n "$2" && "${RBUFFER:0:1}" != "$2" ]] && return 1
        return 0
    else
        return 1
    fi
}

# TODO Fix this clumsy logic
_autopair-skip-p() {
    [ "${RBUFFER:0:1}" = "$2" ] && [ "${LBUFFER#*$1}" != "$LBUFFER" ] && [ "${RBUFFER#*$2}" != "$RBUFFER" ]
}

_autopair-insert() {
    LBUFFER+="$1"
    RBUFFER="$2$RBUFFER"
}

autopair-insert-or-skip() {
    local char=$(_autopair-get-pair $KEYS)
    if _autopair-skip-p "$KEYS" "$char";
    then
        zle forward-char
    elif _autopair-p;
    then
        _autopair-insert "$KEYS" "$char"
    else
        zle self-insert
    fi
}

autopair-skip() {
    if [[ "${RBUFFER:0:1}" = "$KEYS" && "$RBUFFER" =~ '^.($|[^a-zA-Z])' ]];
    then
        zle forward-char
    else
        zle self-insert
    fi
}

autopair-insert() {
    local char=$(_autopair-get-pair $KEYS)
    if _autopair-p;
    then
        _autopair-insert "$KEYS" "$char"
    else
        zle self-insert
    fi
}

autopair-delete() {
    local lchar="${LBUFFER: -1}"
    local rchar="${RBUFFER:0:1}"
    local pair=$(_autopair-get-pair "$lchar")
    if [ -n "$pair" ] && $(_autopair-p "$lchar" "$pair");
    then
        zle delete-char
    fi
    zle backward-delete-char
}

zle -N autopair-insert
zle -N autopair-insert-or-skip
zle -N autopair-skip
zle -N autopair-delete
