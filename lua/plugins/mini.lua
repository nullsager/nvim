-- mini.nvim 模块：编辑增强与界面
-- mini.nvim 是单个插件包含几十个独立模块，这里按需 setup 启用。

require("mini.pairs").setup({})
require("mini.surround").setup({})

-- Python 三引号：mini.pairs 只认单字符配对，输入 ''' 会变成 ''''，回车后还残留一个引号。
-- 这里在 Python buffer 接管 ' 和 "：敲第三个引号时直接补成 '''|'''，其余情况交还 mini.pairs；
-- 同时把引号对注册给 mini.pairs 的 <CR>，在 '''|''' 中间回车会展开成三行。
-- 与 mini.pairs 默认一致：' 前面是字母时不配对（don't），反斜杠转义时都不配对
local quote_neigh = { ["'"] = "^[^%a\\]", ['"'] = "^[^\\]" }

local function triple_quote(q)
  local neigh = quote_neigh[q]
  local qqq = q:rep(3)
  local left = vim.keycode("<C-g>U<Left>")
  return function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local before, after = line:sub(1, col), line:sub(col + 1)
    local closing = #after:match("^" .. q .. "*")
    if before:sub(-2) ~= q:rep(2) or before:sub(-3) == qqq or closing > 3 then
      return MiniPairs.closeopen(q .. q, neigh)
    end
    -- 光标前的三引号数为奇数，说明正处在三引号字符串里，这次是在敲结尾引号
    local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, row - 1, false), "\n") .. before:sub(1, -3)
    if select(2, text:gsub(qqq, "")) % 2 == 1 then
      return MiniPairs.closeopen(q .. q, neigh)
    end
    -- 补齐开头的第三个引号 + 结尾引号（mini.pairs 可能已经自动补了一个），光标停在中间
    return q .. q:rep(3 - closing) .. left:rep(3 - closing)
  end
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("UserPythonTripleQuote", { clear = true }),
  pattern = "python",
  desc = "Python 三引号自动配对",
  callback = function(ev)
    for _, q in ipairs({ "'", '"' }) do
      MiniPairs.map_buf(ev.buf, "i", q, {
        action = "closeopen",
        pair = q .. q,
        neigh_pattern = quote_neigh[q],
        register = { cr = true },
      })
      vim.keymap.set("i", q, triple_quote(q), { buffer = ev.buf, expr = true, replace_keycodes = false })
    end
  end,
})

-- 注释：gc + 动作（gcap 注释整段），gcc 注释当前行。
-- 内置 Treesitter 注入检测：Markdown 代码块里能自动用块内语言的注释符。
require("mini.comment").setup({})

-- 对齐：可视模式选中后按 ga 进入交互对齐。
-- 维护 Markdown 管道表格：选中表格行，ga 后输入 | 作为分隔符即可重新对齐。
require("mini.align").setup({})

-- 关闭 buffer 但保留窗口布局（:bd 在窗口没有别的 buffer 可显示时会把窗口一起关掉）。
-- 有未保存修改时先询问，而不是像 :bd! 那样直接丢弃。
require("mini.bufremove").setup({})
vim.keymap.set({ "i", "n", "t" }, "<C-q>", function()
  MiniBufremove.delete()
end, { desc = "Delete buffer" })

-- 文件管理器：分栏浏览，像编辑文本一样增删改名（改完按 = 同步到磁盘）。
-- 打开时定位到当前文件；l / h 进入 / 返回目录，q 关闭。
require("mini.files").setup({})
vim.keymap.set("n", "<leader>e", function()
  local file = vim.api.nvim_buf_get_name(0)
  MiniFiles.open(vim.uv.fs_stat(file) and file or nil)
end, { desc = "File explorer" })

-- Git：mini.git 提供 :Git 命令和状态栏分支信息；
-- mini.diff 在行号处标出改动，gh / gH + 动作暂存 / 撤销改动（ghgh 作用于当前 hunk），
-- [h / ]h 在改动间跳转，<leader>ud 切换叠加显示具体差异。
require("mini.git").setup({})
require("mini.diff").setup({})
vim.keymap.set("n", "<leader>ud", function()
  MiniDiff.toggle_overlay(0)
end, { desc = "Toggle diff overlay" })

-- 状态栏：模式（彩色底）/ git 分支与改动统计 / 诊断计数 / 文件名 / filetype / 行列位置。
-- 配色取自主题同款 Catppuccin Mocha 色板。
local statusline = require("mini.statusline")

statusline.setup({
  use_icons = true,
})

-- 右侧文件信息只保留 filetype，去掉 unix / utf-8 等噪音
statusline.section_fileinfo = function()
  local ft = vim.bo.filetype
  return ft == "" and "" or " " .. ft .. " "
end

-- 位置段：行:列（固定宽度，右对齐）
statusline.section_location = function()
  return "%2l:%-2v"
end

-- Org clock 段：正在计时的任务，没有计时则为空串（该段自动消失）。
-- _G.orgmode 由 orgmode 插件在加载时定义，其 statusline() 内部有 300ms 防抖，
-- 未初始化时返回空串，可以安全地在每次重画时调用。
-- 原始格式为 "(Org) [已用/预估] (标题)"，这里改成 "󰅐 已用/预估 标题"。
local function section_org_clock()
  if not _G.orgmode then
    return ""
  end
  local clock = _G.orgmode.statusline()
  local total, title = clock:match("^%(Org%) %[(.-)%] %((.*)%)$")
  if not total then
    return ""
  end
  -- 窄窗口只留时长，宽窗口补上任务名（过长则截断，避免把文件名挤出状态栏）
  if statusline.is_truncated(100) then
    return "󰅐 " .. total
  end
  if vim.fn.strdisplaywidth(title) > 24 then
    title = vim.fn.strcharpart(title, 0, 12) .. "…"
  end
  return "󰅐 " .. total .. " " .. title
end

-- 计时数字每分钟才变一次，而状态栏只在有操作时重画：
-- 静置时定时轻推一次，保证不动键盘也能看到时长在走。
-- 上面那次 section_org_clock() 调用只是触发插件内部重算（防抖 300ms），
-- 因此要等它算完再重画，否则画上去的还是旧值。
local org_clock_timer = vim.uv.new_timer()
org_clock_timer:start(
  30000,
  30000,
  vim.schedule_wrap(function()
    if section_org_clock() ~= "" then
      vim.defer_fn(function()
        vim.cmd.redrawstatus()
      end, 400)
    end
  end)
)

-- 各段布局：模式 → git 分支（mini.git）+ 改动统计（mini.diff）+ 诊断 → 文件名 → org 计时 → filetype → 位置
statusline.active = function()
  local mode, mode_hl = statusline.section_mode({ trunc_width = 75 })
  local git = statusline.section_git({ trunc_width = 75 })
  local diff = statusline.section_diff({ trunc_width = 75 })
  local diagnostics = statusline.section_diagnostics({ trunc_width = 75 })
  local filename = statusline.section_filename({ trunc_width = 140 })
  local fileinfo = statusline.section_fileinfo({ trunc_width = 120 })
  local location = statusline.section_location({ trunc_width = 75 })
  local org_clock = section_org_clock()

  return statusline.combine_groups({
    { hl = mode_hl, strings = { mode } },
    { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics } },
    "%<",
    { hl = "MiniStatuslineFilename", strings = { filename } },
    "%=", -- 左右分界：org 计时 / filetype / 位置推到窗口右缘
    { hl = "MiniStatuslineOrgClock", strings = { org_clock } },
    { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
    { hl = mode_hl, strings = { location } },
  })
end

-- 状态栏高亮：与 Catppuccin Mocha 同源的色板，换主题时重新应用
local palette = {
  blue = "#89b4fa",
  green = "#a6e3a1",
  mauve = "#cba6f7",
  red = "#f38ba8",
  yellow = "#f9e2af",
  teal = "#94e2d5",
  text = "#cdd6f4",
  subtext = "#a6adc8",
  overlay = "#6c7086",
  base = "#1e1e2e",
  mantle = "#181825",
  surface = "#313244",
}

local function statusline_hl()
  local hl = vim.api.nvim_set_hl
  -- 模式段：彩色底 + 深色粗体字
  hl(0, "MiniStatuslineModeNormal", { fg = palette.base, bg = palette.blue, bold = true })
  hl(0, "MiniStatuslineModeInsert", { fg = palette.base, bg = palette.green, bold = true })
  hl(0, "MiniStatuslineModeVisual", { fg = palette.base, bg = palette.mauve, bold = true })
  hl(0, "MiniStatuslineModeReplace", { fg = palette.base, bg = palette.red, bold = true })
  hl(0, "MiniStatuslineModeCommand", { fg = palette.base, bg = palette.yellow, bold = true })
  hl(0, "MiniStatuslineModeOther", { fg = palette.base, bg = palette.teal, bold = true })
  -- 内容段：深灰底
  hl(0, "MiniStatuslineFilename", { fg = palette.text, bg = palette.surface })
  hl(0, "MiniStatuslineDevinfo", { fg = palette.subtext, bg = palette.surface })
  hl(0, "MiniStatuslineFileinfo", { fg = palette.subtext, bg = palette.surface })
  -- org 计时段：黄色高亮，提醒时钟还在跑
  hl(0, "MiniStatuslineOrgClock", { fg = palette.yellow, bg = palette.surface, bold = true })
  -- 非当前窗口的状态栏整体灰化
  hl(0, "MiniStatuslineInactive", { fg = palette.overlay, bg = palette.mantle })
end

statusline_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("UserStatuslineHl", { clear = true }),
  callback = statusline_hl,
  desc = "重新应用状态栏高亮",
})

-- 标签页：把打开的 buffer 显示为顶部标签（两个以上才显示）。
-- 切换：[b / ]b（Vim 内置的上/下一个 buffer），或鼠标点击标签。
require("mini.tabline").setup({})
