CFLAGS  := -std=c99 -Wall -O2 -D_REENTRANT -g
LIBS    := -lpthread -lm

TARGET  := $(shell uname -s | tr [A-Z] [a-z] 2>/dev/null || echo unknown)

ifeq ($(TARGET), sunos)
	CFLAGS += -D_PTHREADS
	LIBS   += -lsocket
endif

SRC  := wrk.c darray.c bstrlib.c bstraux.c aprintf.c stats.c units.c ae.c zmalloc.c http_parser.c tinymt64.c dynamic.c
BIN  := wrk

ODIR := obj
OBJ  := $(patsubst %.c,$(ODIR)/%.o,$(SRC))

all: $(BIN)

clean:
	$(RM) $(BIN) obj/*

$(BIN): $(OBJ)
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

$(OBJ): config.h Makefile | $(ODIR)

$(ODIR):
	@mkdir $@

src/dynamic.c: src/dynamic.rl
	ragel src/dynamic.rl

$(ODIR)/%.o : %.c
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: all clean
.SUFFIXES:
.SUFFIXES: .c .o

vpath %.c src
vpath %.h src
