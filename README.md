# zsh-autopair

A simple plugin that auto-closes and deletes matching delimiters in ZSH.

e.g. 
* `echo |` => <kbd>"</kbd> => `echo "|"`
* `rm -f *.|` => <kbd>{</kbd> => `rm -f *.{|}`
* `git commit -m "|"` => <kbd>backspace</kbd> => `git commit -m |`

Disclaimer: I'm no shell guru, suggestions and PRs are welcome!

## Install

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

Bind the following:

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

Then type your heart out!
