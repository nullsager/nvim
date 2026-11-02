-- Markdown 渲染：render-markdown + mini.icons

require("mini.icons").setup()

require("render-markdown").setup({
  enabled = true,

  file_types = {
    "markdown",
    "codecompanion",
  },

  -- 普通 Markdown 默认只在普通模式、命令模式等状态下渲染。
  -- 插入模式会恢复为原始 Markdown，方便编辑。
  render_modes = {
    "n",
    "c",
    "t",
  },

  -- 普通模式下光标所在行也保持渲染，阅读时不会被源码打断。
  -- 需要看原始 Markdown 时进入插入模式即可（render_modes 不含 "i"）。
  anti_conceal = {
    enabled = false,
  },

  -- 全局关闭 sign column 中的 Markdown 图标。
  sign = {
    enabled = false,
  },

  code = {
    width = "block",
    right_pad = 1,
  },

  heading = {
    icons = {
      "󰲡 ",
      "󰲣 ",
      "󰲥 ",
      "󰲧 ",
      "󰲩 ",
      "󰲫 ",
    },
  },

  pipe_table = {
    preset = "round",
  },

  -- 不渲染 LaTeX 公式，直接看源码（该模块默认开启，必须显式关闭）
  latex = {
    enabled = false,
  },

  overrides = {
    filetype = {
      codecompanion = {
        -- CodeCompanion Chat 在所有模式下保持渲染。
        render_modes = true,

        -- 推荐保留 true：
        -- 输入或修改当前行时显示原始 Markdown。
        anti_conceal = {
          enabled = true,
        },

        sign = {
          enabled = false,
        },
      },
    },
  },
})

-- ---------------------------------------------------------
-- 配色
-- ---------------------------------------------------------
-- options.lua 加载的是 Neovim 自带的 catppuccin（Vim 移植版），它没给 Markdown
-- 和 render-markdown 定义颜色：六级标题同一种蓝，标题背景借用 diff 的红绿，
-- callout 是 Vim 默认的纯红纯橙，==高亮== 和行内代码长得一样。
-- 这里按 catppuccin Mocha 调色板补上；换了别的主题就不生效，交还给主题。
local function set_highlights()
  if vim.g.colors_name ~= "catppuccin" or vim.o.background ~= "dark" then
    return
  end
  local function hl(name, val)
    vim.api.nvim_set_hl(0, name, val)
  end

  -- 标题：每级一种颜色（插入模式下的源码也跟着变），背景是该颜色与底色按 20% 混合
  local headings = {
    { "#f38ba8", "#493446" }, -- red
    { "#fab387", "#4a3c40" }, -- peach
    { "#f9e2af", "#4a4548" }, -- yellow
    { "#a6e3a1", "#394545" }, -- green
    { "#74c7ec", "#2f4054" }, -- sapphire
    { "#b4befe", "#3c3e58" }, -- lavender
  }
  for i, c in ipairs(headings) do
    hl("@markup.heading." .. i .. ".markdown", { fg = c[1], bold = true })
    hl("RenderMarkdownH" .. i .. "Bg", { bg = c[2] })
  end

  -- 行内代码与 ==高亮== 区分开：前者青色字 + 浅底，后者黄色字 + 黄底
  hl("@markup.raw.markdown_inline", { fg = "#94e2d5" })
  hl("RenderMarkdownCodeInline", { bg = "#313244" })
  hl("RenderMarkdownInlineHighlight", { fg = "#f9e2af", bg = "#4a4548" })

  -- 列表符号与链接
  hl("@markup.list.markdown", { fg = "#89dceb" })
  hl("RenderMarkdownBullet", { fg = "#89dceb" })
  hl("RenderMarkdownUnchecked", { fg = "#7f849c" })
  hl("RenderMarkdownChecked", { fg = "#a6e3a1" })
  hl("@markup.link.label.markdown_inline", { fg = "#89b4fa" })

  -- 引用：竖线和正文都退到灰色，不再整段粉色
  hl("RenderMarkdownQuote", { fg = "#7f849c" })
  hl("@markup.quote.markdown", { fg = "#a6adc8" })

  -- 表格边框调暗，突出内容；表头那一圈稍亮一点
  hl("RenderMarkdownTableHead", { fg = "#7f849c" })
  hl("RenderMarkdownTableRow", { fg = "#585b70" })

  -- callout：note/info 蓝、tip/success 绿、important/example 紫、warning/question 黄、danger/bug 红
  hl("RenderMarkdownInfo", { fg = "#89dceb" })
  hl("RenderMarkdownSuccess", { fg = "#a6e3a1" })
  hl("RenderMarkdownHint", { fg = "#cba6f7" })
  hl("RenderMarkdownWarn", { fg = "#f9e2af" })
  hl("RenderMarkdownError", { fg = "#f38ba8" })
end

set_highlights()

local group = vim.api.nvim_create_augroup("UserMarkdown", { clear = true })

-- :colorscheme 会清空自定义高亮，重新加载主题后再补一次
vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  desc = "Markdown: catppuccin highlights",
  callback = set_highlights,
})

-- 长列表项折行时，续行与正文对齐，而不是退回到 "- " 下面
-- （列表格式 formatlistpat 由内置 markdown ftplugin 设置，breakindent 见 options.lua）
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "markdown",
  desc = "Markdown: align wrapped list items",
  callback = function()
    vim.opt_local.breakindentopt = "list:-1"
  end,
})
