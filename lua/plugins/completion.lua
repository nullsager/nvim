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

  -- 输入函数参数时显示签名，并高亮当前正在填写的参数
  signature = {
    enabled = true,
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

      -- 编写独立的 LaTeX 文件时使用；omni 接 VimTeX 的补全：
      -- \ref{ / \cite{ 补标签和文献，\usepackage{ 补宏包，\begin{ 补环境名
      tex = {
        inherit_defaults = true,
        "latex",
        "omni",
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
        -- AI 候选总排在列表末尾。它们比 LSP 晚约 1 秒才到，排在前面会把已有
        -- 候选往下挤：<C-n> 选中的项被挤出前 10 名时 blink 会直接取消选中，
        -- 回车就变成了换行。
        score_offset = -100,
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

-- 选中后冻结补全列表。
-- 晚到的结果会让 blink 取消已选中的项，回车就变成了换行。有两种情况：
--   1. 异步源（minuet AI 候选，约 1 秒后才到）重排列表，选中项被挤出前 10 名；
--   2. 打字快、LSP 慢时，上一个请求的结果带着发请求时的旧 context 回来，
--      关键字长度和当前不同，blink 误判为"又打字了"而取消选中。
-- 这里改成：晚到的结果一律按当前 context 处理；用 <C-n>/<C-p> 主动选中某项后，
-- 只要关键字没变（还没继续打字），就不再刷新列表。继续打字后列表照常更新，
-- 晚到的候选也会出现。
-- 注意：这里替换的是 blink 内部函数 list.show（基于 blink.cmp 1.10），
-- 升级 blink 后如果补全异常，先检查这段。
local blink_list = require("blink.cmp.completion.list")
local blink_trigger = require("blink.cmp.completion.trigger")
local blink_list_show = blink_list.show

local function same_keyword(a, b)
  return a ~= nil
    and b ~= nil
    and a.id == b.id
    and a.bounds.start_col == b.bounds.start_col
    and a.bounds.length == b.bounds.length
end

blink_list.show = function(context, items_by_source)
  local live = blink_trigger.context
  if live ~= nil and live.id == context.id then
    context = live
  end

  if blink_list.is_explicitly_selected and same_keyword(blink_list.context, context) then
    return
  end
  return blink_list_show(context, items_by_source)
end
