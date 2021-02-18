
SRCS = ladybug.s bank2.s mainframe.s osExtension.s
OBJS = $(SRCS:%.s=%.o)
MOD = ladybug.mod ladybug.mod2

all: $(MOD)

%.o: %.s
	asnut --core=NEWT -g -l $<

$(MOD): $(OBJS) linker.scm ladybug.moddesc
	lnnut -g $(OBJS) --list-file=linker.lst  --extra-output-formats=mod2 linker.scm ladybug.moddesc -o ladybug

clean:
	-rm $(OBJS) $(MOD) ladybug
