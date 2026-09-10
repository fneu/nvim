-- Powerline-style statusline (design carried over from the old .vimrc), themed
-- with luna's palette. Solves the "long branch overrides filename" problem:
--   * the branch is capped (truncated at the END, so its start stays visible),
--     so it can never dominate the line;
--   * the file path keeps the filename intact — middle directories are
--     compacted to their first letter (pathshorten), and any remaining overflow
--     is eaten from the LEFT of the path via `%<`, protecting the filename.
-- Filetype and expandtab/shiftwidth are intentionally dropped.

local M = {}

local SEP_R = "" -- powerline right-facing separator (U+E0B0)
local SEP_L = "" -- powerline left-facing separator (U+E0B2)
local BRANCH = "" -- branch glyph (U+E0A0)

-- Define the segment highlight groups from luna's palette. Reapplied on
-- ColorScheme so a theme switch doesn't wipe them.
function M.setup_highlights()
  local ok, p = pcall(require, "luna.palette")
  if not ok then
    return
  end
  local function hl(name, fg, bg, opts)
    opts = opts or {}
    opts.fg, opts.bg = fg, bg
    vim.api.nvim_set_hl(0, name, opts)
  end
  hl("StBuf", p.bg, p.func, { bold = true }) -- buffer-number chip
  hl("StBranch", p.grey_light, p.surface) -- branch segment
  hl("StFile", p.fg, p.bg_alt) -- filename body
  hl("StFlag", p.keyword, p.bg_alt, { bold = true }) -- modified/readonly flags
  hl("StFill", p.fg, p.bg_alt) -- middle stretch
  hl("StRight", p.bg, p.func, { bold = true }) -- position chip
  -- separators: fg = colour of the segment the arrow "belongs" to
  hl("StSepBufBranch", p.func, p.surface) -- buf -> branch
  hl("StSepBufFile", p.func, p.bg_alt) -- buf -> file (no branch)
  hl("StSepBranchFile", p.surface, p.bg_alt) -- branch -> file
  hl("StSepRight", p.func, p.bg_alt) -- file -> position chip
  hl("StInactive", p.comment, p.bg_alt) -- whole line when window inactive
end

local function esc(s)
  return (s:gsub("%%", "%%%%"))
end

local function win_width()
  local win = vim.g.statusline_winid
  if win and win ~= 0 and vim.api.nvim_win_is_valid(win) then
    return vim.api.nvim_win_get_width(win)
  end
  return vim.o.columns
end

-- Branch, capped to a share of the window width and truncated at the end so the
-- start (ticket id / prefix) stays readable.
local function branch(width)
  local b = vim.b.gitsigns_head
  if not b or b == "" then
    return nil
  end
  local cap = math.max(12, math.min(40, math.floor(width * 0.25)))
  if vim.fn.strchars(b) > cap then
    b = vim.fn.strcharpart(b, 0, cap - 1) .. "…"
  end
  return b
end

-- Path relative to cwd, with the directory compacted to first letters and the
-- filename kept whole.
local function path()
  local bt = vim.bo.buftype
  if bt ~= "" then
    local t = vim.fn.expand("%:t")
    return t ~= "" and t or ("[" .. bt .. "]")
  end
  local full = vim.fn.expand("%:.")
  if full == "" then
    return "[No Name]"
  end
  local tail = vim.fn.fnamemodify(full, ":t")
  local head = vim.fn.fnamemodify(full, ":h")
  if head == "." or head == "" then
    return tail
  end
  return vim.fn.pathshorten(head) .. "/" .. tail
end

function M.active()
  local width = win_width()
  local br = branch(width)
  local out = { "%#StBuf# %n " }
  if br then
    out[#out + 1] = "%#StSepBufBranch#" .. SEP_R
    out[#out + 1] = "%#StBranch# " .. BRANCH .. " " .. esc(br) .. " "
    out[#out + 1] = "%#StSepBranchFile#" .. SEP_R
  else
    out[#out + 1] = "%#StSepBufFile#" .. SEP_R
  end
  -- `%<` marks where truncation starts: the directory prefix is eaten first.
  out[#out + 1] = "%#StFile# %<" .. esc(path())
  out[#out + 1] = "%#StFlag#%{&modified?'  +':''}%{&readonly?'  ':''}"
  out[#out + 1] = "%#StFill#%="
  out[#out + 1] = "%#StSepRight#" .. SEP_L
  out[#out + 1] = "%#StRight# %l:%c  %P "
  return table.concat(out)
end

function M.inactive()
  local br = branch(win_width())
  local out = { "%#StInactive# %n  " }
  if br then
    out[#out + 1] = esc(br) .. "  "
  end
  out[#out + 1] = "%<" .. esc(path())
  out[#out + 1] = "%{&modified?'  +':''}%="
  out[#out + 1] = " %l:%c  %P "
  return table.concat(out)
end

function M.render()
  if vim.g.statusline_winid == vim.api.nvim_get_current_win() then
    return M.active()
  end
  return M.inactive()
end

function M.setup()
  M.setup_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("statusline_hl", { clear = true }),
    callback = M.setup_highlights,
  })
  vim.o.laststatus = 2
  vim.o.statusline = "%!v:lua.require'statusline'.render()"
end

return M
