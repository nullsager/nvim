-- AI 助手：CodeCompanion（DeepSeek）
--
-- 需要环境变量 DEEPSEEK_API_KEY（写在 ~/.config/secrets.env 里，由 ~/.zshrc source，然后重开终端）。
-- 默认模型是官方稳定别名 `deepseek-flash`，会自动指向当前 Flash 版本；
-- 也可设置 DEEPSEEK_MODEL 固定到某个具体模型 ID。
--
-- 切换模型的几种方式：
--   1. chat 窗口里按 `ga`   —— 插件内置，只影响当前这个对话
--   2. <leader>am           —— 改默认模型，chat / inline / cmd 一起生效
--   3. <leader>aM           —— 用选定的模型新开一个 chat，不动默认值
--   4. :CodeCompanionChat adapter=deepseek model=deepseek-v4-pro

local adapters = require("codecompanion.adapters")

local DEEPSEEK_MODEL = vim.env.DEEPSEEK_MODEL or "deepseek-flash"

-- 模型菜单，`ga` 和 <leader>am / <leader>aM 共用。
-- 插件内置清单里的 deepseek-v4-flash / deepseek-chat / deepseek-reasoner
-- 现在都被 API 路由到 deepseek-flash，这里只列实际不同的模型。
local MODELS = {
  ["deepseek-flash"] = "DeepSeek Flash（自动跟随当前版本）",
  ["deepseek-v4-pro"] = "DeepSeek V4 Pro",
}
MODELS[DEEPSEEK_MODEL] = MODELS[DEEPSEEK_MODEL] or DEEPSEEK_MODEL

require("codecompanion").setup({
  adapters = {
    http = {
      -- 用函数重新定义 deepseek，而不是 `adapters.http.extend`：
      -- extend 的补丁在 adapter 解析的最后一步才合并，会把
      -- `:CodeCompanionChat model=xxx` 显式指定的模型覆盖回 default。
      -- 其余参数沿用插件默认：思考模式开启，reasoning_effort = "max"。
      deepseek = function()
        local adapter = adapters.extend("deepseek", {
          schema = { model = { default = DEEPSEEK_MODEL } },
        })
        local choices = {}
        for model, name in pairs(MODELS) do
          choices[model] = {
            formatted_name = name,
            meta = { context_window = 1048576 },
            opts = { can_reason = true, can_use_tools = true },
          }
        end
        adapter.schema.model.choices = choices
        return adapter
      end,
    },
  },

  interactions = {
    chat = { adapter = "deepseek" },
    inline = { adapter = "deepseek" },
    cmd = { adapter = "deepseek" },
  },

  display = {
    chat = {
      window = { width = 0.45 },
    },
  },

  opts = {
    language = "Simplified Chinese",
  },
})

-- ---------------------------------------------------------
-- 模型切换
-- ---------------------------------------------------------

local function pick_model(on_choice)
  local models = vim.tbl_keys(MODELS)
  table.sort(models)
  vim.ui.select(models, {
    prompt = "DeepSeek 模型",
    format_item = function(model)
      return MODELS[model]
    end,
  }, function(model)
    if model then
      on_choice(model)
    end
  end)
end

-- 修改 chat / inline / cmd 的默认模型（当前会话内有效）
local function set_default_model(model)
  local cc_config = require("codecompanion.config")
  for _, interaction in ipairs({ "chat", "inline", "cmd" }) do
    cc_config.interactions[interaction].adapter = { name = "deepseek", model = model }
  end

  -- 如果当前缓冲区正好是一个 chat，顺手把它也切过去
  local chat = require("codecompanion.interactions.chat").buf_get_chat(0)
  if chat and chat:change_adapter("deepseek") then
    chat:change_model({ model = model })
  end

  vim.notify("CodeCompanion 默认模型：" .. MODELS[model])
end

