-- Powerline-style statusline (design carried over from the old .vimrc), themed
-- with luna's palette. Solves the "long branch overrides filename" problem:
--   * the branch is capped (truncated at the END, so its start stays visible),
--     so it can never dominate the line;
--   * the file path keeps the filename intact — middle directories are
--     compacted to their first letter (pathshorten), and any remaining overflow
--     is eaten from the LEFT of the path via `%<`, protecting the filename.
-- Filetype and expandtab/shiftwidth are intentionally dropped.

local M = {}

-- Nerd-font glyphs, written as raw UTF-8 byte escapes so the literal characters
-- can't be silently stripped from the source file by an editor/transfer.
local SEP_R = "\238\130\176" -- powerline right-facing separator (U+E0B0)
local SEP_L = "\238\130\178" -- powerline left-facing separator (U+E0B2)
local THIN_R = "\238\130\177" -- thin right-facing chevron (U+E0B1)
local BRANCH = "\238\130\160" -- branch glyph (U+E0A0)
local LOCK = "\238\130\162" -- padlock glyph (U+E0A2)

-- Accent colour per buffer kind, applied to the outer chips + their arrows:
--   ""  -> normal buffer (blue), "G" -> terminal (green), "R" -> readonly (red)
local function accent_suffix(buf)
  if vim.bo[buf].buftype == "terminal" then
    return "G"
  end
  if vim.bo[buf].readonly then
    return "R"
  end
  return ""
end

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
  -- Constant middle segments.
  hl("StBranch", p.grey_light, p.surface) -- branch segment
  hl("StFile", p.fg, p.bg_alt) -- filename body
  hl("StFill", p.fg, p.bg_alt) -- middle stretch
  hl("StSepBranchFile", p.surface, p.bg_alt) -- branch -> file
  -- Modified/readonly flag chip on the right: grey text on orange.
  hl("StFlagChip", p.warning, p.surface, { bold = true })
  hl("StSepFlagFill", p.surface, p.bg_alt) -- fill -> flag chip
  -- Accent-coloured chips + their separators, one set per buffer kind.
  -- Separator fg = colour of the chip the arrow "belongs" to.
  local accents = { [""] = p.func, G = p.ok, R = p.error }
  for sfx, accent in pairs(accents) do
    hl("StBuf" .. sfx, p.bg, accent, { bold = true }) -- buffer-number chip
    hl("StRight" .. sfx, p.bg, accent, { bold = true }) -- position chip
    hl("StSepBufBranch" .. sfx, accent, p.surface) -- buf -> branch
    hl("StSepBufFile" .. sfx, accent, p.bg_alt) -- buf -> file (no branch)
    hl("StSepRight" .. sfx, accent, p.bg_alt) -- file -> position chip
    hl("StSepFlagRight" .. sfx, accent, p.surface) -- flag chip -> position chip
  end

  -- Inactive window: same segment structure, but greyscale instead of the blue
  -- accent. The buffer chip and branch share one grey (surface) and are divided
  -- by a thin chevron rather than a hard colour transition; the file path drops
  -- to a darker grey so the branch stays visually distinct from it.
  hl("StBufI", p.grey_light, p.surface) -- buffer-number chip (branch grey)
  hl("StChevI", p.grey, p.surface) -- thin chevron: buf -> branch (same grey)
  hl("StBranchI", p.grey_light, p.surface) -- branch segment
  hl("StRightI", p.grey_light, p.surface) -- position chip (branch grey)
  hl("StFileI", p.grey_light, p.bg_alt) -- filename body
  hl("StFillI", p.grey, p.bg_alt) -- middle stretch
  hl("StFlagChipI", p.grey_light, p.border) -- muted flag chip
  hl("StSepFlagFillI", p.border, p.bg_alt) -- fill -> flag chip
  hl("StSepFlagRightI", p.surface, p.border) -- flag chip -> position chip
  hl("StSepBufFileI", p.surface, p.bg_alt) -- buf -> file (no branch)
  hl("StSepBranchFileI", p.surface, p.bg_alt) -- branch -> file
  hl("StSepRightI", p.surface, p.bg_alt) -- file -> position chip
end

local function esc(s)
  return (s:gsub("%%", "%%%%"))
end

