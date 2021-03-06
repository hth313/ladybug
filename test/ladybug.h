#ifndef __LADYBUG_H
#define __LADYBUG_H

.import ladybug
.import lb-test

.postfix ALDI, PSEI, DSZI, DECI, INCI, WSIZE, CLRI (semi-merged-postfix)
.postfix LDI, STI, CMP, SEX                        (semi-merged-postfix)
.postfix SB, CB, B?                                (semi-merged-postfix)
.postfix RR, RL, RRC, RLC, ASR, SL, SR             (semi-merged-postfix)
.postfix MASKL, MASKR, BITSUM, TST                 (semi-merged-postfix)
.postfix #LIT                                      (semi-merged-integer-literal)
.postfix =I, ≠I, <I, <=I, <>I                      (semi-merged-dual)

// Using an instruction with a # makes the C preprocessor complain, we hide
// it using a macro.
#define integer #LIT

#endif // __LADYBUG_H
