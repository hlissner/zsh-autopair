# A widget that auto-inserts matching pairs in ZSH.

# TODO Clean up!

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

_autopair-get-other-pair() {
    case "$1" in
        ')') echo -n '(' ;;
        ']') echo -n '[' ;;
        '}') echo -n '{' ;;
        *) echo -n "" ;;
    esac
}

_autopair-balanced-p() {
    if [ "$1" = "$2" ]; then
        local l=$(_autopair-count "$LBUFFER" "$1")
        local r=$(_autopair-count "$RBUFFER" "$2")
    else
        local l=$(_autopair-count "$BUFFER" "$1")
        local r=$(_autopair-count "$BUFFER" "$2")
    fi
    [ -n "$l" ] && [ -n "$r" ] && [ "$l" = "$r" ] && return 0
    # [ "$1" = "$2" ] && local n="0" || local n="1"
    [ $(( $l % 2 )) -eq 1 ] && [ $(( $r % 2 )) -eq 1 ] && return 0
    return 1
}

_autopair-count() {
    expr $(echo "$1" | fgrep -o "$2" - | wc -l ) + 0
}

_autopair-pair-p() {
    local rchar=$(_autopair-get-pair $KEYS)

    # Don't pair if pair doesn't exist
    [ -z "$rchar" ] && return 1
    # For quotes...
    if [ "\\$KEYS" =~ '\\['"'"'`"]' ]; then
        # Don't pair if next to alphanumerics
        [ "$LBUFFER" =~ "[a-zA-Z0-9]$" ] || [ "$RBUFFER" =~ "^[a-zA-Z0-9]" ] && return 1
    else # For braces
        # Don't pair if next to the same starting delimiter
        [ "${RBUFFER:0:1}" = "$KEYS" ] && return 1
    fi
    # Pair if surrounded by boundaries
    [ "$LBUFFER" =~ "(^|[ 	])$" ] && [ "$RBUFFER" =~ "^($|[ 	])" ] && return 0
    # Don't pair if the delimiters are unbalanced
    ! _autopair-balanced-p "$KEYS" "$rchar" && return 1

    return 0
}

_autopair-skip-p() {
    [ -z "$2" ] && return 1
    if [ "${RBUFFER:0:1}" = "$2" ]; then
        _autopair-balanced-p "$1" "$2" && return 0
    fi
    return 1
}

_autopair-delete-p() {
    local lchar="${LBUFFER: -1}"
    local rchar=$(_autopair-get-pair "$lchar")
    if [ -n "$rchar" ] && [ "${RBUFFER:0:1}" = "$rchar" ]; then
        _autopair-balanced-p "$lchar" "$rchar" && return 0
    fi
    return 1
}

_autopair-insert() {
    LBUFFER+="$1"
    RBUFFER="$2$RBUFFER"
}

autopair-insert-or-skip() {
    local rchar=$(_autopair-get-pair $KEYS)
    if _autopair-skip-p "$KEYS" "$rchar";
    then
        zle forward-char
    elif _autopair-pair-p;
    then
        _autopair-insert "$KEYS" "$rchar"
    else
        zle self-insert
    fi
}

autopair-skip() {
    local other=$(_autopair-get-other-pair "$KEYS")
    if [ -n "$other" ] && _autopair-skip-p "$other" "$KEYS"
    then
        zle forward-char
    else
        zle self-insert
    fi
}

autopair-insert() {
    if _autopair-pair-p;
    then
        local rchar=$(_autopair-get-pair $KEYS)
        _autopair-insert "$KEYS" "$rchar"
    else
        zle self-insert
    fi
}

autopair-delete() {
    if _autopair-delete-p;
    then
        zle delete-char
    fi
    zle backward-delete-char
}

zle -N autopair-insert
zle -N autopair-insert-or-skip
zle -N autopair-skip
zle -N autopair-delete
