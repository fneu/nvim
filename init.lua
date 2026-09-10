vim.g.mapleader = " "

vim.keymap.set({ "n", "x", "o" }, "ö", "[", { remap = true, desc = "Use previous bracket mapping" })
vim.keymap.set({ "n", "x", "o" }, "ä", "]", { remap = true, desc = "Use next bracket mapping" })


-- Editor options
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.scrolloff = 3
vim.opt.sidescrolloff = 5

vim.opt.list = true
vim.opt.listchars = { tab = "→ ", nbsp = "␣", trail = "·", extends = "›", precedes = "‹" }
vim.opt.showbreak = "↪ "

vim.opt.updatetime = 400
vim.opt.showmode = false
vim.opt.clipboard = "unnamedplus"

-- Treesitter-based folding, folds open by default
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevelstart = 99

-- Extras carried over from .vimrc
vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.wildignore:append({ "*.o", "*.obj", ".git", "*.rbc", "*.pyc", "__pycache__" })
vim.opt.shortmess:append("c")
vim.opt.mouse = "a"
vim.opt.ttimeoutlen = 100


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

-- Treesitter (main branch): install parsers, enable highlighting and textobjects
require("nvim-treesitter").install({
  "python", "c_sharp", "lua", "vim", "vimdoc", "query",
  "markdown", "markdown_inline", "html", "css", "scss",
  "javascript", "typescript", "tsx", "json", "yaml", "toml", "xml",
  "diff", "git_config", "gitcommit", "gitignore",
  "bash", "haskell", "powershell", "dockerfile",
})

vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    pcall(vim.treesitter.start)
  end,
  desc = "Start Treesitter highlighting",
})

require("nvim-treesitter-textobjects").setup({
  select = {
    lookahead = true,
    selection_modes = {
      ["@parameter.outer"] = "v",
      ["@function.outer"] = "V",
      ["@class.outer"] = "V",
    },
    include_surrounding_whitespace = false,
  },
  move = {
    set_jumps = true,
  },
})

local ts_select = require("nvim-treesitter-textobjects.select").select_textobject
for lhs, obj in pairs({
  af = "@function.outer",
  ["if"] = "@function.inner",
  ac = "@class.outer",
  ic = "@class.inner",
  aa = "@parameter.outer",
  ia = "@parameter.inner",
}) do
  vim.keymap.set({ "x", "o" }, lhs, function()
    ts_select(obj, "textobjects")
  end, { desc = "Select " .. obj })
end

local ts_move = require("nvim-treesitter-textobjects.move")
vim.keymap.set({ "n", "x", "o" }, "]f", function()
  ts_move.goto_next_start("@function.outer", "textobjects")
end, { desc = "Next function start" })
vim.keymap.set({ "n", "x", "o" }, "[f", function()
  ts_move.goto_previous_start("@function.outer", "textobjects")
end, { desc = "Previous function start" })
vim.keymap.set({ "n", "x", "o" }, "]F", function()
  ts_move.goto_next_end("@function.outer", "textobjects")
end, { desc = "Next function end" })
vim.keymap.set({ "n", "x", "o" }, "[F", function()
  ts_move.goto_previous_end("@function.outer", "textobjects")
end, { desc = "Previous function end" })

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

-- Filetype-specific settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "make",
  callback = function()
    vim.opt_local.expandtab = false
  end,
  desc = "Use real tabs in Makefiles",
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "html", "json", "typescript", "css", "scss" },
  callback = function()
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
  desc = "Two-space indent for web/data filetypes",
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.colorcolumn = "99"
  end,
  desc = "Python column guide at 99",
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
vim.keymap.set("n", "<leader>as", function()
  require("sidekick.cli").select({ focus = true })
end, { desc = "Sidekick Switch CLI Session" })

-- Wiki: plain-markdown work notes (see lua/wiki.lua)
local wiki = require("wiki")
vim.keymap.set("n", "<leader>ww", wiki.daily, { desc = "Wiki: today's daily note" })
vim.keymap.set("n", "<leader>wi", wiki.index, { desc = "Wiki: open index" })
vim.keymap.set("n", "<leader>wn", wiki.new_note, { desc = "Wiki: new topic note" })
vim.keymap.set("n", "<leader>wf", wiki.find, { desc = "Wiki: find files" })
vim.keymap.set("n", "<leader>w/", wiki.grep, { desc = "Wiki: grep contents" })
vim.keymap.set("n", "<leader>wt", wiki.todos, { desc = "Wiki: open todos" })
vim.keymap.set("n", "<leader>ws", wiki.tags, { desc = "Wiki: search by tag" })
vim.keymap.set("n", "<leader>wd", function()
  require("oil").open(wiki.root())
end, { desc = "Wiki: browse root (Oil)" })
vim.keymap.set("n", "<leader>aw", wiki.cli, { desc = "Wiki: open Copilot CLI rooted at wiki" })

vim.keymap.set("i", "<C-g>d", function()
  return os.date("%Y-%m-%d")
end, { expr = true, desc = "Insert date" })
vim.keymap.set("i", "<C-g>t", function()
  return os.date("%H:%M")
end, { expr = true, desc = "Insert time" })
