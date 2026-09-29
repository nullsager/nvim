-- 编辑器基础选项
-- 本模块必须最先加载：leader 键需要在所有快捷键映射之前设置。

vim.g.mapleader = " "

-- ---------------------------------------------------------
-- 外观
-- ---------------------------------------------------------
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.cmd.colorscheme("catppuccin")
vim.o.winborder = "single"

-- ---------------------------------------------------------
-- 剪贴板与滚动
-- ---------------------------------------------------------
-- 本地使用 wl-copy/xclip；SSH 里的 Neovim 没有远程桌面剪贴板，改用
-- OSC 52 让终端把复制内容转发到本地系统剪贴板。
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  vim.g.clipboard = "osc52"
end
vim.opt.clipboard:append("unnamedplus")
vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 10

-- ---------------------------------------------------------
-- 缩进
-- ---------------------------------------------------------
vim.opt.tabstop = 2 -- tabwidth
vim.opt.shiftwidth = 2 -- indent width
vim.opt.softtabstop = 2 -- soft tab stop not tabs on tab/backspace
vim.opt.expandtab = true -- use spaces instead of tabs
vim.opt.smartindent = true -- smart auto-indent
vim.opt.autoindent = true -- copy indent from current line

-- ---------------------------------------------------------
-- 搜索
-- ---------------------------------------------------------
-- 搜索时忽略大小写；但搜索词里含大写字母时恢复区分（smartcase）
vim.opt.ignorecase = true
vim.opt.smartcase = true
-- 输入 :s 替换命令时实时预览效果（改为 "split" 会额外弹出屏幕外匹配的预览窗口）
vim.opt.inccommand = "nosplit"

-- ---------------------------------------------------------
-- 其他
-- ---------------------------------------------------------
vim.opt.undofile = true
vim.opt.splitbelow = true
vim.opt.splitright = true
-- CursorHold 事件与 swap 文件写入的触发间隔（默认 4000ms 偏慢）
vim.opt.updatetime = 250
-- 可视块编辑时允许光标越过行尾（改表格、对齐文本很好用）
vim.opt.virtualedit = "block"

-- ---------------------------------------------------------
-- netrw 内置文件管理器
-- ---------------------------------------------------------
-- 设置宽度占屏幕宽度的20%
vim.g.netrw_winsize = 20
-- 将显示样式设置为“树形目录” (类似主流文件树插件，按回车展开/收起)
vim.g.netrw_liststyle = 3
-- 隐藏顶部烦人的帮助信息 (按 I 键可以随时呼出/隐藏)
vim.g.netrw_banner = 0
-- 设为 4 意味着：在文件树中按回车打开文件时，在右侧的窗口中打开
vim.g.netrw_browse_split = 4
-- 当分割窗口时，新的窗口在右边
vim.g.netrw_altv = 1
