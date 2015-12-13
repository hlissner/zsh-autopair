# zsh-autopair

![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)
![ZSH 5.0.2](https://img.shields.io/badge/zsh-v5.0.2-orange.svg?style=flat-square)

A simple plugin that auto-closes, deletes and skips over matching delimiters in zsh
intelligently. Hopefully.

e.g. 
* `echo |` => <kbd>"</kbd> => `echo "|"`
* `rm -f *.|` => <kbd>{</kbd> => `rm -f *.{|}`
* `git commit -m "|"` => <kbd>backspace</kbd> => `git commit -m |`
* `cat ./*.{py,rb|}` => <kbd>}</kbd> => `cat ./*.{py,rb}|`

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
bindkey '<' autopair-insert

bindkey ')' autopair-skip
bindkey ']' autopair-skip
bindkey '}' autopair-skip
bindkey '>' autopair-skip

bindkey '^?' autopair-delete   # backspace
```

Then type your heart out!
