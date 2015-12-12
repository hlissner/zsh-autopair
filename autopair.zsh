# A widget that auto-inserts matching pairs in ZSH.

# TODO Option for allowed/restricted pairing boundaries
# TODO Option for auto-init keybinds

_autopair-get-pair() {
    if [[ -n "$1" ]]
    then case "$1" in
             '"') echo -n '"' ;;
             "'") echo -n "'" ;;
             '`') echo -n '`' ;;
             '(') echo -n ')' ;;
             '[') echo -n ']' ;;
             '{') echo -n '}' ;;
             *) echo -n "";;
         esac
    elif [[ -n "$2" ]]
    then case "$2" in
             ')') echo -n '(' ;;
             ']') echo -n '[' ;;
             '}') echo -n '{' ;;
             *) echo -n "" ;;
         esac
    fi
}

_autopair-balanced-p() {
    local l=$(_autopair-count $([[ $1 == $2 ]] && echo "$LBUFFER" || echo "$BUFFER") "$1")
    local r=$(_autopair-count $([[ $1 == $2 ]] && echo "$RBUFFER" || echo "$BUFFER") "$2")
    [[ -z $1 || -z $r ]] && return 1
    [[ $l == $r || $(( $l % 2 == 1 && $r % 2 == 1 )) ]] && return 0
    return 1
}

_autopair-count() {
    expr $(echo "$1" | fgrep -o "${2/-/\-}" - | wc -l ) + 0
}

_autopair-pair-p() {
    local rchar=$(_autopair-get-pair $KEYS)

    # Don't pair if pair doesn't exist
    [[ -z "$rchar" ]] && return 1
    # For quotes...
    if [[ "$KEYS" == (\'|\"|\`) ]]
    then
        # Don't pair if next to alphanumerics
        [[ "$LBUFFER" =~ "[a-zA-Z0-9]$" || "$RBUFFER" =~ "^[a-zA-Z0-9]" ]] && return 1
    else # For braces
        # Don't pair if next to the same starting delimiter
        [[ $RBUFFER[1] == $KEYS ]] && return 1
    fi
    # Pair if surrounded by boundaries
    [[ "$LBUFFER" =~ "(^|[ 	])$" && "$RBUFFER" =~ "^($|[ 	])" ]] && return 0
    # Don't pair if the delimiters are unbalanced
    ! _autopair-balanced-p "$KEYS" "$rchar" && return 1

    return 0
}

_autopair-skip-p() {
    [[ -n "$2" && $RBUFFER[1] == $2 ]] && _autopair-balanced-p "$1" "$2"
}

_autopair-delete-p() {
    local lchar=$LBUFFER[-1]
    local rchar=$(_autopair-get-pair "$lchar")
    [[ -n "$rchar" && $RBUFFER[1] == $rchar ]] && _autopair-balanced-p "$lchar" "$rchar"
}

_autopair-self-insert() {
    LBUFFER+="$1"
    RBUFFER="$2$RBUFFER"
}

autopair-insert() {
    if _autopair-pair-p
    then _autopair-self-insert "$KEYS" $(_autopair-get-pair $KEYS)
    else zle self-insert
    fi
}

autopair-insert-or-skip() {
    local rchar=$(_autopair-get-pair $KEYS)
    if _autopair-skip-p "$KEYS" "$rchar"
    then zle forward-char
    else
        _autopair-pair-p && _autopair-self-insert "$KEYS" "$rchar" || zle self-insert
    fi
}

autopair-skip() {
    if _autopair-skip-p $(_autopair-get-pair "" "$KEYS") "$KEYS"
    then zle forward-char
    else zle self-insert
    fi
}

autopair-delete() {
    _autopair-delete-p && zle delete-char
    zle backward-delete-char
}

zle -N autopair-insert
zle -N autopair-insert-or-skip
zle -N autopair-skip
zle -N autopair-delete
