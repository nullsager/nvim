-- 底部终端：按 <C-\> 在窗口底部切换一个占屏 30% 的终端。
-- 终端 buffer 会被保留，再次打开时恢复到上一次的会话。

-- 记录终端的 buffer 和 window ID
local term_buf = nil
local term_win = nil

local function toggle_terminal()
  -- 如果窗口存在且有效，说明终端开着，直接隐藏它
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    -- 终端是唯一窗口时无法隐藏（E444），保持原状
    if #vim.api.nvim_list_wins() > 1 then
      vim.api.nvim_win_hide(term_win)
      term_win = nil
    end
  else
    -- 计算屏幕高度的 30%
    local height = math.floor(vim.o.lines * 0.3)
    -- 在最底部打开一个 split
    vim.cmd("botright " .. height .. "split")
    term_win = vim.api.nvim_get_current_win()
    -- 如果 buffer 存在且有效，直接加载该 buffer
    if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
      vim.api.nvim_win_set_buf(term_win, term_buf)
    else
      -- 否则新建一个终端
      vim.cmd("terminal")
      term_buf = vim.api.nvim_get_current_buf()
    end
    -- 优化终端显示：取消行号和标志列
    vim.wo[term_win].number = false
    vim.wo[term_win].relativenumber = false
    vim.wo[term_win].signcolumn = "no"
    -- 打开后自动进入插入模式
    vim.cmd("startinsert")
  end
end

vim.keymap.set({ "n", "t" }, "<C-\\>", toggle_terminal, { noremap = true, silent = true, desc = "Toggle bottom terminal" })
