-- AI 助手：CodeCompanion（DeepSeek + Anthropic Claude）
--
-- 需要的环境变量（写在 ~/.zshrc 里，然后重开终端）：
--   DEEPSEEK_API_KEY    DeepSeek 官方 key
--   ANTHROPIC_API_KEY   Anthropic 官方 key
--
-- 当前 DeepSeek 默认模型。官方提供稳定的 `deepseek-flash` 别名；
-- 也可设置 DEEPSEEK_MODEL 固定到某个具体模型 ID。
-- 官方稳定别名 `deepseek-flash` 会指向当前 Flash 版本。
local DEEPSEEK_MODEL = vim.env.DEEPSEEK_MODEL or "deepseek-flash"

-- 切换模型的几种方式：
--   1. chat 窗口里按 `ga`   —— 插件内置，只影响当前这个对话
--   2. <leader>am           —— 改默认模型，chat / inline / cmd 一起生效
--   3. <leader>aM           —— 用选定的模型新开一个 chat，不动默认值
--   4. :CodeCompanionChat adapter=anthropic model=claude-opus-5（命令行有补全）

local codecompanion = require("codecompanion")
local adapter_utils = require("codecompanion.adapters.utils")
local anthropic_base = require("codecompanion.adapters.http.anthropic")

-- ---------------------------------------------------------
-- Anthropic 适配说明
--
-- 插件 v19 内置的模型列表里还没有 Claude 5 系（只到 Opus 4.8 / Fable 5），
-- 下面的 extend 会把 claude-opus-5 / claude-sonnet-5 合并进内置的 choices，
-- 其余模型（Sonnet 4.6、Haiku 4.5 等）仍然保留，`ga` 里都能选到。
-- ---------------------------------------------------------

-- 这批模型已经删掉了 temperature / top_k 参数，带上会直接返回 400；
-- 同时它们支持 output_config.effort 的全部五个档位（low ~ max）。
local MODERN_CLAUDE = {
  ["claude-opus-5"] = true,
  ["claude-sonnet-5"] = true,
  ["claude-opus-4-8"] = true,
  ["claude-opus-4-7"] = true,
  ["claude-fable-5"] = true,
}

local function is_modern_claude(self)
  local model = adapter_utils.model(self)
  return type(model) == "string" and MODERN_CLAUDE[model] == true
end

