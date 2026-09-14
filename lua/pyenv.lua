-- Resolve the Python interpreter for a project so tooling (LSP, debugger)
-- loads that project's own libraries. Prefers an active virtualenv, then a
-- local .venv/venv (as created by `uv` or `python -m venv`), and finally the
-- global python. Shared servers/adapters live in mason, so no per-project
-- install is required.
local M = {}

local is_win = vim.fn.has("win32") == 1

function M.detect(root)
  root = root or vim.fn.getcwd()
  local venv = vim.env.VIRTUAL_ENV
  if venv and venv ~= "" then
    local p = is_win and (venv .. "\\Scripts\\python.exe") or (venv .. "/bin/python")
    if vim.uv.fs_stat(p) then
      return p
    end
  end
  for _, dir in ipairs({ ".venv", "venv" }) do
    local p = is_win and (root .. "\\" .. dir .. "\\Scripts\\python.exe")
      or (root .. "/" .. dir .. "/bin/python")
    if vim.uv.fs_stat(p) then
      return p
    end
  end
  return vim.fn.exepath("python")
end

return M
