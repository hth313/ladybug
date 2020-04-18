OS4 = ../../OS4/src
SRCS = ladybug.s bank2.s
OBJS = $(SRCS:%.s=%.o)
MOD = ladybug.mod

all: $(MOD)

%.o: %.s
	asnut -I$(OS4) -I/usr/local/lib/nutstudio-nut-3.0.3/include -g -l $^ -o $@
#+RTS -s -prof -hy -L60
# -xc -K500K -p -s    -prof -hc   -hy -L60

$(MOD): $(OBJS) linker.scm ladybug.moddesc
	lnnut -g $(OBJS) --list-file=linker.lst linker.scm ladybug.moddesc

clean:
	-rm $(OBJS) $(MOD) ladybug.elf
