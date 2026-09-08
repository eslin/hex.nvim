local M = {}

function M.drop_undo_history()
  local undolevels = vim.o.undolevels
  vim.o.undolevels = -1
  vim.cmd [[exe "normal a \<BS>\<Esc>"]]
  vim.o.undolevels = undolevels
end

function M.dump_to_hex(hex_dump_cmd)
  local modified = vim.bo.mod
  vim.b.hex_transforming = true

  vim.bo.bin = true
  vim.b['hex'] = true

  -- Dump current buffer, not file from disk
  vim.cmd([[%! ]] .. hex_dump_cmd)

  vim.b.hex_ft = vim.bo.ft
  vim.bo.ft = 'xxd'
  M.drop_undo_history()
  M.dettach_all_lsp_clients_from_current_buf()

  -- Toggling view must not change dirty state
  vim.bo.mod = modified
  vim.b.hex_ascii_tick = vim.api.nvim_buf_get_changedtick(0)
  vim.b.hex_transforming = false
end

function M.assemble_from_hex(hex_assemble_cmd)
  local modified = vim.bo.mod
  vim.b.hex_transforming = true

  vim.cmd([[%! ]] .. hex_assemble_cmd)
  vim.bo.ft = vim.b.hex_ft
  M.drop_undo_history()
  vim.b['hex'] = false

  -- Preserve dirty state from hex edits
  vim.bo.mod = modified
  vim.b.hex_transforming = false
end

function M.begin_patch_from_hex(hex_assemble_cmd)
  vim.b.hex_cur_pos = vim.fn.getcurpos()
  vim.b.hex_transforming = true
  vim.cmd([[%! ]] .. hex_assemble_cmd)
end

function M.finish_patch_from_hex(hex_dump_cmd)
  vim.cmd([[%! ]] .. hex_dump_cmd)
  vim.fn.setpos('.', vim.b.hex_cur_pos)
  vim.bo.mod = true
  vim.b.hex_transforming = false
end

function M.refresh_ascii(hex_dump_cmd, hex_assemble_cmd)
  local modified = vim.bo.mod
  local cursor = vim.fn.getcurpos()
  vim.b.hex_transforming = true

  vim.cmd([[%! ]] .. hex_assemble_cmd)
  vim.cmd([[%! ]] .. hex_dump_cmd)

  vim.fn.setpos('.', cursor)
  vim.bo.mod = modified
  vim.b.hex_transforming = false
end

function M.is_program_executable(program)
  if vim.fn.executable(program) == 1 then
    return true
  else
    vim.notify(program .. " is not installed on this system, aborting!", vim.log.levels.WARN)
    return false
  end
end

function M.dettach_all_lsp_clients_from_current_buf()
  local attached_servers = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
  for _, attached_server in ipairs(attached_servers) do
    attached_server.stop()
  end
end

return M
