
SRCS = programmer.s bank2.s mainframe.s osExtension.s
OBJS = $(SRCS:%.s=%.o)
MOD = programmer.mod

all: $(MOD)

%.o: %.s
	../../goabby/bin/asnut -g $<

$(MOD): $(OBJS) linker.scm programmer.moddesc
	../../goabby/bin/lnnut -g $(OBJS) linker.scm programmer.moddesc

clean:
	rm $(OBJS) $(MOD)