codecompanion.setup({
  -- 只覆盖真正需要修改的参数。
  -- 模型列表、模型能力和 API 地址都使用插件内置配置。
  adapters = {
    http = {
      -- 说明：这里是直接替换预设条目，而不是用 `adapters.http.extend`。
      -- extend 里的补丁是在 adapter 解析的最后一步才合并进去的，会把
      -- `:CodeCompanionChat model=xxx` 显式指定的模型重新覆盖成 default，
      -- 用函数形式重新定义 adapter 就没有这个问题。
      deepseek = function()
        local adapter = require("codecompanion.adapters").extend("deepseek", {
          schema = {
            -- DeepSeek 默认模型；可用 DEEPSEEK_MODEL 覆盖
            model = {
              default = DEEPSEEK_MODEL,
            },

            -- 默认启用思考模式
            ["thinking.type"] = {
              default = "enabled",
            },

            -- DeepSeek V4 系列支持 high 和 max
            reasoning_effort = {
              default = "max",
            },

            -- 限制单次响应的最大输出长度
            -- max_tokens = {
            --   default = 8192,
            -- },

            -- 思考模式启用时，temperature 通常不会生效
            temperature = {
              default = 0.4,
            },
          },
        })

        -- 保留插件内置模型，并把当前/环境变量指定的模型加入菜单。
        -- 这样新模型即使尚未被 CodeCompanion 内置，也能直接使用。
        local choices = adapter.schema.model.choices
        choices["deepseek-flash"] = {
          formatted_name = "DeepSeek Flash（自动跟随当前版本）",
          meta = { context_window = 1048576 },
          opts = { can_reason = true, can_use_tools = true },
        }
        if DEEPSEEK_MODEL ~= "deepseek-flash" then
          choices[DEEPSEEK_MODEL] = {
            formatted_name = DEEPSEEK_MODEL,
            meta = { context_window = 1048576 },
            opts = { can_reason = true, can_use_tools = true },
          }
        end
        return adapter
      end,

      anthropic = function()
        return require("codecompanion.adapters").extend("anthropic", {
          schema = {
            model = {
              -- Anthropic 默认模型
              default = "claude-opus-5",

              -- 只是往内置 choices 里“加”条目，不会覆盖已有模型
              choices = {
                ["claude-opus-5"] = {
                  formatted_name = "Claude Opus 5",
                  meta = { context_window = 1000000, max_tokens = 128000 },
                  -- can_reason = true -> 默认发送 thinking = { type = "adaptive" }
                  opts = { can_reason = true, can_manage_context = true, has_vision = true },
                },
                ["claude-sonnet-5"] = {
                  formatted_name = "Claude Sonnet 5",
                  meta = { context_window = 1000000, max_tokens = 128000 },
                  opts = { can_reason = true, can_manage_context = true, has_vision = true },
                },
              },
            },

            -- 5 系 / Opus 4.7+ 已移除 temperature，发过去会 400，这里直接不发
            temperature = {
              enabled = function(self)
                return not is_modern_claude(self)
              end,
            },

            -- 思考深度 + 总体 token 预算（对应 API 的 output_config.effort）
            -- low 最省；high 是默认；xhigh 写代码最合适；max 最贵最认真
            ["output_config.effort"] = {
              order = 10,
              mapping = "parameters",
              type = "enum",
              optional = true,
              default = "high",
              choices = { "low", "medium", "high", "xhigh", "max" },
              desc = "Controls thinking depth and overall token spend.",
              enabled = is_modern_claude,
            },
          },

          handlers = {
            -- 内置 handler 只发 thinking = { type = "adaptive" }，
            -- 而 5 系模型的 display 默认是 "omitted"（思考内容返回空字符串）。
            -- 补一个 display = "summarized"，chat 窗口里才看得到思考摘要。
            form_parameters = function(self, params, messages)
              params = anthropic_base.handlers.form_parameters(self, params, messages)
              if params.thinking and params.thinking.type == "adaptive" then
                params.thinking.display = "summarized"
              end
              return params
            end,
          },
        })
      end,

      opts = {
        -- 切换 adapter 时显示模型选择菜单
        show_model_choices = true,
      },
    },
  },

  interactions = {
    chat = {
      adapter = {
        name = "deepseek",
        model = DEEPSEEK_MODEL,
      },
    },

    inline = {
      adapter = {
        name = "deepseek",
        model = DEEPSEEK_MODEL,
      },
    },

    cmd = {
      adapter = {
        name = "deepseek",
        model = DEEPSEEK_MODEL,
      },
    },
  },

  display = {
    chat = {
      -- 显示思考内容
      show_reasoning = true,

      -- 默认折叠思考内容，避免占用太多空间
      fold_reasoning = true,

      -- 显示 token 数量
      show_token_count = true,

      -- render-markdown 已经负责标题分隔样式
      show_header_separator = false,

      window = {
        layout = "vertical",
        width = 0.45,
        full_height = true,
      },
    },

    diff = {
      enabled = true,
    },
  },

  opts = {
    log_level = "ERROR",
    language = "Simplified Chinese",

    -- 允许把当前代码、选区和文件内容发送给模型
    send_code = true,
  },
})

-- ---------------------------------------------------------
-- 模型切换
-- ---------------------------------------------------------

-- 常用模型清单，只影响 <leader>am / <leader>aM 的选择菜单；
-- `ga` 仍然可以选到 adapter 里的全部模型。
local MODELS = {
  { adapter = "deepseek", model = "deepseek-flash", label = "DeepSeek Flash（自动跟随当前版本）" },
  { adapter = "deepseek", model = "deepseek-v4-pro", label = "DeepSeek V4 Pro" },
  { adapter = "anthropic", model = "claude-opus-5", label = "Claude Opus 5" },
  { adapter = "anthropic", model = "claude-sonnet-5", label = "Claude Sonnet 5" },
  { adapter = "anthropic", model = "claude-haiku-4-5", label = "Claude Haiku 4.5（便宜快速）" },
}

