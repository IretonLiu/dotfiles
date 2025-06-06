dapui = require("dapui")
dapui.setup({
    icons = { expanded = "▾", collapsed = "▸" },
    mappings = { expand = { "<CR>", "<2-LeftMouse>", "<C-]>" }, open = "o", remove = "d", edit = "e" },
    sidebar = {
        open_on_start = true,
        elements = {
            { id = "watches", size = 0.4 },
            { id = "scopes",  size = 0.35 },
            { id = "stacks",  size = 0.25 },
        },
        width = 30,
        position = "left"
    },
    tray = {
        open_on_start = true,
        elements = { "repl" },
        height = 10,
        position = "bottom"
    },
    floating = { max_height = nil, max_width = nil },
    windows = { "breakpoints", "watches", "scopes", "stacks", "repl" },
    sidebar_layout = "horizontal",
    tray_position = "bottom"
})

local dap = require("dap")

dap.listeners.before.attach.dapui_config = function()
    dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
    dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
    dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
    dapui.close()
end
