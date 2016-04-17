# zsh-autopair
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](./LICENSE)
![ZSH 5.0.2](https://img.shields.io/badge/zsh-v5.0.2-orange.svg?style=flat-square)

A simple plugin that auto-closes, deletes and skips over matching delimiters in zsh
intelligently. Hopefully.

> NOTE: zsh-autopair is untested for versions of Zsh below 5.0.2. Please report any
> issues you have in earlier versions!

e.g.
* `echo |` => <kbd>"</kbd> => `echo "|"`
* `rm -f *.|` => <kbd>{</kbd> => `rm -f *.{|}`
* `git commit -m "|"` => <kbd>backspace</kbd> => `git commit -m |`
* `cat ./*.{py,rb|}` => <kbd>}</kbd> => `cat ./*.{py,rb}|`

## Install

Download and source `autopair.zsh`

### Antigen

`antigen-bundle hlissner/zsh-autopair`

### zgen
```
if ! zgen saved; then
    echo "Creating a zgen save"

    # ... other plugins

    zgen load hlissner/zsh-autopair

    zgen save
fi
```

### Zgen + Prezto

Prezto's Editor module will reset autopair's bindings. A workaround is available in
[issue #6](https://github.com/hlissner/zsh-autopair/issues/6).

### zplug
Load autopair after compinit, otherwise, the plugin won't work.
```bash
zplug "hlissner/zsh-autopair", nice:10
```

## Usage

zsh-autopair sets itself up, unless you have `AUTOPAIR_INHIBIT_INIT` set.

* If delimiters on the right side of the cursor are interfering with completion, bind
  <kbd>Tab</kbd> to `expand-or-complete-prefix`. Which will offer completion and ignore
  what's to the right of cursor.`

  `bindkey '^I' expand-or-complete-prefix`

* zsh-autopair will interfere with isearch, and will disable itself in isearch, so long
  as `AUTOPAIR_INHIBIT_INIT` is not set.
* Works wonderfully with [zsh-syntax-highlight] and
  `ZSH_HIGHLIGHT_HIGHLIGHTERS+=brackets`. Just be sure you load zsh-syntax-highlight
  *after* zsh-autopair.
* Mixes well with these vi-mode zsh modules: [surround], [select-quoted], and
  [select-bracketed] (they're built into zsh as of zsh-5.0.8)
* Check out my [zshrc]. I've spent unholy amounts of time tweaking it.

## Configuration

Feel free to tweak the following variables to adjust autopair's behavior:

* `AUTOPAIR_BETWEEN_WHITESPACE` (default: blank): if set, regardless of whether
  delimiters are unbalanced or do not meet a boundary check, pairs will be auto-closed
  if surrounded by whitespace, BOL or EOL.
* `AUTOPAIR_INHIBIT_INIT` (default: blank): if set, autopair will not automatically set
  up keybinds. [Check out the initialization code](autopair.zsh#L118) if you want to
  know what it does.
* `AUTOPAIR_PAIRS` (default: ``(` ` ' ' " " { } [ ] ( ) < >)``): An associative array
  that map pairs. Only one-character pairs are supported.
* `AUTOPAIR_LBOUNDS`/`AUTOPAIR_RBOUNDS` (default: see below): Associative
  lists of regex character groups dictating the 'boundaries' for autopairing depending
  on the delimiter. These are their default values:

  ```zsh
  AUTOPAIR_LBOUNDS[all]='[.:/\!]'
  AUTOPAIR_LBOUNDS[quotes]='[]})a-zA-Z0-9]'
  AUTOPAIR_LBOUNDS[braces]=''
  AUTOPAIR_LBOUNDS['"']='"'
  AUTOPAIR_LBOUNDS["'"]="'"
  AUTOPAIR_LBOUNDS['`']='`'

  AUTOPAIR_RBOUNDS[all]='[[{(<,.:?/%$!a-zA-Z0-9]'
  AUTOPAIR_RBOUNDS[quotes]='[a-zA-Z0-9]'
  AUTOPAIR_RBOUNDS[braces]=''
  ```

  For example, if `$AUTOPAIR_LBOUNDS[braces]="[a-zA-Z]"`, then braces (`{([`) won't be
  autopaired if the cursor follows an alphabetical character.

  Individual delimiters can be used too. Setting `$AUTOPAIR_RBOUNDS['{']="[0-9]"` will
  cause <kbd>{</kbd> specifically to not be autopaired when the cursor precedes a number.

[zshrc]: https://github.com/hlissner/dotfiles/blob/master/zshrc
[zsh-syntax-highlighting]: https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/pattern.md
[surround]: https://github.com/zsh-users/zsh/blob/master/Functions/Zle/surround
[select-quoted]: https://github.com/zsh-users/zsh/blob/master/Functions/Zle/select-quoted
[select-bracketed]: https://github.com/zsh-users/zsh/blob/master/Functions/Zle/select-bracketed
