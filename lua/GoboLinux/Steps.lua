-- vi: set foldmethod=marker foldlevel=0:
--
-- Steps.lua
-- ---------------------------------------------------------------------------
--  - 2008
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 31/01/08 08:00:46 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

-- Create module {{{1
module("Steps",package.seeall)

-- Imports {{{1

-- Local Variables {{{1
-- Exported Variables {{{1

-- Local Functions {{{1

local function get_args (follow, ... )
	return follow, arg
end  ----------  end of function get_args  ----------

local function add ( self, step, func )
	self.Steps[step] = func
	return self
end  ----------  end of function add  ----------

local function remove ( self, step )
	if self.Steps[step] then
		self.Steps[step] = nil
	end
	return self
end  ----------  end of function remove  ----------

local function start ( self, step, ... )
	local args = arg or {}
	local follow = step
	while follow and self.Steps[follow] do
		follow, args = get_args(self.Steps[follow](unpack(args)))
	end
	return unpack(args)
end  ----------  end of function start  ----------

-- Exported Functions {{{1
local methods = {
	remove = remove,
	add = add,
	start = start,
}

function new ( steps)
	local s = {Steps = steps or {}}
	return setmetatable(s, {__index=methods})
end  ----------  end of function new  ----------

-- Types {{{1

