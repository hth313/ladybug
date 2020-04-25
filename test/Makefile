
RPNS = top.rpn incdec.rpn absneg.rpn div.rpn mul.rpn addsub.rpn mask.rpn \
       logical.rpn bit.rpn shift.rpn sex.rpn cmp.rpn memory.rpn stack.rpn \
       alpha.rpn bitsum.rpn wsize.rpn compare.rpn exchange.rpn

SRCS = lb-test.s lb-test-2.s
OBJS = $(RPNS:%.rpn=%.o) $(SRCS:%.s=%.o)
MOD = lb-test.mod

all: $(MOD)

%.o: %.s
	asnut -l -g $<

%.o: %.rpn
	rpncomp -I../src -l $<

$(MOD): $(OBJS) Plugin4K.scm lb-test.moddesc
	lnnut --list-file=linker.lst -g $(OBJS) Plugin4K.scm lb-test.moddesc

clean:
	rm $(OBJS) $(MOD)
