-- Test running & debugging via neotest. Python uses pytest, C# uses xUnit
-- (via neotest-dotnet). Debugging a test reuses the nvim-dap adapters. Keys
-- follow the vim-test bindings from the legacy vimrc (<leader>t...).
local M = {}

function M.setup()
  local neotest = require("neotest")

  neotest.setup({
    adapters = {
      require("neotest-python")({
        runner = "pytest",
        dap = { justMyCode = false },
      }),
      require("neotest-dotnet")({
        dap = { adapter_name = "coreclr" },
      }),
    },
  })

  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { desc = desc })
  end
  map("<leader>tn", function()
    neotest.run.run()
  end, "Test: nearest")
  map("<leader>tf", function()
    neotest.run.run(vim.fn.expand("%"))
  end, "Test: file")
  map("<leader>ta", function()
    neotest.run.run(vim.fn.getcwd())
  end, "Test: all")
  map("<leader>tl", function()
    neotest.run.run_last()
  end, "Test: last")
  map("<leader>td", function()
    neotest.run.run({ strategy = "dap" })
  end, "Test: debug nearest")
  map("<leader>ts", function()
    neotest.summary.toggle()
  end, "Test: summary")
  map("<leader>to", function()
    neotest.output.open({ enter = true })
  end, "Test: output")
  map("<leader>tO", function()
    neotest.output_panel.toggle()
  end, "Test: output panel")
  map("<leader>tS", function()
    neotest.run.stop()
  end, "Test: stop")
end

return M