-- ---------------------------------------------------------
-- 翻译
-- ---------------------------------------------------------
-- 不经过 chat / inline，直接用 deepseek adapter 发一次性请求，结果流式
-- 显示在光标旁的浮窗里。固定用 Flash 并关闭思考模式，查词约 1 秒出结果。
--
--   <leader>tw  查光标下的单词（可视模式：查选中的词组），按所在句子给出词义
--   <leader>ts  翻译光标所在的句子
--   <leader>tp  翻译光标所在的段落
--   <leader>tt  翻译选中的文本（可视模式）
--
-- 浮窗在光标移动、进入插入模式或切换 buffer 时自动关闭；
-- 普通模式下再按一次同一快捷键可进入浮窗滚动、复制，q 关闭。

local PROMPTS = {
  word = [[你是英汉词典。用户会给出一个英文单词或短语，以及它所在的原文。用简体中文按下面的格式回答，不要寒暄，不要复述原文：
单词 /音标/ 词性（如果是变形，在括号里注明原形；短语可省略音标）
本句：它在这段原文里的意思
其他：最多三个其他常见义项，用分号隔开]],
  text = [[你是专业译者。把用户给出的文本译成准确、通顺的简体中文；如果原文是中文，则译成英文。
只输出译文，不要解释，不要复述原文。原文里句子中间的换行只是排版折行，按完整句子翻译；保留列表、代码、命令和专有名词。]],
}

local translate_adapter
local float = {} -- 当前浮窗：win、请求 handle、触发它的快捷键 lhs

local function close_float()
  if float.handle then
    float.handle.cancel()
  end
  if float.win and vim.api.nvim_win_is_valid(float.win) then
    vim.api.nvim_win_close(float.win, true)
  end
  float = {}
  pcall(vim.api.nvim_del_augroup_by_name, "CodeCompanionTranslate")
end

local function open_float(title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"

  -- 光标在窗口上半部分就往下弹，否则往上弹
  local below = vim.fn.winline() <= vim.api.nvim_win_get_height(0) / 2
  float.win = vim.api.nvim_open_win(buf, false, {
    relative = "cursor",
    anchor = below and "NW" or "SW",
    row = below and 1 or 0,
    col = 0,
    width = 10,
    height = 1,
    style = "minimal",
    title = " " .. title .. " ",
  })
  vim.wo[float.win].wrap = true
  vim.wo[float.win].linebreak = true
  vim.keymap.set("n", "q", close_float, { buffer = buf, nowait = true })

  local src, pos = vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0)
  local group = vim.api.nvim_create_augroup("CodeCompanionTranslate", { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
    group = group,
    buffer = src,
    callback = function(ev)
      -- 退出可视模式时光标可能被修正一格，位置没变就不算移动
      if ev.event == "InsertEnter" or not vim.deep_equal(vim.api.nvim_win_get_cursor(0), pos) then
        close_float()
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(ev)
      if ev.buf ~= buf and ev.buf ~= src then
        close_float()
      end
    end,
  })
  return buf
end

local function render(buf, text)
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    return
  end
  local lines = vim.split(text, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = 10
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  vim.api.nvim_win_set_width(win, math.min(width, 80, vim.o.columns - 4))
  -- 按折行后的实际行数设高度，最多占屏幕 40%
  local height = vim.api.nvim_win_text_height(win, {}).all
  vim.api.nvim_win_set_height(win, math.min(height, math.floor(vim.o.lines * 0.4)))
end

-- context 只在查词时传入：要查的词所在的原文
local function translate(title, system, text, context)
  close_float()
  text = vim.trim(text)
  if text == "" then
    return vim.notify("没有可翻译的内容", vim.log.levels.WARN)
  end
  if context then
    text = ("单词：%s\n原文：%s"):format(text, context)
  end

  if not translate_adapter then
    local adapter = adapters.resolve("deepseek", { model = "deepseek-flash" })
    translate_adapter = adapter:map_schema_to_params(require("codecompanion.schema").get_default(adapter, {
      ["thinking.type"] = "disabled",
      temperature = 0.3,
    }))
  end

  local buf = open_float(title)
  render(buf, "翻译中…")

  local parts = {}
  float.handle = require("codecompanion.http").new({ adapter = translate_adapter }):send({
    messages = {
      { role = "system", content = system },
      { role = "user", content = text },
    },
  }, {
    silent = true,
    on_chunk = function(chunk)
      local result = adapters.call_handler(translate_adapter, "parse_chat", chunk)
      local content = result and result.output and result.output.content
      if content and content ~= "" then
        table.insert(parts, content)
        render(buf, table.concat(parts))
      end
    end,
    on_done = function()
      if #parts == 0 then
        render(buf, "（没有返回内容）")
      end
    end,
    on_error = function(err)
      local detail = type(err.stderr) == "table" and err.stderr.body or err.stderr
      render(buf, ("翻译失败：%s\n%s"):format(err.message or "", tostring(detail or "")))
    end,
  })
end

-- 用文本对象取文字（is 句子、ip 段落），不移动光标、不占用寄存器
local function textobj(obj)
  local view = vim.fn.winsaveview()
  vim.cmd("normal! v" .. obj .. "\27")
  local lines = vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = vim.fn.visualmode() })
  vim.fn.winrestview(view)
  return table.concat(lines, "\n")
