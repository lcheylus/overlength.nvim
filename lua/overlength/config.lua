-- File:        overlength/config.lua
-- Author:      Laurent Cheylus <foxy@free.fr>
-- Created:     02 Aug 2022
-- SPDX-License-Identifier: MIT

-- Default configuration
local default_opts = {
  -- Overlength highlighting enabled by default
  enabled = true,

  -- Colors for Overlength highlight group
  colors = {
    ctermfg = nil,
    ctermbg = 'darkgrey',
    fg = nil,
    bg = '#8B0000',
  },

  -- Mode to use textwidth local options
  -- 0: Don't use textwidth at all, always use config.default_overlength.
  -- 1: Use `textwidth, unless it's 0, then use config.default_overlength.
  -- 2: Always use textwidth. There will be no highlighting where
  --    textwidth == 0, unless added explicitly
  textwidth_mode = 2,
  -- Default overlength with no filetype
  default_overlength = 80,
  -- How many spaces past your overlength to start highlighting
  grace_length = 1,
  -- Highlight only the column or until the end of the line
  highlight_to_eol = true,

  -- List of filetypes to disable overlength highlighting
  disable_ft = { 'qf', 'help', 'man', 'packer', 'NvimTree', 'Telescope', 'WhichKey' },
}

local M = {}

local function validate(opts)
  if opts == nil then
    return true
  end

  if type(opts) ~= 'table' then
    vim.api.nvim_err_writeln('Error: overlength/config - opts is not a table')
    return false
  end

  if (opts['colors'] ~= nil) and (type(opts['colors']) ~= 'table') then
    vim.api.nvim_err_writeln('Error: overlength/config - opts["colors"] is not a table')
    return false
  end

  if (opts['disable_ft'] ~= nil) and (type(opts['disable_ft']) ~= 'table') then
    vim.api.nvim_err_writeln('Error: overlength/config - opts["disable_ft"] is not a table')
    return false
  end

  if opts['textwidth_mode'] ~= nil then
    -- In Lua 5.1, cannot check if number type is integer or float
    if tonumber(opts['textwidth_mode']) == nil then
      vim.api.nvim_err_writeln('Error: overlength/config - opts["textwidth_mode"] is not an integer')
      return false
    elseif (opts['textwidth_mode'] < 0) or (opts['textwidth_mode'] > 2) then
      vim.api.nvim_err_writeln('Error: overlength/config - invalid value for opts["textwidth_mode"], must be 0, 1 or 2')
      return false
    end
  end

  return true
end

function M.parse(opts)
  local config

  if validate(opts) then
    config = vim.tbl_deep_extend('force', default_opts, opts or {})
  else
    config = vim.tbl_deep_extend('force', default_opts, {})
  end

  -- Disabled filetypes
  config.ft_specific_length = {}
  for _, v in ipairs(config.disable_ft) do
    config.ft_specific_length[v] = 0
  end

  return config
end

return M
