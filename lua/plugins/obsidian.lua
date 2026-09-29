-- Obsidian 笔记：在 Neovim 和 Obsidian 中使用同一个笔记库。
-- 本文件包含 obsidian.nvim 的插件配置，以及笔记相关的自定义功能
-- （callout / 表格 / 复选框的快速插入）。

local notes_path = "/home/lc/Documents/notes"

if vim.fn.isdirectory(notes_path) ~= 1 then
  return
end

require("obsidian").setup({
  -- 使用新版统一命令，例如 :Obsidian backlinks。
  legacy_commands = false,

  workspaces = {
    {
      name = "notes",
      path = notes_path,
    },
  },

  -- 与 Obsidian 的“新笔记存放位置”保持一致。
  notes_subdir = "draft",
  new_notes_location = "notes_subdir",

  -- 优先使用笔记标题作为文件名，避免默认的“时间戳-随机字符”名称。
  note_id_func = function(title)
    if title and title ~= "" then
      -- 替换 Linux/Windows 文件名及路径中容易产生歧义的字符。
      return title:gsub("[/\\:*?\"<>|]", "-")
    end
    return os.date("%Y-%m-%d-%H%M%S")
  end,

  -- 与 Obsidian 的 Daily notes 设置保持一致。
  daily_notes = {
    folder = "dailynote",
    date_format = "%Y-%m-%d",
  },

  -- 与 Obsidian 的附件目录保持一致。
  attachments = {
    folder = "images",
  },

  -- Obsidian 当前设置为使用标准 Markdown 链接。
  link = {
    style = "markdown",
  },

  -- 保留现有笔记内容，不自动插入 YAML frontmatter。
  frontmatter = {
    enabled = false,
  },

  -- 使用已经安装的 fzf-lua 显示搜索结果。
  picker = {
    name = "fzf-lua",
  },

  -- Markdown 的视觉渲染已经由 render-markdown.nvim 负责。
  ui = {
    enable = false,
  },
})

-- ---------------------------------------------------------
-- 笔记导航快捷键
-- ---------------------------------------------------------

-- 从任意目录用 netrw 打开整个笔记库；进入后其余 Obsidian 命令即可使用。
vim.keymap.set("n", "<leader>oo", function()
  vim.cmd.edit(notes_path)
end, { desc = "Browse Obsidian vault" })

vim.keymap.set("n", "<leader>of", "<cmd>Obsidian quick_switch<cr>", {
  desc = "Find Obsidian note",
})
vim.keymap.set("n", "<leader>os", "<cmd>Obsidian search<cr>", {
  desc = "Search Obsidian vault",
})
vim.keymap.set("n", "<leader>ob", "<cmd>Obsidian backlinks<cr>", {
  desc = "Show Obsidian backlinks",
})
vim.keymap.set("n", "<leader>ot", "<cmd>Obsidian today<cr>", {
  desc = "Open today's Obsidian note",
})
vim.keymap.set("n", "<leader>on", function()
  vim.ui.input({ prompt = "笔记标题：" }, function(title)
    if not title or vim.trim(title) == "" then
      return
    end
    vim.api.nvim_cmd({ cmd = "Obsidian", args = { "new", vim.trim(title) } }, {})
  end)
end, { desc = "Create named Obsidian note" })
vim.keymap.set("n", "<leader>op", "<cmd>Obsidian paste_img<cr>", {
  desc = "Paste image into Obsidian note",
})
vim.keymap.set("n", "<leader>ov", function()
  if vim.bo.modified then
    vim.cmd.write()
  end
  vim.cmd("Obsidian open")
end, { desc = "View current note in Obsidian" })

-- ---------------------------------------------------------
-- 快速插入 Obsidian 元素
-- callout / 表格 / 复选框 在 Neovim 中纯手打比较繁琐，
-- 这里提供可视化菜单 + 一键生成，替代手工排版。
-- ---------------------------------------------------------

-- 在光标所在行下方插入若干行（保证块级元素前后有独立行）
local function insert_lines_below(lines)
  local lnum = vim.fn.line(".")
  vim.api.nvim_buf_set_lines(0, lnum, lnum, false, lines)
