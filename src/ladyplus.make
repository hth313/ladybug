# Create an image with OS, Ratatosk and Ladybug as a single entity for
# complete debugging.

MAINFRAME = ../../mainframe/src
OS4 = ../../OS4/src
BOOST41 = ../../boost41/src
LIB41 = ../../lib41/include

VPATH = $(MAINFRAME):$(OS4):$(BOOST41)

LADYPLUS = ladyplus.mod
SRCS = ladybug.s bank2.s \
       core.s coreBank2.s buffer.s shell.s keyboard.s  catalog.s \
       secondaryFunctions.s semiMerged.s xmem.s  partial.s assignment.s timer.s \
       boost.s cat.s compile.s poll.s ramed.s xmemory.s xeq.s \
       assign.s readrom16.s writerom16.s random.s partialKeys.s \
       compare.s \
       cn0b.s cn1b.s cn2b.s cn3b.s cn4b.s cn5b.s cn6b.s \
       cn7b.s cn8b.s cn9b.s cn10b.s cn11b.s \
       extfuns.s time.s extfuns2.s
OBJS = $(SRCS:%.s=%-plus.o)
LADYPLUS = ladyplus.mod

%-plus.o: %.s
	asnut -DHP41CX --cpu=newt -I$(OS4) -I$(LIB41) -g --list-file=$(*F)-plus.lst $< -o $@

all: $(LADYPLUS)

$(LADYPLUS): $(OBJS) ladyplus.scm ladyplus.moddesc
	lnnut -g $(OBJS) --list-file=ladyplus.lst --extra-output-formats=mod2 ladyplus.scm ladyplus.moddesc ../../lib41/src/lib41-os4.a

clean:
	rm $(OBJS) $(MOD)
