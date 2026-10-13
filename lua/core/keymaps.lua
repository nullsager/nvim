-- 通用快捷键（与插件无关）
-- 插件相关的快捷键放在 lua/plugins/ 下对应的模块中。

-- ---------------------------------------------------------
-- 模式切换与窗口操作
-- ---------------------------------------------------------
vim.keymap.set("i", "jk", "<Esc>", { desc = "Escape insert mode" })
vim.keymap.set("t", "jk", "<C-\\><C-n>", { desc = "Escape terminal mode" })
-- <C-q> 关闭 buffer 见 plugins/mini.lua（mini.bufremove）

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
-- 交给支持格式化的 LSP：Python 用 ruff server，C/C++ 用 clangd（效果同 clang-format）。
-- LSP 只修改有变化的部分，不会像 %! 那样整体替换 buffer、丢失 mark 和折叠。
-- ruff 的行宽等设置见 plugins/lsp.lua。
local function lsp_format()
  local clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/formatting" })
  if #clients == 0 then
    vim.notify("No LSP formatter for " .. vim.bo.filetype, vim.log.levels.WARN)
    return
  end
  vim.lsp.buf.format({ timeout_ms = 3000 })
end

vim.keymap.set("n", "<leader>cf", lsp_format, { silent = true, desc = "code format" })

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

-- 文件管理器 <leader>e 见 plugins/mini.lua（mini.files）

-- ---------------------------------------------------------
-- 折行（wrap）显示开关
-- ---------------------------------------------------------
-- wrap：超长行折行完整显示；nowrap：超出屏幕的部分隐藏，光标过去时横向滚动
-- 只对当前窗口生效（wrap 是窗口局部选项）
vim.keymap.set("n", "<leader>uw", function()
  vim.wo.wrap = not vim.wo.wrap
  vim.notify(vim.wo.wrap and "wrap：超长行折行显示" or "nowrap：超长行截断隐藏")
end, { desc = "Toggle line wrap" })

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

-- ---------------------------------------------------------
-- 粘贴到下一行 / 上一行
-- ---------------------------------------------------------
-- 不管寄存器里是整行还是行内片段，都作为新行放到当前行下方 / 上方，
-- 光标跳到粘贴内容的首行首个非空字符。支持 count（3]p）和寄存器（"a]p）。
-- 覆盖了内置的 ]p / [p（按当前行缩进调整后粘贴）。
local function put_linewise(above)
  return function()
    local lines = vim.fn.getreg(vim.v.register, 1, true)
    if #lines == 0 then
      return
    end
    local block = {}
    for _ = 1, vim.v.count1 do
      vim.list_extend(block, lines)
    end
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local at = above and row - 1 or row
    vim.api.nvim_buf_set_lines(0, at, at, false, block)
    vim.api.nvim_win_set_cursor(0, { at + 1, 0 })
    vim.cmd("normal! ^")
  end
end

vim.keymap.set("n", "]p", put_linewise(false), { desc = "Paste on next line" })
vim.keymap.set("n", "[p", put_linewise(true), { desc = "Paste on previous line" })
