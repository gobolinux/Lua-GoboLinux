-- vi: set foldmethod=marker foldlevel=0:
--
-- test.lua
-- ---------------------------------------------------------------------------
--  - 2007
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 14/11/07 14:29:47 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

package.cpath="../../.libs/?.so"

require "cpio"

local testfiles = {
	"test.cpio",
	"test.cpio.gz",
	"test.cpio.bz2"
}
local outputdir = "../tests/output_dir"

local function list_tar (tarHandler)
	print("Listing file")
	local file, err = tarHandler:read()
	if not file then print(err) os.exit() end
	local i=1
	while file do
		print(i .. " - " .. file)
		i=i+1
		file = tarHandler:read()
	end
	--tarHandler:seek(0,"SEEK_SET")
end

local function extract_tar (tarHandler)
	print ("Extracting file:")
	tarHandler:extractAll(outputdir)
end
for _, file in ipairs(testfiles) do
	local fd, err = cpio.open(file, "r")
	if err then 
		print("Errors when opening tar file: " .. err)
		os.exit()
	end
	print(fd:type())
	list_tar(fd)
	fd:close()
end
--extract_tar(mytar)
