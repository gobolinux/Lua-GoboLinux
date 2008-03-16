-- vi: set foldmethod=marker foldlevel=0:
--
-- test.lua
-- ---------------------------------------------------------------------------
--  - 2008
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 01/03/08 14:30:33 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

-- Imports
require "env"
require "GoboLinux.cui"
local cui = GoboLinux.cui

local t = {
	1,2,3,4,5,6,7
}

local function co ()
	return coroutine.create(function ()
		for i,p in ipairs(t) do
			coroutine.yield(false, "This is a very very very very long Testing "..tostring(i), function ()
				os.execute("sleep 1")
			end)
			coroutine.yield(true, "This is a ting "..tostring(i), function ()
				os.execute("sleep 1")
			end)

		end
		return true, "Done"
	end)
end

--cui.title("Testing percent_bar 1")
--cui.percent_bar(#t, co())
cui.title("Testing percent_bar 2")
cui.percent_bar(#t, co(),"Align=Center","LevelPosition=Left","Level=3")
