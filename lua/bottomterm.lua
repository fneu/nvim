-- Toggleable bottom terminal. Behaves like sidekick's terminal but pinned to
-- the bottom of the screen: dismissing it only closes the window, so the
-- buffer and its running shell survive and reappear on the next toggle.
local M = { buf = nil, win = nil, height = 15 }

-- Interactive shell for the terminal. On Windows launch PowerShell explicitly
-- with -NoLogo (the global 'shell' is also PowerShell now, but this keeps the
-- banner suppressed and the choice self-documented). Prefer pwsh (PowerShell 7,
-- faster) and fall back to the built-in powershell.exe. The user profile still
-- loads so aliases and functions are available.
local function shell_cmd()
  if vim.fn.has("win32") == 1 then
    local exe = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell"
    return { exe, "-NoLogo" }
  end
  return { vim.o.shell }
end

local function job_alive()
  local buf = M.buf
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return false
  end
  local job = vim.b[buf].terminal_job_id
  return job ~= nil and vim.fn.jobwait({ job }, 0)[1] == -1
end

function M.toggle()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    -- Hide only: keep the buffer + job so state is preserved.
    vim.api.nvim_win_close(M.win, false)
    M.win = nil
    return
  end

  vim.cmd("botright " .. M.height .. "split")
  M.win = vim.api.nvim_get_current_win()
  vim.wo[M.win].number = false
  vim.wo[M.win].relativenumber = false
  vim.wo[M.win].signcolumn = "no"
  vim.wo[M.win].winfixheight = true

  if job_alive() then
    vim.api.nvim_win_set_buf(M.win, M.buf)
  else
    M.buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_win_set_buf(M.win, M.buf)
    vim.fn.jobstart(shell_cmd(), { term = true })
  end
  vim.cmd.startinsert()
end

function M.setup()
  vim.keymap.set({ "n", "t" }, "<C-t>", function()
    M.toggle()
  end, { desc = "Toggle bottom terminal" })
end

return M
