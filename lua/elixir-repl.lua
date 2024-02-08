local ts = require 'nvim-treesitter.ts_utils'

local nvim_command = vim.api.nvim_command
local nvim_input   = vim.api.nvim_input


vim.keymap.set('n', ',r', function ()
   nvim_command(':w')
   to_repl('recompile', {send=true})
end)


function setup ()
   vim.keymap.set('n', '<leader>m', start_repl)

   -- Evaluate current selection.
   vim.keymap.set('v', ',e', function ()
      nvim_command('norm "0y')
      to_repl(vim.fn.getreg(0))
   end)

   -- Evaluate current node.
   vim.keymap.set('n', ',e', function ()
      local bufnr = vim.api.nvim_get_current_buf()
      local node  = ts.get_node_at_cursor()
      local text  = vim.treesitter.get_node_text(node, bufnr)
      to_repl(text)
   end)

   -- Evaluate current line.
   vim.keymap.set('n', ',l', function ()
      to_repl(vim.api.nvim_get_current_line())
   end)

   -- Evaluate smallest root node.
   vim.keymap.set('n', ',d', function ()
      local bufnr = vim.api.nvim_get_current_buf()
      local node  = ts.get_node_at_cursor()
      local text  = vim.treesitter.get_node_text(get_root(node), bufnr)
      to_repl(text)
   end)

   -- Set visual selection to smallest root.
   vim.keymap.set('n', ',v', function ()
      local bufnr = vim.api.nvim_get_current_buf()
      local node  = ts.get_node_at_cursor()
      ts.update_selection(bufnr, get_root(node))
   end)
end


function start_repl ()
   vim.api.nvim_command(':w | tabnew')
   vim.api.nvim_command(':setlocal nonumber norelativenumber')
   vim.api.nvim_command(':term iex -S mix')
   vim.api.nvim_buf_set_name(0, 'iex') 
end


function get_root (node)
   local parent = node:parent()

   if (parent and parent:start() == node:start())
   then
      return get_root(parent)
   else
      return node
   end
end


function to_repl (text, opts)
   opts = opts or {}

   local channel
   for _, ch in pairs(vim.api.nvim_list_chans()) do
      channel = channel or (ch['pty'] and ch['id'])
   end

   if not channel then
      error('No REPL running.')
      return
   end

   vim.api.nvim_chan_send(channel,
      ' ' .. text .. (opts.send and '\n' or ''))

   nvim_command('tabnext')
   nvim_input('A')
end


return {
   setup    = setup,
   start    = start_repl,
   to_repl  = to_repl,
   get_root = get_root,
}
