-- Markdown note-taking helpers: clipboard-screenshot paste and timestamped
-- meeting sections. Screenshot capture is Windows-only (System.Windows.Forms).

-- Save the clipboard image next to the buffer under assets/ and return a
-- markdown image link, or nil if the clipboard holds no image.
local function paste_screenshot()
  local buf_dir = vim.fn.expand("%:p:h")
  if buf_dir == "" then
    buf_dir = vim.fn.getcwd()
  end
  local img_dir = buf_dir .. "\\assets"
  local name = "screenshot_" .. os.date("%Y%m%d_%H%M%S") .. ".png"
  local path = img_dir .. "\\" .. name

  local script = vim.fn.tempname() .. ".ps1"
  vim.fn.writefile({
    "Add-Type -AssemblyName System.Windows.Forms",
    "if (-not [System.Windows.Forms.Clipboard]::ContainsImage()) { exit 1 }",
    'New-Item -ItemType Directory -Force -Path "' .. img_dir .. '" | Out-Null',
    '[System.Windows.Forms.Clipboard]::GetImage().Save("' .. path .. '")',
  }, script)
  vim.fn.system({ "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script })
  local ok = vim.v.shell_error == 0
  vim.fn.delete(script)

  if not ok then
    vim.notify("No image in clipboard", vim.log.levels.WARN)
    return nil
  end
  return "![](assets/" .. name .. ")"
end

vim.keymap.set("n", "<leader>p", function()
  local link = paste_screenshot()
  if link then
    vim.api.nvim_put({ link }, "l", true, false)
  end
end, { buffer = true, desc = "Paste clipboard screenshot" })

vim.keymap.set("i", "<C-g>p", function()
  local link = paste_screenshot()
  if link then
    vim.api.nvim_put({ link }, "c", false, true)
  end
end, { buffer = true, desc = "Paste clipboard screenshot inline" })

-- Append a "## HH:MM " section at the end of the buffer and start typing.
vim.keymap.set("n", "<leader>h", function()
  local header = "## " .. os.date("%H:%M") .. " "
  vim.api.nvim_buf_set_lines(0, -1, -1, false, { "", header })
  local last = vim.api.nvim_buf_line_count(0)
  vim.api.nvim_win_set_cursor(0, { last, #header })
  vim.cmd.startinsert({ bang = true })
end, { buffer = true, desc = "Append timestamped section" })
