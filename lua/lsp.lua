-- Native LSP setup (vim.lsp.config / vim.lsp.enable). Servers are installed
-- via mason (see lua/tools.lua). Buffer-local keymaps mirror the muscle memory
-- from the legacy vimrc (ALE / OmniSharp bindings) so the same keys work
-- across every language.
local M = {}

local detect_python = require("pyenv").detect

local function on_attach(client, bufnr)
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end
  local fzf = require("fzf-lua")

  -- Definitions on `gd` (a familiar key; Neovim has no native LSP `gd`, only
  -- <C-]>). Uses the built-in handler, so it jumps on a single result and
  -- fills the quickfix list on many -- consistent with the native grr / gri.
  -- References (grr), implementations (gri) and code action (gra) are all left
  -- to Neovim's native maps; gra's picker is fzf via register_ui_select().
  map("n", "gd", vim.lsp.buf.definition, "Go to definition")
  map("n", "<leader>s", fzf.lsp_live_workspace_symbols, "Search workspace symbols")

  -- Organize imports (no native equivalent).
  map("n", "gI", function()
    vim.lsp.buf.code_action({
      context = { only = { "source.organizeImports" }, diagnostics = {} },
      apply = true,
    })
  end, "Organize imports")

  -- Signature help + overload cycling. Native <C-s> is insert-mode only; this
  -- adds a normal-mode trigger. Overloads show "(n/total)"; press <C-s> again
  -- to focus the float, then <C-s> to cycle through every overload.
  map("n", "<C-s>", vim.lsp.buf.signature_help, "Signature help (cycle overloads)")

  -- ruff is a linter/fixer only; let basedpyright own hover.
  if client.name == "ruff" then
    client.server_capabilities.hoverProvider = false
  end
end

function M.setup()
  -- Rounded borders for all floating windows that don't set their own
  -- (hover, signature help, diagnostic floats). Lets us rely on the native
  -- K / <C-W>d / <C-s> maps instead of re-mapping them just to add a border.
  vim.o.winborder = "rounded"

  -- Completion capabilities from blink.cmp, applied to every server.
  vim.lsp.config("*", {
    capabilities = require("blink.cmp").get_lsp_capabilities(),
  })

  vim.diagnostic.config({
    severity_sort = true,
    float = { source = true },
    -- Native ]d / [d already jump; open the float automatically on jump.
    jump = { float = true },
    virtual_text = { spacing = 2, source = "if_many" },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "❌",
        [vim.diagnostic.severity.WARN] = "❗",
        [vim.diagnostic.severity.INFO] = "»",
        [vim.diagnostic.severity.HINT] = "›",
      },
    },
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client then
        on_attach(client, args.buf)
      end
    end,
    desc = "Set up buffer-local LSP keymaps",
  })

  -- Python: basedpyright for types/hover/navigation, ruff for lint + fixes.
  vim.lsp.config("basedpyright", {
    before_init = function(_, config)
      config.settings = config.settings or {}
      config.settings.python = config.settings.python or {}
      config.settings.python.pythonPath = detect_python(config.root_dir)
    end,
    settings = {
      basedpyright = {
        analysis = {
          typeCheckingMode = "standard",
          diagnosticMode = "openFilesOnly",
        },
      },
    },
  })
  vim.lsp.config("ruff", {})
  vim.lsp.enable({ "basedpyright", "ruff" })

  -- C#: Roslyn. roslyn.nvim auto-enables on cs files and locates the
  -- mason-installed server; extra settings go through vim.lsp.config("roslyn").
  require("roslyn").setup({})
  vim.lsp.config("roslyn", {
    settings = {
      ["csharp|completion"] = {
        dotnet_show_completion_items_from_unimported_namespaces = true,
        dotnet_show_name_completion_suggestions = true,
      },
      ["csharp|inlay_hints"] = {
        csharp_enable_inlay_hints_for_implicit_object_creation = true,
      },
    },
  })
end

return M
