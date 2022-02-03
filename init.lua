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
}

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

local function read_file(path)
  local file = io.open(path, "rb") -- r read mode and b binary mode
  if not file then
    return {}
  end
  local content = file:read("*a") -- *a or *all reads the whole file
  file:close()

  local lines = {}
  for s in content:gmatch("[^\r\n]+") do
    table.insert(lines, s)
  end
  return lines
end

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
        { BufferInput = t.find_args },
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
              { Length = 1 },
              { Min = 1 },
              { Length = 3 },
            },
          },
          splits = {
            "Nothing",
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
    }
  end

  xplr.fn.custom.find.exec_command = function(app)
    find_args = app.input_buffer or find_args

    local cmd = find_command .. " " .. find_args
    local result_file, errors_file = os.tmpname(), os.tmpname()
    local ret = os.execute(cmd .. " > " .. result_file .. " 2> " .. errors_file)

    if ret == 0 then
      result = read_file(result_file)
      errors = {}
    else
      result = {}
      errors = read_file(errors_file)
    end

    os.remove(result_file)
    os.remove(errors_file)
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
      table.insert(
        ui,
        tostring(#result) .. " result found for `" .. cmd .. "` ..."
      )
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
