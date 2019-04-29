
SRCS = ladybug.s bank2.s mainframe.s osExtension.s
OBJS = $(SRCS:%.s=%.o)
MOD = ladybug.mod

all: $(MOD)

%.o: %.s
	asnut -g -l $<

$(MOD): $(OBJS) linker.scm ladybug.moddesc
	lnnut -g $(OBJS) --list-file=linker.lst linker.scm ladybug.moddesc -o ladybug

clean:
	-rm $(OBJS) $(MOD) ladybug
