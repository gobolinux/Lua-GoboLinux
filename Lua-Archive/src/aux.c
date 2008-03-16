/*
 * =====================================================================================
 *
 *       Filename:  aux.c
 *
 *    Description:  High level functions to manage archive files.
 *
 *        Version:  1.0
 *        Created:  20/11/07 11:06:18 CET
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  Aitor Pérez Iturri (api), aitor.iturri@gmail.com
 *        Company:  ia Systems
 *
 * =====================================================================================
 */

#include	<archive.h>
#include	<stdio.h>
#include	<stdlib.h>
#include	<archive.h>
#include	<sys/stat.h>

#include	"luaarchive.h"
#include	"aux.h"

	int
aux_getmode ( char * mode )
{
	switch(mode[0]) {
		case 'r':
			return LUAARCHIVE_RDMODE;
		case 'w':
			return LUAARCHIVE_WRMODE;
		default:
			return LUAARCHIVE_UNKMODE;
	}
}		/* -----  end of function archive_getmode  ----- */


	char *
aux_gettypename ( int type )
{
	switch (type) {
		case LUAARCHIVE_TAR:
			return "tar";
		case LUAARCHIVE_CPIO:
			return "cpio";
		case LUAARCHIVE_ISO9660:
			return "iso9660";
		case LUAARCHIVE_MTREE:
			return "mtree";
		default:
			return NULL;
	}
}		/* -----  end of function aux_gettypename  ----- */

	int
aux_open ( luaarchive_p archivehandler, char * path )
{
	switch (archivehandler->mode) {
		case LUAARCHIVE_RDMODE: 
			return archive_read_open_filename(archivehandler->archive, path, LUAL_BUFFERSIZE);
		case LUAARCHIVE_WRMODE:
			return archive_write_open_filename(archivehandler->archive, path);
		default: 
			archive_set_error(archivehandler->archive, LUAARCHIVE_ERR_UNKMODE,
						LUAARCHIVE_ERRMSG_UNKMODE);
			return 1;
	}
}		/* -----  end of function aux_open  ----- */


	int
aux_close ( luaarchive_p archivehandler )
{
	switch (archivehandler->mode) {
		case LUAARCHIVE_RDMODE:
			if (!archive_read_close(archivehandler->archive))
				return 1;
			return archive_read_finish(archivehandler->archive);
		case LUAARCHIVE_WRMODE:
			if (!archive_write_close(archivehandler->archive))
				return 1;
			return archive_write_finish(archivehandler->archive);
		default:
			archive_set_error(archivehandler->archive, LUAARCHIVE_ERR_UNKMODE,
					LUAARCHIVE_ERRMSG_UNKMODE);
			return 1;
	}
}		/* -----  end of function aux_close  ----- */


	int
aux_finish ( luaarchive_p archivehandler )
{
	switch (archivehandler->mode) {
		case LUAARCHIVE_RDMODE:
			return archive_read_finish(archivehandler->archive);
		case LUAARCHIVE_WRMODE:
			return archive_write_finish(archivehandler->archive);
		default:
			archive_set_error(archivehandler->archive, LUAARCHIVE_ERR_UNKMODE,
					LUAARCHIVE_ERRMSG_UNKMODE);
			return 1;
	}
}		/* -----  end of function aux_finish  ----- */


	int
aux_support_format_read ( luaarchive_p archivehandler )
{
	switch (archivehandler->type) {
		case LUAARCHIVE_TAR:
			return archive_read_support_format_tar(archivehandler->archive);
		case LUAARCHIVE_CPIO:
			return archive_read_support_format_cpio(archivehandler->archive);
		default:
			archive_set_error(archivehandler->archive, LUAARCHIVE_ERR_UNKTYPE,
					LUAARCHIVE_ERRMSG_UNKTYPE);
			return 1;
	}
}		/* -----  end of function aux_support_format_read  ----- */


	int