end

-- 取可视模式的选区并退出可视模式
local function selection()
  local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  return table.concat(lines, "\n")
end

local function lookup(word)
  -- 语境优先取整句；句子太长（比如没有句号的长列表）就退回当前行
  local context = textobj("is")
  if vim.fn.strchars(context) > 800 then
    context = vim.api.nvim_get_current_line()
  end
  translate("查词", PROMPTS.word, word, context)
end

-- ---------------------------------------------------------
-- 快捷键
-- ---------------------------------------------------------
-- 可视模式用 "x" 而不是 "v"：v 还包含 select 模式，补全片段占位符里
-- 敲空格（leader）会被当成映射前缀而卡住。

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

-- 普通模式的翻译键：浮窗已由同一个键打开时，再按一次就进入浮窗（同 K 的习惯）
local function map_translate(lhs, fn, desc)
  map("n", lhs, function()
    if float.lhs == lhs and float.win and vim.api.nvim_win_is_valid(float.win) then
      return vim.api.nvim_set_current_win(float.win)
    end
    fn()
    float.lhs = lhs
  end, desc)
end

map({ "n", "x" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>", "CodeCompanion Actions")
map("n", "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", "Toggle CodeCompanion Chat")
map("n", "<leader>an", "<cmd>CodeCompanionChat<cr>", "New CodeCompanion Chat")
map({ "n", "x" }, "<leader>ai", "<cmd>CodeCompanion<cr>", "CodeCompanion Inline")
map("x", "<leader>ad", "<cmd>CodeCompanionChat Add<cr>", "Add Selection to CodeCompanion Chat")
map("x", "<leader>ae", "<cmd>CodeCompanion /explain<cr>", "Explain Selected Code")
map("x", "<leader>af", "<cmd>CodeCompanion /fix<cr>", "Fix Selected Code")
map("x", "<leader>at", "<cmd>CodeCompanion /tests<cr>", "Generate Tests")
map("n", "<leader>ag", "<cmd>CodeCompanion /commit<cr>", "Generate Git Commit Message")
map("n", "<leader>am", function()
  pick_model(set_default_model)
end, "Switch Default AI Model")
map("n", "<leader>aM", function()
  pick_model(function(model)
    vim.cmd("CodeCompanionChat adapter=deepseek model=" .. model)
  end)
end, "New Chat With Model")

map_translate("<leader>tw", function()
  lookup(vim.fn.expand("<cword>"))
end, "Look up word")
map_translate("<leader>ts", function()
  translate("翻译", PROMPTS.text, textobj("is"))
end, "Translate sentence")
map_translate("<leader>tp", function()
  translate("翻译", PROMPTS.text, textobj("ip"))
end, "Translate paragraph")
map("x", "<leader>tw", function()
  lookup(selection())
end, "Look up selection")
map("x", "<leader>tt", function()
  translate("翻译", PROMPTS.text, selection())
end, "Translate selection")
