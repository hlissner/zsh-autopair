[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](./LICENSE)
![ZSH 5.0.2+](https://img.shields.io/badge/zsh-v5.0.2-orange.svg?style=flat-square)
[![Build Status](https://img.shields.io/travis/hlissner/zsh-autopair/master.svg?label=master&style=flat-square)](https://travis-ci.org/hlissner/zsh-autopair)

# zsh-autopair
A simple plugin that auto-closes, deletes and skips over matching delimiters in
zsh intelligently. Hopefully.

> NOTE: zsh-autopair is untested for versions of Zsh below 5.0.2. Please report
> any issues you have in earlier versions!

Specifically, zsh-autopair does 5 things for you:

1. It inserts matching pairs (by default, that means brackets, quotes and
   spaces):

   e.g. `echo |` => <kbd>"</kbd> => `echo "|"`

2. It skips over matched pairs:

   e.g. `cat ./*.{py,rb|}` => <kbd>}</kbd> => `cat ./*.{py,rb}|`

3. It auto-deletes pairs on backspace:

   e.g. `git commit -m "|"` => <kbd>backspace</kbd> => `git commit -m |`

4. And does all of the above only when it makes sense to do so. e.g. when the
   pair is balanced and when the cursor isn't next to a boundary character:

   e.g. `echo "|""` => <kbd>backspace</kbd> => `echo |""` (doesn't aggressively eat up too many quotes)

5. Spaces between brackets are expanded and contracted.

   e.g. `echo [|]` => <kbd>space</kbd> => `echo [ | ]` => <kbd>backspace</kbd> => `echo [|]`


<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Install](#install)
    - [Antigen](#antigen)
    - [zgen](#zgen)
    - [zplug](#zplug)
- [Configuration](#configuration)
    - [Adding/Removing pairs](#addingremoving-pairs)
- [Troubleshooting & compatibility issues](#troubleshooting--compatibility-issues)
    - [zgen & prezto compatibility](#zgen--prezto-compatibility)
    - [text on right-side of cursor interfere with completion](#text-on-right-side-of-cursor-interfere-with-completion)
    - [zsh-autopair & isearch?](#zsh-autopair--isearch)
    - [Midnight Commander](#midnight-commander)
- [Other resources](#other-resources)

<!-- markdown-toc end -->

## Install
Download and source `autopair.zsh`

### Antigen
`antigen bundle hlissner/zsh-autopair`

### zgen
```
if ! zgen saved; then
    echo "Creating a zgen save"

    # ... other plugins
    zgen load hlissner/zsh-autopair

    zgen save
fi
```

### zplug
Load autopair _after compinit_, otherwise, the plugin won't work.
```bash
zplug "hlissner/zsh-autopair", defer:2
```


## Configuration
zsh-autopair sets itself up. You can prevent this by setting
`AUTOPAIR_INHIBIT_INIT`.

**Options:**
* `AUTOPAIR_BETWEEN_WHITESPACE` (default: blank): if set, regardless of whether
  delimiters are unbalanced or do not meet a boundary check, pairs will be
  auto-closed if surrounded by whitespace, BOL or EOL.
* `AUTOPAIR_INHIBIT_INIT` (default: blank): if set, autopair will not
  automatically set up keybinds. [Check out the initialization
  code](autopair.zsh#L118) if you want to know what it does.
* `AUTOPAIR_PAIRS` (default: ``('`' '`' "'" "'" '"' '"' '{' '}' '[' ']' '(' ')'
  ' ' ' ')``): An associative array that map pairs. Only one-character pairs are
  supported. To modify this, see the "Adding/Removing pairs" section.
* `AUTOPAIR_LBOUNDS`/`AUTOPAIR_RBOUNDS` (default: see below): Associative lists
  of regex character groups dictating the 'boundaries' for autopairing depending
  on the delimiter. These are their default values:

  ```bash
  AUTOPAIR_LBOUNDS=(all '[.:/\!]')
  AUTOPAIR_LBOUNDS+=(quotes '[]})a-zA-Z0-9]')
  AUTOPAIR_LBOUNDS+=(spaces '[^{([]')
  AUTOPAIR_LBOUNDS+=(braces '')
  AUTOPAIR_LBOUNDS+=('`' '`')
  AUTOPAIR_LBOUNDS+=('"' '"')
  AUTOPAIR_LBOUNDS+=("'" "'")

  AUTOPAIR_RBOUNDS=(all '[[{(<,.:?/%$!a-zA-Z0-9]')
  AUTOPAIR_RBOUNDS+=(quotes '[a-zA-Z0-9]')
  AUTOPAIR_RBOUNDS+=(spaces '[^]})]')
  AUTOPAIR_RBOUNDS+=(braces '')
  ```

  For example, if `$AUTOPAIR_LBOUNDS[braces]="[a-zA-Z]"`, then braces (`{([`) won't be
  autopaired if the cursor follows an alphabetical character.

  Individual delimiters can be used too. Setting `$AUTOPAIR_RBOUNDS['{']="[0-9]"` will
  cause <kbd>{</kbd> specifically to not be autopaired when the cursor precedes a number.

### Adding/Removing pairs
You can change the designated pairs in zsh-autopair by modifying the
`AUTOPAIR_PAIRS` envvar. This can be done _before_ initialization like so:

``` sh
typeset -gA AUTOPAIR_PAIRS
AUTOPAIR_PAIRS+=("<" ">")
```

Or after initialization; however, you'll have to bind keys to `autopair-insert`
manually:

```sh
AUTOPAIR_PAIRS+=("<" ">")
bindkey "<" autopair-insert
# prevents breakage in isearch
bindkey -M isearch "<" self-insert
```

To _remove_ pairs, use `unset 'AUTOPAIR_PAIRS[<]'`. Unbinding is optional.

## Troubleshooting & compatibility issues
### zgen & prezto compatibility
Prezto's Editor module is known to reset autopair's bindings. A workaround is to
_defer autopair from initializing_ (by setting `AUTOPAIR_INHIBIT_INIT=1`) and
initialize it manually (by calling `autopair-init`):

``` sh
source "$HOME/.zgen/zgen.zsh"

# Add this
AUTOPAIR_INHIBIT_INIT=1

if ! zgen saved; then
    zgen prezto
    # ...
    zgen load hlissner/zsh-autopair 'autopair.zsh'
    #...
    zgen save
fi

# And this
autopair-init
```

### text on right-side of cursor interfere with completion
Bind <kbd>Tab</kbd> to `expand-or-complete-prefix` and completion will ignore
what's to the right of cursor:

`bindkey '^I' expand-or-complete-prefix`

This has the unfortunate side-effect of overwriting whatever's right of the
cursor, however.

### zsh-autopair & isearch?
zsh-autopair silently disables itself in isearch, as the two are incompatible.

### Midnight Commander
MC hangs when zsh-autopair tries to bind the space key. This also breaks the MC
subshell.

Disable space expansion to work around this: `unset 'AUTOPAIR_PAIRS[ ]'`

## Other resources
* Works wonderfully with [zsh-syntax-highlight] and
  `ZSH_HIGHLIGHT_HIGHLIGHTERS+=brackets`, but zsh-syntax-highlight must be
  loaded *after* zsh-autopair.
* Mixes well with these vi-mode zsh modules: [surround], [select-quoted], and
  [select-bracketed] (they're built into zsh as of zsh-5.0.8)
* Other relevant repositories of mine:
  + [dotfiles]
  + [emacs.d]
  + [vimrc]
  + [zshrc]


[dotfiles]: https://github.com/hlissner/dotfiles
[vimrc]: https://github.com/hlissner/.vim
[emacs.d]: https://github.com/hlissner/doom-emacs
[zshrc]: https://github.com/hlissner/dotfiles/tree/master/shell/%2Bzsh
[zsh-syntax-highlighting]: https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/pattern.md
[surround]: https://github.com/zsh-users/zsh/blob/master/Functions/Zle/surround
[select-quoted]: https://github.com/zsh-users/zsh/blob/master/Functions/Zle/select-quoted
[select-bracketed]: https://github.com/zsh-users/zsh/blob/master/Functions/Zle/select-bracketed
