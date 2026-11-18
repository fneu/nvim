-- Formatting via conform.nvim. Code files (Python, C#) format on save; data
-- files (JSON, XML) format on demand with <leader>gq (the legacy ALEFix key).
-- Linting is handled by the LSP servers (ruff, Roslyn), not a separate plugin.
local M = {}

function M.setup()
  local conform = require("conform")

  conform.setup({
    formatters_by_ft = {
      python = { "black" },
      json = { "jq" },
      -- Terraform: `terraform fmt` (needs the terraform CLI on PATH), matching
      -- the HashiCorp extension's format-on-save. tfvars is also valid HCL.
      terraform = { "terraform_fmt" },
      ["terraform-vars"] = { "terraform_fmt" },
      -- xmllint ships with libxml2; used on demand only (not in mason).
      xml = { "xmllint" },
      -- C# has no entry here: it formats through the Roslyn LSP, which
      -- respects the project's .editorconfig (see format_on_save below).
    },
    format_on_save = function(bufnr)
      local ft = vim.bo[bufnr].filetype
      if ft == "python" or ft == "terraform" or ft == "terraform-vars" then
        return { timeout_ms = 3000, lsp_format = "never" }
      elseif ft == "cs" then
        return { timeout_ms = 3000, lsp_format = "fallback" }
      end
      -- Everything else (json, xml, ...) stays manual.
      return nil
    end,
  })

  vim.keymap.set({ "n", "x" }, "<leader>gq", function()
    conform.format({ async = false, lsp_format = "fallback", timeout_ms = 3000 })
  end, { desc = "Format buffer/selection" })
end

return M
