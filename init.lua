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

-- Cursor: block in normal, vertical bar in insert *and* terminal mode. The
-- default omits `t`, so terminal mode would otherwise inherit the block.
vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve-t:ver25,r-cr-o:hor20"

-- Windows: use PowerShell for :terminal, :! and system() instead of the
-- cmd.exe default. This is safe despite the config's heavy fzf-lua use: on
-- Windows fzf-lua hardcodes cmd.exe for its own process spawning *and* its
-- shell escaping, ignoring 'shell' entirely. Settings follow
-- `:help shell-powershell`. Prefers pwsh (PowerShell 7) and falls back to the
-- built-in powershell.exe.
if vim.fn.has("win32") == 1 then
  vim.o.shell = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell"
  vim.o.shellcmdflag = table.concat({
    "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy RemoteSigned -Command",
    "[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;",
    "$PSDefaultParameterValues['Out-File:Encoding']='utf8';",
  }, " ")
  vim.o.shellredir = '2>&1 | %%{ "$_" } | Out-File %s; exit $LastExitCode'
  vim.o.shellpipe = '2>&1 | %%{ "$_" } | Tee-Object %s; exit $LastExitCode'
  vim.o.shellquote = ""
  vim.o.shellxquote = ""
end


vim.pack.add({
  "https://github.com/WTFox/luna.nvim",
  "https://github.com/zbirenbaum/copilot.lua",
  "https://github.com/folke/sidekick.nvim",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
  "https://github.com/nvim-tree/nvim-web-devicons",
  "https://github.com/folke/which-key.nvim",
  "https://github.com/windwp/nvim-autopairs",
  "https://github.com/folke/todo-comments.nvim",
  "https://github.com/j-hui/fidget.nvim",
  {
    src = "https://github.com/Saghen/blink.cmp",
    version = vim.version.range("1"),
  },
  "https://github.com/rafamadriz/friendly-snippets",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/sindrets/diffview.nvim",
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/kylechui/nvim-surround",
  "https://github.com/tpope/vim-eunuch",
  "https://github.com/tpope/vim-fugitive",
  "https://github.com/barrettruth/canola.nvim", -- oil.nvim fork with fixes (provides the `oil` module)
  -- Tool management (LSP servers, formatters, debuggers)
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
  -- C# language server (handles Roslyn's non-standard solution/notification protocol)
  "https://github.com/seblyng/roslyn.nvim",
  -- Formatting
  "https://github.com/stevearc/conform.nvim",
  -- Debugging
  "https://github.com/mfussenegger/nvim-dap",
  "https://github.com/nvim-neotest/nvim-nio",
  "https://github.com/rcarriga/nvim-dap-ui",
  "https://github.com/theHamsta/nvim-dap-virtual-text",
  "https://github.com/mfussenegger/nvim-dap-python",
  -- Testing
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-neotest/neotest",
  "https://github.com/nvim-neotest/neotest-python",
  "https://github.com/Issafalcon/neotest-dotnet",
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

-- Defer copilot until the first insert (its own README recommends
-- `event = "InsertEnter"`). On Windows copilot.lua re-verifies its bundled
-- language-server's NTFS ACLs on every launch by spawning two PowerShell
-- processes; loading it lazily keeps that cost off the cold-start path.
vim.api.nvim_create_autocmd("InsertEnter", {
  once = true,
  desc = "Lazy-load copilot.lua on first insert",
  callback = function()
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
  end,
})
require("sidekick").setup()
require("nvim-web-devicons").setup()
require("nvim-surround").setup()
-- which-key: popup that shows follow-up keys after a prefix. Groups below just
-- label the leader prefixes; individual keys come from each mapping's `desc`.
local wk = require("which-key")
wk.setup({ preset = "modern", delay = 800 })
wk.add({
  { "<leader>a", group = "AI / Sidekick" },
  { "<leader>g", group = "Git" },
  { "<leader>t", group = "Test" },
  { "<leader>d", group = "Debug" },
})
require("luna").setup()
vim.cmd.colorscheme("luna")
require("statusline").setup()
require("nvim-autopairs").setup({})
require("fidget").setup({})
local todo = require("todo-comments")
todo.setup({})
vim.keymap.set("n", "]t", function()
  todo.jump_next()
end, { desc = "Next todo comment" })
vim.keymap.set("n", "[t", function()
  todo.jump_prev()
end, { desc = "Previous todo comment" })
require("bottomterm").setup()
require("oil").setup({
  keymaps = {
    ["`"] = false,
    ["gc"] = "actions.cd",
  },
})
require("diffview").setup()
require("fzf-lua").setup({
  keymap = {
    fzf = {
      -- Send *all* results to the quickfix list in one keystroke (works for
      -- every picker, including the LSP definition/reference/implementation
      -- pickers). Cycle the entries afterwards with :cnext / :cprev (]q / [q).
      -- (`alt-q` still sends only the selected entries; `alt-a` toggles all.)
      ["ctrl-q"] = "select-all+accept",
    },
  },
  -- Workaround for an upstream fzf-lua bug: the branches/worktrees line
  -- highlighters reference the global `FzfLua`, which is undefined in the
  -- `-u NONE` multiprocess child, so the transform errors, yields no lines,
  -- and the picker closes instantly. Running the transform in-process (where
  -- the `FzfLua` global exists) avoids it.
  git = {
    branches = { multiprocess = false },
    worktrees = { multiprocess = false },
  },
})
-- Route vim.ui.select through fzf-lua so the native code-action picker (gra)
-- and any other ui.select prompt use fzf's fuzzy UI.
require("fzf-lua").register_ui_select()
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
  signature = {
    enabled = true,
    window = { border = "rounded" },
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

-- Language tooling: mason-managed servers/formatters/debuggers, native LSP,
-- formatting, debugging, and test running. Order matters: mason first so its
-- bin dir is on PATH before the LSP/formatters resolve their executables.
require("tools").setup()
require("lsp").setup()
require("formatting").setup()

-- nvim-dap and neotest are only useful once you're editing Python or C#, and
-- they're the heaviest part of startup. Defer their setup to the first such
-- buffer (runs once). This also covers `nvim foo.py` since FileType fires
-- after this autocmd is registered.
do
  local loaded = false
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "python", "cs" },
    callback = function()
      if loaded then
        return
      end
      loaded = true
      require("debugging").setup()
      require("testing").setup()
    end,
    desc = "Lazy-load DAP + neotest on first Python/C# buffer",
  })
end

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
vim.keymap.set("n", "<leader>gg", "<Cmd>Git<CR>", { desc = "Fugitive status" })
vim.keymap.set("n", "<leader>ga", "<Cmd>Gwrite<CR>", { desc = "Git stage current file" })
vim.keymap.set("n", "<leader>gd", "<Cmd>DiffviewOpen<CR>", { desc = "Review Git changes" })
vim.keymap.set("n", "<leader>gh", "<Cmd>DiffviewFileHistory %<CR>", { desc = "Git history for file" })
vim.keymap.set("n", "<leader>gb", "<Cmd>Gitsigns blame_line<CR>", { desc = "Git blame line" })
vim.keymap.set("n", "<leader>gc", function()
  require("fzf-lua").git_branches()
end, { desc = "Git branches (switch/checkout)" })
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