aux_support_format_write ( luaarchive_p archivehandler )
{
	switch (archivehandler->type) {
		case LUAARCHIVE_TAR:
			  return archive_write_set_format_ustar(archivehandler->archive);
		case LUAARCHIVE_CPIO:
			  return archive_write_set_format_cpio(archivehandler->archive);
		default:
			  archive_set_error(archivehandler->archive, LUAARCHIVE_ERR_UNKTYPE,
					  LUAARCHIVE_ERRMSG_UNKTYPE);
			  return 1;
	}
}		/* -----  end of function aux_support_format_write  ----- */

	int
aux_support_format ( luaarchive_p archivehandler )
{
	switch (archivehandler->mode) {
		case LUAARCHIVE_RDMODE:
			return aux_support_format_read (archivehandler);
		case LUAARCHIVE_WRMODE:
			return aux_support_format_write (archivehandler);
		default:
			archive_set_error(archivehandler->archive, LUAARCHIVE_ERR_UNKMODE,
					LUAARCHIVE_ERRMSG_UNKMODE);
			return 1;
	}
}		/* -----  end of function aux_support_format  ----- */

	int
aux_support_compression_read ( luaarchive_p archivehandler )
{
	switch (archivehandler->compression) {
		case LUAARCHIVE_GZIP:
			return archive_read_support_compression_gzip(archivehandler->archive);
		case LUAARCHIVE_BZIP2:
			return archive_read_support_compression_bzip2(archivehandler->archive);
		case LUAARCHIVE_COMPRESS:
			return archive_read_support_compression_compress(archivehandler->archive);
		case LUAARCHIVE_NOCOMPRESSION:
			return archive_read_support_compression_none(archivehandler->archive);
		case LUAARCHIVE_ALLCOMPRESSION:
			return archive_read_support_compression_all(archivehandler->archive);
		default:
			archive_set_error(archivehandler->archive, LUAARCHIVE_ERR_BADCOMPRESSION,
					LUAARCHIVE_ERRMSG_BADCOMPRESSION);
			return 1;
	}
}		/* -----  end of function aux_support_compression_read  ----- */

	int
aux_support_compression_write ( luaarchive_p archivehandler )
{
	switch(archivehandler->compression) {
		case LUAARCHIVE_GZIP:
			return archive_write_set_compression_gzip(archivehandler->archive);
		case LUAARCHIVE_BZIP2:
			return archive_write_set_compression_bzip2(archivehandler->archive);
		case LUAARCHIVE_NOCOMPRESSION:
			return archive_write_set_compression_none(archivehandler->archive);
		default:
			archive_set_error(archivehandler->archive, LUAARCHIVE_ERR_BADCOMPRESSION,
					LUAARCHIVE_ERRMSG_BADCOMPRESSION);
			return 1;
	}
}		/* -----  end of function aux_support_compression_write  ----- */

	int
aux_support_compression ( luaarchive_p archivehandler )
{
	switch (archivehandler->mode) {
		case LUAARCHIVE_RDMODE:
			return aux_support_compression_read(archivehandler);
		case LUAARCHIVE_WRMODE:
			return aux_support_compression_write(archivehandler);
		default:
			archive_set_error(archivehandler->archive, LUAARCHIVE_ERR_UNKMODE,
					LUAARCHIVE_ERRMSG_UNKMODE);
			return 1;
	}
}		/* -----  end of function aux_support_compression  ----- */


	char * 
aux_filetype ( mode_t m )
{
	if (S_ISREG(m))     return "regular";
    else if (S_ISLNK(m))    return "link";
    else if (S_ISDIR(m))    return "directory";
    else if (S_ISCHR(m))    return "character device";
    else if (S_ISBLK(m))    return "block device";
    else if (S_ISFIFO(m))   return "fifo";
    else if (S_ISSOCK(m))   return "socket";
    else            return "?";

}		/* -----  end of function aux_filetype  ----- */


	char *
aux_mode ( luaarchive_p archivehandler )
{
	switch (archivehandler->mode) {
		case LUAARCHIVE_RDMODE:
			return "read";
		case LUAARCHIVE_WRMODE:
			return "write";
		default:
			return "unknow";
	}
}		/* -----  end of function aux_mode  ----- */


