# A git blame plugin for neovim inspired by VS Code's GitLens plugin

![nvim-blamer-lua](nvim-blamer-lua.png)

## requirement

neovim version: >= 0.5.0-dev ( or nightly version )

the `git` cli must exists in your system and in `PATH` env

## features

- configuable message format
- delay auto hide feature
- dynamic toggle


## usage

just install the plugin and it should works automatically.

for example, use [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'ttys3/nvim-blamer.lua'

""" must after plugin loaded, for example,
""" if you are using vim-plug, this should put after `call plug#end()`
""" enable auto show blame info when cursor move
call nvimblamer#auto()

""" config the plugin
lua <<EOF

require'nvim-blamer'.setup({
    enable = true,
    format = '%committer │ %committer-time-human │ %summary',
})

EOF

```

## default config

```lua
{
    enable = false,  -- you must set this to true in order to show the blame info
    prefix = '  ', -- you can cusomize it to any thing, unicode emoji, even disable it, just set to empty lua string
    format = '%committer │ %committer-time %committer-tz │ %summary',
    auto_hide = false, -- set this to true will enable delay hide even you do not have the cursor moved
    hide_delay = 3000, -- this is the delay time in milliseconds for delay auto hide
}
```

you may need install some patched font to use unicode emoji, like NerdFont <https://github.com/ryanoasis/nerd-fonts>

you can find your favorite emoji using <https://www.nerdfonts.com/cheat-sheet>

here are some emoji candicates:

`\uE702` 

`\uF1D2` 

`\uF1D3` 

`\uE80D` 

`\uF417` 

## availabe template vars

you can use `filename`, `hash`, `summary`, `committer`, `committer-mail`, `committer-tz`, `committer-time` and `committer-time-human`

```json
{
  "filename": "lua/blamer.lua",
  "hash": "db43ae622dbec1ba3fd8172c2d4fed1b2980c39c",
  "summary": "fix: bypass ft list: rename LuaTree to NvimTree. do not show Not Committed Yet msg",

  "committer": "荒野無燈",
  "committer-mail": "<a@example.com>",
  "committer-tz": "+0800",
  "committer-time": "1610563580",

  "author": "荒野無燈",
  "author-mail": "<a@example.com>",
  "author-time": "1610563580",
  "author-tz": "+0800",
}
```

## available commands

```vim
""" auto show blame info when cursor move
:NvimBlamerAuto

""" toggle blame info display
:NvimBlamerToggle
```

## credits

thanks for the unicode emoji from <https://github.com/romkatv/powerlevel10k/blob/3920940ea84f6fba767cbed3fe6ba0653411c706/internal/icons.zsh#L226>

the idea and the init code come from https://www.reddit.com/r/neovim/comments/f1vxhl/replicate_the_basic_functionality_vscodes_gitlens/
https://teukka.tech/vimtip-gitlens.html


## related works

<https://github.com/APZelos/blamer.nvim>

<https://github.com/f-person/git-blame.nvim>

<https://github.com/tveskag/nvim-blame-line>

<https://github.com/zivyangll/git-blame.vim>
