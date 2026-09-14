-- Debugging via nvim-dap. Python uses debugpy, C# uses netcoredbg (both from
-- mason). Keys follow the vimspector "HUMAN" layout used in the legacy vimrc
-- (F5/F9/F10/F11).
local M = {}

local function mason_pkg(...)
  return table.concat({ vim.fn.stdpath("data"), "mason", "packages", ... }, "/")
end

function M.setup()
  local dap = require("dap")
  local dapui = require("dapui")

  dapui.setup()
  require("nvim-dap-virtual-text").setup({})

  -- Python. The adapter runs from mason's debugpy, but the debuggee runs under
  -- the project's own interpreter (debugpy injects itself, so the project venv
  -- does not need debugpy installed).
  local is_win = vim.fn.has("win32") == 1
  local debugpy_python = is_win and mason_pkg("debugpy", "venv", "Scripts", "python.exe")
    or mason_pkg("debugpy", "venv", "bin", "python")
  local dap_python = require("dap-python")
  dap_python.setup(debugpy_python)
  dap_python.test_runner = "pytest"
  dap_python.resolve_python = function()
    return require("pyenv").detect()
  end

  -- C# / .NET via netcoredbg. Prefer the real executable (nvim-dap spawns it
  -- directly and cannot run mason's .cmd wrapper on Windows).
  local netcoredbg = is_win and mason_pkg("netcoredbg", "netcoredbg", "netcoredbg.exe")
    or mason_pkg("netcoredbg", "netcoredbg", "netcoredbg")
  if not vim.uv.fs_stat(netcoredbg) then
    netcoredbg = vim.fn.exepath("netcoredbg")
  end
  dap.adapters.coreclr = {
    type = "executable",
    command = netcoredbg,
    args = { "--interpreter=vscode" },
  }
  dap.configurations.cs = {
    {
      type = "coreclr",
      name = "Launch (netcoredbg)",
      request = "launch",
      program = function()
        return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
      end,
    },
  }

  -- Open/close the UI automatically around a session.
  dap.listeners.after.event_initialized["dapui"] = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated["dapui"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["dapui"] = function()
    dapui.close()
  end

  vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "", linehl = "", numhl = "" })
  vim.fn.sign_define("DapStopped", { text = "▶", texthl = "", linehl = "Visual", numhl = "" })

  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { desc = desc })
  end
  map("<F5>", dap.continue, "Debug: continue/start")
  map("<F9>", dap.toggle_breakpoint, "Debug: toggle breakpoint")
  map("<F10>", dap.step_over, "Debug: step over")
  map("<F11>", dap.step_into, "Debug: step into")
  map("<S-F11>", dap.step_out, "Debug: step out")
  map("<leader>db", dap.toggle_breakpoint, "Debug: toggle breakpoint")
  map("<leader>dc", dap.continue, "Debug: continue")
  map("<leader>dr", dap.repl.toggle, "Debug: toggle REPL")
  map("<leader>du", dapui.toggle, "Debug: toggle UI")
  map("<leader>dt", dap.terminate, "Debug: terminate")
end

return M
