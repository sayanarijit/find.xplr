[![find-xplr.gif](https://s10.gifyu.com/images/find-xplr.gif)](https://gifyu.com/image/Szb6a)

An interactive finder plugin to complement [map.xplr](https://github.com/sayanarijit/map.xplr).

> **WARNING:** This plugin will execute the find command during each input. So
> only use read-only commands.

## Requirements

`find` or `fd` or any finder of your choice. By default it uses `find`.

## Installation

### Install manually

- Add the following line in `~/.config/xplr/init.lua`

  ```lua
  local home = os.getenv("HOME")
  package.path = home
    .. "/.config/xplr/plugins/?/src/init.lua;"
    .. home
    .. "/.config/xplr/plugins/?.lua;"
    .. package.path
  ```

- Clone the plugin

  ```bash
  mkdir -p ~/.config/xplr/plugins

  git clone https://github.com/sayanarijit/find.xplr ~/.config/xplr/plugins/find
  ```

- Require the module in `~/.config/xplr/init.lua`

  ```lua
  require("find").setup()

  -- Or

  require("find").setup{
    mode = "default",
    key = "F",
    templates = {
      ["find all"] = {
        key = "a",
        find_command = "find",
        find_args = ". -name ",
        cursor_position = 13,
      },
      ["find files"] = {
        key = "f",
        find_command = "find",
        find_args = ". -name  -type f",
        cursor_position = 13,
      },
      ["find directories"] = {
        key = "d",
        find_command = "find",
        find_args = ". -name  -type d",
        cursor_position = 13,
      },
    },
    refresh_screen_key = "ctrl-r",
  }

  -- Press `F` to find files interactively using the `find_command`.
  ```

## Find-Map workflow

This library complements [map.xplr](https://github.com/sayanarijit/map.xplr) to
create a powerful workflow in which you first **find a set of files
interactively**, and then **map them to some command, also interactively**.

## Features

- Set the initial cursor position for complex find command templates.
- Use custom find command templates.
- Refresh screen with `ctrl-r`.

## TODO

- [ ] Ignore errors
- [ ] Improve performance
- [ ] Add timeout
- [ ] Allow pipes
- [ ] Templates for most common find command arguments
- [ ] More convenient integration with map.xplr
