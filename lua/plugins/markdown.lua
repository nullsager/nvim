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

  latex = {
    enabled = true,
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
