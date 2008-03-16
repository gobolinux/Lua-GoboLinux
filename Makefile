CURRENT_DIR=`pwd`

INSTALL_DIR="1.0"
PROGRAM_NAME="Lua-GoboLinux"
PROGRAM_VERSION="1.0"
LUA_MODULES="lua/"
LUA_SETTINGS="Settings"
C_MODULES="src/GoboLinux"
TARBALL_EXCLUDE 	= "*.{o,gz,zip}"
TARBALL_EXCLUDE2	= "Scripts/Root/*"
ZIP_EXCLUDE     	= *.o *.gz *.zip Scripts/Root*

all: sources localinstall

sources:
	cd $(CURRENT_DIR)/src/ && $(MAKE)

localinstall:
	mkdir -p $(INSTALL_DIR)/Shared/lua/5.1
	mkdir -p $(INSTALL_DIR)/lib/lua/5.1
	mkdir -p $(INSTALL_DIR)/Resources/Defaults/Settings/$(PROGRAM_NAME)
	cp -a $(LUA_MODULES)/* $(INSTALL_DIR)/Shared/lua/5.1
	cp -a $(LUA_SETTINGS)/* $(INSTALL_DIR)/Resources/Defaults/Settings/$(PROGRAM_NAME)
	cp -a $(C_MODULES)/* $(INSTALL_DIR)/lib/lua/5.1

clean:
	cd $(CURRENT_DIR)/src/ && $(MAKE) clean

distclean:
	cd $(CURRENT_DIR)/src/ && $(MAKE) distclean
	rm -rf $(INSTALL_DIR)

# requires sudo
goboinstall:
	sudo mkdir -p /Programs/$(PROGRAM_NAME)/
	sudo cp -a $(INSTALL_DIR) /Programs/$(PROGRAM_NAME)/
	sudo SymlinkProgram $(PROGRAM_NAME)
	sudo UpdateSettings $(PROGRAM_NAME)
	sudo SymlinkProgram $(PROGRAM_NAME)

#---------- tarball --------------------------------------
tarball:
					lokaldir=`pwd`; lokaldir=$${lokaldir##*/}; \
					rm --force $$lokaldir.tar.gz;              \
					tar --exclude=$(TARBALL_EXCLUDE)           \
						--exclude=$(TARBALL_EXCLUDE2)			\
					    --create                               \
					    --gzip                                 \
					    --verbose                              \
					    --file  $$lokaldir.tar.gz *

#---------- zip ------------------------------------------
zip:
					lokaldir=`pwd`; lokaldir=$${lokaldir##*/}; \
					zip -r  $$lokaldir.zip * -x $(ZIP_EXCLUDE)


