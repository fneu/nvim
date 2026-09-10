vim.g.mapleader = " "

vim.keymap.set({ "n", "x", "o" }, "ö", "[", { remap = true, desc = "Use previous bracket mapping" })
vim.keymap.set({ "n", "x", "o" }, "ä", "]", { remap = true, desc = "Use next bracket mapping" })


vim.pack.add({
  "https://github.com/zbirenbaum/copilot.lua",
  "https://github.com/folke/sidekick.nvim",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
  "https://github.com/nvim-tree/nvim-web-devicons",
  {
    src = "https://github.com/Saghen/blink.cmp",
    version = vim.version.range("1"),
  },
  "https://github.com/rafamadriz/friendly-snippets",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/sindrets/diffview.nvim",
  "https://github.com/NeogitOrg/neogit",
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/barrettruth/canola.nvim",
})

require("copilot").setup({
  suggestion = {
    auto_trigger = true,
    hide_during_completion = true,
    keymap = {
      accept = false,
      accept_word = "<M-w>",
      accept_line = "<M-l>",
      next = false,
      prev = false,
      dismiss = false,
    },
  },
})
require("sidekick").setup()
require("nvim-web-devicons").setup()
require("oil").setup({
  keymaps = {
    ["`"] = false,
    ["gc"] = "actions.cd",
  },
})
require("diffview").setup()
require("fzf-lua").setup()
require("neogit").setup({
  integrations = {
    diffview = true,
    fzf_lua = true,
  },
})
require("gitsigns").setup({
  on_attach = function(buffer)
    local gitsigns = require("gitsigns")
    local function map(mode, lhs, rhs, desc, opts)
      vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", {
        buffer = buffer,
        desc = desc,
      }, opts or {}))
    end

    map("n", "]c", function()
      if vim.wo.diff then
        return "]c"
      end
      vim.schedule(gitsigns.next_hunk)
      return "<Ignore>"
    end, "Next Git hunk", { expr = true })
    map("n", "[c", function()
      if vim.wo.diff then
        return "[c"
      end
      vim.schedule(gitsigns.prev_hunk)
      return "<Ignore>"
    end, "Previous Git hunk", { expr = true })
  end,
})

require("blink.cmp").setup({
  keymap = {
    preset = "default",
    ["<Tab>"] = {
      function(cmp)
        if cmp.is_menu_visible() then
          return cmp.select_next()
        end
      end,
      function()
        return require("sidekick").nes_jump_or_apply()
      end,
      function()
        local suggestion = require("copilot.suggestion")
        if suggestion.is_visible() then
          suggestion.accept()
          return true
        end
      end,
      "fallback",
    },
    ["<S-Tab>"] = {
      function(cmp)
        if cmp.is_menu_visible() then
          return cmp.select_prev()
        end
      end,
      "fallback",
    },
    ["<CR>"] = { "select_and_accept", "fallback" },
    ["<M-j>"] = { "snippet_forward", "fallback" },
    ["<M-k>"] = { "snippet_backward", "fallback" },
  },
  completion = {
    documentation = { auto_show = true },
    ghost_text = { enabled = false },
  },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },
})

vim.api.nvim_create_autocmd("User", {
  pattern = "BlinkCmpMenuOpen",
  callback = function()
    vim.b.copilot_suggestion_hidden = true
  end,
  desc = "Hide Copilot while the completion menu is open",
})
vim.api.nvim_create_autocmd("User", {
  pattern = "BlinkCmpMenuClose",
  callback = function()
    vim.b.copilot_suggestion_hidden = false
  end,
  desc = "Show Copilot after the completion menu closes",
})

vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit Terminal mode" })

vim.keymap.set("i", "<Esc>", function()
  local suggestion = require("copilot.suggestion")
  if suggestion.is_visible() then
    suggestion.dismiss()
  end
  return "<Esc>"
end, { expr = true, desc = "Dismiss Copilot suggestion" })

-- Restore Terminal mode whenever a terminal buffer receives focus.
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    if vim.bo.buftype == "terminal" then
      vim.cmd.startinsert()
    end
  end,
  desc = "Enter Terminal mode when focusing a terminal",
})

vim.keymap.set("n", "<Tab>", function()
  if not require("sidekick").nes_jump_or_apply() then
    return "<Tab>"
  end
end, { expr = true, desc = "Goto/Apply Next Edit Suggestion" })
vim.keymap.set("n", "-", "<Cmd>Oil<CR>", { desc = "Open Oil in current file's directory" })
vim.keymap.set("n", "_", function()
  require("oil").open(vim.fn.getcwd())
end, { desc = "Open Oil in project root (cwd)" })
vim.keymap.set("n", "<leader><leader>", function()
  require("fzf-lua").files()
end, { desc = "Find project files" })
vim.keymap.set("n", "<leader>/", function()
  require("fzf-lua").live_grep()
end, { desc = "Search project text" })
vim.keymap.set("n", "<leader>b", function()
  require("fzf-lua").buffers()
end, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>gg", "<Cmd>Neogit<CR>", { desc = "Open Neogit" })
vim.keymap.set("n", "<leader>gd", "<Cmd>DiffviewOpen<CR>", { desc = "Review Git changes" })
vim.keymap.set("n", "<leader>gh", "<Cmd>DiffviewFileHistory %<CR>", { desc = "Git history for file" })
vim.keymap.set("n", "<leader>gb", "<Cmd>Gitsigns blame_line<CR>", { desc = "Git blame line" })
vim.keymap.set({ "n", "t", "i", "x" }, "<C-.>", function()
  require("sidekick.cli").focus()
end, { desc = "Sidekick Focus" })
vim.keymap.set("n", "<leader>aa", function()
  require("sidekick.cli").toggle({name = "copilot", focus = true})
end, { desc = "Sidekick Toggle CLI" })
vim.keymap.set("n", "<leader>ad", function()
  require("sidekick.cli").close()
end, { desc = "Detach a CLI Session" })
vim.keymap.set({ "n", "x" }, "<leader>at", function()
  require("sidekick.cli").send({ msg = "{this}" })
end, { desc = "Send This" })
vim.keymap.set("n", "<leader>af", function()
  require("sidekick.cli").send({ msg = "{file}" })
end, { desc = "Send File" })
vim.keymap.set("x", "<leader>av", function()
  require("sidekick.cli").send({ msg = "{selection}" })
end, { desc = "Send Visual Selection" })
vim.keymap.set({ "n", "x" }, "<leader>ap", function()
  require("sidekick.cli").prompt()
end, { desc = "Sidekick Select Prompt" })
