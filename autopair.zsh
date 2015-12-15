# A widget that auto-inserts matching pairs in ZSH.

# Stops zsh-autopair from auto-binding keymaps
AUTOPAIR_INHIBIT_INIT=
AUTOPAIR_BETWEEN_WHITESPACE=

typeset -A AUTOPAIR_PAIRS
AUTOPAIR_PAIRS=('`' '`' "'" "'" '"' '"' '{' '}' '[' ']' '(' ')' '<' '>')

typeset -A AUTOPAIR_LBOUNDS
AUTOPAIR_LBOUNDS=(\
    all '[.:/\!]' \
    quotes '[]})a-zA-Z0-9]' \
    braces '' \
    '"' '"' \
    "'" "'" \
    '`' '`')

typeset -A AUTOPAIR_RBOUNDS
AUTOPAIR_RBOUNDS=(\
    all '[[{(<,.:?/%$!a-zA-Z0-9]' \
    quotes '[a-zA-Z0-9]' \
    braces '')

####

ap-boundary-p() {
    [[ -n "$1" && "$LBUFFER" =~ "${1}$" || -n "$2" && "$RBUFFER" =~ "^${2}" ]]
}
ap-next-to-boundary-p() {
    local groups=(all)
    case "$1" in
        \'|\"|\`)    groups+=quotes ;;
        \{|\[|\(|\<) groups+=braces ;;
    esac
    groups+="$1"
    for group in $groups; do
        ap-boundary-p "$AUTOPAIR_LBOUNDS[$group]" "$AUTOPAIR_RBOUNDS[$group]" && return 0
    done
    return 1
}

# If provided pair is balanced in the buffer
ap-balanced-p() {
    local lbuf="${LBUFFER//\\$1}"
    local rbuf="${RBUFFER//\\$2}"
    local llen="${#lbuf//[^$1]}"
    local rlen="${#rbuf//[^$2]}"
    (( $rlen == 0 && $llen == 0 )) && return 0
    if [[ "$1" == "$2" ]]; then
        (( $llen == $rlen || ($llen + $rlen) % 2 == 0 )) && return 0
    else
        local l2len="${#lbuf//[^$2]}"
        local r2len="${#rbuf//[^$1]}"
        local ltotal=$(( $llen - $l2len ))
        local rtotal=$(( $rlen - $r2len ))

        (( $ltotal < 0 )) && ltotal=0
        (( $ltotal < $rtotal )) && return 1
        return 0
    fi
    return 1
}

ap-can-pair-p() {
    local rchar="$AUTOPAIR_PAIRS[$KEYS]"

    # Don't pair if pair doesn't exist
    [[ -z "$rchar" ]] && return 1

    # Force pair if surrounded by space/[BE]OL, regardless of boundaries/balance
    [[ -n "$AUTOPAIR_BETWEEN_WHITESPACE" && \
        "$LBUFFER" =~ "(^|[ 	])$" && \
        "$RBUFFER" =~ "^($|[ 	])" ]] && return 0

    # Don't pair quotes if the delimiters are unbalanced
    ! ap-balanced-p $KEYS $rchar && return 1

    # Don't pair when in front of characters that likely signify the start of a string
    # or path (i.e. boundary characters)
    ap-next-to-boundary-p "$KEYS" "$rchar" && return 1

    return 0
}

ap-can-skip-p() {
    [[ -n "$2" && "$RBUFFER[1]" == "$2" ]] # && ap-balanced-p "$1" "$2"
}

ap-can-delete-p() {
    local lchar="$LBUFFER[-1]"
    local rchar="$AUTOPAIR_PAIRS[$lchar]"
    [[ -n "$rchar" && "$RBUFFER[1]" == "$rchar" ]] && ap-balanced-p "$lchar" "$rchar"
}

typeset -A AUTOPAIR_REVERSE_PAIRS
for i in ${(@k)AUTOPAIR_PAIRS}; do AUTOPAIR_REVERSE_PAIRS["$AUTOPAIR_PAIRS[$i]"]="$i"; done
typeset -r AUTOPAIR_REVERSE_PAIRS

autopair-self-insert() {
    LBUFFER+="$1$2"
    zle .backward-char
}

autopair-insert() {
    local rchar="$AUTOPAIR_PAIRS[$KEYS]"
    if [[ $KEYS == (\'|\"|\`) ]] && ap-can-skip-p "$KEYS" "$rchar"; then
        zle .forward-char
    elif ap-can-pair-p; then
        autopair-self-insert "$KEYS" "$rchar"
    else
        zle .self-insert
    fi
}

autopair-close() {
    if ap-can-skip-p "$AUTOPAIR_REVERSE_PAIRS[$KEYS]" "$KEYS"
    then zle .forward-char
    else zle .self-insert
    fi
}

autopair-delete() {
    ap-can-delete-p && zle .delete-char
    zle .backward-delete-char
}

# Initialization
[[ -z "$AUTOPAIR_INHIBIT_INIT" ]] && {
    for i in ${(@k)AUTOPAIR_PAIRS}; do
        bindkey "$i" autopair-insert
        bindkey -M isearch "$i" self-insert
    done

    local l=(')' '}' ']' '>')
    for i in $l; do
        bindkey "$i" autopair-close
        bindkey -M isearch "$i" self-insert
    done

    bindkey "^?" autopair-delete
    bindkey -M isearch "^?" backward-delete-char

    zle -N autopair-insert
    zle -N autopair-close
    zle -N autopair-delete
}
