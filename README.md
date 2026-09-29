# Neovim 个人配置手册

> 基于 **Neovim 0.12+** 的模块化配置，使用内置 `vim.pack` 管理插件。
> 面向 C/C++、Python 开发、Markdown 笔记（Obsidian）与 Org mode 任务管理工作流，
> 集成 DeepSeek / Claude AI 助手。

**Leader 键 = 空格（`<Space>`）**，按下后稍作停留会弹出 which-key 快捷键提示面板。

---

## 目录

- [一、配置结构](#一配置结构)
- [二、环境与依赖](#二环境与依赖)
- [三、插件清单与管理](#三插件清单与管理)
- [四、编辑器基础行为](#四编辑器基础行为)
- [五、快捷键速查表](#五快捷键速查表)
- [六、功能详解](#六功能详解)
- [七、自定义指南](#七自定义指南)
- [八、常见问题（FAQ）](#八常见问题faq)
- [九、备份与回滚](#九备份与回滚)

---

## 一、配置结构

```
~/.config/nvim/
├── init.lua                    入口：按顺序加载各模块，本身不含逻辑
├── README.md                   本文件
├── nvim-pack-lock.json         插件版本锁定文件（vim.pack 自动生成，勿手改）
├── nvim.log                    Neovim 运行日志（自动生成）
├── snippets/                   自定义代码片段（文件名 = filetype，如 org.json）
└── lua/
    ├── core/                   与插件无关的基础配置
    │   ├── options.lua         编辑器选项（含 Leader 键，必须最先加载）
    │   ├── keymaps.lua         通用快捷键、代码格式化
    │   ├── terminal.lua        底部终端切换（<C-\>）
    │   └── autocmds.lua        自动命令：fcitx5 输入法同步、恢复光标位置
    └── plugins/                每个插件一个文件，配置与其快捷键放在一起
        ├── init.lua            插件清单（vim.pack.add）+ 各插件模块的加载入口
        ├── which-key.lua       快捷键提示面板：modern 布局 / 图标规则 / 分组标签
        ├── mini.lua            mini.nvim 模块：配对 / 环绕 / 注释 / 对齐 / 状态栏 / 标签页
        ├── minuet.lua          AI 行内补全：minuet-ai（DeepSeek FIM，经 blink.cmp）
        ├── completion.lua      自动补全：blink.cmp
        ├── lsp.lua             LSP：clangd / pyright + 诊断开关
        ├── fzf.lua             模糊搜索：fzf-lua
        ├── treesitter.lua      语法高亮 / 折叠 / 缩进 / 语法对象
        ├── obsidian.lua        Obsidian 笔记 + 笔记元素快速插入
        ├── orgmode.lua         Org mode：任务 / 议程 / 速记
        ├── codecompanion.lua   AI 助手（DeepSeek / Claude）
        ├── markdown.lua        Markdown 渲染：render-markdown + mini.icons
        └── markdown-preview.lua Markdown 浏览器实时预览（<leader>mp）
```

**加载顺序**（`init.lua`）：

```
core.options  →  core.keymaps  →  core.terminal  →  core.autocmds  →  plugins
```

`core.options` 必须最先加载，因为 `vim.g.mapleader` 需要在所有快捷键映射之前设置；
插件配置放在最后，因为 `vim.pack.add` 会把插件目录加入 `runtimepath`。

---

## 二、环境与依赖

### 必需

| 依赖 | 用途 | 安装（Arch Linux） |
|------|------|---------------------|
| Neovim ≥ 0.12 | 本配置使用 `vim.pack`、`vim.lsp.enable` 等新 API | `sudo pacman -S neovim` |
| git | vim.pack 克隆插件 | `sudo pacman -S git` |
| fzf | fzf-lua 的后端 | `sudo pacman -S fzf` |
| Nerd Font | 显示补全图标、Markdown 标题图标 | 如 `ttf-jetbrainsmono-nerd`，并在终端中启用 |

### 语言服务器与格式化工具

| 工具 | 用途 | 当前状态 |
|------|------|----------|
| clangd | C/C++ LSP | 已安装 |
| pyright | Python LSP | 已安装 |
| clang-format | C/C++ 格式化（`<leader>cf`） | 已安装 |
| ruff | Python 格式化（`<leader>cf`） | 已安装 |

### 可选

| 依赖 | 用途 |
|------|------|
| fcitx5 + fcitx5-remote | 输入法状态自动切换（见 [fcitx5 输入法自动切换](#61-fcitx5-输入法自动切换)） |
| wl-clipboard / xclip | 系统剪贴板互通（`unnamedplus`） |
| Node.js（含 npm） | markdown-preview 浏览器预览的前端依赖（见 [6.9 节](#69-markdown-渲染与浏览器预览)） |
| `DEEPSEEK_API_KEY` 环境变量 | CodeCompanion 对话与 minuet AI 补全共用（见 [CodeCompanion AI 助手](#68-codecompanion-ai-助手)） |
| `ANTHROPIC_API_KEY` 环境变量 | CodeCompanion 调用 Claude API（不用 Claude 可不设） |
| C 编译器（cc / gcc / clang） | 首次启动时编译 Org 的 Treesitter parser（一次性，见 [Org mode 任务管理](#610-org-mode-任务管理)） |
| pandoc 或 emacs | Org 导出为 HTML / PDF 等格式（不用导出功能可忽略） |

---

## 三、插件清单与管理

### 插件清单（19 个）

| 插件 | 用途 |
|------|------|
| which-key.nvim | 快捷键提示面板：modern 布局 + 图标 + 分组标签（见 6.11 节） |
| mini.nvim | 模块集：pairs（括号配对）、surround（环绕编辑）、comment（注释）、align（对齐）、statusline（状态栏）、tabline（buffer 标签页），见 6.12 节 |
| mini.icons | 图标库 |
| blink.cmp（`1.*`） | 自动补全引擎 |
| blink-cmp-latex | LaTeX 命令补全源 |
| friendly-snippets | 代码片段集合 |
| minuet-ai.nvim | AI 行内补全（DeepSeek FIM），作为 blink.cmp 补全源，见 6.6 节 |
| nvim-lspconfig | LSP 官方配置集合 |
| fzf-lua | 模糊搜索 |
| nvim-web-devicons | 文件类型图标 |
| obsidian.nvim | Obsidian 笔记库集成 |
| orgmode | Org mode：任务管理、议程（Agenda）、速记（Capture） |
| render-markdown.nvim | Markdown 实时渲染 |
| markdown-preview.nvim | Markdown 浏览器实时预览（`<leader>mp`；退出 Neovim 后页面保留为静态快照） |
| plenary.nvim | 通用 Lua 依赖库 |
| treesitter-parser-registry | Treesitter parser 注册表 |
| nvim-treesitter | 语法分析：高亮 / 折叠 / 缩进 |
| nvim-treesitter-textobjects | 语法对象（函数、类、参数……） |
| codecompanion.nvim（`^19`） | AI 助手，接入 DeepSeek 与 Anthropic Claude |

### 使用 vim.pack 管理插件

插件声明集中在 `lua/plugins/init.lua`，版本锁定在 `nvim-pack-lock.json`。

```lua
-- 添加插件：在 lua/plugins/init.lua 的 vim.pack.add({...}) 中加一行
"https://github.com/owner/repo",

-- 指定版本（示例）
{ src = "https://github.com/owner/repo", version = vim.version.range("1.*") },
```

常用命令：

| 命令 | 作用 |
|------|------|
| `:lua vim.pack.update()` | 更新所有插件（会逐个列出变更并询问确认） |
| `:lua vim.pack.update({ "fzf-lua" })` | 只更新指定插件 |
| `:lua vim.pack.get()` | 查看已安装插件及状态 |
| `:lua vim.pack.del({ "插件名" })` | 删除插件（同时从清单中移除该行） |
| `:lua vim.pack.clean()` | 清理清单中已不存在的插件目录 |

> 提示：`nvim-pack-lock.json` 记录了每个插件的精确 commit，把它纳入版本管理（git）
> 即可在任意机器上复现完全一致的插件版本。

---

## 四、编辑器基础行为

| 选项 | 值 | 说明 |
|------|-----|------|
| `number` + `relativenumber` | 开 | 当前行显示绝对行号，其余行显示相对行号 |
| `termguicolors` | 开 | 24-bit 真彩色 |
| `cursorline` | 开 | 高亮光标所在行 |
| 主题 | catppuccin | 来自系统运行时（Arch neovim 包附带） |
| `winborder` | `single` | 所有浮窗使用单线边框 |
| `clipboard` | `+unnamedplus` | 与系统剪贴板互通（需 wl-clipboard/xclip） |
| `scrolloff` / `sidescrolloff` | 10 | 光标距窗口上下/左右边缘至少保留 10 行/列 |
| `tabstop` / `shiftwidth` / `softtabstop` | 2 | Tab 宽度与缩进宽度均为 2 |
| `expandtab` | 开 | 用空格代替 Tab |
| `smartindent` / `autoindent` | 开 | 智能自动缩进 |
| `undofile` | 开 | 持久化撤销历史，关闭文件后仍可撤销 |
| `splitbelow` / `splitright` | 开 | 新分屏默认在下方/右方 |
| `ignorecase` + `smartcase` | 开 | 搜索忽略大小写；但搜索词含大写字母时恢复区分 |
| `inccommand` | `nosplit` | 输入 `:s` 替换命令时实时预览效果 |
| `updatetime` | 250 | CursorHold 等事件的触发间隔（默认 4000ms 偏慢） |
| `virtualedit` | `block` | 可视块编辑时光标可越过行尾（改表格、对齐文本好用） |

---

## 五、快捷键速查表

> 模式缩写：**n** 普通 / **i** 插入 / **v** 可视 / **x** 可视(不含选择) / **o** 操作符等待 / **t** 终端

### 5.1 基础编辑与窗口（core/keymaps.lua）

| 快捷键 | 模式 | 作用 |
|--------|------|------|
| `jk` | i | 退出插入模式（等同 `<Esc>`） |
| `jk` | t | 退出终端模式（等同 `<C-\><C-n>`） |
| `<C-q>` | i / n / t | 强制删除当前 buffer（`:bd!`） |
| `<Esc>` | n | 清除搜索高亮 |
| `j` / `k`（无数字前缀） | n / x | 按屏幕行上下移动：折行文本中一次跨一个视觉行；带数字前缀（`5j`）仍按真实行号跳，配合相对行号使用 |
| `<Up>` / `<Down>` | n / x | 同上，方向键也改为按屏幕行移动 |
| `<C-h>` / `<C-j>` / `<C-k>` / `<C-l>` | n / t | 移动光标到 左 / 下 / 上 / 右 窗口（终端模式下同样可用，注意事项见 FAQ Q9） |
| `<C-Up>` / `<C-Down>` | i / n / t | 窗口高度 ±3 |
| `<C-Left>` / `<C-Right>` | i / n / t | 窗口宽度 ±3 |
| `<leader>cf` | n | 格式化当前文件（见 [代码格式化](#65-代码格式化)） |
| `<leader>zM` | n | 折叠所有代码块 |
| `<leader>zR` | n | 展开所有代码块 |

### 5.2 终端（core/terminal.lua）

| 快捷键 | 模式 | 作用 |
|--------|------|------|
| `<C-\>` | n / t | 切换底部终端（占屏 30%，会话保留，详见 [底部终端](#63-底部终端)） |

### 5.3 文件浏览 netrw（内置）

| 快捷键 | 模式 | 作用 |
|--------|------|------|
| `<leader>e` | n | 在左侧开关文件树（`:Lexplore`） |

netrw 已定制为树形显示、宽 20%、回车在右侧窗口打开文件。常用内置按键：

| 按键 | 作用 |
|------|------|
| `回车` | 打开文件 / 展开收起目录 |
| `%` / `d` | 新建文件 / 新建目录 |
| `D` / `R` | 删除 / 重命名 |
| `I` | 显示/隐藏顶部帮助横幅 |
| `<C-l>` | 刷新列表 |

### 5.4 模糊搜索 fzf-lua

**文件与内容**（`<leader>f` 前缀）：

| 快捷键 | 模式 | 作用 |
|--------|------|------|
| `<leader>ff` | n | 模糊查找文件 |
| `<leader>fg` | n | 全项目实时搜索文本（live grep） |
| `<leader>fw` | n | 搜索光标下的单词 |
| `<leader>fw` | v | 搜索选中的文本 |
| `<leader>fb` | n | 在已打开的 buffer 间切换 |
| `<leader>fr` | n | 最近打开过的文件 |
| `<leader>fR` | n | 恢复上一次的搜索窗口 |

**Neovim 内置资源**：

| 快捷键 | 模式 | 作用 |
|--------|------|------|
| `<leader>fh` | n | 搜索帮助文档（help tags） |
| `<leader>fk` | n | 搜索所有快捷键映射 |
| `<leader>fc` | n | 搜索所有可用命令 |

**LSP 与诊断**：

| 快捷键 | 模式 | 作用 |
|--------|------|------|
| `<leader>fd` | n | 当前文件的诊断列表（显示开关见 `<leader>ul`） |
| `<leader>fs` | n | 当前文件的符号大纲（函数 / 类等） |

**Git**（`<leader>g` 前缀，依赖系统 git 命令，需在 Git 仓库内使用）：

| 快捷键 | 模式 | 作用 |
|--------|------|------|
| `<leader>gf` | n | 查找被 Git 跟踪的文件 |
| `<leader>gs` | n | 查看 Git 状态（改动文件） |
| `<leader>gc` | n | 浏览提交历史 |
| `<leader>gb` | n | 浏览 / 切换分支 |

> fzf-lua 还有大量内置命令可直接使用，如 `:FzfLua lsp_references`、
> `:FzfLua quickfix` 等，输入 `:FzfLua` 后按 Tab 可查看全部。

### 5.5 自动补全 blink.cmp（插入模式）

补全菜单自动弹出，也可用 `<C-Space>` 手动唤起：

| 快捷键 | 作用 |
|--------|------|
| `<C-n>` / `<C-p>`（或 `↓` / `↑`） | 选择下 / 上一个候选 |
| `<CR>` | 确认补全 |
| `<C-y>` | 确认补全（同上） |
| `<C-e>` | 取消并关闭菜单 |
| `<C-Space>` | 打开补全菜单 / 展开或收起文档浮窗 |
| `<C-b>` / `<C-f>` | 在文档浮窗中向上 / 向下滚动 |
| `<C-k>` | 显示 / 隐藏函数签名帮助 |
| `<Tab>` / `<S-Tab>` | snippet 占位符之间向前 / 向后跳转 |
| `<A-y>` | 手动唤起 AI 补全（只显示 minuet 候选，见 [AI 行内补全](#66-补全snippet-与-latex)） |
| `<leader>um`（普通模式） | AI 补全总开关（`:Minuet blink toggle`） |

补全行为特点：

- 候选**不预选、不自动插入**，必须手动确认（`preselect = false`）
- 文档浮窗延迟 300ms 自动弹出
- 补全菜单三列显示：补全项与描述 | 类型图标与类型 | 来源（lsp/path/snippets/buffer/minuet/LaTeX）
- AI 行内补全（minuet）是第 5 个补全源，**只在代码文件随打字自动触发**，
  文本文件需 `<A-y>` 手动唤起；关闭方法见 6.6 节

### 5.6 LSP 与诊断

| 快捷键 | 模式 | 作用 |
|--------|------|------|
| `<leader>ul` | n | 全局开关诊断信息（**默认关闭**） |
| `gl` | n | 浮窗显示当前行诊断详情 |

以下快捷键为 Neovim 0.12 **内置**的 LSP 映射（clangd/pyright attach 后可用）：

| 快捷键 | 作用 |
|--------|------|
| `K` | 悬浮文档（hover） |
| `grn` | 重命名符号 |
| `gra` | Code Action |
| `grr` | 跳转到引用列表 |
| `gri` | 跳转到实现 |
| `grt` | 跳转到类型定义 |
| `gO` | 文档符号大纲 |
| `<C-s>`（插入模式） | 函数签名帮助 |

### 5.7 Treesitter 语法对象（plugins/treesitter.lua）

**选择**（x / o 模式，可配合 `d`、`c`、`y` 等操作符）：

| 快捷键 | 选中目标 | 示例 |
|--------|----------|------|
| `af` / `if` | 整个函数 / 函数体 | `daf` 删除函数、`vif` 选中函数体 |
| `ac` / `ic` | 整个类 / 类内部 | `yac` 复制整个类 |
| `aa` / `ia` | 函数参数（含 / 不含逗号） | `daa` 删除当前参数 |
| `al` / `il` | 整个循环 / 循环体 | `cil` 改写循环体 |
| `ai` / `ii` | 整个条件分支 / 分支内部 | `vai` 选中 if 块 |

> 选中函数 / 类后自动进入行可视模式（`V`），参数为字符可视（`v`），便于整行操作；
> 光标不在目标内部时会自动向后寻找最近的目标（`lookahead`）。

**跳转**（n / x / o 模式，记入 jumplist，可用 `<C-o>` 跳回）：

| 快捷键 | 作用 |
|--------|------|
| `]f` / `[f` | 下一个 / 上一个函数开头 |
| `]F` / `[F` | 下一个 / 上一个函数结尾 |
| `]c` / `[c` | 下一个 / 上一个类开头 |

**交换参数**（n 模式）：

| 快捷键 | 作用 |
|--------|------|
| `<leader>sn` | 当前参数与下一个参数交换 |
| `<leader>sp` | 当前参数与上一个参数交换 |

### 5.8 Obsidian 笔记（plugins/obsidian.lua）

| 快捷键 | 模式 | 作用 |
|--------|------|------|
| `<leader>oo` | n | 用 netrw 浏览整个笔记库 |
| `<leader>of` | n | 按文件名快速打开笔记（fzf） |
| `<leader>os` | n | 全文搜索笔记内容 |
| `<leader>ob` | n | 查看当前笔记的反向链接 |
| `<leader>ot` | n | 打开 / 创建今天的日记 |
| `<leader>on` | n | 输入标题创建新笔记（存入 `draft/`） |
| `<leader>op` | n | 粘贴剪贴板图片到笔记（存入 `images/`） |
| `<leader>ov` | n | 保存并在 Obsidian 应用中打开当前笔记 |
| `<leader>mc` | n | 插入 Callout（9 种类型菜单选择，见下文） |
| `<leader>mt` | n | 插入 Markdown 表格（输入 列x行，自动对齐） |
| `<leader>mb` | n / v | 切换复选框状态 |

### 5.9 CodeCompanion AI 助手（plugins/codecompanion.lua）

**全局快捷键**：

| 快捷键 | 模式 | 作用 |
|--------|------|------|
| `<leader>aa` | n / v | 打开动作面板（所有预设动作的菜单） |
| `<leader>ac` | n | 打开 / 隐藏当前聊天窗口 |
| `<leader>an` | n | 新建聊天 |
| `<leader>ai` | n | Inline 模式：让 AI 生成 / 修改光标附近代码 |
| `<leader>ai` | v | 对选中代码执行 Inline 请求 |
| `<leader>ad` | v | 把选中代码追加到当前聊天 |
| `<leader>ae` | v | 解释选中代码（`/explain`） |
| `<leader>af` | v | 修复选中代码（`/fix`） |
| `<leader>at` | v | 为选中代码生成测试（`/tests`） |
| `<leader>am` | n | 切换默认模型（菜单选择，chat / inline / cmd 一起生效，见 [CodeCompanion AI 助手](#68-codecompanion-ai-助手)） |
| `<leader>aM` | n | 用选定模型新建聊天（不改动默认模型） |
| `<leader>ag` | n | 根据暂存区生成 Git commit message（`/commit`） |

**聊天窗口内置按键**（codecompanion 默认）：

| 按键 | 模式 | 作用 |
|------|------|------|
| `?` | n | 显示全部聊天按键帮助 |
| `<CR>` 或 `<C-s>` | n（`<C-s>` 也可用于 i） | 发送消息 |
| `q` | n | 停止当前请求 |
| `gr` | n | 重新生成上一条回复 |
| `gx` | n | 清空聊天记录 |
| `<C-c>` | n / i | 关闭聊天窗口 |
| `ga` | n | 切换 adapter / 模型 |
| `gc` | n | 插入空代码块 |
| `gy` | n | 复制最后一个代码块 |
| `gf` | n | 折叠所有代码块 |
| `}` / `{` | n | 下一个 / 上一个聊天 |
| `]]` / `[[` | n | 跳到下 / 上一个消息标题 |

### 5.10 Org mode（plugins/orgmode.lua）

**全局快捷键**（任意 buffer 可用）：

| 快捷键 | 模式 | 作用 |
|--------|------|------|
| `<leader>oa` | n | 打开 Agenda 菜单（`a` 周议程 / `t` 待办列表 / `m` 标签过滤 / `s` 搜索） |
| `<leader>oc` | n | 打开 Capture 速记菜单（默认 `t` = Task 模板） |

**.org 文件内**（buffer 局部映射，完整帮助随时按 `g?`）：

| 快捷键 | 作用 |
|--------|------|
| `<Tab>` / `<S-Tab>` | 折叠 / 展开当前标题；循环全文折叠级别 |
| `cit` / `ciT` | 切换 TODO 状态：`cit` 弹快速选择菜单（`t`/`n`/`h`/`w`/`d`/`c`），`ciT` 逐个后退 |
| `<leader>ot` | 修改标题标签（tags） |
| `<leader>o,` | 设置优先级（A / B / C） |
| `<leader>mb` | 切换复选框 `- [ ]` / `- [X]`（默认 `<C-Space>`，因与输入法切换冲突改键） |
| `<<` / `>>` | 提升 / 降低当前标题层级 |
| `<s` / `>s` | 提升 / 降低整个子树层级 |
| `<leader>o*` | 当前行在标题与正文间互转 |
| `<leader><CR>` | 智能新建同级标题 / 列表项 / 表格行（依上下文） |
| `<leader>oih` / `<leader>oiT` / `<leader>oit` | 内容后插入标题 / 紧随其后插入 TODO / 内容后插入 TODO |
| `<leader>oK` / `<leader>oJ` | 子树上移 / 下移 |
| `}` / `{` | 下一个 / 上一个可见标题 |
| `]]` / `[[` | 下一个 / 上一个同级标题 |
| `<leader>oid` / `<leader>ois` | 设置 DEADLINE / SCHEDULED 日期 |
| `<leader>oi.` / `<leader>oi!` | 插入主动 / 非主动时间戳 |
| `<C-a>` / `<C-x>` | 增减光标处的日期或时间 |
| `<S-Up>` / `<S-Down>` | 按天增减光标处日期 |
| `cid` | 弹出日历修改光标处日期 |
| `<leader>oo` | 打开光标处的链接 / 日期 |
| `<leader>oli` / `<leader>ols` | 插入链接 / 存储当前位置的链接 |
| `<leader>or` | Refile：把当前标题移动到其他文件 / 标题下 |
| `<leader>o$` / `<leader>oA` | 归档子树到 `*_archive` 文件 / 切换 ARCHIVE 标签 |
| `<leader>ona` | 为当前标题添加备注 |
| `<leader>oxi` / `<leader>oxo` | 开始 / 结束计时（clocking）；在别的任务上再按 `oxi` 会自动停掉上一个 |
| `<leader>oxq` / `<leader>oxj` | 取消当前这段计时（不记账） / 跳回正在计时的任务 |
| `<leader>oxe` | 设置预估工时（`Effort` 属性，会显示在状态栏计时段里） |
| `<leader>oe` | 导出（HTML / PDF 等，需 pandoc 或 emacs） |
| `<leader>o'` | 在独立窗口编辑光标所在的 `#+begin_src` 代码块（仅限代码块，不支持表格） |

**Agenda 视图内**：

| 快捷键 | 作用 |
|--------|------|
| `f` / `b` | 下一个 / 上一个时间段 |
| `.` | 回到今天 |
| `vd` / `vw` / `vm` / `vy` | 切换 日 / 周 / 月 / 年 视图 |
| `J` | 跳转到指定日期 |
| `<CR>` / `<Tab>` | 在当前窗口 / 其他窗口打开任务 |
| `r` | 刷新视图 |
| `t` | 切换任务的 TODO 状态 |
| `/` | 按标签 / 关键字过滤 |
| `K` | 预览任务在文件中的位置 |
| `q` | 退出 Agenda |

**Capture 窗口内**：`<C-c>` 保存并关闭，`<leader>or` refile 到指定位置，`<leader>ok` 放弃。

> 冲突说明：org buffer 内 `<leader>oo` / `<leader>ot` 是插件的 buffer 局部映射，
> 会覆盖 Obsidian 的同名全局映射（仅在 org 文件内生效，见 [Q8](#八常见问题faq)）。
> 另外复选框切换键插件默认为 `<C-Space>`，与 fcitx5 输入法切换冲突，
> 已在 `orgmode.lua` 中改为 `<leader>mb`（与 Markdown 复选框键一致，
> 在 org buffer 内覆盖 Obsidian 的同名全局映射，语义相同）。

### 5.11 mini 编辑增强与界面（plugins/mini.lua）

**注释**（mini.comment）：

| 快捷键 | 模式 | 作用 |
|--------|------|------|
| `gcc` | n | 注释 / 取消注释当前行 |
| `gc` + 动作 | n | 注释目标区域，如 `gcap` 整段、`gcG` 到文件末尾 |
| `gc` | x | 注释选中的行 |

> Markdown 代码块内用 `gc` 会自动使用块内语言的注释符（Treesitter 注入检测）。

**环绕编辑**（mini.surround，`s` 前缀）：

| 快捷键 | 模式 | 作用 |
|--------|------|------|
| `sa` + 对象 + 符号 | n | 添加环绕，如 `saiw)` 给光标所在词加上 `(...)` |
| `sa` + 符号 | x | 给选区添加环绕 |
| `sd` + 符号 | n | 删除环绕，如 `sd(` |
| `sr` + 旧符号 + 新符号 | n | 替换环绕，如 `sr(` 后输入 `[`，把 `(...)` 换成 `[...]` |
| `sf` / `sF` + 符号 | n | 光标跳到环绕的右 / 左侧 |
| `sh` + 符号 | n | 高亮环绕区域 |

**对齐**（mini.align）：

| 快捷键 | 模式 | 作用 |
|--------|------|------|
| `ga` | x | 交互式对齐选区：按提示输入分隔符（如 `\|`）后回车 |
| `gA` | x | 同 `ga`，但带实时预览 |

**状态栏与标签页**（mini.statusline / mini.tabline）：
状态栏显示模式（Catppuccin 彩色底）、git 分支、诊断计数、文件名、
Org 计时任务（计时中才出现）、filetype 与行列位置（详见 6.12 节）；打开两个以上 buffer 时顶部显示 buffer 标签，
切换方式：`[b` / `]b`（Vim 内置的上 / 下一个 buffer）、鼠标点击标签、`<leader>fb`。

### 5.12 Markdown 浏览器预览（plugins/markdown-preview.lua）

| 快捷键 | 模式 | 作用 |
|--------|------|------|
| `<leader>mp` | n | 开关浏览器实时预览（仅 Markdown 文件内生效，其他文件只提示不动作，详见 [6.9 节](#69-markdown-渲染与浏览器预览)） |

---

## 六、功能详解

### 6.1 fcitx5 输入法自动切换

位置：`lua/core/autocmds.lua`（系统安装 fcitx5-remote 时自动启用）

解决"插入模式用中文输入，退回普通模式后快捷键被输入法拦截"的经典痛点：

| 时机 | 行为 |
|------|------|
| `InsertLeave` / `TermLeave` | 记录当前输入法状态；若处于中文状态则切换为英文 |
| `InsertEnter` / `TermEnter` | 恢复之前记录的中文状态 |
| `VimEnter` | 启动时确保普通模式为英文 |
| `VimLeavePre` | 退出 Neovim 时恢复系统输入法状态 |

效果：普通模式下 `hjkl` 等快捷键永远可用，回到插入模式中文输入无缝恢复。

### 6.2 恢复上次光标位置

位置：`lua/core/autocmds.lua`

重新打开文件时自动跳回上次退出时的光标位置（`BufReadPost` 事件，读取 `"` 标记）。
diff 模式下自动跳过；标记位置超出文件行数时安全忽略。

### 6.3 底部终端

位置：`lua/core/terminal.lua`，快捷键 `<C-\>`

- 在窗口底部打开占屏 **30%** 的终端，再按一次隐藏
- 终端 **buffer 常驻**：隐藏后再打开会回到同一会话（命令历史、运行状态都在）
- 终端窗口自动关闭行号与标志列，打开即进入输入模式
- 在终端里按 `jk` 退回普通模式，可像普通 buffer 一样滚动复制
- 终端内同样可用 `<C-h/j/k/l>` 直接跳转窗口（见 5.1；代价与恢复方法见 FAQ Q9）
- 边界保护：终端是唯一窗口时按 `<C-\>` 不会报 E444 错误

### 6.4 Treesitter：高亮 / 折叠 / 缩进

位置：`lua/plugins/treesitter.lua`

**parser 管理**：`treesitter_parsers` 列表中的 23 个 parser 在启动时异步安装缺失项，
已安装的不会重复安装。想支持新语言，往列表里加一行即可。

**按 filetype 启用**（`FileType` 自动命令）：

1. **高亮**：`vim.treesitter.start()`（含语言注入，如 Markdown 代码块内按各自语言高亮）
2. **折叠**：`foldmethod = expr`，打开文件时 `foldlevel = 99`（默认全部展开）
3. **智能缩进**：对 `treesitter_indent_filetypes` 中的语言启用实验性 Treesitter 缩进；
   若某语言缩进异常，从该表中删掉对应行即可回退到默认缩进

折叠相关按键（Vim 内置）：`zc` 折叠 / `zo` 展开 / `za` 切换当前折叠，
配合 `<leader>zM` / `<leader>zR` 全局折叠与展开。

> 注：CodeCompanion 聊天 buffer 被注册为 markdown 文件类型，
> 因此聊天内容同样享受 Markdown 高亮与渲染。

### 6.5 代码格式化

位置：`lua/core/keymaps.lua`，快捷键 `<leader>cf`

| 文件类型 | 命令 |
|----------|------|
| c / cpp | `clang-format`（项目根目录的 `.clang-format` 文件自动生效） |
| python | `ruff format -` |

安全机制（重构时加固）：

- 当前 filetype 无对应工具 → 仅提示，不动 buffer
- 格式化工具未安装 → 仅提示，不动 buffer（避免 `%!` 过滤器把 shell 报错写进文件）
- 命令执行失败 → 自动 `undo` 恢复原内容并提示
- 成功后恢复光标位置与视图

**添加新语言**：在 `keymaps.lua` 的 `formatters` 表中加一行，例如 `go = "gofmt"`。

### 6.6 补全、Snippet 与 LaTeX

位置：`lua/plugins/completion.lua`

**补全源**（默认）：`lsp` → `path` → `snippets` → `buffer` → `minuet`（AI 行内补全）

**按文件类型扩展**（`per_filetype`）：`markdown`、`codecompanion`、`tex`、`plaintex`
额外启用 `latex` 源。

**LaTeX 补全**（blink-cmp-latex）：

- 在 Markdown 中输入 `\alpha`、`\sum` 等会出现补全候选
- `insert_command = true`：确认后插入的是 **LaTeX 命令本身**（`\alpha`），
  而不是 Unicode 字符（α），符合 Markdown 公式编写习惯
- `score_offset = 100`：LaTeX 候选排在最前

**AI 行内补全**（minuet-ai.nvim，`lua/plugins/minuet.lua`）：

- 随打字出现的 AI 补全候选（菜单中来源名 `minuet`），走 DeepSeek 的
  FIM 补全接口——`openai_fim_compatible` 的内置默认 provider
  （端点 `api.deepseek.com/beta/completions`，模型 `deepseek-v4-flash`），
  复用 `DEEPSEEK_API_KEY`，与 CodeCompanion 共用同一个 key
- **只在代码文件自动触发**（c / cpp / python / lua / shell / 前端 / 配置文件，
  名单在 `minuet.lua` 顶部的 `auto_trigger_filetypes`）；org / markdown 等
  文本文件不自动请求，`<A-y>` 手动唤起不受此限制
- 请求频率限制：停顿 400ms（debounce）后才触发、1 秒内最多一次（throttle）、
  单次最多生成 256 token、上下文最多约 16000 字符（约 4000 token）
- `<leader>um` 或 `:Minuet blink toggle` 总开关；`:Minuet change_provider`
  可现场切换 provider / 模型
- 与 CodeCompanion 的分工：minuet 是**被动补全**（边打字边出候选），
  CodeCompanion 是**主动交互**（对话 / Inline 改写），两者互补不冲突

**Snippet**（friendly-snippets 自动加载）：

- `markdown` 文件额外加载 `tex` 的 snippets
- `codecompanion` 额外加载 `markdown` + `tex` 的 snippets
- 用 `<Tab>` / `<S-Tab>` 在占位符间跳转

**自定义 Snippet**：`~/.config/nvim/snippets/` 下的 JSON 文件会被自动扫描，
文件名去 `.json` 后缀即 filetype。当前内置 `org.json`（Org 表格 `<t`、
TODO 标题 `tdo`、代码块 `src`），详见 [orgmode.md](orgmode.md) 5.5 节。

**自动配对 / 环绕 / 注释**：由 mini.pairs、mini.surround、mini.comment 提供，
配置与按键说明见 6.12 节与 5.11 节。

### 6.7 Obsidian 笔记工作流

位置：`lua/plugins/obsidian.lua`

与 Obsidian 应用**共用同一个笔记库** `~/Documents/notes`，目录约定完全对齐：

| 项目 | 值 |
|------|-----|
| 新笔记 | `draft/`，以笔记标题为文件名（非法字符替换为 `-`），无标题时用时间戳 |
| 日记 | `dailynote/`，文件名格式 `YYYY-MM-DD` |
| 附件 / 图片 | `images/` |
| 链接风格 | 标准 Markdown 链接 `[text](path)` |
| frontmatter | 不自动生成，保留笔记原样 |
| 搜索面板 | fzf-lua |
| UI 渲染 | 关闭（交给 render-markdown） |

**快速插入笔记元素**（纯 Lua 实现，替代手工排版）：

- `<leader>mc` **Callout**：菜单选择 9 种类型
  （note / tip / important / warning / caution / question / example / bug / quote），
  再输入可选标题，自动插入 `> [!TYPE] 标题` 块并进入编辑位置
- `<leader>mt` **表格**：输入 `列x行`（如 `3x2`，支持 `x`、`X`、`×`、`*`），
  生成按中文显示宽度对齐的管道表格，占位文字可直接覆盖输入
- `<leader>mb` **复选框**：在 `- [ ]` / `- [x]` 间切换

> 注意：多数 `:Obsidian` 子命令需要在笔记库目录内使用；
> 先用 `<leader>oo` 或 `<leader>of` 进入笔记库即可。

### 6.8 CodeCompanion AI 助手

位置：`lua/plugins/codecompanion.lua`

**准备工作**：设置环境变量（写入 `~/.zshrc`，重开终端生效；不用 Claude 可只设 DeepSeek）：

```bash
export DEEPSEEK_API_KEY="sk-xxxxxxxx"
export ANTHROPIC_API_KEY="sk-ant-xxxxxxxx"
```

**两个 adapter 的默认参数**（chat / inline / cmd 三种交互默认都用 deepseek）：

| adapter | 默认模型 | 参数要点 |
|---------|----------|----------|
| deepseek（默认） | `deepseek-v4-flash` | 思考模式默认开启（聊天中显示、默认折叠）；`reasoning_effort = max`；`temperature = 0.4` |
| anthropic | `claude-opus-5` | 5 系已移除 temperature（配置按模型自动不发，避免 400）；`effort` 五档 low ~ max，默认 high；思考内容以摘要形式显示 |

**模型切换的四种方式**：

| 方式 | 生效范围 |
|------|----------|
| 聊天窗口内按 `ga` | 只影响当前对话，可选到 adapter 内置的全部模型 |
| `<leader>am` | 改默认模型，chat / inline / cmd 一起生效（当前会话内） |
| `<leader>aM` | 用选定模型新开聊天，不动默认值 |
| `:CodeCompanionChat adapter=anthropic model=claude-opus-5` | 命令行方式，参数有补全 |

`<leader>am` / `<leader>aM` 的菜单是常用模型清单：DeepSeek V4 Flash / Pro、
Claude Opus 5 / Sonnet 5 / Haiku 4.5（便宜快速）。

> Claude 5 系适配说明：插件 v19 内置模型列表只到 Opus 4.8，配置里把
> claude-opus-5 / claude-sonnet-5 合并进了 choices（其余内置模型保留，
> `ga` 里都能选到）；这批模型不带 temperature、支持 effort 五档，
> 思考摘要的显示也做了修补。

**界面**：聊天窗口为右侧垂直分栏，宽 45%、全高；显示 token 用量与思考内容（默认折叠）；
AI 修改代码时提供 diff 视图供确认；回复语言为简体中文。

**三种交互方式**：

1. **Chat**（`<leader>an` / `<leader>ac`）：多轮对话，支持 `/explain`、
   `/fix`、`/tests`、`/commit` 等 slash 命令；聊天 buffer 本质是 Markdown，
   可补全 LaTeX 公式
2. **Inline**（`<leader>ai`）：对当前位置或选区直接生成 / 改写代码，
   以 diff 形式确认后应用
3. **动作面板**（`<leader>aa`）：浏览全部预设动作的菜单

### 6.9 Markdown 渲染与浏览器预览

**Buffer 内渲染**：`lua/plugins/markdown.lua`（render-markdown + mini.icons）

- 作用文件类型：`markdown` 与 `codecompanion`
- **普通 / 命令 / 终端模式渲染，插入模式显示原文**，编辑所见即所得不打架；
  CodeCompanion 聊天窗口是例外——**所有模式（含插入模式）保持渲染**，
  只有正在编辑的行恢复为原文
- 光标所在行始终显示原始 Markdown（anti-conceal），方便修改语法
- 渲染项：标题图标（󰲡~󰲫，需 Nerd Font）、代码块（块宽 + 右边距）、
  圆角管道表格、LaTeX 公式
- sign column 图标全局关闭，保持界面干净
- 渲染依赖的 `conceallevel = 2` 仅对 markdown / org / codecompanion 局部设置
  （`UserConceal` 自动命令组，同时设 `concealcursor = "nc"`：普通 / 命令模式
  隐藏语法、插入模式显示原文），不影响代码文件

**浏览器实时预览**：`lua/plugins/markdown-preview.lua`，快捷键 `<leader>mp`
（仅 Markdown 文件内生效）。与 render-markdown 互补：后者在 buffer 内做视觉
渲染，本插件在浏览器生成实时页面（编辑自动刷新、同步滚动），适合检查最终
排版、演示与分享：

- 页面主题为 dark，用系统默认浏览器打开；打开后命令行会回显预览 URL 方便复制
- 切换到其他 buffer 时自动关闭对应预览页
- **退出 Neovim 后浏览器页面保留为静态快照**（配置在 `VimLeavePre` 清除了
  插件注册的页面关闭回调；此后刷新失效属正常）
- 前端依赖（插件 `app/` 目录的 Node 服务）由 `plugins/init.lua` 的
  `PackChanged` 钩子在插件安装 / 更新后自动执行 `npm install`，需要系统有
  Node.js；失败时可手动执行 `:call mkdp#util#install()`

### 6.10 Org mode 任务管理

位置：`lua/plugins/orgmode.lua`

与 Obsidian 的**分工**：Obsidian 管 Markdown 知识笔记（`~/Documents/notes`），
Org mode 管任务与日程（`~/Documents/org`），两套文件互不干扰。

**目录约定**：

| 项目 | 值 |
|------|-----|
| Org 文件目录 | `~/Documents/org`（启动时自动创建） |
| Agenda 扫描范围 | 该目录下所有 `.org` 文件 |
| Capture 默认文件 | `~/Documents/org/refile.org` |

**首次启动**：插件自动克隆并用系统 C 编译器（cc / gcc）编译 Org 专用的
Treesitter parser（终端显示 "Tree-sitter grammar installed!"，仅需一次）。
Org 文件的高亮与折叠由插件自身的 ftplugin 管理，不占用
`treesitter.lua` 的 parser 列表，两者互不影响。

**快速上手**：

1. `<leader>oc` 打开 Capture 菜单，按 `t` 选 Task 模板，写完按 `<C-c>` 保存
   （内容存入 `refile.org`；想放弃按 `<leader>ok`）
2. 在任意 `.org` 文件中写 `* TODO 任务标题`，光标在标题上按 `cit`
   循环切换 TODO → DONE
3. `<leader>ois` / `<leader>oid` 给任务加 SCHEDULED（计划何时做）/
   DEADLINE（何时必须完成）日期
4. `<leader>oa` 打开 Agenda 菜单：按 `a` 看本周议程、`t` 看全部待办、
   `m` 按标签过滤、`s` 全文搜索
5. 忘记按键时在 org buffer 内按 `g?`，调出插件内置的完整按键帮助

**核心概念**：

- **TODO 状态**：`TODO → NEXT → HOLD → WAITING → DONE → CANCELLED`；
  `cit` 弹出快速选择菜单（按 `t` / `n` / `h` / `w` / `d` / `c` 直达，
  `ciT` 仍是逐个后退），切换为 DONE / CANCELLED 时自动记录完成时间
  （`org_log_done = 'time'`）。`HOLD` 用于被打断、暂时挂起的任务，
  `WAITING` 用于卡在别人身上的任务，二者与"还没开始的 TODO"区分开
- **日期**：支持重复周期写法，如 `<2026-08-13 Thu +1w>` 表示每周重复；
  Agenda 依此把任务排到未来各天
- **折叠**：打开文件默认只显示顶层标题（`org_startup_folded = 'overview'`），
  `<Tab>` 展开当前标题，`<S-Tab>` 循环全文折叠级别
- **折行与链接显示**：org 文件关闭了自动折行（`wrap = false`，长行向右延伸、
  靠水平滚动查看），避免长标题与中英文混排在窗口边缘拆成难看的多行；
  链接平时隐藏语法、只显示带下划线的描述文字，插入模式恢复原文
- **Refile**（`<leader>or`）：把当前标题移动到其他文件或标题下，
  配合 Capture 实现"先速记、后归档"的 GTD 流程
- **归档**（`<leader>o$`）：把已完成的子树移入同名 `_archive` 文件，
  保持主文件清爽
- **计时（Clocking）**：`<leader>oxi` 开始计时、`<leader>oxo` 结束、
  `<leader>oxq` 取消这段计时、`<leader>oxj` 跳回正在计时的任务；
  全局只有一个时钟，在别的任务上再按 `<leader>oxi` 会自动停掉上一个，
  所以"中断当前任务去做别的"直接切过去按一次即可。
  计时中状态栏右侧显示 `󰅐 已用时长 任务名`，Agenda 里按 `R` 看工时统计

**内置 LSP**（实验性）：插件自带的纯 Lua server，为 org buffer 提供链接、
标签、TODO 关键字等补全，经 blink.cmp 的 `lsp` 源自动生效；
不需要时删除 `orgmode.lua` 末尾的 `vim.lsp.enable("org")` 即可。

**导出**：org 文件内按 `<leader>oe` 打开导出菜单，HTML / PDF 等格式
需系统安装 pandoc 或 emacs，不用导出功能可忽略。

**官方文档**：Neovim 内执行 `:Org help`，或访问 <https://nvim-orgmode.github.io>。

> 日常使用教程（工作流 + 11 个使用场景）见 [orgmode.md](orgmode.md)。

### 6.11 which-key 快捷键提示

位置：`lua/plugins/which-key.lua`

按下 `<leader>`（空格）或其他前缀键后稍作停留，自动弹出可选快捷键面板。
所有自定义快捷键都写有 `desc` 描述，面板中显示可读说明而非原始命令。

**布局**：`preset = "modern"`——带边框与居中标题的浮窗（边框为 single，
与全局 `winborder` 一致），底部显示翻页与滚动按键提示；
面板内可用 `<C-d>` / `<C-u>` 滚动。

**分组标签**：`<leader>` 的子前缀都有名字与图标，按一下空格即可纵览全部功能：

| 前缀 | 分组 |
|------|------|
| `<leader>f` | 查找 Find |
| `<leader>g` | Git |
| `<leader>a` | AI 助手 |
| `<leader>o` | 笔记与 Org |
| `<leader>m` | Markdown 元素 |
| `<leader>c` | 代码 Code |
| `<leader>s` | 参数交换 Swap |
| `<leader>z` | 折叠 Folds |
| `<leader>u` | 开关 Toggle |

普通模式的 `s` 前缀（mini.surround）同样标注为"环绕 Surround"。
分组项只给面板节点命名，不创建任何映射；想调整分组名或图标，
改 `which-key.lua` 的 `spec` 表即可。

**图标**：条目图标按 `desc` 关键词自动匹配（不区分大小写），内置规则已覆盖
find / search / git / code / toggle / buffer / window / diagnostic / format 等，
另有 grep / obsidian / org 三条补充规则；分组图标取自 mini.icons 的
filetype 图标（Git 󰊢、Markdown 󰍔、Org ），需 Nerd Font。

**内置前缀提示**：插件同时为 Neovim 默认按键生成说明——`g`、`z`、`]` / `[`、
`<C-w>` 窗口操作、操作符后的文本对象等；按 `'` 列出标记、`"` 列出寄存器、
`z=` 列出拼写建议。

**其他**：面板在按键停顿 200ms 后出现；手动调出用 `:WhichKey`（列全部）
或 `:WhichKey <leader>o`（指定前缀）；怀疑映射配置有误时执行
`:checkhealth which-key`。

### 6.12 mini 编辑增强与界面

位置：`lua/plugins/mini.lua`。
mini.nvim 是一个包含数十个独立模块的插件，这里按需 setup 启用其中的 6 个：

| 模块 | 功能 |
|------|------|
| mini.pairs | 括号、引号自动配对闭合 |
| mini.surround | 环绕符号的添加 / 删除 / 替换 / 跳转（按键见 5.11 节） |
| mini.comment | 注释（`gcc` / `gc`，Markdown 代码块内自动识别块内语言注释符） |
| mini.align | 可视模式交互对齐（`ga`），维护 Markdown 管道表格 |
| mini.statusline | 状态栏（自定义布局与配色，见下文） |
| mini.tabline | buffer 标签页：两个以上 buffer 时显示，`[b` / `]b` 或鼠标点击切换 |

**状态栏定制**（mini.statusline）：布局为
`模式 → git 分支 + 诊断计数 → 文件名 → Org 计时 → filetype → 行列位置`，
模式段用 Catppuccin Mocha 彩色底（NORMAL 蓝 / INSERT 绿 / VISUAL 紫 /
REPLACE 红 / COMMAND 黄），内容段深灰底，非当前窗口整体灰化。
git 分支由 `UserGitBranch` 自动命令异步获取写入 `vim.b.gitsigns_head`
（新仓库显示分支名，detached HEAD 显示 `@短commit`）；配色定义在
`mini.lua` 的 `statusline_hl()`，换主题时自动重新应用。

Org 计时段（黄色高亮）只在 org clock 运行时出现，形如 `󰅐 0:23/1:00 写周报`
（`已用时长 / 预估工时 任务名`，没设 Effort 时只显示已用时长，
窗口窄于 100 列时只留时长）。取值来自 orgmode 官方的
`_G.orgmode.statusline()`，其内部有 300ms 防抖，因此可以在每次重画时调用；
clock in / out 后由 `orgmode.lua` 里的事件监听触发一次延迟重画，
静置时则由 `mini.lua` 中的 30 秒定时器推动计时数字继续跳动。

**启用更多模块**：在 `lua/plugins/mini.lua` 中加一行
`require("mini.xxx").setup({})` 即可（如 mini.files 文件管理器、
mini.operators 文本运算符、mini.sessions 会话管理等），
全部模块列表见 `:help mini.nvim`。

---

## 七、自定义指南

| 需求 | 修改位置 |
|------|----------|
| 改编辑器选项 | `lua/core/options.lua` |
| 加 / 改通用快捷键 | `lua/core/keymaps.lua` |
| 加 / 改某插件的快捷键 | `lua/plugins/` 下对应文件（就近原则） |
| 加插件 | `lua/plugins/init.lua` 清单 + 新建 `lua/plugins/xxx.lua` 配置 |
| 加语言服务器 | `lua/plugins/lsp.lua` 中 `vim.lsp.enable("xxx")` |
| 加格式化工具 | `lua/core/keymaps.lua` 的 `formatters` 表 |
| 启用更多 mini 模块 | `lua/plugins/mini.lua` 加一行 `require("mini.xxx").setup({})` |
| 加 Treesitter 语言 | `lua/plugins/treesitter.lua` 的 `treesitter_parsers` 等三张表 |
| 换 AI 模型 / 参数 | `lua/plugins/codecompanion.lua` 的 `adapters` 段 |
| 换笔记库路径 | `lua/plugins/obsidian.lua` 顶部的 `notes_path` |
| 换 Org 文件目录 | `lua/plugins/orgmode.lua` 顶部的 `org_path` |

**示例：添加一个插件**

```lua
-- 1. lua/plugins/init.lua 的 vim.pack.add({...}) 中加入：
"https://github.com/lewis6991/gitsigns.nvim",

-- 2. 新建 lua/plugins/gitsigns.lua：
require("gitsigns").setup({})

-- 3. 在 lua/plugins/init.lua 底部加入：
require("plugins.gitsigns")
```

重启 Neovim 即自动安装。

---

## 八、常见问题（FAQ）

**Q1：Python 文件按 `<leader>cf` 提示 "Formatter not installed: ruff"？**
系统未安装 ruff，执行 `sudo pacman -S ruff` 即可。配置已做防护：
工具缺失或执行失败都不会破坏 buffer 内容。

**Q2：诊断信息（错误波浪线）怎么不见了？**
本配置**默认全局关闭诊断**（`vim.diagnostic.enable(false)`）。
按 `<leader>ul` 切换显示，`gl` 随时查看当前行详情。

**Q3：which-key 不需要 setup 吗？**
只声明、不配置也能工作——which-key v3 的 plugin 文件会在启动 500ms 后
自动执行默认 setup。本配置在 `lua/plugins/which-key.lua` 中显式 setup，
是为了定制 modern 布局、图标规则与分组标签（见 6.11 节）；
显式 setup 抢先完成初始化后，默认的自动 setup 会直接跳过。

**Q4：catppuccin 主题在插件清单里找不到？**
它不是 vim.pack 管理的插件，而是 Arch 的 neovim 包自带的
`/usr/share/nvim/runtime/colors/catppuccin.vim`。换系统或发行版时，
若提示主题不存在，需改用插件方式安装（如 `catppuccin/nvim`）。

**Q5：`<leader>ff` 搜索结果里找不到某些文件？**
fzf-lua 遵循 `.gitignore` 并受 `fd`/`rg` 规则影响（本机设置了
`FZF_DEFAULT_COMMAND=fd --type f --hidden --exclude .git`）。
被 git 忽略的文件默认不会出现，这是预期行为。

**Q6：终端里怎么滚动查看历史输出？**
按 `jk` 退出终端模式进入普通模式，即可用 `hjkl`/`gg`/`G` 滚动翻页，
按 `i` 回到输入。

**Q7：启动时看到 fcitx5 相关报错或没有输入法切换？**
确认 `fcitx5-remote` 在 PATH 中（`which fcitx5-remote`）。
未安装时该功能整体静默跳过，不影响其他功能。

**Q8：在 Org 文件里按 `<leader>oo` / `<leader>ot`，为什么不是 Obsidian 的功能？**
orgmode 的快捷键是 org buffer 的**局部映射**，会覆盖同名全局映射：
org 文件内 `<leader>oo` 是"打开链接 / 日期"，`<leader>ot` 是"修改标签"；
离开 org buffer 后即恢复为 Obsidian 的全局映射。这是预期行为，
两者按文件类型各司其职（`.md` 用 Obsidian，`.org` 用 orgmode）。

**Q9：终端模式下 `<C-l>`（清屏）、`<C-k>`（删行）等按键不生效？**
`<C-h/j/k/l>` 已映射为窗口跳转且在终端模式下生效，因此不再发送给
终端里运行的程序。需要清屏时可直接输入 `clear` 命令；若希望某个键
传回终端程序，把 `lua/core/keymaps.lua` 中对应映射的模式从
`{ "n", "t" }` 改回 `"n"` 即可（终端里先按 `jk` 再跳窗）。

**Q10：搜索时不想忽略大小写怎么办？**
当前是 `ignorecase + smartcase` 组合：小写搜索词忽略大小写，
含大写字母则精确匹配。想临时精确搜索小写词，可在词尾加 `\C`
（如 `/foo\C`）；想全局改行为，见 `lua/core/options.lua` 搜索段。

**Q11：按 `<leader>mp` 没有预览 / 提示 npm 相关错误？**
浏览器预览需要 Node.js：插件安装 / 更新后会自动在其 `app/` 目录执行
`npm install`，若当时系统没有 npm 会失败。安装 Node.js 后重启 Neovim
重新触发，或手动执行 `:call mkdp#util#install()`。另外该键只在
Markdown 文件内生效，其他文件按了只弹提示。

**Q12：AI 补全（minuet）什么时候会发请求、怎么关？**
只在代码文件自动请求（停顿 400ms 后、每秒最多一次），org / markdown
等文本文件不会自动请求。DeepSeek FIM 计费很低，但介意的话随时按
`<leader>um` 关闭（等同 `:Minuet blink toggle`）；`<A-y>` 手动唤起
始终可用。

---

## 九、备份与回滚

重构前的原始单文件配置完整备份于：

```
~/.config/nvim-backup-20260811-193741/
```

如需整体回滚：

```bash
rm -rf ~/.config/nvim
cp -a ~/.config/nvim-backup-20260811-193741 ~/.config/nvim
```

确认新配置稳定使用后，可自行删除备份目录。

---

> 配置即文档：每个 Lua 文件顶部都有职责说明，关键分支均有中文注释，
> 配合本手册的"修改位置"表格即可快速定位任何功能。
