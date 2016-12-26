
RPNS = top.rpn incdec.rpn absneg.rpn div.rpn mul.rpn addsub.rpn mask.rpn \
       logical.rpn bit.rpn
SRCS = lb-test.s
OBJS = $(RPNS:%.rpn=%.o) $(SRCS:%.s=%.o)
MOD = lb-test.mod

all: $(MOD)

%.o: %.s
	asnut -g $<

%.o: %.rpn
	rpncomp -l $<

$(MOD): $(OBJS) Plugin4K.scm lb-test.moddesc
	lnnut -g $(OBJS) Plugin4K.scm lb-test.moddesc

clean:
	rm $(OBJS) $(MOD)
