-- mini.nvim 模块：编辑增强与界面
-- mini.nvim 是单个插件包含几十个独立模块，这里按需 setup 启用。

require("mini.pairs").setup({})
require("mini.surround").setup({})

-- 注释：gc + 动作（gcap 注释整段），gcc 注释当前行。
-- 内置 Treesitter 注入检测：Markdown 代码块里能自动用块内语言的注释符。
require("mini.comment").setup({})

-- 对齐：可视模式选中后按 ga 进入交互对齐。
-- 维护 Markdown 管道表格：选中表格行，ga 后输入 | 作为分隔符即可重新对齐。
require("mini.align").setup({})

-- 状态栏：模式（彩色底）/ git 分支 / 诊断计数 / 文件名 / filetype / 行列位置。
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

-- 各段布局：模式 → git 分支 + 诊断 → 文件名 → org 计时 → filetype → 位置
statusline.active = function()
  local mode, mode_hl = statusline.section_mode({ trunc_width = 75 })
  local git = statusline.section_git({ trunc_width = 75 })
  local diagnostics = statusline.section_diagnostics({ trunc_width = 75 })
  local filename = statusline.section_filename({ trunc_width = 140 })
  local fileinfo = statusline.section_fileinfo({ trunc_width = 120 })
  local location = statusline.section_location({ trunc_width = 75 })
  local org_clock = section_org_clock()

  return statusline.combine_groups({
    { hl = mode_hl, strings = { mode } },
    { hl = "MiniStatuslineDevinfo", strings = { git, diagnostics } },
    "%<",
    { hl = "MiniStatuslineFilename", strings = { filename } },
    "%=", -- 左右分界：org 计时 / filetype / 位置推到窗口右缘
    { hl = "MiniStatuslineOrgClock", strings = { org_clock } },
    { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
    { hl = mode_hl, strings = { location } },
  })
end

-- git 分支名：section_git 读取 vim.b.gitsigns_head（名字沿用 gitsigns 约定，
-- 不装 gitsigns 也能用）。异步获取避免状态栏刷新时阻塞。
local function set_git_branch(buf, name)
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.b[buf].gitsigns_head = name
      vim.cmd.redrawstatus()
    end
  end)
end

local function update_git_branch()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  local dir = file ~= "" and vim.fn.fnamemodify(file, ":h") or vim.uv.cwd()

  -- --show-current 对无 commit 的新分支也能返回名字；detached HEAD 时为空
  vim.system({ "git", "-C", dir, "branch", "--show-current" }, { text = true }, function(res)
    if res.code ~= 0 then
      return
    end
    local branch = vim.trim(res.stdout or "")
    if branch ~= "" then
      set_git_branch(buf, branch)
      return
    end
    -- detached HEAD：显示短 commit 号
    vim.system({ "git", "-C", dir, "rev-parse", "--short", "HEAD" }, { text = true }, function(res2)
      if res2.code == 0 then
        set_git_branch(buf, "@" .. vim.trim(res2.stdout or ""))
      end
    end)
  end)
end

local git_branch_group = vim.api.nvim_create_augroup("UserGitBranch", { clear = true })

vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained" }, {
  group = git_branch_group,
  callback = update_git_branch,
  desc = "异步获取 git 分支名供状态栏显示",
})

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
