
SRCS = programmer.s mainframe.s
OBJS = $(SRCS:%.s=%.o)
MOD = programmer.mod

all: $(MOD)

%.o: %.s
	../../goabby/bin/asnut -g $<

$(MOD): $(OBJS) Plugin4K.scm programmer.moddesc
	../../goabby/bin/lnnut -g $(OBJS) Plugin4K.scm programmer.moddesc

clean:
	rm $(OBJS) $(MOD)
