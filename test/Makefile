
RPNS = top.rpn incdec.rpn absneg.rpn div.rpn mul.rpn addsub.rpn mask.rpn
SRCS = lb-test.s
OBJS = $(RPNS:%.rpn=%.o) $(SRCS:%.s=%.o)
MOD = lb-test.mod

all: $(MOD)

%.o: %.s
	../../goabby/bin/asnut -g $<

%.o: %.rpn
	../../goabby/bin/rpncomp -L $<

$(MOD): $(OBJS) Plugin4K.scm lb-test.moddesc
	../../goabby/bin/lnnut -g $(OBJS) Plugin4K.scm lb-test.moddesc

clean:
	rm $(OBJS) $(MOD)
