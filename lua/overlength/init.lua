-- File:        overlength/init.lua
-- Author:      Laurent Cheylus <foxy@free.fr>
-- Created:     02 Aug 2022
-- SPDX-License-Identifier: MIT

local M = {}

local config = {}
local overlength_enabled

--
-- Private methods
--
local function get_virtual_column_modifier()
  if config.highlight_to_eol then
    return '>'
  else
    return ''
  end
end

local function get_virtual_column_offset()
  if config.highlight_to_eol then
    return -1
  else
    return 0
  end
end

local function get_repeat_char()
  if config.highlight_to_eol then
    return [[.\+]]
  else
    return '.'
  end
end

local function get_overlength()
  if config.ft_specific_length[vim.bo.filetype] ~= nil then
    return config.ft_specific_length[vim.bo.filetype]
  end

  -- Different options based on textwidth_mode config
  -- 0: Don't use textwidth at all, always use config.default_overlength.
  -- 1: Use `textwidth, unless it's 0, then use config.default_overlength.
  -- 2: Always use textwidth. There will be no highlighting where
  --    textwidth == 0, unless added explicitly
  --
  -- If textwidth == 0, we just won't highlight in that filetype.
  if config.textwidth_mode == 0 then
    return config.default_overlength
  elseif config.textwidth_mode == 1 then
    if vim.bo.textwidth > 0 then
      return vim.bo.textwidth
    else
      return config.default_overlength
    end
  else
    return vim.bo.textwidth
  end
end

local function matchdelete()
  if vim.w.last_overlength ~= nil then
    vim.fn.matchdelete(vim.w.last_overlength)
    vim.w.last_overlength = nil
  end
end

local function matchadd()
  if get_overlength() == 0 then
    -- print('get_overlength = 0')
    return
  end

  if overlength_enabled then
    if vim.w.last_overlength == nil then
      vim.w.overlength_pattern = [[\%]]
          .. get_virtual_column_modifier()
          .. get_overlength() + config.grace_length + get_virtual_column_offset()
          .. 'v'
          .. get_repeat_char()

      vim.w.last_overlength = vim.fn.matchadd('OverLength', vim.w.overlength_pattern)
    end
  end
end

local function refresh()
  -- Force clean of highlight groups
  matchdelete()

  if overlength_enabled then
    matchadd()
  else
    matchdelete()
  end
end

-- Create user commands and autocommands
local function setup_commands()
  vim.api.nvim_create_user_command('OverlengthEnable', function()
    require('overlength').enable()
  end, { desc = 'Enable OverLength highlight' })
  vim.api.nvim_create_user_command('OverlengthDisable', function()
    require('overlength').disable()
  end, { desc = 'Disable OverLength highlight' })
  vim.api.nvim_create_user_command('OverlengthToggle', function()
    require('overlength').toggle()
  end, { desc = 'Toggle OverLength highlight' })

  vim.api.nvim_create_autocmd({ 'BufEnter', 'Filetype' }, {
    group = vim.api.nvim_create_augroup('Overlength', {}),
    callback = refresh,
  })
end

--
-- Public methods
--
M.set_overlength = function(ft, length)
  config.ft_specific_length[ft] = length
end

M.disable = function()
  overlength_enabled = false
  refresh()
end

M.enable = function()
  overlength_enabled = true
  refresh()
end

M.toggle = function()
  overlength_enabled = not overlength_enabled
  refresh()
end

M.setup = function(opts)
  -- Check Neovim version >= 0.7.0
  if vim.fn.has('nvim-0.7') ~= 1 then
    vim.api.nvim_err_writeln('Error: overlength - Neovim version >= 0.7.0 necessary')
    return
  end

  setup_commands()

  config = require('overlength.config').parse(opts)
  overlength_enabled = config.enabled

  -- Set OverLength highlight group
  local colors = {}
  local ok, hl = pcall(vim.api.nvim_get_hl_by_name, 'Normal', true)
  if ok then
    for k, v in pairs(hl) do
      colors[k] = string.format('#%06x', v)
    end
  end

  for k, v in pairs(config.colors) do
    if k and k ~= nil then
      colors[k] = v
    end
  end
  -- vim.print(colors)

  -- Needs to schedule it, not created if called directly
  vim.schedule(function()
    vim.api.nvim_set_hl(0, 'OverLength', colors)
  end)

  refresh()
end

return M