end

-- Callout：从菜单中选择类型，标题可选
local callout_types = {
  { name = "note",      desc = "普通提示 · 蓝" },
  { name = "tip",       desc = "技巧建议 · 绿" },
  { name = "important", desc = "重点强调 · 紫" },
  { name = "warning",   desc = "警告强调 · 黄" },
  { name = "caution",   desc = "小心谨慎 · 红" },
  { name = "question",  desc = "提问讨论 · 橙" },
  { name = "example",   desc = "举例说明 · 紫" },
  { name = "bug",       desc = "缺陷记录 · 红" },
  { name = "quote",     desc = "引用摘录 · 灰" },
}

local function insert_callout()
  vim.ui.select(callout_types, {
    prompt = "选择 Callout 类型：",
    format_item = function(t)
      return string.format("%s  ·  %s", t.name, t.desc)
    end,
  }, function(selected)
    if not selected then
      return
    end
    vim.ui.input({ prompt = "Callout 标题（直接回车留空）：" }, function(title)
      if title == nil then
        return
      end
      title = vim.trim(title)
      local header = string.format(
        "> [!%s]%s",
        selected.name:upper(),
        title ~= "" and (" " .. title) or ""
      )
      insert_lines_below({ header, "> " })
      vim.api.nvim_win_set_cursor(0, { vim.fn.line(".") + 1, 2 })
      vim.cmd("startinsert")
    end)
  end)
end

-- 表格：输入"列x行"生成对齐好的管道表格
local function insert_table()
  vim.ui.input({ prompt = "表格尺寸（列x行，例如 3x2）：" }, function(dim)
    if not dim or vim.trim(dim) == "" then
      return
    end
    local cols, rows = dim:match("^(%d+)%s*[xX×*]%s*(%d+)$")
    if not cols then
      vim.notify("格式应为 列x行，例如 3x2（3列 2 行）", vim.log.levels.WARN)
      return
    end
    cols, rows = tonumber(cols), tonumber(rows)
    if cols < 1 or cols > 20 or rows < 1 or rows > 50 then
      vim.notify("行列数超出合理范围（列 1~20，行 1~50）", vim.log.levels.WARN)
      return
    end

    -- 用中文占位符生成，光标进入后直接覆盖输入
    local cells = {}
    for r = 1, rows do
      cells[r] = {}
      for c = 1, cols do
        cells[r][c] = r == 1 and ("列" .. c) or ("内容" .. c)
      end
    end

    -- 每列按内容实际显示宽度对齐（中文按 2 列宽计）
    local widths = {}
    for c = 1, cols do
      local w = 0
      for r = 1, rows do
        w = math.max(w, vim.fn.strdisplaywidth(cells[r][c]))
      end
      widths[c] = w
    end

    local function format_row(row)
      local parts = {}
      for c = 1, cols do
        local pad = widths[c] - vim.fn.strdisplaywidth(row[c])
        parts[c] = " " .. row[c] .. string.rep(" ", pad) .. " "
      end
      return "|" .. table.concat(parts, "|") .. "|"
    end

    local lines = { format_row(cells[1]) }

    local seps = {}
    for c = 1, cols do
      seps[c] = string.rep("-", math.max(3, widths[c]))
    end
    lines[#lines + 1] = "|" .. table.concat(seps, "|") .. "|"
    for r = 2, rows do
      lines[#lines + 1] = format_row(cells[r])
    end

    insert_lines_below(lines)
    vim.api.nvim_win_set_cursor(0, { vim.fn.line(".") + 1, 2 })
    vim.cmd("startinsert")
  end)
end

vim.keymap.set("n", "<leader>mc", insert_callout, { noremap = true, silent = true, desc = "Insert Obsidian callout" })
vim.keymap.set("n", "<leader>mt", insert_table, { noremap = true, silent = true, desc = "Insert Markdown table" })
vim.keymap.set({ "n", "v" }, "<leader>mb", "<cmd>Obsidian toggle_checkbox<cr>", {
  noremap = true,
  silent = true,
  desc = "Toggle Obsidian checkbox",
})
