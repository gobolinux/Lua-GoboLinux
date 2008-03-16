#
#
#
#
#
#

PROJECT_NAME=GoboLinux
LIBRARY=$(PROJECT_NAME).so

LUA_LIBS=`pkg-config --libs lua`

CC = gcc
CFLAGS += -I./include 

OBJ_MODULES=fs/fs.o
OBJ_LIBRARY=GoboLinux.o

all: $(LIBRARY)

$(LIBRARY): modules GoboLinux.o
	$(CC) $(CFLAGS) -shared -o $@  $(OBJ_MODULES) $(OBJ_LIBRARY)
	mkdir -p GoboLinux
	cp $@ GoboLinux/

GoboLinux.o: GoboLinux.c
	$(CC) -c $^ $(CFLAGS)

modules:
	cd fs && $(MAKE) 

clean: 
	cd fs && $(MAKE) clean
	rm -rf *.o
	rm -rf $(LIBRARY)

distclean: clean
	rm -rf GoboLinux
