/*
 * =====================================================================================
 *
 *       Filename:  lcpio.c
 *
 *    Description:  :
 *
 *        Version:  1.0
 *        Created:  23/11/07 01:38:08 CET
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

#include	"lcpio.h"
#include	"luaarchive.h"
#include	"aux.h"

/* Interface Functions */

	int
l_open ( lua_State * L )
{
	luaarchive_p cpiohandler;
	char *mode, * path, * compression;
	path = (char *) luaL_checkstring(L, 1);
	mode = (char *) luaL_checkstring(L, 2);
	if (lua_isnone(L,3))
			lua_pushnil(L); // Pushes nil as Arg #3
	else
		compression = (char *) luaL_checkstring(L, 3);

	if (!luaarchive_new (L, mode, LUAARCHIVE_CPIO_HANDLER))
		return luaarchive_pusherror(L, (char *)lua_tostring(L, -1));

	cpiohandler = luaarchive_tohandler(L, -1, LUAARCHIVE_CPIO_HANDLER);
	cpiohandler->type = LUAARCHIVE_CPIO;
	cpiohandler->compression = luaarchive_tocompression(L, 3, mode);

	if (aux_support_format(cpiohandler))
		return luaarchive_pusharchiveerror(L, cpiohandler);

	if (aux_support_compression(cpiohandler))
		return luaarchive_pusharchiveerror(L, cpiohandler);

	if (aux_open(cpiohandler, path) != ARCHIVE_OK) {
		lua_pushstring(L, (char *)archive_error_string(cpiohandler->archive));
		aux_finish(cpiohandler);
		return luaarchive_pusherror(L, (char *)lua_tostring(L, -1));
	}

	lua_getmetatable(L, -1);
	switch (cpiohandler->mode) {
		case LUAARCHIVE_RDMODE:
			lua_pushcfunction(L, l_read);
			lua_setfield(L, -2, "read");
			break;
		case LUAARCHIVE_WRMODE:
			lua_pushcfunction(L, l_write);
			lua_setfield(L, -2, "write");
			break;
	}
	lua_replace(L, -4);
	return 1;
}		/* -----  end of function l_open  ----- */


	int
l_close ( lua_State *L )
{
	return luaarchive_close(L, LUAARCHIVE_CPIO_HANDLER);
}		/* -----  end of function l_close  ----- */


	int
l_read ( lua_State *L )
{
	return luaarchive_read(L, LUAARCHIVE_CPIO_HANDLER);
}		/* -----  end of function l_read  ----- */


	int
l_type ( lua_State *L )
{
	return luaarchive_type(L, LUAARCHIVE_CPIO_HANDLER);
}		/* -----  end of function l_type  ----- */


	int
l_write ( lua_State *L )
{
	return 0;
}		/* -----  end of function l_write  ----- */

static const struct luaL_reg cpio [] = {
	{"open", l_open},
	{"close", l_close},
	{NULL, NULL}
};

static const struct luaL_reg cpiohandler [] = {
	{"close", l_close},
	{"type", l_type},
	{NULL, NULL}
};


	int
luaopen_cpio ( lua_State *L )
{
	luaL_newmetatable(L, LUAARCHIVE_CPIO_HANDLER);
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);
	lua_settable(L, -3);
	luaL_register(L, NULL, cpiohandler);
	luaL_register(L, LUAARCHIVE_CPIO_MODULE, cpio);
	return 1;
}		/* -----  end of function luaopen_cpio  ----- */
