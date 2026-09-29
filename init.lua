-- Neovim 配置入口
--
-- 目录结构：
--   lua/core/options.lua    编辑器选项（含 leader 键，必须最先加载）
--   lua/core/keymaps.lua    通用快捷键
--   lua/core/terminal.lua   底部终端切换
--   lua/core/autocmds.lua   自动命令（fcitx5 输入法同步、恢复光标位置）
--   lua/plugins/            插件清单与各插件配置（obsidian.lua 内含笔记元素快速插入）

require("core.options")
require("core.keymaps")
require("core.terminal")
require("core.autocmds")
require("plugins")
