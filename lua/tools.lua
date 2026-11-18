-- External tool management via mason. Language servers, formatters, and
-- debug adapters are installed into nvim-data/mason (shared across all
-- projects) instead of per-project virtual environments, so nothing needs to
-- be added to a project's own dev dependencies.
local M = {}

-- Tools kept installed and up to date. mason package names.
M.ensure_installed = {
  -- LSP servers
  "basedpyright", -- Python: types, hover, navigation
  "ruff", -- Python: linting + fixes (second LSP)
  "roslyn-language-server", -- C#: consumed by roslyn.nvim
  "terraform-ls", -- Terraform / HCL (HashiCorp's official server)
  -- Formatters
  "black", -- Python
  "jq", -- JSON (on demand)
  -- Debug adapters
  "debugpy", -- Python
  "netcoredbg", -- C# / .NET
}

function M.setup()
  require("mason").setup({
    ui = { border = "rounded" },
  })
  -- mason.setup prepends nvim-data/mason/bin to PATH, so the servers resolve
  -- by name for both lspconfig and conform.
  require("mason-tool-installer").setup({
    ensure_installed = M.ensure_installed,
    run_on_start = true,
  })
end

return M
