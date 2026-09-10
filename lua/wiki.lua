-- A plain-markdown work wiki: a daily-note capture inbox plus organized topic
-- notes, all searchable with fzf-lua. Root is $WIKI_ROOT (falls back to the
-- OneDrive folder).

local M = {}

function M.root()
  local r = vim.env.WIKI_ROOT or vim.fn.expand("~/OneDrive - Nordex SE/Wiki")
  return vim.fs.normalize(r)
end

-- Open a wiki file, creating parent dirs and seeding a title for new files.
local function open(path, title)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local is_new = vim.fn.filereadable(path) == 0
  vim.cmd.edit(vim.fn.fnameescape(path))
  if is_new and title then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "# " .. title, "" })
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
  end
end

-- Today's daily note: the zero-friction capture inbox.
function M.daily()
  local date = os.date("%Y-%m-%d")
  open(M.root() .. "/daily/" .. date .. ".md", date)
end

function M.index()
  open(M.root() .. "/index.md", "Index")
end

-- Create/open a durable topic note under notes/.
function M.new_note()
  vim.ui.input({ prompt = "New note name: " }, function(name)
    if not name or name == "" then
      return
    end
    local slug = name:gsub("%s+", "-"):gsub("[^%w%-_]", ""):lower()
    if slug == "" then
      return
    end
    open(M.root() .. "/notes/" .. slug .. ".md", name)
  end)
end

function M.find()
  require("fzf-lua").files({ cwd = M.root() })
end

function M.grep()
  require("fzf-lua").live_grep({ cwd = M.root() })
end

-- List every open todo ("- [ ]") across the wiki.
function M.todos()
  require("fzf-lua").grep({ cwd = M.root(), search = "- \\[ \\]", no_esc = true })
end

-- Open (or create) a Copilot CLI session rooted at the wiki, so its AI sees
-- your notes rather than the current project. Sidekick keys sessions by
-- (tool, cwd), so this coexists with any project-dir session; reuse the
-- existing wiki session if one is already running.
function M.cli()
  local root = M.root()
  local Session = require("sidekick.cli.session")
  local State = require("sidekick.cli.state")
  local target = Session.sid({ tool = "copilot", cwd = root })
  for _, state in ipairs(State.get({ name = "copilot" })) do
    if state.session and state.session.sid == target then
      State.attach(state, { show = true, focus = true })
      return
    end
  end
  local session = Session.new({ tool = "copilot", cwd = root })
  State.attach(State.get_state(session), { show = true, focus = true })
end

-- Grep for a #tag across the wiki.
function M.tags()
  vim.ui.input({ prompt = "Tag (without #): " }, function(tag)
    if not tag or tag == "" then
      return
    end
    require("fzf-lua").grep({ cwd = M.root(), search = "#" .. tag })
  end)
end

return M
