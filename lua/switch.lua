--@+leo-ver=4-encoding=iso-8859-15,.
--@+node:@file Switch.lua
--@@language lua
--@@encoding iso-8859-15
--@@pagewidth 80
--@@tabwidth 2
-- Case implementation
-- Based on: http://lua-users.org/wiki/SwitchStatement
--
function switch(c)
	local swtbl = {
		casevar = c,
		caseof = function (self, code)
			local f
			if (self.casevar) then
				f = code[self.casevar] or code.default
			else
				f = code.missing or code.default
			end
			if f then
				if type(f)=="function" then
					return f(self.casevar,self)
				else
					-- f is value not a function
					if (code[f]) and self.casevar ~= code[f] then
						self.casevar = f
						return self.caseof(self,code)
					else
						return f
					end
				end
			end
		end
	}
	return swtbl
end
--@-node:@file Switch.lua
--@-leo
