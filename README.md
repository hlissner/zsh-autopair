# zsh-autopair

Auto-close matching delimiters in ZSH (and automatic pair deletion on backspace).

e.g. `echo |` => <kbd>"</kbd> => `echo "|"`

Suggestions and PRs are welcome!

## Install

Source `autopair.zsh` and bind the following keys:

```zsh
bindkey '`' autopair-insert-or-skip
bindkey '"' autopair-insert-or-skip
bindkey "'" autopair-insert-or-skip
bindkey '(' autopair-insert
bindkey '[' autopair-insert
bindkey '{' autopair-insert

bindkey ')' autopair-skip
bindkey ']' autopair-skip
bindkey '}' autopair-skip

bindkey '^?' autopair-delete   # backspace
```

### Antigen

`antigen-bundle hlissner/zsh-autopair`

### Zgen

```
if ! zgen saved; then
    echo "Creating a zgen save"

    # ... other plugins

    zgen load hlissner/zsh-autopair

    zgen save
fi
```

## Usage

Type yo' heart out!

## TODO

* More sophisticated balance checks
