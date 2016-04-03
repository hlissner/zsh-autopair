#!/usr/bin/env zsh

# A widget that auto-inserts matching pairs in ZSH.

AUTOPAIR_INHIBIT_INIT=${AUTOPAIR_INHIBIT_INIT:-}
AUTOPAIR_BETWEEN_WHITESPACE=${AUTOPAIR_BETWEEN_WHITESPACE:-}

typeset -gA AUTOPAIR_PAIRS
AUTOPAIR_PAIRS=('`' '`' "'" "'" '"' '"' '{' '}' '[' ']' '(' ')')

typeset -gA AUTOPAIR_LBOUNDS
AUTOPAIR_LBOUNDS=('`' '`')
AUTOPAIR_LBOUNDS[all]='[.:/\!]'
AUTOPAIR_LBOUNDS[quotes]='[]})a-zA-Z0-9]'
AUTOPAIR_LBOUNDS[braces]=''
AUTOPAIR_LBOUNDS['"']='"'
AUTOPAIR_LBOUNDS["'"]="'"

typeset -gA AUTOPAIR_RBOUNDS
AUTOPAIR_RBOUNDS[all]='[[{(<,.:?/%$!a-zA-Z0-9]'
AUTOPAIR_RBOUNDS[quotes]='[a-zA-Z0-9]'
AUTOPAIR_RBOUNDS[braces]=''

####

ap-get-pair() {
    if [[ -n "$1" ]]; then
        echo "${AUTOPAIR_PAIRS[$1]}"
    elif [[ -n "$2" ]]; then
        for i in ${(@k)AUTOPAIR_PAIRS}; do
            [[ "$2" == "${AUTOPAIR_PAIRS[$i]}" ]] && echo "$i" && break
        done
    fi
}

ap-boundary-p() {
    [[ -n "$1" && "$LBUFFER" =~ "$1$" ]] || [[ -n "$2" && "$RBUFFER" =~ "^$2" ]]
}
ap-next-to-boundary-p() {
    local -a groups
    groups=(all)
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
    local rchar=$(ap-get-pair "$KEYS")

    # Don't pair if pair doesn't exist
    [[ -z "$rchar" ]] && return 1

    # Force pair if surrounded by space/[BE]OL, regardless of boundaries/balance
    [[ -n "$AUTOPAIR_BETWEEN_WHITESPACE" && \
        "$LBUFFER" =~ "(^|[ 	])$" && \
        "$RBUFFER" =~ "^($|[ 	])" ]] && return 0

    # Don't pair quotes if the delimiters are unbalanced
    ! ap-balanced-p "$KEYS" "$rchar" && return 1

    # Don't pair when in front of characters that likely signify the start of a string
    # or path (i.e. boundary characters)
    ap-next-to-boundary-p "$KEYS" "$rchar" && return 1

    return 0
}

ap-can-skip-p() {
    ! [[ -n "$2" && "$RBUFFER[1]" == "$2" && "$LBUFFER[-1]" != '\' ]] && return 1
    [[ "$1" == "$2" ]] && ! ap-balanced-p "$1" "$2" && return 1
    return 0
}

ap-can-delete-p() {
    local lchar="$LBUFFER[-1]"
    local rchar=$(ap-get-pair "$lchar")
    ! [[ -n "$rchar" && "$RBUFFER[1]" == "$rchar" ]] && return 1
    [[ "$lchar" == "$rchar" ]] && ! ap-balanced-p "$lchar" "$rchar" && return 1
    return 0
}

autopair-self-insert() {
    LBUFFER+="$1$2"
    zle backward-char
}

autopair-insert() {
    local rchar=$(ap-get-pair "$KEYS")
    if [[ "$KEYS" == (\'|\"|\`) ]] && ap-can-skip-p "$KEYS" "$rchar"; then
        zle forward-char
    elif ap-can-pair-p; then
        autopair-self-insert "$KEYS" "$rchar"
    else
        zle self-insert
    fi
}

autopair-close() {
    if ap-can-skip-p $(ap-get-pair "" "$KEYS") "$KEYS"
    then zle forward-char
    else zle self-insert
    fi
}

autopair-delete() {
    ap-can-delete-p && zle .delete-char
    zle backward-delete-char
}

# Initialization
autopair-init() {
    zle -N autopair-insert
    zle -N autopair-close
    zle -N autopair-delete

    for i in ${(@k)AUTOPAIR_PAIRS}; do
        bindkey "$i" autopair-insert
        bindkey -M isearch "$i" self-insert
    done

    local -a l
    l=(')' '}' ']')
    for i in $l; do
        bindkey "$i" autopair-close
        bindkey -M isearch "$i" self-insert
    done

    bindkey "^?" autopair-delete
    bindkey -M isearch "^?" backward-delete-char
}
[[ -z "$AUTOPAIR_INHIBIT_INIT" ]] && autopair-init
