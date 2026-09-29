-- 自动命令

-- ---------------------------------------------------------
-- fcitx5 输入法状态同步：
-- 离开可输入文字的模式时切到英文，回来时恢复之前的中文状态。
-- fcitx5-remote 返回 2 表示输入法已激活，1 表示未激活。
-- ---------------------------------------------------------
local fcitx5_remote = vim.fn.exepath("fcitx5-remote")
if fcitx5_remote ~= "" then
  local restore_fcitx5 = false
  local fcitx5_group = vim.api.nvim_create_augroup("Fcitx5InputMethod", { clear = true })

  local function run_fcitx5(args)
    local result = vim.system(vim.list_extend({ fcitx5_remote }, args), { text = true }):wait()
    return result.code == 0, vim.trim(result.stdout or "")
  end

  local function switch_to_english()
    local ok, state = run_fcitx5({})
    if not ok then
      return
    end
    restore_fcitx5 = state == "2"
    if restore_fcitx5 then
      run_fcitx5({ "-c" })
    end
  end

  local function restore_input_method()
    if restore_fcitx5 then
      run_fcitx5({ "-o" })
    end
  end

  vim.api.nvim_create_autocmd({ "InsertLeave", "TermLeave" }, {
    group = fcitx5_group,
    callback = switch_to_english,
    desc = "Switch fcitx5 to English outside input modes",
  })

  vim.api.nvim_create_autocmd({ "InsertEnter", "TermEnter" }, {
    group = fcitx5_group,
    callback = restore_input_method,
    desc = "Restore fcitx5 state in input modes",
  })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = fcitx5_group,
    callback = switch_to_english,
    desc = "Start Neovim Normal mode in English",
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = fcitx5_group,
    callback = restore_input_method,
    desc = "Restore fcitx5 state when leaving Neovim",
  })
end

-- ---------------------------------------------------------
-- 重新打开文件时恢复上次的光标位置
-- ---------------------------------------------------------
local last_pos_group = vim.api.nvim_create_augroup("UserRestoreCursor", { clear = true })

vim.api.nvim_create_autocmd("BufReadPost", {
  group = last_pos_group,
  desc = "Restore last cursor position",
  callback = function()
    if vim.o.diff then -- except in diff mode
      return
    end
    local last_pos = vim.api.nvim_buf_get_mark(0, '"') -- {line, col}
    local last_line = vim.api.nvim_buf_line_count(0)
    local row = last_pos[1]
    if row < 1 or row > last_line then
      return
    end
    pcall(vim.api.nvim_win_set_cursor, 0, last_pos)
  end,
})
