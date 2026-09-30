-- AI 行内补全：minuet-ai.nvim
-- 与 CodeCompanion 分工：CodeCompanion 是主动触发的对话 / Inline 改写，
-- minuet 是随打字出现的 AI 补全候选（DeepSeek FIM 接口，经 blink.cmp 补全源）。
--
-- 复用 CodeCompanion 的 DEEPSEEK_API_KEY。DeepSeek 已是 openai_fim_compatible
-- 的内置默认 provider（端点 https://api.deepseek.com/beta/completions）。
-- 使用官方稳定的 deepseek-flash 别名；也可用 DEEPSEEK_MODEL 覆盖默认模型，
-- 或用 DEEPSEEK_FIM_MODEL 为 FIM 接口单独指定模型。

local deepseek_model = vim.env.DEEPSEEK_FIM_MODEL or vim.env.DEEPSEEK_MODEL or "deepseek-flash"
--
-- 费用控制：
--   - enable_predicates 把自动补全限制在代码文件；org / markdown 等文本
--     文件不自动请求（<A-y> 手动唤起不受限制）
--   - throttle 1000ms / debounce 400ms（默认值）：最多每秒一次请求
--   - 总开关：<leader>um 或 :Minuet blink toggle

local auto_trigger_filetypes = {
  "c", "cpp",
  "python",
  "lua",
  "sh", "bash",
  "vim",
  "json", "yaml", "toml",
  "html", "css", "javascript", "typescript", "tsx",
}

require("minuet").setup({
  provider = "openai_fim_compatible",
  provider_options = {
    openai_fim_compatible = {
      name = "deepseek",
      model = deepseek_model,
      api_key = "DEEPSEEK_API_KEY",
      optional = {
        max_tokens = 256,
        top_p = 0.9,
      },
    },
  },

  -- 只在代码文件自动触发；函数返回 false 时不发起请求
  enable_predicates = {
    function(bufnr)
      return vim.tbl_contains(auto_trigger_filetypes, vim.bo[bufnr or 0].filetype)
    end,
  },
})

-- AI 补全总开关（which-key 落在 <leader>u「开关 Toggle」组）
vim.keymap.set("n", "<leader>um", "<cmd>Minuet blink toggle<cr>", {
  desc = "Toggle Minuet AI completion",
})