if DEEPSEEK_MODEL ~= "deepseek-flash" then
  table.insert(MODELS, 1, { adapter = "deepseek", model = DEEPSEEK_MODEL, label = "DeepSeek（环境变量指定）" })
end

local function pick_model(on_choice)
  vim.ui.select(MODELS, {
    prompt = "CodeCompanion 模型",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice then
      on_choice(choice)
    end
  end)
end

-- 修改 chat / inline / cmd 的默认 adapter 与模型（当前会话内有效）
local function set_default_model(choice)
  local cc_config = require("codecompanion.config")
  for _, interaction in ipairs({ "chat", "inline", "cmd" }) do
    cc_config.interactions[interaction].adapter = {
      name = choice.adapter,
      model = choice.model,
    }
  end

  -- 如果当前缓冲区正好是一个 chat，顺手把它也切过去
  local chat = require("codecompanion.interactions.chat").buf_get_chat(0)
  if chat and chat:change_adapter(choice.adapter) then
    chat:change_model({ model = choice.model })
  end

  vim.notify("CodeCompanion 默认模型：" .. choice.label)
end

-- ---------------------------------------------------------
-- 快捷键
-- ---------------------------------------------------------

-- 打开动作面板
vim.keymap.set({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>", {
  noremap = true,
  silent = true,
  desc = "CodeCompanion Actions",
})

-- 打开或隐藏当前 Chat
vim.keymap.set("n", "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", {
  noremap = true,
  silent = true,
  desc = "Toggle CodeCompanion Chat",
})

-- 打开一个新的 Chat
vim.keymap.set("n", "<leader>an", "<cmd>CodeCompanionChat<cr>", {
  noremap = true,
  silent = true,
  desc = "New CodeCompanion Chat",
})

-- 普通模式：打开 Inline 输入窗口
-- 可用于要求 AI 生成或修改当前位置附近的代码
vim.keymap.set("n", "<leader>ai", "<cmd>CodeCompanion<cr>", {
  noremap = true,
  silent = true,
  desc = "CodeCompanion Inline",
})

-- 可视模式：对选中的代码执行 Inline 请求
vim.keymap.set("v", "<leader>ai", "<cmd>CodeCompanion<cr>", {
  noremap = true,
  silent = true,
  desc = "CodeCompanion Inline Selection",
})

-- 把选中的代码添加到当前 Chat
vim.keymap.set("v", "<leader>ad", "<cmd>CodeCompanionChat Add<cr>", {
  noremap = true,
  silent = true,
  desc = "Add Selection to CodeCompanion Chat",
})

-- 解释选中的代码
vim.keymap.set("v", "<leader>ae", "<cmd>CodeCompanion /explain<cr>", {
  noremap = true,
  silent = true,
  desc = "Explain Selected Code",
})

-- 修复选中的代码
vim.keymap.set("v", "<leader>af", "<cmd>CodeCompanion /fix<cr>", {
  noremap = true,
  silent = true,
  desc = "Fix Selected Code",
})

-- 为选中的代码生成测试
vim.keymap.set("v", "<leader>at", "<cmd>CodeCompanion /tests<cr>", {
  noremap = true,
  silent = true,
  desc = "Generate Tests",
})

-- 切换默认模型（chat / inline / cmd 一起改）
vim.keymap.set("n", "<leader>am", function()
  pick_model(set_default_model)
end, {
  silent = true,
  desc = "Switch Default AI Model",
})

-- 用指定模型新建一个 Chat（不改默认值）
vim.keymap.set("n", "<leader>aM", function()
  pick_model(function(choice)
    vim.cmd(("CodeCompanionChat adapter=%s model=%s"):format(choice.adapter, choice.model))
  end)
end, {
  silent = true,
  desc = "New Chat With Model",
})

-- 可选：生成 Git commit message
vim.keymap.set("n", "<leader>ag", "<cmd>CodeCompanion /commit<cr>", {
  noremap = true,
  silent = true,
  desc = "Generate Git Commit Message",
})
