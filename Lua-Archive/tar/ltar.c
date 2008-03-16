/*
 * =====================================================================================
 *
 *       Filename:  ltar.c
 *
 *    Description:  Lua-Tar binding implementation.
 *
 *        Version:  1.0
 *        Created:  20/11/07 09:21:51 CET
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  Aitor Pérez Iturri (api), aitor.iturri@gmail.com
 *        Company:  ia Systems
 *
 * =====================================================================================
 */

#include	<lua.h>
#include	<lualib.h>
#include	<lauxlib.h>
#include	<archive.h>
#include	<archive_entry.h>

#include	"ltar.h"
#include 	"luaarchive.h"
#include	"aux.h"

/* Interface Functions */


	int
l_open ( lua_State * L )
{
	luaarchive_p tarhandler;
	char * path, *mode, *compression;
	path = (char *) luaL_checkstring(L,1);
	mode = (char *) luaL_checkstring(L,2);
	if (lua_isnone(L,3))
		lua_pushnil(L); // Pushes nil as Arg #3
	else
		compression = (char *) luaL_checkstring(L, 3);
	
	// Creates a new archive in selected mode
	if (!luaarchive_new(L, mode, LUAARCHIVE_TAR_HANDLER))
		return luaarchive_pusherror(L, (char *)lua_tostring(L, -1));

	tarhandler = luaarchive_tohandler(L, -1, LUAARCHIVE_TAR_HANDLER);
	tarhandler->type = LUAARCHIVE_TAR;
	tarhandler->compression = luaarchive_tocompression(L, 3, mode);

	if (aux_support_format(tarhandler)) 
		return luaarchive_pusharchiveerror(L, tarhandler);

	if (aux_support_compression(tarhandler)) 
		return luaarchive_pusharchiveerror(L, tarhandler);

	// Open the file
	if (aux_open(tarhandler, path) != ARCHIVE_OK) {
		lua_pushstring(L, (char *)archive_error_string(tarhandler->archive));
		aux_finish(tarhandler);
		return luaarchive_pusherror(L, (char *)lua_tostring(L, -1));
	}

	// Add specific functions for each openning mode
	lua_getmetatable(L, -1);
	switch (tarhandler->mode) {
		case LUAARCHIVE_RDMODE:
			lua_pushcfunction(L, l_read);
			lua_setfield(L, -2, "read");
			lua_pushcfunction(L, l_extract);
			lua_setfield(L, -2, "extract");
			lua_pushcfunction(L, l_entry);
			lua_setfield(L, -2, "entry");
//			lua_pop(L, 2);
			break;
		case LUAARCHIVE_WRMODE:
			lua_pushcfunction(L, l_write);
			lua_setfield(L, -2, "write");
//			lua_pop(L, 2);
			break;
	}
	// Stack:
	// tarhandler.metatable
	// tarhandler
	lua_replace(L, -1); // Lets the userdata on the top of the stack.
	return 1;
}		/* -----  end of function l_open  ----- */


	int
l_close ( lua_State *L )
{
	return luaarchive_close(L, LUAARCHIVE_TAR_HANDLER);
}		/* -----  end of function l_close  ----- */


	int
l_read ( lua_State *L )
{
	return luaarchive_read(L, LUAARCHIVE_TAR_HANDLER);
}		/* -----  end of function l_read  ----- */


	int
l_type ( lua_State *L )
{
	return luaarchive_type(L, LUAARCHIVE_TAR_HANDLER);
}		/* -----  end of function l_type  ----- */


	int
l_mode ( lua_State *L )
{
	return luaarchive_mode(L, LUAARCHIVE_TAR_HANDLER);
}		/* -----  end of function l_mode  ----- */


	int
l_write ( lua_State *L )
{
	return luaarchive_write(L, LUAARCHIVE_TAR_HANDLER);
}		/* -----  end of function l_write  ----- */


	int
l_extract ( lua_State * L )
{
	return luaarchive_extract(L, LUAARCHIVE_TAR_HANDLER);
}		/* -----  end of function l_extract  ----- */

	int
l_entry ( lua_State * L )
{
	return luaarchive_entry(L, LUAARCHIVE_TAR_HANDLER);
}		/* -----  end of function l_entry  ----- */

static const struct luaL_reg tar [] = {
	{"open", l_open},
	{"close", l_close},
	{NULL, NULL}
};

static const struct luaL_reg tarhandler [] = {
	{"close", l_close},
	{"mode", l_mode},
	{"type", l_type},
	{NULL, NULL}
};


	int
luaopen_tar_core ( lua_State *L )
{
	luaL_newmetatable(L, LUAARCHIVE_TAR_HANDLER);
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);
	// Stack:
	// 		(table) LUAARCHIVE_TAR_HANDLER
	// 		(string) __index
	// 		(table) LUAARCHIVE_TAR_HANDLER
	lua_settable(L, -3);
	luaL_register(L, NULL, tarhandler);
	luaL_register(L, LUAARCHIVE_TAR_MODULE, tar);
	return 1;
}		/* -----  end of function luaopen_tar  ----- */
