#!/usr/bin/env zsh

AUTOPAIR_INHIBIT_INIT=${AUTOPAIR_INHIBIT_INIT:-}
AUTOPAIR_BETWEEN_WHITESPACE=${AUTOPAIR_BETWEEN_WHITESPACE:-}
AUTOPAIR_SPC_WIDGET=${AUTOPAIR_SPC_WIDGET:-"$(bindkey " " | cut -c5-)"}
AUTOPAIR_BKSPC_WIDGET=${AUTOPAIR_BKSPC_WIDGET:-"$(bindkey "^?" | cut -c6-)"}
AUTOPAIR_DELWORD_WIDGET=${AUTOPAIR_DELWORD_WIDGET:-"$(bindkey "^w" | cut -c6-)"}

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


### Helpers ############################

# Returns the other pair for $1 (a char), blank otherwise
_ap-get-pair() {
    if [[ -n $1 ]]; then
        echo ${AUTOPAIR_PAIRS[$1]}
    elif [[ -n $2 ]]; then
        local i
        for i in ${(@k)AUTOPAIR_PAIRS}; do
            [[ $2 == ${AUTOPAIR_PAIRS[$i]} ]] && echo $i && break
        done
    fi
}

# Return 0 if cursor's surroundings match either regexp: $1 (left) or $2 (right)
_ap-boundary-p() {
    [[ -n $1 && $LBUFFER =~ "$1$" ]] || [[ -n $2 && $RBUFFER =~ "^$2" ]]
}

# Return 0 if the surrounding text matches any of the AUTOPAIR_*BOUNDS regexps
_ap-next-to-boundary-p() {
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
        _ap-boundary-p ${AUTOPAIR_LBOUNDS[$group]} ${AUTOPAIR_RBOUNDS[$group]} && return 0
    done
    return 1
}

# Return 0 if there are the same number of $1 as there are $2 (chars; a
# delimiter pair) in the buffer.
_ap-balanced-p() {
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
            # Balancing spaces is unnecessary. If there is at least one space on
            # either side of the cursor, it is considered balanced.
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

# Return 0 if the last keypress can be auto-paired.
_ap-can-pair-p() {
    local rchar="$(_ap-get-pair $KEYS)"

    [[ -n $rchar ]] || return 1

    if [[ $rchar != " " ]]; then
        # Force pair if surrounded by space/[BE]OL, regardless of
        # boundaries/balance
        [[ -n $AUTOPAIR_BETWEEN_WHITESPACE && \
            $LBUFFER =~ "(^|[ 	])$" && \
            $RBUFFER =~ "^($|[ 	])" ]] && return 0

        # Don't pair quotes if the delimiters are unbalanced
        ! _ap-balanced-p $KEYS $rchar && return 1
    elif [[ $RBUFFER =~ "^[ 	]*$" ]]; then
        # Don't pair spaces surrounded by whitespace
        return 1
    fi

    # Don't pair when in front of characters that likely signify the start of a
    # string, path or undesirable boundary.
    _ap-next-to-boundary-p $KEYS $rchar && return 1

    return 0
}

# Return 0 if the adjacent character (on the right) can be safely skipped over.
_ap-can-skip-p() {
    if [[ -z $LBUFFER ]]; then
        return 1
    elif [[ $1 == $2 ]]; then
        if [[ $1 == " " ]]; then
            return 1
        elif ! _ap-balanced-p $1 $2; then
            return 1
        fi
    fi
    if ! [[ -n $2 && ${RBUFFER[1]} == $2 && ${LBUFFER[-1]} != '\' ]]; then
        return 1
    fi
    return 0
}

# Return 0 if the adjacent character (on the right) can be safely deleted.
_ap-can-delete-p() {
    local lchar="${LBUFFER[-1]}"
    local rchar="$(_ap-get-pair $lchar)"
    ! [[ -n $rchar && ${RBUFFER[1]} == $rchar ]] && return 1
    if [[ $lchar == $rchar ]]; then
        if [[ $lchar == ' ' && ( $LBUFFER =~ "[^{([] +$" || $RBUFFER =~ "^ +[^]})]" ) ]]; then
            # Don't collapse spaces unless in delimiters
            return 1
        elif ! _ap-balanced-p $lchar $rchar; then
            return 1
        fi
    fi
    return 0
}

# Insert $1 and add $2 after the cursor
_ap-self-insert() {
    LBUFFER+=$1
    RBUFFER="$2$RBUFFER"
}


### Widgets ############################

autopair-insert() {
    local rchar="$(_ap-get-pair $KEYS)"
    if [[ $KEYS == (\'|\"|\`| ) ]] && _ap-can-skip-p $KEYS $rchar; then
        zle forward-char
    elif _ap-can-pair-p; then
        _ap-self-insert $KEYS $rchar
    elif [[ $rchar == " " ]]; then
        zle ${AUTOPAIR_SPC_WIDGET:-self-insert}
    else
        zle self-insert
    fi
}

autopair-close() {
    if _ap-can-skip-p "$(_ap-get-pair "" $KEYS)" $KEYS; then
        zle forward-char
    else
        zle self-insert
    fi
}

autopair-delete() {
    _ap-can-delete-p && RBUFFER=${RBUFFER:1}
    zle ${AUTOPAIR_BKSPC_WIDGET:-backward-delete-char}
}

autopair-delete-word() {
    _ap-can-delete-p && RBUFFER=${RBUFFER:1}
    zle ${AUTOPAIR_DELWORD_WIDGET:-backward-delete-word}
}


### Initialization #####################

autopair-init() {
    zle -N autopair-insert
    zle -N autopair-close
    zle -N autopair-delete
    zle -N autopair-delete-word

    local p
    for p in ${(@k)AUTOPAIR_PAIRS}; do
        bindkey "$p" autopair-insert
        bindkey -M isearch "$p" self-insert

        local rchar="$(_ap-get-pair $p)"
        if [[ $p != $rchar ]]; then
            bindkey "$rchar" autopair-close
            bindkey -M isearch "$rchar" self-insert
        fi
    done

    bindkey "^?" autopair-delete
    bindkey "^h" autopair-delete
    bindkey "^w" autopair-delete-word
    bindkey -M isearch "^?" backward-delete-char
    bindkey -M isearch "^h" backward-delete-char
    bindkey -M isearch "^w" backward-delete-word
}
[[ -n $AUTOPAIR_INHIBIT_INIT ]] || autopair-init
