#===============================================================================
#
#         File: Makefile
#  Description: 
#
#        Usage: make              (generate executable(s)                    )
#               make clean        (remove objects, executables, prerequisits )
#               make distclean	  (remove local installs also				 )
#               make tarball      (generate compressed archive               )
#               make zip          (generate compressed archive               )
#               make localinstall (install the project under .				 )
#               make goboinstall  (install the project for GoboLinux systems )	
#                                  
#       Author: Aitor Pérez Iturri
#        Email: aitor.iturri@gmail.com
#      Created: 
#
#===============================================================================

CURRENT_DIR			= `pwd`

#--------- project info ----------------------------------
PROJECT_NAME		= Lua-Archive
PROJECT_VERSION		= 1.0

#--------- build configuration ---------------------------
CC              	= gcc
CCP             	= g++
CFLAGS          	= -c -g -Wall
LFLAGS          	= -g
SYS_LIBS        	= -lm
TARBALL_EXCLUDE 	= "*.{o,gz,zip}"
ZIP_EXCLUDE     	= *.o *.gz *.zip

TARGETS				= tar.so cpio.so

#--------- install configuration -------------------------
USES_LUA_MODULES	= yes
USES_C_MODULES		= yes
USES_DOCS			= yes
LOCAL_INSTALL		= $(CURRENT_DIR)/$(PROJECT_VERSION)
C_MODULES			= tar/tar cpio/cpio
LUA_MODULES			= lua/tar.lua
DOCS				= README

#---------- targets --------------------------------------
all:	$(TARGETS)

%.o:	%.c
			$(CC) $(CFLAGS) $*.c

%.o:	%.cc
			$(CCP) $(CFLAGS) $*.cc
 
#---------- target 1 -------------------------------------
#  C  target
common:
		@cd src && $(MAKE)

#---------- target 2 -------------------------------------
tar.so:	common
		@cd tar && $(MAKE)

cpio.so: common
		@cd cpio && $(MAKE)

#---------- target 3 -------------------------------------

#---------- tarball --------------------------------------
tarball:
					lokaldir=`pwd`; lokaldir=$${lokaldir##*/}; \
					rm --force $$lokaldir.tar.gz;              \
					tar --exclude=$(TARBALL_EXCLUDE)           \
					    --create                               \
					    --gzip                                 \
					    --verbose                              \
					    --file  $$lokaldir.tar.gz *

#---------- zip ------------------------------------------
zip:
					lokaldir=`pwd`; lokaldir=$${lokaldir##*/}; \
					zip -r  $$lokaldir.zip * -x $(ZIP_EXCLUDE)

#---------- clear up -------------------------------------
clean:	clean_common clean_modules
				rm  --force  $(EXECUTABLE) $(OBJECTS) $(PREREQUISITES)
 
#---------- clean common ---------------------------------
clean_common:
			@cd src && $(MAKE) clean

#---------- clean modules --------------------------------
clean_modules:
			@cd tar && $(MAKE) clean
			@cd cpio && $(MAKE) clean

#---------- distribution clean ---------------------------
distclean:	clean
			rm -rf $(LOCAL_INSTALL)

#---------- local installation ---------------------------
localinstall:	all
ifeq ($(USES_LUA_MODULES),yes)
			mkdir -p $(LOCAL_INSTALL)/Shared/lua/5.1
			cp -a $(LUA_MODULES) $(LOCAL_INSTALL)/Shared/lua/5.1
endif
ifeq ($(USES_C_MODULES),yes)
			mkdir -p $(LOCAL_INSTALL)/lib/lua/5.1
			cp -a $(C_MODULES) $(LOCAL_INSTALL)/lib/lua/5.1
endif
ifeq ($(USES_DOCS),yes)
			mkdir -p $(LOCAL_INSTALL)/doc
			cp -a $(DOCS) $(LOCAL_INSTALL)/doc
endif

#---------- goboinstall ----------------------------------
goboinstall:	localinstall
			sudo mkdir -p /Programs/$(PROJECT_NAME)/
			sudo cp -a $(LOCAL_INSTALL) /Programs/$(PROJECT_NAME)/
			sudo SymlinkProgram $(PROJECT_NAME)
			sudo UpdateSettings $(PROJECT_NAME)
			sudo SymlinkProgram $(PROJECT_NAME)