-- The window/buffer this statusline is being drawn for. With a global `%!`
-- statusline, Lua's `expand('%')`/`vim.bo`/`vim.b` still refer to the *actually
-- current* buffer, so inactive windows would otherwise all report the active
-- buffer. Resolve everything through `g:statusline_winid` instead.
local function ctx()
  local win = vim.g.statusline_winid
  if not win or win == 0 or not vim.api.nvim_win_is_valid(win) then
    win = vim.api.nvim_get_current_win()
  end
  return win, vim.api.nvim_win_get_buf(win)
end

local function win_width(win)
  if win and vim.api.nvim_win_is_valid(win) then
    return vim.api.nvim_win_get_width(win)
  end
  return vim.o.columns
end

-- Branch, capped to a share of the window width and truncated at the end so the
-- start (ticket id / prefix) stays readable.
local function branch(buf, width)
  local b = vim.b[buf].gitsigns_head
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
local function path(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  local bt = vim.bo[buf].buftype
  if bt ~= "" then
    local t = vim.fn.fnamemodify(name, ":t")
    return t ~= "" and t or ("[" .. bt .. "]")
  end
  if name == "" then
    return "[No Name]"
  end
  local full = vim.fn.fnamemodify(name, ":.")
  local tail = vim.fn.fnamemodify(full, ":t")
  local head = vim.fn.fnamemodify(full, ":h")
  if head == "." or head == "" then
    return tail
  end
  return vim.fn.pathshorten(head) .. "/" .. tail
end

local function flag_text(buf)
  local parts = {}
  if vim.bo[buf].modified then
    parts[#parts + 1] = "+"
  end
  if vim.bo[buf].readonly then
    parts[#parts + 1] = LOCK
  end
  return table.concat(parts, " ")
end

function M.active()
  local win, buf = ctx()
  local width = win_width(win)
  local sfx = accent_suffix(buf)
  local br = branch(buf, width)
  local out = { "%#StBuf" .. sfx .. "# %n " }
  if br then
    out[#out + 1] = "%#StSepBufBranch" .. sfx .. "#" .. SEP_R
    out[#out + 1] = "%#StBranch# " .. BRANCH .. " " .. esc(br) .. " "
    out[#out + 1] = "%#StSepBranchFile#" .. SEP_R
  else
    out[#out + 1] = "%#StSepBufFile" .. sfx .. "#" .. SEP_R
  end
  -- `%<` marks where truncation starts: the directory prefix is eaten first.
  out[#out + 1] = "%#StFile# %<" .. esc(path(buf))
  out[#out + 1] = "%#StFill#%="
  local fl = flag_text(buf)
  if fl ~= "" then
    out[#out + 1] = "%#StSepFlagFill#" .. SEP_L
    out[#out + 1] = "%#StFlagChip# " .. esc(fl) .. " "
    out[#out + 1] = "%#StSepFlagRight" .. sfx .. "#" .. SEP_L
  else
    out[#out + 1] = "%#StSepRight" .. sfx .. "#" .. SEP_L
  end
  out[#out + 1] = "%#StRight" .. sfx .. "# %l:%c  %P "
  return table.concat(out)
end

function M.inactive()
  local win, buf = ctx()
  local width = win_width(win)
  local br = branch(buf, width)
  local out = { "%#StBufI# %n " }
  if br then
    out[#out + 1] = "%#StChevI#" .. THIN_R .. " "
    out[#out + 1] = "%#StBranchI#" .. BRANCH .. " " .. esc(br) .. " "
    out[#out + 1] = "%#StSepBranchFileI#" .. SEP_R
  else
    out[#out + 1] = "%#StSepBufFileI#" .. SEP_R
  end
  out[#out + 1] = "%#StFileI# %<" .. esc(path(buf))
  out[#out + 1] = "%#StFillI#%="
  local fl = flag_text(buf)
  if fl ~= "" then
    out[#out + 1] = "%#StSepFlagFillI#" .. SEP_L
    out[#out + 1] = "%#StFlagChipI# " .. esc(fl) .. " "
    out[#out + 1] = "%#StSepFlagRightI#" .. SEP_L
  else
    out[#out + 1] = "%#StSepRightI#" .. SEP_L
  end
  out[#out + 1] = "%#StRightI# %l:%c  %P "
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
