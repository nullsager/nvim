-- 自动补全：blink.cmp
-- 另含 minuet-ai 的接入（AI 行内补全，配置见 lua/plugins/minuet.lua）。

-- <A-y> 手动唤起 minuet AI 补全（只显示 AI 候选）；
-- minuet 未就绪时不绑定动作，保证补全本身不受影响。
local minuet_ok, minuet = pcall(require, "minuet")
local minuet_manual = minuet_ok and minuet.make_blink_map and minuet.make_blink_map()
  or function() end

require("blink.cmp").setup({
  keymap = {
    preset = "default",

    -- 确认补全
    ["<CR>"] = { "accept", "fallback" },

    -- 手动唤起 AI 补全
    ["<A-y>"] = minuet_manual,

    -- 手动打开补全菜单
    ["<C-Space>"] = {
      "show",
      "show_documentation",
      "hide_documentation",
    },

    -- snippet 占位符跳转
    ["<Tab>"] = { "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "snippet_backward", "fallback" },
  },

  completion = {
    list = {
      selection = {
        preselect = false,
        auto_insert = false,
      },
    },

    documentation = {
      auto_show = true,
      auto_show_delay_ms = 300,
    },

    menu = {
      draw = {
        columns = {
          { "label", "label_description", gap = 1 },
          { "kind_icon", "kind", gap = 1 },
          { "source_name" },
        },
      },
    },
  },

  sources = {
    -- 默认补全源（minuet：AI 行内补全，只在代码文件自动触发，见 plugins/minuet.lua）
    default = {
      "lsp",
      "path",
      "snippets",
      "buffer",
      "minuet",
    },

    -- 只在 Markdown 中额外启用 LaTeX 补全源
    per_filetype = {
      markdown = {
        inherit_defaults = true,
        "latex",
      },

      -- 如果希望 CodeCompanion Chat 中也能补全公式，可以保留
      codecompanion = {
        inherit_defaults = true,
        "latex",
      },

      -- 编写独立的 LaTeX 文件时使用
      tex = {
        inherit_defaults = true,
        "latex",
      },
      plaintex = {
        inherit_defaults = true,
        "latex",
      },
    },

    providers = {
      minuet = {
        name = "minuet",
        module = "minuet.blink",
        async = true,
        timeout_ms = 3000, -- 与 minuet 的 request_timeout（3 秒）对齐
      },

      latex = {
        name = "LaTeX",
        module = "blink-cmp-latex",

        opts = {
          -- true：输入 \alpha，接受后插入 \alpha
          -- false：输入 \alpha，接受后插入 Unicode 字符 α
          --
          -- 你是在编写 Markdown LaTeX 公式，因此应该设为 true
          insert_command = true,
        },

        -- 提升 LaTeX 补全项优先级
        score_offset = 100,
      },

      snippets = {
        opts = {
          -- friendly-snippets 默认会被 blink.cmp 自动加载
          friendly_snippets = true,

          -- 让 Markdown 同时使用 tex 的 snippets
          extended_filetypes = {
            markdown = { "tex" },
            codecompanion = { "markdown", "tex" },
          },
        },
      },
    },
  },
})
