/*
 * =====================================================================================
 *
 *       Filename:  lcpio.h
 *
 *    Description:  
 *
 *        Version:  1.0
 *        Created:  23/11/07 01:38:24 CET
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  Aitor Pérez Iturri (api), aitor.iturri@gmail.com
 *        Company:  ia Systems
 *
 * =====================================================================================
 */

#ifndef _L_CPIO_H_
#define _L_CPIO_H_

#define LUAARCHIVE_CPIO_VERSION				"1.0"

#define LUAARCHIVE_CPIO_MODULE				"cpio"
#define LUAARCHIVE_CPIO_HANDLER				"ARCHIVE.CPIO"

static int l_open (lua_State *);
static int l_close (lua_State *);
static int l_read (lua_State *);
static int l_write (lua_State *);
static int l_type (lua_State *);

#endif
