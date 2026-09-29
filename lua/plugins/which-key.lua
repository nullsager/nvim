-- which-key：快捷键提示面板
-- v3 的 plugin/ 文件会在启动 500ms 后自动执行一次默认 setup；
-- 这里显式 setup 抢在前面完成初始化，以定制布局、图标与分组标签。

local wk = require("which-key")

wk.setup({
  -- modern 布局：带边框与居中标题的浮窗，底部显示翻页/滚动按键说明
  --（边框覆盖为 single，与全局 winborder 保持一致）
  preset = "modern",
  win = {
    border = "single",
  },

  icons = {
    -- 规则对 desc 小写后做 Lua 模式匹配，命中即显示图标；用户规则优先，
    -- 内置规则（find / search / git / code / toggle / buffer / window /
    -- diagnostic / format……）继续生效。
    rules = {
      { pattern = "grep", icon = "", color = "green" },
      { pattern = "obsidian", icon = "", color = "azure" },
      { pattern = "org", icon = "", color = "cyan" },
    },
  },

  -- 分组标签：group 项只负责给面板节点命名和配图标，不创建任何映射。
  spec = {
    -- <leader> 子前缀
    { "<leader>f", group = "查找 Find", icon = { icon = "", color = "green" }, mode = { "n", "v" } },
    { "<leader>g", group = "Git", icon = { cat = "filetype", name = "git" }, mode = "n" },
    { "<leader>a", group = "AI 助手", icon = { icon = "", color = "green" }, mode = { "n", "v" } },
    { "<leader>o", group = "笔记与 Org", icon = { cat = "filetype", name = "org" }, mode = "n" },
    { "<leader>m", group = "Markdown 元素", icon = { cat = "filetype", name = "markdown" }, mode = { "n", "v" } },
    { "<leader>c", group = "代码 Code", icon = { icon = "", color = "orange" }, mode = "n" },
    { "<leader>s", group = "参数交换 Swap", icon = { icon = "󰅇", color = "yellow" }, mode = "n" },
    { "<leader>z", group = "折叠 Folds", icon = { icon = "", color = "cyan" }, mode = "n" },
    { "<leader>u", group = "开关 Toggle", icon = { icon = "", color = "yellow" }, mode = "n" },

    -- 无 leader 的自定义前缀（mini.surround：sa/sd/sr/sf/sh……）
    { "s", group = "环绕 Surround", mode = { "n", "v" } },
  },
})
