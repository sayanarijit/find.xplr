---@diagnostic disable
local xplr = xplr
---@diagnostic enable

local result = {}
local errors = {}

local find_command = "find"
local find_args = ""

local templates = {
  ["find all"] = {
    key = "a",
    find_command = "find",
    find_args = ". -name ",
    cursor_position = 8,
  },
  ["find files"] = {
    key = "f",
    find_command = "find",
    find_args = ". -name  -type f",
    cursor_position = 8,
  },
  ["find directories"] = {
    key = "d",
    find_command = "find",
    find_args = ". -name  -type d",
    cursor_position = 8,
  },
}

local function splitlines(str)
  local lines = {}
  for line in str:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  return lines
end

local function parse_args(args)
  args = args or {}
  args.mode = args.mode or "default"
  args.key = args.key or "F"
  args.templates = args.templates or templates
  args.refresh_screen_key = args.refresh_screen_key or "ctrl-r"

  return args
end

local layout = {
  CustomContent = {
    title = "find",
    body = { DynamicList = { render = "custom.find.render" } },
  },
}

local function setup(args)
  args = parse_args(args)

  xplr.config.modes.custom.find = {
    name = "find",
    key_bindings = {
      on_key = {
        esc = {
          help = "cancel",
          messages = {
            "PopMode",
          },
        },
        ["ctrl-c"] = {
          help = "terminate",
          messages = {
            "Terminate",
          },
        },

        -- disable dangerous keys
        ["&"] = { messages = {} },
        [">"] = { messages = {} },
        ["<"] = { messages = {} },
        ["|"] = { messages = {} },
        ["`"] = { messages = {} },
      },
    },
  }

  local i = 0
  for help, t in pairs(args.templates) do
    i = i + 1

    local mode_name = "find_" .. tostring(i)

    xplr.config.modes.custom.find.key_bindings.on_key[t.key] = {
      help = help,
      messages = {
        "PopMode",
        { SetInputBuffer = t.find_command },
        { CallLuaSilently = "custom.find.capture_find_command" },
        { SetInputBuffer = t.find_args },
        { UpdateInputBuffer = { SetCursor = t.cursor_position } },
        { CallLuaSilently = "custom.find.exec_command" },
        { SwitchModeCustomKeepingInputBuffer = mode_name },
      },
    }

    xplr.config.modes.custom[mode_name] = {
      name = help,
      layout = {
        Vertical = {
          config = {
            constraints = {
              { Min = 1 },
              { Length = 3 },
            },
          },
          splits = {
            layout,
            "InputAndLogs",
          },
        },
      },
      key_bindings = {
        on_key = {
          enter = {
            help = "select result",
            messages = {
              { CallLuaSilently = "custom.find.select_result" },
            },
          },
          [args.refresh_screen_key] = {
            help = "refresh screen",
            messages = {
              "ClearScreen",
              "Refresh",
            },
          },
          esc = {
            help = "cancel",
            messages = {
              "PopMode",
            },
          },
          ["ctrl-c"] = {
            help = "terminate",
            messages = {
              "Terminate",
            },
          },

          -- disable dangerous keys
          [">"] = { messages = {} },
          ["<"] = { messages = {} },
          ["|"] = { messages = {} },
          ["`"] = { messages = {} },
        },
        default = {
          messages = {
            "UpdateInputBufferFromKey",
            { CallLuaSilently = "custom.find.exec_command" },
          },
        },
      },
    }
  end

  xplr.config.modes.builtin[args.mode].key_bindings.on_key[args.key] = {
    help = "find",
    messages = {
      "PopMode",
      { SwitchModeCustom = "find" },
    },
  }

  xplr.fn.custom.find = {}

  xplr.fn.custom.find.select_result = function(_)
    local msgs = {}

    for _, path in ipairs(result) do
      table.insert(msgs, { SelectPath = path })
    end

    table.insert(msgs, "PopMode")

    return msgs
  end

  xplr.fn.custom.find.capture_find_command = function(app)
    find_command = app.input_buffer or find_command
    find_args = ""

    return {
      { SetInputBuffer = "" },
      { SetInputPrompt = "!" .. find_command .. " " },
    }
  end

  xplr.fn.custom.find.exec_command = function(app)
    if not app.input_buffer or app.input_buffer == find_args then
      return
    end

    find_args = app.input_buffer

    local cmd = find_command .. " " .. find_args
    local res = xplr.util.shell_execute("bash", { "-c", cmd })

    if res.returncode == 0 then
      result = splitlines(res.stdout)
      errors = {}
    else
      result = {}
      errors = splitlines(res.stderr)
    end
  end

  xplr.fn.custom.find.render = function(ctx)
    local cmd = find_command .. " " .. find_args

    local ui = { " " }
    if #errors ~= 0 then
      table.insert(ui, "Errors:")
      table.insert(ui, " ")

      for _, err in ipairs(errors) do
        table.insert(ui, "  " .. err)
      end
    else
      table.insert(ui, tostring(#result) .. " result found for `" .. cmd .. "` ...")
      table.insert(ui, " ")

      for i1, file in ipairs(result) do
        table.insert(ui, "  " .. file)
        if i1 > ctx.layout_size.height then
          break
        end
      end
    end

    return ui
  end
end

return { setup = setup, templates = templates }
