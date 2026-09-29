-- Org mode：任务管理、议程（Agenda）、速记（Capture）
-- 与 Obsidian 分工：Markdown 笔记库放 ~/Documents/notes（知识沉淀），
-- Org 文件放 ~/Documents/org（任务 / 日程 / 待办），两者互不干扰。

local org_path = "/home/lc/Documents/org"

-- conceal 依赖按文件类型局部设置，避免影响代码文件：
--   org        隐藏链接语法，只显示描述
--   markdown / codecompanion  render-markdown 的渲染依赖 conceal
local conceal_group = vim.api.nvim_create_augroup("UserConceal", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = conceal_group,
  pattern = { "markdown", "org", "codecompanion" },
  callback = function()
    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = "nc"
  end,
})

-- 关闭 org 的自动折行，避免长标题/中英文混排在窗口边缘被拆成难看的多行。
vim.api.nvim_create_autocmd("FileType", {
  group = conceal_group,
  pattern = "org",
  callback = function()
    vim.opt_local.wrap = false
  end,
})

-- 首次使用前确保 Org 目录存在，避免 Agenda / Capture 报错
vim.fn.mkdir(org_path, "p")

require("orgmode").setup({
  -- Agenda 汇总此目录下所有 .org 文件中的任务
  org_agenda_files = org_path .. "/**/*",

  -- Capture（<leader>oc 快速记录）默认写入的文件
  org_default_notes_file = org_path .. "/refile.org",

  -- TODO 状态流：竖线 | 之前是"未完成"、之后是"完成"。
  -- 括号里是快速选择键：设了快速键后 cit 不再逐个循环，而是弹出菜单按字母直达，
  -- 状态多了也只需两次按键（ciT 仍是逐个后退）。
  --   NEXT      已排期、下一个动手做的
  --   HOLD      被打断 / 自己主动挂起（切走时钟前顺手标上，与 TODO 区分开）
  --   WAITING   卡在别人身上，等外部反馈
  --   CANCELLED 不做了（算"完成"侧，不再出现在待办列表里）
  org_todo_keywords = { "TODO(t)", "NEXT(n)", "HOLD(h)", "WAITING(w)", "|", "DONE(d)", "CANCELLED(c)" },

  -- 新状态词的配色，取值同状态栏的 Catppuccin Mocha 色板
  org_todo_keyword_faces = {
    NEXT = ":foreground #89b4fa :weight bold", -- blue
    HOLD = ":foreground #f9e2af :weight bold", -- yellow
    WAITING = ":foreground #fab387 :weight bold", -- peach
    CANCELLED = ":foreground #6c7086 :slant italic", -- overlay，灰掉
  },

  mappings = {
    org = {
      -- 插件默认用 <C-Space> 切换复选框，与 fcitx5 输入法切换键冲突；
      -- 改为 <leader>mb，与 Markdown 笔记中 Obsidian 的复选框切换键保持一致
      org_toggle_checkbox = "<leader>mb",
    },
  },
})

-- Orgmode 默认只给链接着色；加下划线，让隐藏后的描述仍然明显可点击。
local function underline_org_links()
  vim.api.nvim_set_hl(0, "@org.hyperlink.desc", { underline = true })
end
underline_org_links()
vim.api.nvim_create_autocmd("ColorScheme", { callback = underline_org_links })

-- clock in / out 之后立刻把状态栏的计时段刷出来（该段定义在 plugins/mini.lua）。
-- 插件的 orgmode.statusline() 内部有 300ms 防抖，事件刚触发时拿到的还是旧值，
-- 所以延迟一点再重画；不加这段的话，按完 <leader>oxi 若不碰键盘，
-- 状态栏最长要等 30 秒（mini.lua 里的定时器）才出现。
local org_events = require("orgmode.events")

local function refresh_clock_statusline()
  vim.defer_fn(function()
    vim.cmd.redrawstatus()
  end, 400)
end

org_events.listen(org_events.event.ClockedIn, refresh_clock_statusline)
org_events.listen(org_events.event.ClockedOut, refresh_clock_statusline)

-- 官方实验性 LSP：补全链接、标签、日期等（插件内置纯 Lua server，无需外部程序）。
-- 如不需要可删除本行。
vim.lsp.enable("org")

-- ---------------------------------------------------------
-- 快捷键说明
-- ---------------------------------------------------------
-- 本插件的快捷键绝大多数是 org buffer 局部映射（前缀 <leader>o），
-- 打开 .org 文件后按 g? 可查看插件内置的完整按键帮助。
--
-- 全局新增（与现有配置无冲突）：
--   <leader>oa   打开 Agenda 提示菜单
--   <leader>oc   打开 Capture 快速记录菜单
--
-- 任务状态与计时（org buffer 内）：
--   cit / ciT    切换 TODO 状态（cit 弹出快速选择菜单，按 t/n/h/w/d/c 直达）
--   <leader>oxi  clock in 开始计时；在别的任务上再按一次会自动停掉上一个
--   <leader>oxo  clock out 暂停（时长记入 :LOGBOOK:，下次 clock in 累加）
--   <leader>oxq  取消当前这段计时（不记账）
--   <leader>oxj  跳回正在计时的任务
--   计时进行中，状态栏右侧显示 󰅐 已用时长 / 任务名（见 plugins/mini.lua）
--
-- 注意：在 .org 文件内，以下 buffer 局部映射会覆盖同名全局映射
-- （离开 org buffer 后恢复正常）：
--   <leader>oo   org：打开光标处的链接 / 日期（全局：浏览 Obsidian 笔记库）
--   <leader>ot   org：修改标题标签 tags（全局：打开今天的 Obsidian 日记）
