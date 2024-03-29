# Create an image with OS, OS4, Boost41 and Ladybug as a single entity for
# complete debugging.
#
# NOTE:
# The hp41-OS4-interopability is intended to replace this, but I will
# keep this one around for a while.

MAINFRAME = ../../mainframe/src
OS4 = ../../OS4/src
BOOST41 = ../../boost41/src

VPATH = $(MAINFRAME):$(OS4):$(BOOST41)

LADYPLUS = ladyplus.mod
SRCS = ladybug.s bank2.s \
       core.s coreBank2.s buffer.s shell.s keyboard.s catalog.s \
       secondaryFunctions.s semiMerged.s xmem.s partial.s assignment.s \
       timer.s conversion.s ranges.s \
       boost.s ramed.s compile.s poll.s cat.s xmemory.s xeq.s \
       assign.s readrom16.s writerom16.s random.s partialKeys.s \
       compare.s delay.s returnStack.s luhn.s apx.s fixeng.s vmant.s \
       yntest.s alpha.s binbcds.s arithmetic.s code.s decode.s stack.s \
       bufferUtils.s \
       cn0b.s cn1b.s cn2b.s cn3b.s cn4b.s cn5b.s cn6b.s \
       cn7b.s cn8b.s cn9b.s cn10b.s cn11b.s \
       extfuns.s time.s extfuns2.s
OBJS = $(SRCS:%.s=%-plus.o)
LADYPLUS = ladyplus.mod

%-plus.o: %.s
	asnut -DHP41CX --cpu=newt -I$(OS4) -g --list-file=$(*F)-plus.lst $< -o $@

all: $(LADYPLUS)

$(LADYPLUS): $(OBJS) ladyplus.scm ladyplus.moddesc
	lnnut -g $(OBJS) --list-file=ladyplus.lst --extra-output-formats=mod2 ladyplus.scm ladyplus.moddesc

clean:
	rm $(OBJS) $(MOD)
