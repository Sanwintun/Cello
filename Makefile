CC ?= gcc
AR ?= ar

VERSION = 2.0.2
PACKAGE = libCello-$(VERSION)

BINDIR = ${PREFIX}/bin
INCDIR = ${PREFIX}/include
LIBDIR = ${PREFIX}/lib

SRC := $(wildcard src/*.c)
OBJ := $(addprefix obj/,$(notdir $(SRC:.c=.o)))

TESTS := $(wildcard tests/*.c)
TESTS_OBJ := $(addprefix obj/,$(notdir $(TESTS:.c=.o)))

EXAMPLES := $(wildcard examples/*.c)
EXAMPLES_OBJ := $(addprefix obj/,$(notdir $(EXAMPLES:.c=.o)))
EXAMPLES_EXE := $(EXAMPLES:.c=)

CFLAGS = -I ./include -std=gnu99 -Wall -Wno-unused -O3 -g -ggdb
LFLAGS = -g -ggdb

PLATFORM := $(shell uname)
COMPILER := $(shell $(CC) -v 2>&1 )

ifeq ($(findstring MINGW,$(PLATFORM)),MINGW)
	PREFIX ?= C:/MinGW64/x86_64-w64-mingw32

	DYNAMIC = libCello.dll
	STATIC = libCello.a
	LIBS = -lDbgHelp
	
	INSTALL_LIB = cp $(STATIC) $(LIBDIR)/$(STATIC); cp $(DYNAMIC) $(BINDIR)/$(DYNAMIC)
	INSTALL_INC = cp -r include/Cello.h $(INCDIR)
	UNINSTALL_LIB = rm -f ${LIBDIR}/$(STATIC)
	UNINSTALL_INC = rm -f ${INCDIR}/Cello.h
else ifeq ($(findstring FreeBSD,$(PLATFORM)),FreeBSD)
	PREFIX ?= /usr/local

	DYNAMIC = libCello.so
	STATIC = libCello.a
	LIBS = -lpthread -lexecinfo -lm

	CFLAGS += -fPIC
	LFLAGS += -rdynamic

	INSTALL_LIB = mkdir -p ${LIBDIR} && cp -f ${STATIC} ${LIBDIR}/$(STATIC)
	INSTALL_INC = mkdir -p ${INCDIR} && cp -r include/Cello.h ${INCDIR}
	UNINSTALL_LIB = rm -f ${LIBDIR}/$(STATIC)
	UNINSTALL_INC = rm -f ${INCDIR}/Cello.h
else
	PREFIX ?= /usr/local

	DYNAMIC = libCello.so
	STATIC = libCello.a
	LIBS = -lpthread -ldl -lm

	CFLAGS += -fPIC
	LFLAGS += -rdynamic

	INSTALL_LIB = mkdir -p ${LIBDIR} && cp -f ${STATIC} ${LIBDIR}/$(STATIC)
	INSTALL_INC = mkdir -p ${INCDIR} && cp -r include/Cello.h ${INCDIR}
	UNINSTALL_LIB = rm -f ${LIBDIR}/$(STATIC)
	UNINSTALL_INC = rm -f ${INCDIR}/Cello.h
endif

# Libraries

all: $(DYNAMIC) $(STATIC)

$(DYNAMIC): $(OBJ)
	$(CC) $(OBJ) -shared $(LFLAGS) $(LIBS) -o $@

$(STATIC): $(OBJ)
	$(AR) rcs $@ $(OBJ)

obj/%.o: src/%.c | obj
	$(CC) $< -c $(CFLAGS) -o $@

obj:
	mkdir -p obj

# Tests

check: $(TESTS_OBJ) $(STATIC)
	$(CC) $(TESTS_OBJ) $(STATIC) $(LIBS) $(LFLAGS) -o ./tests/test
	./tests/test
	rm -f ./tests/test.bin ./tests/test.txt

obj/%.o: tests/%.c | obj
	$(CC) $< -c $(CFLAGS) -o $@

# Benchmarks

# TODO: Force bench to build with CELLO_NDEBUG
bench:
	cd benchmarks; ./benchmark; cd ../

# Examples

examples: $(EXAMPLES_EXE)

examples/%: examples/%.c $(STATIC) | obj
	$(CC) $< $(STATIC) $(CFLAGS) $(LIBS) -o $@

# Dist

dist: all | $(PACKAGE)
	cp -R examples include src tests LICENSE.md Makefile README.md $(PACKAGE)
	tar -czf $(PACKAGE).tar.gz $(PACKAGE)

$(PACKAGE):
	mkdir -p $(PACKAGE)

# Clean

clean:
	rm -f $(OBJ) $(TESTS_OBJ) $(EXAMPLES_OBJ) $(STATIC) $(DYNAMIC)
	rm -f test

# Install

install: all
	$(INSTALL_LIB)
	$(INSTALL_INC)
	
# Uninstall

uninstall:
	$(UNINSTALL_LIB)
	$(UNINSTALL_INC)

