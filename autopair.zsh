#!/usr/bin/env zsh

# A widget that auto-inserts matching pairs in ZSH.

AUTOPAIR_INHIBIT_INIT=${AUTOPAIR_INHIBIT_INIT:-}
AUTOPAIR_BETWEEN_WHITESPACE=${AUTOPAIR_BETWEEN_WHITESPACE:-}
AUTOPAIR_SPC_WIDGET=${AUTOPAIR_SPC_WIDGET:-$(bindkey " " | cut -c5-)}

typeset -gA AUTOPAIR_PAIRS
AUTOPAIR_PAIRS=('`' '`' "'" "'" '"' '"' '{' '}' '[' ']' '(' ')' ' ' ' ')

typeset -gA AUTOPAIR_LBOUNDS
AUTOPAIR_LBOUNDS=(all '[.:/\!]')
AUTOPAIR_LBOUNDS+=(quotes '[]})a-zA-Z0-9]')
AUTOPAIR_LBOUNDS+=(spaces '[^{([]')
AUTOPAIR_LBOUNDS+=(braces '')
AUTOPAIR_LBOUNDS+=('`' '`')
AUTOPAIR_LBOUNDS+=('"' '"')
AUTOPAIR_LBOUNDS+=("'" "'")

typeset -gA AUTOPAIR_RBOUNDS
AUTOPAIR_RBOUNDS=(all '[[{(<,.:?/%$!a-zA-Z0-9]')
AUTOPAIR_RBOUNDS+=(quotes '[a-zA-Z0-9]')
AUTOPAIR_RBOUNDS+=(spaces '[^]})]')
AUTOPAIR_RBOUNDS+=(braces '')

####

ap-get-pair() {
    if [[ $1 ]]; then
        echo $AUTOPAIR_PAIRS[$1]
    elif [[ $2 ]]; then
        local i
        for i in ${(@k)AUTOPAIR_PAIRS}; do
            [[ $2 == $AUTOPAIR_PAIRS[$i] ]] && echo $i && break
        done
    fi
}

ap-boundary-p() {
    [[ -n $1 && $LBUFFER =~ "$1$" ]] || [[ -n $2 && $RBUFFER =~ "^$2" ]]
}

ap-next-to-boundary-p() {
    local -a groups
    groups=(all)
    case $1 in
        \'|\"|\`)    groups+=quotes ;;
        \{|\[|\(|\<) groups+=braces ;;
        " ")         groups+=spaces ;;
    esac
    groups+=$1
    local group
    for group in $groups; do
        ap-boundary-p $AUTOPAIR_LBOUNDS[$group] $AUTOPAIR_RBOUNDS[$group] && return 0
    done
    return 1
}

# If provided pair is balanced in the buffer
ap-balanced-p() {
    local lbuf="${LBUFFER//\\$1}"
    local rbuf="${RBUFFER//\\$2}"
    local llen="${#lbuf//[^$1]}"
    local rlen="${#rbuf//[^$2]}"
    if (( rlen == 0 && llen == 0 )); then
        return 0
    elif [[ $1 == $2 ]]; then
        if [[ $1 == " " ]]; then
            # Silence WARN_CREATE_GLOBAL errors
            local match=
            local mbegin=
            local mend=
            [[ $LBUFFER =~ "[^'\"]([ 	]+)$" && $RBUFFER =~ "^${match[1]}" ]] && return 0
            return 1
        elif (( llen == rlen || (llen + rlen) % 2 == 0 )); then
            return 0
        fi
    else
        local l2len="${#lbuf//[^$2]}"
        local r2len="${#rbuf//[^$1]}"
        local ltotal=$((llen - l2len))
        local rtotal=$((rlen - r2len))

        (( ltotal < 0 )) && ltotal=0
        (( ltotal < rtotal )) && return 1
        return 0
    fi
    return 1
}

ap-can-pair-p() {
    local rchar=$(ap-get-pair $KEYS)

    # Don't pair if pair doesn't exist
    [[ $rchar ]] || return 1

    # Don't pair quotes if the delimiters are unbalanced
    if [[ $rchar != " " ]]; then
        # Force pair if surrounded by space/[BE]OL, regardless of
        # boundaries/balance
        [[ $AUTOPAIR_BETWEEN_WHITESPACE && \
            $LBUFFER =~ "(^|[ 	])$" && \
            $RBUFFER =~ "^($|[ 	])" ]] && return 0

        # Don't pair quotes if the delimiters are unbalanced
        ! ap-balanced-p $KEYS $rchar && return 1
    elif [[ $RBUFFER =~ "^[ 	]*$" ]]; then
        return 1
    fi

    # Don't pair when in front of characters that likely signify the start of a
    # string or path (i.e. boundary characters)
    ap-next-to-boundary-p $KEYS $rchar && return 1

    return 0
}

ap-can-skip-p() {
    if [[ $1 == $2 ]]; then
        if [[ $1 == " " ]]; then
            return 1
        elif ! ap-balanced-p $1 $2; then
            return 1
        fi
    fi
    if ! [[ $2 && $RBUFFER[1] == $2 && $LBUFFER[-1] != '\' ]]; then
        return 1
    fi
    return 0
}

ap-can-delete-p() {
    local lchar="$LBUFFER[-1]"
    local rchar=$(ap-get-pair $lchar)
    ! [[ $rchar && $RBUFFER[1] == $rchar ]] && return 1
    [[ $lchar == $rchar ]] && ! ap-balanced-p $lchar $rchar && return 1
    return 0
}

autopair-self-insert() {
    LBUFFER+=$1$2
    zle backward-char
}

autopair-insert() {
    local rchar=$(ap-get-pair $KEYS)
    if [[ $KEYS == (\'|\"|\`| ) ]] && ap-can-skip-p $KEYS $rchar; then
        zle forward-char
    elif ap-can-pair-p; then
        autopair-self-insert $KEYS $rchar
    elif [[ $rchar == " " && $AUTOPAIR_SPC_WIDGET ]]; then
        zle $AUTOPAIR_SPC_WIDGET
    else
        zle self-insert
    fi
}

autopair-close() {
    if ap-can-skip-p $(ap-get-pair "" $KEYS) $KEYS
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

    local p
    for p in ${(@k)AUTOPAIR_PAIRS}; do
        bindkey "$p" autopair-insert
        bindkey -M isearch "$p" self-insert

        local rchar=$(ap-get-pair $p)
        if [[ $p != $rchar ]]; then
            bindkey "$rchar" autopair-close
            bindkey -M isearch "$rchar" self-insert
        fi
    done

    bindkey "^?" autopair-delete
    bindkey "^h" autopair-delete
    bindkey -M isearch "^?" backward-delete-char
    bindkey -M isearch "^h" backward-delete-char
}
[[ $AUTOPAIR_INHIBIT_INIT ]] || autopair-init
