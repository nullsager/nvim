-- 通用快捷键（与插件无关）
-- 插件相关的快捷键放在 lua/plugins/ 下对应的模块中。

-- ---------------------------------------------------------
-- 模式切换与窗口操作
-- ---------------------------------------------------------
vim.keymap.set("i", "jk", "<Esc>", { desc = "Escape insert mode" })
vim.keymap.set("t", "jk", "<C-\\><C-n>", { desc = "Escape terminal mode" })
vim.keymap.set({ "i", "n", "t" }, "<C-q>", "<cmd>bd!<CR>", { desc = "Force delete buffer" })

-- 清除搜索高亮（搜索设置见 options.lua）
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- 窗口间移动光标（替代默认的 <C-w>hjkl）
-- 终端模式下同样生效：<Cmd> 形式直接切换窗口，无需先退出终端模式
vim.keymap.set({ "n", "t" }, "<C-h>", "<Cmd>wincmd h<CR>", { desc = "Move to left window" })
vim.keymap.set({ "n", "t" }, "<C-j>", "<Cmd>wincmd j<CR>", { desc = "Move to lower window" })
vim.keymap.set({ "n", "t" }, "<C-k>", "<Cmd>wincmd k<CR>", { desc = "Move to upper window" })
vim.keymap.set({ "n", "t" }, "<C-l>", "<Cmd>wincmd l<CR>", { desc = "Move to right window" })

-- 调整窗口大小
vim.keymap.set({ "i", "n", "t" }, "<C-Up>", "<cmd>resize +3<CR>", { desc = "Window height +3" })
vim.keymap.set({ "i", "n", "t" }, "<C-Down>", "<cmd>resize -3<CR>", { desc = "Window height -3" })
vim.keymap.set({ "i", "n", "t" }, "<C-Left>", "<cmd>vertical resize -3<CR>", { desc = "Window width -3" })
vim.keymap.set({ "i", "n", "t" }, "<C-Right>", "<cmd>vertical resize +3<CR>", { desc = "Window width +3" })

-- ---------------------------------------------------------
-- 代码格式化
-- ---------------------------------------------------------

-- filetype → 格式化命令（首个单词必须是可执行文件名）
local formatters = {
  c = "clang-format",
  cpp = "clang-format",
  python = "ruff format -",
}

local function smart_format()
  local cmd = formatters[vim.bo.filetype]
  if not cmd then
    vim.notify("No formatter configured for " .. vim.bo.filetype, vim.log.levels.WARN)
    return
  end

  -- 格式化工具不存在时直接返回，避免 %! 把 shell 错误信息写进 buffer
  local exe = vim.split(cmd, " ", { plain = true })[1]
  if vim.fn.executable(exe) == 0 then
    vim.notify("Formatter not installed: " .. exe, vim.log.levels.WARN)
    return
  end

  local view = vim.fn.winsaveview()
  vim.cmd("%!" .. cmd)
  -- 命令执行失败时 buffer 已被替换成错误输出，撤销恢复原内容
  if vim.v.shell_error ~= 0 then
    vim.cmd("undo")
    vim.notify("Format failed: " .. cmd, vim.log.levels.ERROR)
  end
  vim.fn.winrestview(view)
end

vim.keymap.set("n", "<leader>cf", smart_format, { noremap = true, silent = true, desc = "code format" })

-- ---------------------------------------------------------
-- 折叠
-- ---------------------------------------------------------
vim.keymap.set("n", "<leader>zM", "zM", {
  remap = true,
  desc = "Close all folds",
})

vim.keymap.set("n", "<leader>zR", "zR", {
  remap = true,
  desc = "Open all folds",
})

-- ---------------------------------------------------------
-- netrw 文件管理器
-- ---------------------------------------------------------
vim.keymap.set("n", "<leader>e", "<Cmd>Lexplore<CR>", { noremap = true, silent = true, desc = "Toggle Netrw" })

-- ---------------------------------------------------------
-- 折行（wrap）时按屏幕行上下移动
-- ---------------------------------------------------------
-- 不带 count 时用 gj/gk（视觉行），带 count 时保持 j/k（真实行），
-- 这样 relativenumber 的 5j / 3k 之类跳转依然按行号计算。
vim.keymap.set({ "n", "x" }, "j", function()
  return vim.v.count == 0 and "gj" or "j"
end, { expr = true, desc = "Down by display line" })

vim.keymap.set({ "n", "x" }, "k", function()
  return vim.v.count == 0 and "gk" or "k"
end, { expr = true, desc = "Up by display line" })

-- 行首/行尾也跟随屏幕行
vim.keymap.set({ "n", "x" }, "<Down>", "gj", { desc = "Down by display line" })
vim.keymap.set({ "n", "x" }, "<Up>", "gk", { desc = "Up by display line" })
