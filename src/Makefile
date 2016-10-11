
SRCS = ladybug.s bank2.s mainframe.s osExtension.s
OBJS = $(SRCS:%.s=%.o)
MOD = ladybug.mod

all: $(MOD)

%.o: %.s
	asnut -g -L $<

$(MOD): $(OBJS) linker.scm ladybug.moddesc
	lnnut -g $(OBJS) -Llinker.lst linker.scm ladybug.moddesc

clean:
	rm $(OBJS) $(MOD)
