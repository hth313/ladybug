#if 0
;;; **********************************************************************

              LadyBug module for the HP-41 calculator series.

    This module provides an integer mode for the HP-41, much like what is
    available on the HP-16C.

    This module is intended for professionals working with computers at the
    lowest level.

    The name is derived from that the module is a very useful tool when
    debugging, these are kind of friendly bugs, and the HP-41 is powered
    by Lady sized cells.

    Internal HP-41 registers are 56-bits wide, but we want to provide up
    to 64-bit values. These extra bits needs to go somewhere and this
    module makes use of a buffer to store the extra bits and its internal
    settings.


    Accessing the buffer is basically done in 3 different ways.

    Code that need to work no matter if there is a buffer or not, like
    poll vectors use the 'chkbuf' entry which will locate the buffer and
    tell you if it is not there (using P+1/P+2 returns).

    Internal code that want to access internal flags (such as key entry
    and active base), uses 'FindBuffer'. This exits with an error if the
    buffer does not exist. It gives easy access to internal flags (which
    is where such information is stored), and provide a much more elaborate
    setup compared to 'chkbuf'.

    Operations (like add and shifts) uses a variant of 'findIntegerBuffer'
    that sets up the user flags (such as sign mode, carry and zero flags).
    Examples of such routines are 'findIntegerBufferUserFlags' and
    'findIntegerBufferGetXSaveL'.
    These are similar to 'findIntegerBuffer', but as mentioned, they set
    up user flags instead of the internal flag set.

    Exiting needs to be matched with the variant of FindBuffer used. The
    exit routines depend a lot on the flag set that is active.
    Typical use is 'PutX' which stores a new X values and sets flags, which
    means it wants user flags active.
    The few routines that used 'FindBuffer' will need to exit using Exit or
    ExitS11 (exit and set push flag). User flags are not updated in this
    case and there is no provision for a new X value.

;;; **********************************************************************
#endif

#include "mainframe.h"
#include "OS4.h"

;;; Define key code symbol for a function.
KeyCode:      .macro  fun
`\fun_Code`:  .equ    FATOFF(fun)
              .endm

;;; Define key code symbols we use
              KeyCode CLXI          ; create CLXI_Code symbol
              KeyCode Literal       ; used for digit entry

;;; Macro to handle early key release during digit entry.
;;; S13 (running flag) is borrowed here as we know we are not
;;; executing a program at the same time as we are entering
;;; numbers.
releaseKey:   .macro
              ?s13=1                ; key already released?
              goc     10$           ; yes
              rst kb                ; try to release key
              chk kb
              goc     10$           ; key still down
              s13=1                 ; key released
10$:          .endm


;;; Start of function address table (start of ROM)
              .section FAT
XROMno:       .equ    16

              .con    XROMno        ; XROM number
              .con    (FatEnd - FatStart) / 2 ; number of entry points

FatStart:
              .fat    LadyHeader    ; ROM header
              FAT     Literal
              FAT     EXITAPP       ; drop to previous App
              .fat    Integer
              FAT     Binary        ; base related instructions
              FAT     Octal
              FAT     Decimal
              FAT     Hex
              FAT     WSIZE
              FAT     WSIZE?
              FAT     WINDOW
              FAT     CLXI          ; clear IX
              FAT     ENTERI        ; ENTER^ on integer stack
              FAT     LASTXI
              FAT     SWAPI
              FAT     RDNI
              FAT     RUPI
              FAT     ADD           ; Arithmetic instructions
              FAT     SUB
              FAT     MUL           ; Arithmetic instructions
              FAT     DIV
              FAT     RMD
              FAT     ABSI
              FAT     NEG
              FAT     AND           ; Logical instructions
              FAT     NOT
              FAT     OR
              FAT     XOR
              FAT     SL
              FAT     RL            ; Shift instructions
              FAT     RLC
              FAT     SR
              FAT     RR
              FAT     RRC
              FAT     ASR
              FAT     DMUL
              FAT     DDIV
              FAT     DRMD
              FAT     B?
              FAT     CB
              FAT     SB
              FAT     MASKL
              FAT     MASKR
              FAT     LDI
              FAT     STI
              FAT     ALDI
              FAT     DECI
              FAT     INCI
              FAT     CLRI
              FAT     DSZI
              FAT     SEX
              FAT     CMP
              FAT     TST
              FAT     GE?
              FAT     GT?
              FAT     LE?
              FAT     LT?
              FAT     BITSUM
              .fat    Prefix2
FatEnd:       .con    0,0


;;; **********************************************************************
;;;
;;; Buffer layout. The state is kept in a buffer with the following
;;; layout:
;;;
;;; 1000TTZZYYXXLL
;;; HHSS0D00I2WSII
;;;
;;;   where
;;;     HH - buffer number
;;;     SS - size of buffer
;;;     0  - currently not used
;;;      D - window display
;;;     00 - currently not used
;;;     WS - Word size (1-64)
;;;     II - internal flags
;;;
;;; **********************************************************************

;;; Internal flags

;;; Lower nibble is base - 1
;;;   1111   hex
;;;   1001   decimal
;;;   0111   octal
;;;   0001   binary
;;;
;;; Decoding:
;;; 1. bit 1 -> hex or oct (goto 3)
;;; 2. bit 3 -> dec, otherwise bin
;;; 3. bit 3 -> hex, otherwise oct
;;;
;;; Can also be used to check if a entered digit is in range.

;;; Integer mode digit entry ongoing flag.
;;; This is a cached copy of the system digit entry flag, used as it
;;; is easier to have single flag set internally.
;;; The overall state is that the system digit entry and active shell
;;; tells who is doing digit entry.
IF_DigitEntry: .equ   4


;;; ----------------------------------------------------------------------
;;;
;;; Exposed integer flags
;;;
;;; These flags are meant to be shown on annunciators to give visual
;;; feedback.
;;;
;;; Internally, they are up when running instructions, but not when
;;; dealing with input and display code.
;;;
;;; ----------------------------------------------------------------------

Flag_Zero:    .equ    7             ; user flag 0
Flag_Sign:    .equ    6             ; user flag 1
Flag_2:       .equ    5             ; user flag 2
Flag_CY:      .equ    4             ; user flag 3
Flag_Overflow: .equ   3             ; user flag 4
Flag_ZeroFill: .equ   2             ; user flag 5

Flag_UpperHalf: .equ  8             ; set when word size is more than 56

BufNumber:    .equ    0             ; Try with 0! Otherwise 4 might be used?
BufSize:      .equ    2

SWPMD8:       .equlab 0x3fe0
DSPLN:        .equlab 0xFC7
PAR110:       .equlab 0xCEB
ROW930:       .equlab 0x460
PCTOC:        .equlab 0xD7
PARS60:       .equlab 0xCB4

Text1:        .equ    0xf1

OperandIND:   .equ    128
Operand00:    .equ    0
Operand01:    .equ    1
Operand16:    .equ    16
OperandX:     .equ    115
OperandY:     .equ    114
OperandIndX:  .equ    Indirect + OperandIND

;;; Macro to switch to given bank on the fly.
switchBank:   .macro  n
              enrom\n
10$:
              .section Code\n
              .shadow 10$
              .endm

;;; ************************************************************
;;;
;;; ROM header.
;;;
;;; ************************************************************

              .section Code, reorder
              .name   "-LADYBUG 1A"  ; The name of the module
LadyHeader:   rtn

;;; **********************************************************************
;;;
;;; Secondary FATs
;;;
;;; **********************************************************************

              .section Code, reorder
              .name   "(LBFX2)"
Prefix2:      gosub   runSecondary
              .con    58            ; XROM 16,58

              .section LadybugFC2
              .con    .low12 secondary2 ; Root pointer for secondary FAT headers

;;; Secondary FAT header, serving bank 2
              .section LadybugSecondary1, reorder
              .align  4
secondary2:   .con    0      ; pointer to next table
              .con    (FAT2End - FAT2Start) / 2
              .con    58            ; prefix XROM (XROM 16,58 - (LBFX2))
              .con    0             ; start index
              .con    .low12 FAT2Start
              switchBank 2          ; this one is in bank 2
              rtn

              .section LadybugSecondary2
              .align  4
FAT2Start:    .fat    EQ
              .fat    NE
              .fat    LT
              .fat    LE
              .fat    EXCHANGE
              .fat    VIEWI
FAT2End:      .con    0,0

;;; ************************************************************
;;;
;;; ladybugShell - the application shell definition
;;;
;;; This record describes to OS4 that we are an application
;;; with suitable key and display handlers.
;;;
;;; ************************************************************

              .section Shell, reorder
              .align  4
ladybugShell: .con    AppShell
              .con    .low12 displayX
              .con    .low12 keyHandler ; standard keys
              .con    .low12 keyHandler ; user keys
              .con    0                 ; alpha keys, use default
              .con    .low12 myName
              .con    0                 ; no timeouts

              .section Code
              .align  4
myName:       .messl  "LADYBUG"

;;; ************************************************************
;;;
;;; Program literal.
;;;
;;; The name try to be fairly short to avoid scrolling when
;;; shown in a program before the line is changed.
;;; Yes it is descriptive enough to give a hint when briefly
;;; seen and not really typable.
;;;
;;; It is to be followed by a text literal that embeds the actual
;;; integer literal, if not, 0 is loaded.
;;;
;;; ************************************************************

              .section Code, reorder
              .name   "#LIT"
Literal:      gosub   xargument     ; mark as special form
              goto    20$           ; display it
              ?s13=1                ; running?
              goc     10$           ; yes
              ?s4=1                 ; no, single stepping?
              rtn nc                ; no, do nothing
10$:          rxq     findIntegerBufferUserFlags_liftStackS11
              rxq     fetchLiteral
              regn=c  X
              gosub   PUTPCA        ; we already have chip 0 selected
              rgo     putXnoFlags

;;; Display literal in program mode.
20$:          c=0     x
              gosub   findBuffer
              rtn                   ; (P+1) no integer b uffer
              acex                  ; C= buffer address
              cmex
              a=c                   ; A[3:0]= address of literal
              rxq     fetchLiteralA ; fetch the literal
              c=m
              dadd=c                ; select buffer header
              rgo     displayPrgmLiteral


XROMi:        .equ    160 + (XROMno / 4)
XROMj:        .equ    64 * (XROMno % 4)

;;; During digit entry, we use flag 9 to keep track of programming mode
Flag_PRGM:    .equ    9

;;; **********************************************************************
;;;
;;; The keyboard handler. We provide handlers for digit entry and ending
;;; digit entry and point to the keyboard table to use.
;;; Do not support auto assigned top keys, it slows things down too much and
;;; we rely on it for hexadecimal digit entry which should be fast.
;;;
;;; **********************************************************************

              .section Code
              .align  4
keyHandler:   gosub   keyKeyboard   ; does not return
              .con    0             ; flags
              .con    .low12 doDigit ; handle a digit
              .con    .low12 clearDigitEntry ; end digit entry
              .con    .low12 keyTable
                                    ; no transient termination entry needed
                                    ; we do not have keyboard secondaries

              .section Code
              .align  4
clearDigitEntry:
              c=0     x
              gosub   findBuffer
              goto    clearDigitEntry20 ; (P+1) should not happen
              c=data                ; get full header
              cstex                 ; clear internal digit entry flag
              st=0    IF_DigitEntry
              cstex
              pt=     8
              lc      0             ; clear window display
                                    ;  (doing here is safe and helps getting
                                    ;   back to window 0 when leaving program
                                    ;   mode)
              data=c
clearDigitEntry20:
              golong  clearSystemDigitEntry

;;; Handle numeric entry
              .align  4
doDigit:      releaseKey
              rxq     findIntegerBuffer ; buffer address to B[12:10]
              c=st                  ; restore C[1:0]
              acex    x             ; base - 1 to A[0]
              pt=     0             ; get digit to C[2:0]
              c=0     x             ; C.XS= 0
              dadd=c                ; select chip 0
              c=g
              c=c-1   xs            ; test for backspace
              c=c+1   x
              goc     backSpaceJ1   ; backspace
              c=c-1   x             ; restore digit
              c=0     xs
              ?a<c    pt            ; digit out of range?
              goc     digAbort      ; yes, blink and return via reset keyboard
              ;; Import data entry flag to our own to have it handy.
              ;; We need to obey the global one which may be reset by an alarm,
              ;; otherwise we may stay in digit entry after a control program
              ;; have executed, changing the stack entirely!
              c=regn  14
              st=0    IF_DigitEntry
              c=c+c   xs
              c=c+c   xs
              gonc    10$           ; system digit entry not set
              st=1    IF_DigitEntry
10$:          rcr     -2
              c=c+c   xs            ; are we in program mode?
              gonc    runMode       ; no
              st=1    Flag_PRGM
              rxq     prgmDigent    ; yes
              goto    dig35         ; (P+1) start digit entry
              acex                  ; (P+2) ongoing digit entry
              goto    dig40

runMode:      st=0    Flag_PRGM
              ?st=1   IF_DigitEntry ; start digit entry?
              goc     dig37         ; no
              rxq     liftStackS11  ; check if we should lift stack

;;; Start entry with 0, clear digit cache
dig35:        c=regn  14
              rcr     8             ; set flag 22
              cstex
              s1=1
              cstex
              rcr     6
              regn=c  14
              b=0     x             ; Load X (0)
              a=0
              goto    dig40

digAbort:     gosub   BLINK         ; not accepted key, blink
              s13=0                 ; reset borrowed flag
              golong  NFRKB

backSpaceJ1:  goto    backSpace     ; relay

;;; Ongoing digit entry, load X
dig37:        rxq     loadX         ; load X to B.X-A
dig40:        ?s1=1                 ; dispatch on base
              goc     hexoct        ; hex or octal
              ?s3=1
              goc     decDigit      ; decimal
              goto    binDigit      ; binary

hexoct:       ?s3=1
              goc     hexDigit      ; hex
              goto    octDigit      ; octal

decDigit:     rxq     mul10         ; prepare for a new decimal digit
              goto    dig50

hexDigit:     acex    s             ; prepare for a new hex digit
              bcex    x
              rcr     -1
              bcex    x
              asl
              goto    dig50

octDigit:     rxq     shift1
              rxq     shift1
binDigit:     rxq     shift1

;;; Having made room for the new digit, add digit
dig50:        c=0
              pt=     0
              c=g                   ; get digit
              a=a+c                 ; add digit to X
              gonc    44$
              bcex    x
              c=c+1   x
              bcex    x

44$:          rxq     acceptAndSave ; Check if value is accepted, save it
              goto    digAbort      ; too big, blink and return
              st=1    IF_DigitEntry
              c=0     x             ; also set system digit entry
              dadd=c
              c=regn  14
              rcr     2
              cstex
              s2=1
              cstex
              rcr     -2
              regn=c  14
              goto    kbDone

;;; Backspace is pressed, we have four cases.
;;; 1. If entering digits, rub out one (do CLXI if deleting to 0)
;;; 2. Perform CLXI
backSpace:    c=regn  14
              rcr     -2
              c=c+c   xs            ; program mode?
              gonc    10$           ; no
              releaseKey
              rxq     fetchLiteral  ; yes, pick up current number
              st=1    Flag_PRGM
              a=c
              goto    digBSP10J1

10$:          st=0    Flag_PRGM
              ?st=1   IF_DigitEntry ; doing digit entry?
              goc     digBSP        ; yes
              goto    keyCLXIJ1     ; no, do CLXI

kbDone:       releaseKey
              ?st=1   Flag_PRGM
              goc     10$
              rxq     displayXB10
5$:           ?s13=1                ; already released?
              goc     6$            ; yes
              rst kb                ; no, try to release key
              chk kb
              golc    NFRKB         ; return via reset keyboard
                                    ;  if not released
6$:           s13=0                 ; reset S13
              chk kb
              golc    fastDigitEntry ; shortcut to key handler
              golong  NFRC          ; return without resetting keyboard
10$:          rxq     displayPrgmLiteralDE
              goto    5$

digBSP10J1:   goto    digBSP10      ; relay

;;; Back space used and not 0. As the number is smaller than before (we deleted
;;; a character), we can just save it without doing any range checking.
bspNot0:      ?st=1   Flag_PRGM
              goc     10$
              rxq     saveUpperPart
              c=0
              dadd=c
              acex
              regn=c  X
              goto    kbDone
10$:          rxq     saveLiteral
              goto    kbDone

keyCLXIJ1:    goto    keyCLXI            ; relay

;;; Back arrow in digit entry
digBSP:       releaseKey
              rxq     loadX
digBSP10:     ?s1=1
              gonc    5$
              ?s3=1
              goc     hexBSP        ; hex
              goto    octBSP        ; oct
5$:           ?s3=1
              goc     decBSP        ; dec

              c=b                   ; bin, start with upper part
              c=c+c
              c=c+c
              c=c+c                 ; C[3:0]= upper part << 7
              rcr     1             ; C[3:0]= upper part >> 1
                                    ; C.S= bit3 is bit that goes to A.55
              bcex    x             ; B.X= upper part >> 1

              acex                  ; do lower part
              c=c+c                 ; << 3 with wrap around
              gonc    10$
              c=c+1
10$:          c=c+c
              gonc    11$
              c=c+1
11$:          c=c+c
              gonc    12$
              c=c+1
12$:          cstex
              s3=0                  ; assume bit from upper part = 0
              ?a#0    s             ; is it one?
              gonc    15$           ; no
              s3=1                  ; yes, set it
15$:          cstex
              rcr     1
              acex

dig10:        ?a#0                  ; zero result?
              goc     bspNot0       ; no
              ?b#0    x
              goc     bspNot0       ; no

              ;; Back arrow down to nothing left
dig20:        ?st=1   Flag_PRGM     ; in program mode?
              goc     dig25         ; yes
              s11=0                 ; clear push flag in case user NULL the CLXI !!!
                                    ;  (this is not done in mainframe, but it
                                    ;   probably should have)
keyCLXI:      rxq     clearDigitEntry
              pt=     3             ; build complete 2 byte XROM instruction
              lc      XROMi >> 4
              lc      XROMi & 15
              lc      (XROMj + CLXI_Code) >> 4
              lc      (XROMj + CLXI_Code) & 15
              s13=0                 ; reset borrowed key release flag
              golong  RAK70

;;; Back space doing hexadecimal input
hexBSP:       asr                   ; delete hex digit
              c=b     x
              rcr     1
              acex    s
              c=0     xs
              bcex    x
              goto    dig10

decBSP:       rxq     div10
              goto    dig10

;;; Back space doing octal input
octBSP:       c=b     x             ; oct, upper part
              c=c+c
              rcr     1
              c=0     xs
              bcex    x

              acex
              c=c+c
              gonc    10$
              a=a+1   s
10$:          rcr     1
              a=c     m
              a=c     x
              goto    dig10

dig25:        rxq     clearDigitEntry ; clear digit entry flags
              gosub   DATOFF        ; clear flags
              gosub   NXBYTP        ; clean up in program memory
              rcr     -1
              c=c+1   xs            ; text wrapper
              gonc    15$           ; no
              gosub   GETPC
              gosub   DELLIN        ; yes, remove it
              gosub   PUTPC
              gosub   BSTEP
15$:          gosub   GETPC         ; remove XROM literal
              gosub   DELLIN
              gosub   PUTPC
              s13=0                 ; reset borrowed flag
              golong  ERR120        ; back up and show previous program line

              .section Code, reorder
;;; **********************************************************************
;;;
;;; Handle entry of digits in program mode.
;;;
;;; Similar to XROMs with postfix arguments, we use an XROM function
;;; before the actual binary data embedded in a string literal.
;;; Initialization consists of writing the prefix XROM and prepare a text
;;; one place-holder.
;;;
;;; **********************************************************************

prgmDigent:   ?s12=1                ; private?
              golc    XMSGPR        ; yes

              ?st=1   IF_DigitEntry ; start digit entry?
              goc     50$           ; no

              pt=     0
              c=g
              c=stk
              n=c                   ; save char and return address in N

              gosub   INSSUB
              a=0     s             ; number of inserts so far
              ldi     0xa4          ; XROM 16,01  - A4 01
              gosub   INBYTC
              ldi     Literal_Code
              gosub   INBYTC

              releaseKey
              gosub   INSSUB
              a=0     s
              ldi     0xf0          ; Text 0, to avoid gobbling up any following
                                    ; text wrapper literal when we replace it
              gosub   INBYTC

              c=n                   ; restore
              stk=c                 ;  return address
              pt=     0
              g=c                   ;  entered char

              rxq     findIntegerBuffer ; restore M, ST

              c=0                   ; start out with 0
              b=0     x
              dadd=c                ; select chip 0
              pt=     0
              rtn

;;; Load literal from program memory
50$:          c=stk                 ; return to (P+2)
              c=c+1   m
              stk=c

fetchLiteral: gosub   GETPC
fetchLiteralA:
              gosub   NXBYT
              b=0     x             ; clear upper part
              rcr     -1
              c=c+1   xs            ; text wrapper?
              goc     10$           ; yes
              gosub   GETPC         ; no, ensure A[3:0]= PC for #LIT
              c=0                   ; no, load 0
              n=c
              dadd=c                ; select chip 0
              rtn
10$:          rcr     2
              a=c     s             ; A.S= counter
              c=0
              goto    25$

20$:          gosub   INCAD
              gosub   GTBYT         ; read byte from program memory
              pt=     1
              bcex    wpt
              cnex
              rcr     -2
              bcex    wpt
              pt=     3
25$:          cnex
              a=a-1   s
              gonc    20$

              c=0                   ; select chip 0
              dadd=c
              c=regn  14
              cstex
              ?s4=1                 ; single stepping?
              gonc    27$           ; no
              cstex
              c=regn  15            ; yes, bump line counter
              c=c+1   x
              regn=c  15
              goto    28$
27$:          cstex
28$:          c=n                   ; C= lower part of the literal
              rtn


baseChar:     ?s1=1
              goc     1$            ; oct or hex
              ?s3=1
              goc     10$           ; decimal
              goto    2$            ; binary
1$:           ?s3=1
              goc     16$           ; hex
              ldi     'O' - 0x40    ; octal
              rtn
16$:          ldi     'H' - 0x40
              rtn
10$:          ldi     'D' - 0x40
              rtn
2$:           ldi     'B' - 0x40
              rtn

              .section Code, reorder
lineAndBaseLCD:
              ?st=1   Flag_PRGM     ; in program mode?
              gonc    40$           ; no

              gosub   ENCP00
              c=regn  15            ; program line#
              c=a+c   x             ; compensate for that it is semi-merged
              a=c     x             ; A.X= line number
              ldi     16            ; disable RAM (and LCD)
              dadd=c
              a=0     s             ; let GENNUM suggest number of digits
              gosub   GENNUM        ; get line number digits
              gosub   ENLCD

              c=b     s             ; get digit count
              acex                  ; C.M= digits (left aligned), A.S= digit count

25$:          rcr     -1
              a=a-1   s
              gonc    25$
              acex
              abex    s             ; A.S= digit count

30$:          a=a-1   s             ; any digits left?
              goc     34$           ; no
              frsabc                ; sense rightmost character
              slsabc
              rcr     -1
              c=c-1   xs            ; A-F?
              goc     34$           ; yes, no more room for line number digits
              c=c-1   xs
              c=c-1   xs            ; 0-9?
              gonc    34$           ; yes, no more room for line number digits
              ldi     0x30          ; shift in least significant
              pt=     0
              acex    pt            ;  line number digit
              srsabc
              pt=     10
              asr     wpt
              goto    30$

34$:          ldi     ' '           ; make room for base character
              a=c     x
              frsabc
              ?a#c    x
              goc     36$           ; first non-space
              frsabc
              ?a#c    x
              gonc    37$           ; second space
36$:          slsabc
              acex    x
37$:          slsabc
              goto    41$

40$:          frsabc                ; rotate right
41$:          pt=     1
              c=0     x
              c=g
              a=c     x
              c=c+c   xs            ; dot before base character?
              gonc    42$           ; no
              frsabc                ; yes, insert dot on second
              cstex                 ; last character
              s6=1
              cstex
              slsabc
42$:          rxq     baseChar      ; input base character
              a=0     xs
              ?a#0    x             ; dot after base?
              gonc    44$           ; no
              cstex
              s6=1                  ; yes
              cstex
44$:          slsabc
              golong  ENCP00

              .section Code2
              .shadow putXnoFlags - 1
putXnoFlags_rom2:
              enrom1

              .section Code2
              .shadow putXDrop - 1
putXDrop_rom2:
              enrom1

              .section Code2
              .shadow putX - 1
putX_rom2:
              enrom1

              .section Code2
              .shadow exitUserST - 1
exitUserST_rom2:
              enrom1

              .section Code2
exitNoUserST_rom2:
              .shadow exitNoUserST - 1
              enrom1

;;; **********************************************************************
;;;
;;; PutX - Put back final X, update user flags accordingly
;;; PutXDrop - Alternative entry to drop stack over Y.
;;;
;;; In: ST = carry flag valid
;;;     B[12:10] - address of header buffer register
;;;     X - lower port of result
;;;     B[2:0] - upper part of result
;;;     M - carry word
;;;
;;; **********************************************************************

              .section Code, reorder
putXnoFlags:  rxq     maskAndSave
              goto    exitUserST

putXDrop:     rxq     drop

putX:         rxq     maskAndSave
              rxq     setXFlags
;;; Normal exit with loaded and modified user flags in ST.
;;; In most cases you exit via PutX or one of its friends.
exitUserST:   c=0
              dadd=c                ; select chip 0
              c=regn  14
              rcr     12
              c=st                  ; write out user flags
              rcr     -12
              regn=c  14

;;; Exit and show appropriate display depending on the active
;;; shell. This will display the X register early and set
;;; the message flag, avoiding temporary default X register
;;; update, producing a steadier result.
exitNoUserST: gosub   shellDisplay
              golong  NFRC

;;; ************************************************************
;;;
;;; Set base to work in.
;;;
;;; The bad thing here is that mainframe already have taken the
;;; names OCT and DEC, so we need to do something different
;;; with the names. The way here is full names if they fit, and
;;; hexadecimal that is too long is shortened.
;;;
;;; ************************************************************

              .name   "BINS"
Binary:       ldi     1
BaseHelper:   rcr     1
              bcex    s
              rxq     findIntegerBuffer
              cstex
              rcr     1
              bcex    s
              rcr     -1
              data=c
exit:         goto    exitNoUserST

;;; ************************************************************
;;;
;;; Integer mode enable functions.
;;;
;;; Entering integer mode will create the integer buffer.
;;;
;;; ************************************************************

              .name   "INTEGER"
Integer:      nop                   ; non-programmable
                                    ;  (allow mode switch in program mode)
              c=0     x             ; buffer ID 0
              gosub   findBuffer
              goto    createBuf     ; (P+1) create buffer
                                    ; (P+2) buffer exists

activateExit: ldi     .low12 ladybugShell
              gosub   activateShell
              goto    10$           ; (P+1) out of memory
                                    ; (P+2) success
                                    ; assume header address in A.X
              goto    exitNoUserST
10$:          golong  noRoom

              .name   "OCTS"
Octal:        ldi   7
              goto    BaseHelper

              .name   "DECS"
Decimal:      ldi     9
              goto    BaseHelper

              .name   "HEXS"
Hex:          ldi     15
              goto    BaseHelper

;;; **********************************************************************
;;;
;;; Create the integer buffer
;;;
;;; In:  A.X - address of first free register in buffer area
;;; Out: A.X - address of first buffer register
;;;      N.X - address of first buffer register
;;;
;;; **********************************************************************

createBuf:    acex    x             ; save address of first free register
              n=c                   ; in N
              c=0                   ; select chip 0
              dadd=c
              gosub   MEMLFT        ; Check if there is room for the integer
              a=c     x             ; buffer
              ldi     BufSize
              ?a<c    x
              golc    noRoom        ; no

              c=n                   ; yes, create it
              c=c+1   x             ; select upper part register
              dadd=c

              c=0                   ; write initial upper parts register
              c=c+1   s
              data=c

              c=n
              dadd=c                ; select header register
              acex    x             ; A[2:0]= buffer header address

              c=0
              c=c+1   s             ; build header
              pt=     10
              lc      BufSize
              pt=     3
              lc      1             ; word size = 16
              ldi     15            ; hex
              data=c                ; write buffer header

exitNoUserSTR1:
              goto    activateExit

;;; **********************************************************************
;;;
;;; EXITAPP - restore float mode operation
;;;
;;; In reality we exit the top application shell.
;;;
;;; **********************************************************************

              .section Code, reorder
              .name   "EXITAPP"
EXITAPP:      gosub   exitApp
              golong  NFRC

              .section Code, reorder
noBuf:        gosub   errorMessage
              .messl  "NO INTGR BUF"
              golong  errorExit

;;; **********************************************************************
;;;
;;; Locate the integer buffer and set up carry bit in M register.
;;; Terminate with error message "NO PROG BUF": if buffer does not exist.
;;;
;;; CarryToM    Alternative entry, enter with buffer header register
;;;             selected and A.X containing its address. Sets up the
;;;             M carry register.
;;;
;;; Out:
;;;  C[13:2] - buffer header register (also selected)
;;;  C[1:0] - old ST
;;;  ST - internal flags ([1:0] of buffer header)
;;;  M - carry bit
;;;  ST 8/9 - indicates where carry takes place.
;;;  B[12:10] - buffer header address
;;;  A[2:0] - buffer header address
;;;
;;; Preserves: A.S, A.M B.S, B.X and N
;;; Uses: ST
;;;
;;; **********************************************************************

findIntegerBuffer:
              c=0     x
              gosub   findBuffer
              goto    noBuf         ; (P+1)
carryToM:     acex    x             ; (P+2)  C.X= buffer address
              rcr     -10
              bcex    m             ; save in B[12:10]
              st=0    Flag_UpperHalf
              c=data                ; load header (due to CarryToM entry)
              pt=     8             ; clear window#
              lc      0
              data=c
              rcr     2             ; align word size to C[1:0]
              acex    x
              a=0     xs
              ldi     56
              ?a<c    x             ; carry bit in low part (1-55)?
              goc     10$           ; yes
              a=a-c   x
              st=1    Flag_UpperHalf
              ?a#0    x             ; is carry from 56th pos?
              gonc    30$           ; yes
10$:          acex    x
              cstex
              m=c                   ; M[1:0]= old ST

              c=0                   ; prepare carry bit
              c=c+1

;;; Unroll the shift loop to make it faster, typical word size will in
;;; most cases be some power of 2, this makes it take 13 word cycles
;;; no matter which power of 2 it is. Other word sizes are not far behind.

              ?s0=1                 ; bit 0 set?
              gonc    1$            ; no
              c=c+c

1$:           ?s1=1                 ; bit 1 set?
              gonc    2$            ; no
              c=c+c
              c=c+c

2$:           ?s2=1                ; bit 2 set?
              gonc    3$
              rcr     -1

3$:           ?s3=1                 ; bit 3?
              gonc    4$
              rcr     -2

4$:           ?s4=1                 ; bit 4?
              gonc    5$
              rcr     -4

5$:           ?s5=1                 ; bit 5?
              gonc    20$
              rcr     -8

20$:          cmex                  ; save carry mask in M
              st=c                  ; restore old ST
22$:          c=data
              cstex                 ; bring up internal flags
              rtn                   ; done

30$:          c=st
              m=c
              st=0    Flag_UpperHalf
              c=0                   ; carry out in 56 bit register carry
              goto    20$


              .section Code, reorder
findIntegerBufferUserFlags:
              c=regn  14            ; bring up user flags
              rcr     12
              st=c
              rxq     findIntegerBuffer
              cstex                 ; bring up user flags
              rtn

              .section Code2, reorder
findIntegerBufferUserFlags_rom2:
              c=regn  14            ; bring up user flags
              rcr     12
              st=c
              switchBank 1
              rxq     findIntegerBuffer
              switchBank 2
              cstex                 ; bring up user flags
              rtn

              .section Code2, reorder
findIntegerBuffer_rom2:
              switchBank 1
              rxq     findIntegerBuffer
              switchBank 2
              rtn

;;; **********************************************************************
;;;
;;; Find integer buffer, enable stack lift, load integer flags,
;;; save X in L, load X and mask.
;;;
;;; Out: ST = user flags
;;;      M = Carry position
;;;      ST 8 & 9 set with information about carry location
;;;      ST - user exposed flags
;;;      A - lower part of X (also in X)
;;;      B[2:0] - upper part of X
;;;      B[5:3] - upper part Y
;;;      N - High part register, with X saved to L
;;;      B[12:10] - buffer header address
;;; Preserves:
;;;      B.S
;;;      G
;;;
;;; **********************************************************************

Flag_56:      .equ    9             ; set when word size is 56

              .section Code2, reorder
findIntegerBufferGetXSaveL56_rom2:
              st=0    Flag_56
              switchBank 1
              rxq     findIntegerBufferGetXSaveL
              switchBank 2
              c=m
              ?c#0
              rtn c
              st=1    Flag_56
              rtn

              .section Code, reorder
findIntegerBufferGetXSaveL56:
              st=0    Flag_56
              rxq     findIntegerBufferGetXSaveL
              c=m
              ?c#0
              rtn c
              st=1    Flag_56
              rtn

              .section Code, reorder
findIntegerBufferGetXSaveL:
              s0=0                  ; no division by 0 check
findIntegerBufferGetXSaveL0:
              s11=1                 ; set push flag (enable stack lift)
findIntegerBufferGetXSaveL0no11:
              rxq     findIntegerBuffer
              cstex                 ; restore header
              n=c                   ; save header
              rxq     loadX
              ?s0=1                 ; check for X=0?
              gonc    10$           ; no
              ?a#0
              goc     10$
              ?b#0    x
              gsubnc  ERRDE         ; 0, give "DATA ERROR"

10$:          acex
              regn=c  X             ; save masked X in X
              regn=c  L             ; save X in L
              acex

              c=regn  14            ; bring up user flags
              rcr     12
              st=c

              c=b                   ; select trailer register
              rcr     10
              c=c+1
              dadd=c
              c=data
              pt=     1
              c=b     wpt           ; save upper X on L
              data=c                ; save back updated trailer register
              n=c                   ; save a copy in N

              c=0     x             ; select chip 0
              dadd=c
              rtn

              .section Code2, reorder
;;; **********************************************************************
;;;
;;; getSignsMakePositive - Get the signs of X and Y, make them positive
;;;    if desired.
;;;
;;; getSignsMakePositiveZ - Alternative entry, call with S6=1 to inform
;;;    that we are doing DDIV and also wants to swap Y and Z.
;;;
;;; getSigns - Alternative entry, set S7=0 to get the signs without
;;;    making the numbers positive.
;;;
;;; S6 - Controls if the numbers should be made positive and masked as well.
;;;      This flag is the sign-flag, which will be updated by all callers
;;;      at the end, so we can borrow it here.
;;;
;;; In:  B[1:0]= upper part of X
;;;
;;; Out: B[1:0]= upper part of X
;;;      A.S= sign of Y (Z)
;;;      C.S= sign of X
;;;
;;; Note: Y and Z are swapped when doing DDIV to ensure that Y always
;;;       contains the low part of the divisor (Z gets the upper part).
;;;       This is done to simplify for the DIV routine which always
;;;       have to lower bits in Y.
;;;
;;; **********************************************************************

getSignsMakePositive:
              s6=0
getSignsMakePositiveZ:              ; potential Z register operation (DDIV)
              s7=1
getSigns:     c=regn  X
              a=c
              rxq     signPositive  ; get sign of X
              goto    10$           ; (P+1) not changed
              acex                  ; (P+2) changed
              regn=c  X             ; write back changed lower X
              acex
10$:          bcex    s             ; B.S= sign of X
              bcex                  ; C= SBBB.......UUU
              rcr     4             ; C= UUUSBBB.......
              bcex                  ; B= UUUSBBB.......
              c=regn  Y
              a=c
              c=n
              rcr     4             ; C[1:0]= upper Y
              bcex    x             ; B[1:0]= upper Y
              rxq     maskABx_rom2  ; mask Y
              c=0     xs            ; B[2]= non-zero flag indicating doing Y
              c=c+1   xs
              bcex    xs
              rxq     signPositive
              goto    20$           ; (P+1) not changed
                                    ; (P+2) changed
              acex                  ; A.S= sign(Y), C=lower Y
              regn=c  Y
              acex
              cnex
              rcr     4
              bcex    x
              bcex    xs
              rcr     -4
              cnex

20$:          a=c     s
              bcex
              rcr     -4
              bcex    m             ; restore buffer pointer
              bcex    x             ; restore upper X
              rtn

              .section Code2, reorder
;;; Get the sign and maybe make positive
signPositive: rxq     getSign_rom2  ; get the sign
              ?c#0    s             ; positive?
              gonc    50$           ; yes
              ?s7=1                 ; make positive?
              gonc    50$           ; no
              ?st=1   Flag_2        ; sign mode?
500$:         gonc    50$           ; no

              ?s6=1                 ; double divide?
              gonc    10$           ; no
              ?b#0    xs            ; double divide, doing Y?
              goc     20$           ; yes, need special treatment
10$:          c=b
              c=-c    x             ; negate upper part
              acex
              c=-c                  ; negate lower part
              gonc    11$
              a=a-1   x             ; carry to upper part
11$:          b=a
              a=c
15$:          rxq     maskABx_rom2
              c=0     s             ; C.S= negative flag
              c=c+1   s
17$:          c=stk                 ; return to (P+2)
              c=c+1   m
              gotoc

;;; Cases below when we do not need to negate. For stack registers
;;; other than X we need to mask them, and double divide also
;;; requires swapping Y and Z
50$:          ?b#0    xs            ; no need to negate, doing Y?
              rtn nc                ; no, we are done, return to (P+1)
                                    ; yes, mask Y
              bcex    s             ; B.S= saved sign
              rxq     maskABx_rom2
              ?s6=1                 ; double divide?
              gonc    55$           ; no

;;; For double divide we need to mask Z, and swap it with Y.
;;; Currently we have loaded Y, so we save Y in Z and mask
;;; Z and leave it loaded and let the caller save it in Y
;;; (believing it was Y).
              c=regn  Z
              acex                  ; A= Z
              regn=c  Z             ; save Y in Z
              c=n                   ; C= upper parts
              rcr     6
              bcex    x             ; save upper Y in Z and
              bcex    xs            ; load upper Z to B[1:0]
              rcr     -6
              n=c
              rxq     maskABx_rom2
55$:          bcex    s             ; restore sign
              goto    17$           ; return to (P+2)

150$:         goto    15$           ; relay

;;; Negating for double divide and we have Y loaded in B[1:0]-A.
;;; This is actually the upper bits.
;;; We then load Z (lower bits), negate it and let the caller save
;;; it in Y as the DDIV routine wants them swapped.
;;;
;;; The currently loaded B[1:0]-A is properly masked, but the lower
;;; part we get from Z needs to be masked.
20$:          s3=1                  ; use c=-c

              c=regn  Z             ; C= low part of lower half
              acex
              regn=c  Z             ; Z= low part of upper half
              cnex
              rcr     6
              pt=     1
              bcex    wpt           ; swap upper parts
              cnex
              rxq     maskABx_rom2  ; mask lower part

              acex                  ; negate lower part in low half
              c=-c
              gonc    21$
              s3=0                  ; bit-not next
21$:          bcex    wpt           ; negate upper part of low half
              c=-c-1  wpt           ; bitnot
              ?s3=1                 ; should have negated?
              gonc    22$           ; no
              c=c+1   wpt           ; yes
              goc     22$
              s3=0                  ; bitnot next
22$:          bcex    wpt
              a=c
              c=regn  Z             ; get low part of upper half
              c=-c-1
              ?s3=1                 ; should be negated?
              gonc    23$           ; no
              c=c+1                 ; yes
              goc     23$
              s3=0                  ; bitnot next
23$:          regn=c  Z
              cnex                  ; get upper part of upper half
              c=-c-1  wpt
              ?s3=1                 ; should be negated?
              gonc    24$           ; no
              c=c+1   wpt           ; yes
24$:          rcr     -6            ; realign trailer register
              cnex
              goto    150$

              .section Code2, reorder
bitMask_rom2: switchBank 1
              rxq     bitMask
              switchBank 2
              rtn

              .section Code, reorder
;;; IN: A.X - bit number (0-64)
;;; OUT: C.X - upper part
;;;      C   - lower part
;;;      A.S - 0 if bit is in lower part
;;;            1 if bit is in upper part
;;; USES: A,C
;;;
;;; bitMask_G - alternative entry that takes the bit number from G
bitMask_G:    pt=     0
              c=0
              c=g
              goto    bitMask10
bitMask:      c=0
              acex    x
bitMask10:    rcr     -3
              a=c                   ; A.S= 0, flag for bit in upper part
                                    ; A.M= counter
              a=0     x             ; high part

              c=0                   ; load a 1
              c=c+1
10$:          a=a-1   m
              rtn c                 ; done
              c=c+c
              gonc    10$
              a=a+1   x             ; move bit into upper part
              a=a+1   s             ; A.S= 1 for upper part
              acex    x
15$:          a=a-1   m
              rtn c                 ; done
              c=c+c   x
              goto    15$

              .section Code, reorder
;;; ----------------------------------------------------------------------
;;;
;;; drop - drop stack, by copying T to Z and Z to Y
;;;        Assume that Y should be lost and X is written elsewhere.
;;; dropZN10 - alternative entry where upper part of Z is held in N[1:0],
;;;            call with S9=0
;;;
;;; In: B[12:10] - buffer header address
;;;
;;; Out: Chip 0 selected
;;;
;;; ----------------------------------------------------------------------

drop:         s9=1
dropZN10:     c=b                   ; select upper part register
              rcr     10
              c=c+1   x
              dadd=c
              c=data                ; drop stack, upper parts
              pt=     8
              g=c                   ; G=upper part of T
              pt= 6
              cgex                  ; write T, get old Z
              ?s9=1
              goc     10$
              cnex                  ; take new Z from N[1:0]
              pt=     0
              g=c
              cnex
10$:          pt=     4
              c=g                   ; Y= Z
              data=c
              c=0     x
              dadd=c                ; select chip 0
              c=data                ; get T
              cnex                  ; save in N

              c=regn  Z             ; drop stack, lower part
              regn=c  Y             ; Y = Z
              cnex                  ; get T
              regn=c  Z             ; Z = T
              rtn

              .section Code, reorder
;;; ----------------------------------------------------------------------
;;;
;;; maskAndSave - finalize result in X by masking it, update zero/sign
;;;               flags depending on value in X, and finally save the
;;;               upper part to buffer
;;; maskAndSave10 - alternative entry with X in A
;;;
;;; In: B[12:10] - buffer header address
;;;     X - lower part of X
;;;     B[1:0] - upper part of X
;;;     M - carry word
;;;     ST - user flags
;;;     chip 0 - selected
;;;
;;; Out: ST - updated user flags (sign and zero)
;;;
;;; ----------------------------------------------------------------------

maskAndSave:  c=regn  X
              a=c
maskAndSave10:
              rxq     maskABx_rom1
              acex
              regn=c  X

saveUpperPart:
              ;; save upper part
              c=b                   ; get buffer header address
              rcr     10
              c=c+1   x
              dadd=c                ; select trailer register
              c=data                ; write upper part of X to
              rcr     2             ;  buffer
              pt=     1
              c=b     wpt
              rcr     -2
              data=c
              rtn

;;; New value in B[2:0] and A
acceptAndSave:
              c=m                   ; make mask of bits outside word
              c=c-1
              c=-c-1
              ?st=1   Flag_UpperHalf
              goc     1$
              ?b#0    x             ; lower part, check upper part bits
              rtn c                 ; yes, something set, bail out
              c=c&a
              ?c#0
              rtn c
2$:           c=stk
              c=c+1   m             ; will return to (P+2)
              stk=c
              c=regn  14
              rcr     -2
              c=c+c   xs            ; program mode?
              goc     saveLiteral   ; yes
              acex
              regn=c  X             ; write to X
              ?st=1   Flag_UpperHalf
              rtn nc
              goto    saveUpperPart
1$:           abex                  ; mask in upper part
              c=c&a
              abex
              ?c#0    x
              rtn c
              goto    2$

;;; ----------------------------------------------------------------------
;;;
;;; Save literal in program mode.
;;; We know the number is small enough to fit into current base, update
;;; the text wrapper program line to contain the new number.
;;;
;;; IN: A - lower part
;;;     B[2:0] - upper part
;;;     G - new digit
;;;     B[12:10] - buffer address
;;; OUT: G - new digit (preserved)
;;;      B[12:10] - buffer address (preserved)
;;;
;;; ----------------------------------------------------------------------

saveLiteral:  acex
              n=c                   ; save lower part of number

              gosub   NXBYTP        ; inspect program memory
              rcr     -1
              c=c+1   xs            ; is it a text wrapper?
              gonc    4$            ; no

              rcr     2             ; C.S= counter
              a=c     s             ; A.S= counter
              c=b     x             ; C[2:0]= upper part
              m=c
3$:           c=0     x             ; null out the text wrapper
              gosub   PTBYTA
              gosub   INCADA
              a=a-1   s
              gonc    3$
              c=m
              bcex    x             ; B.X= upper part

4$:
              pt=     1
              c=n
              a=0     s             ; counter
              ?b#0    x
              goc     20$
              ?c#0                  ; need a postfix text instruction?
              gonc    19$           ; no, not at this point

8$:           a=a-1   s             ; loop to align lower part and count
              rcr     -2            ;  number of bytes needed for it
              ?c#0    wpt
              gonc    8$

12$:          n=c                   ; save aligned lower part

              ldi     8             ; normalize counter
              rcr     1
              a=a+c   s
              b=a     s             ; B.S= counter

              gosub   GETPC         ; get PC, we are already set up for insert

              c=b
              c=g                   ; C[3:4]= G preserved
              rcr     6             ; preserve B[12:10], B.X and G in B.M
              bcex    m

              a=0     s             ; number of inserts so far

              ldi     0xf
              c=b     s
              rcr     -1
              gosub   INBYTC        ; insert text prefix

              c=b
              rcr     -6
              ?c#0    x             ; do we have upper part?
              gsubc   INBYTC        ; yes write it

15$:          c=n
              rcr     -2
              cnex
              gosub   INBYTC
              bcex    s
              c=c-1   s
              bcex    s
              ?b#0    s
              goc     15$

              bcex                  ; restore B[12:10]
              rcr     -6
              pt=     3
              g=c                   ; restore G
              bcex    m
19$:          st=1    Flag_PRGM     ; this is to get the program step
                                    ;  left aligned
              rtn

20$:          rcr     -2            ; align lower part
              goto    12$

             .section Code, reorder
;;; ----------------------------------------------------------------------
;;;
;;; setXFlags - set sign/zero flags according to X.
;;; setSignFlag - only set the sign flag.
;;;
;;; In: B.X - upper part of X
;;;     X - lower part of X
;;;     S8/S9 - set according to word size
;;;     M - carry mask
;;;
;;; Out: Sign flag in user flags set to highest bit in X according to
;;;      word size
;;;
;;; Uses: C, A
;;;
;;; ----------------------------------------------------------------------

setXFlags:    st=0    Flag_Zero     ; clear flags we will update

              c=0     x
              dadd=c
              ?b#0    x             ; check for zero result
              goc     setSignFlag   ; non-zero
              c=regn  X
              ?c#0
              goc     setSignFlag   ; non-zero

              st=1    Flag_Zero     ; set zero flag

setSignFlag:  st=0    Flag_Sign
              ?st=1   Flag_UpperHalf ; high part exists?
              goc     2$            ; yes
              c=regn  X             ; align sign bit with carry
              c=c+c
              gonc    5$
                                    ; sign from bit 55 location
1$:           st=1    Flag_Sign
              rtn

2$:           c=b     x             ; upper word
              c=c+c   x
5$:           a=c
              c=m
              c=c&a
              ?c#0
              goc     1$
              rtn

              .section Code2, reorder
setSignFlag_rom2:
              switchBank 1
              rxq     setSignFlag
              switchBank 2
              rtn

;;; ----------------------------------------------------------------------
;;;
;;; setFlagsABx - set sign/zero flags according to B.X-A
;;;
;;; In: B.X - upper part of value
;;;     A - lower part of value
;;;     S8/S9 - set according to word size
;;;     M - carry mask
;;;
;;; Out: Zero and sign flags in user flags set to highest bit according
;;;      to word size
;;;
;;; Uses: C, A
;;;
;;; ----------------------------------------------------------------------

              .section Code2, reorder
setFlagsABx:  rxq     maskABx_rom2
              st=0    Flag_Zero
              ?b#0    x
              goc     10$
              ?a#0
              goc     10$
              st=1    Flag_Zero
10$:          st=0    Flag_Sign
              ?st=1   Flag_UpperHalf
              goc     22$
              acex
              c=c+c
              gonc    25$
20$:           st=1    Flag_Sign
              rtn

22$:          c=b     x             ; upper word
              c=c+c   x
25$:          a=c
              c=m
              c=c&a
              ?c#0
              goc     20$
              rtn

              .section Code, reorder
;;; **********************************************************************
;;;
;;; XOR - Entry point for exclusive OR between X and Y.
;;;
;;; **********************************************************************

              .name   "XOR"
XOR:          rxq     findIntegerBufferGetXSaveL
              c=b                   ; save buf ptr on stack
              rcr     6
              stk=c
              c=regn  Y             ; XOR lower part of X with Y
              b=c
              c=c|a
              bcex
              c=c&a
              c=-c-1
              abex
              c=c&a
              regn=c  X

              c=n                   ;  do upper part
              rcr     2
              a=c     x
              rcr     2 + 6
              c=stk
              rcr     -6
              b=c
              c=c|a
              bcex    x
              c=c&a
              c=-c-1  x
aoxfix_0:     abex    x             ; A[1:0] - upper part of X
              c=c&a
aoxfix:       bcex    x             ; B[1:0] - upper result
aoxfix_2:     rgo     putXDrop

;;; **********************************************************************
;;;
;;; OR - Entry point for OR between X and Y.
;;;
;;; **********************************************************************

              .name   "OR"
OR:           rxq     findIntegerBufferGetXSaveL
              c=regn  Y             ; OR lower part of X with Y
              c=c|a
              regn=c  X             ; write back

              c=n                   ;  do upper part
              rcr     4
              abex    x
              c=c|a

              goto    aoxfix

;;; **********************************************************************
;;;
;;; AND - Entry point for AND between X and Y.
;;;
;;; **********************************************************************

              .name   "AND"
AND:          rxq     findIntegerBufferGetXSaveL
              c=regn  Y             ; AND lower part of X with Y
              c=c&a
              regn=c  X             ; write back

              c=n                   ; do upper part
              rcr     2
              a=c
              rcr     2
              c=c&a

              c=n                   ;  do upper part
              rcr     4             ; C[1:0] - upper part of Y
              goto    aoxfix_0

;;; **********************************************************************
;;;
;;; SUB - Entry point for SUB Y with X.
;;;
;;; **********************************************************************

              .name   "SUB"
SUB:          s9=1
              goto    ADD_2

;;; **********************************************************************
;;;
;;; ADD - Entry point for ADD X and Y.
;;;
;;; **********************************************************************

              .name   "ADD"
ADD:          s9=0
ADD_2:        rxq     findIntegerBufferGetXSaveL
              switchBank 2
              st=0    Flag_Overflow ; prepare overflow flag
              ?st=1   Flag_2        ; unsigned mode?
              gonc    5$            ; yes
              s6=0                  ; not doing DDIV
              s7=0                  ; do not make the values positive
              rxq     getSigns
              ?s9=1                 ; doing subtract?
              goc     2$            ; yes
              ?a#c    s             ; same signs?
              goc     5$            ; no, will not overflow
1$:           st=1    Flag_Overflow ; assume overflow
              b=a     s             ; B.S= flag to check against
              goto    5$
2$:           ?a#c    s             ; different signs?
              goc     1$            ; yes, may overflow
5$:           c=b     x
              cnex                  ; N.X= upper X
              rcr     4             ; C[1:0]= upper Y
              bcex    x             ; B[1:0]= upper Y
              c=regn  Y
              a=c                   ; A= lower Y
              rxq     maskABx_rom2  ; B.X/A = Y masked
              c=regn  X
              ?s9=1                 ; doing subtract?
              goc     40$           ; yes

              c=c+a                 ; ADD
              gonc    10$           ; no carry
              bcex    x             ; carry to upper part
              c=c+1   x
              bcex    x
10$:          regn=c  X             ; save lower part
              a=c                   ; A= lower X
              c=n                   ; C.X= upper part of X
              abex    x             ; A.X= upper part of Y
              a=a+c   x             ; add them
              abex    x             ; B.X= upper part of result

15$:          ?st=1   Flag_Overflow ; check for overflow?
              gonc    21$           ; no
              rxq     getSign_rom2
              abex    s
              ?a#c    s             ; different sign?
              goc     20$           ; yes, overflow (we have correct flag)
              st=0    Flag_Overflow

20$:          abex    s             ; restore A
21$:          st=0    Flag_CY
              c=m                   ; make unmask
              c=c-1
              c=-c-1
              ?st=1   Flag_UpperHalf
              goc     29$           ; check against upper part
              c=c&a
22$:          ?c#0                  ; carry?
              gonc    25$           ; no
              ?st=1   Flag_2        ; yes, signed mode?
              goc     24$
              st=1    Flag_Overflow ; unsigned, also set overflow
24$:          st=1    Flag_CY
25$:          rgo     putXDrop_rom2

29$:          abex    x             ; mask against upper part
              c=c&a
              abex    x
              c=0     m
              c=0     s
              goto  22$

;;; Do not try to negate Y and use ADD for subtracting, it does not work
;;; with the overflow flag if Y is the smallest negative number, as it
;;; cannot be negated without overflow. Instead we actually use subtract
;;; here.
40$:          c=a-c                 ; SUB
              gonc    41$
              bcex    x
              c=c-1   x             ; borrow from upper part
              bcex    x
41$:          regn=c  X             ; save lower part
              a=c                   ; A= lower part of result
              abex                  ; A.X = upper part of Y
              c=n                   ; C.X = upper part of X
              a=a-c   x
              abex
              goto    15$

              .section Code, reorder
;;; **********************************************************************
;;;
;;; CLXI - Entry point for clear integer X register, and disable stack lift.
;;;
;;; **********************************************************************

              .name   "CLXI"
CLXI:         gosub   displayingMessage
              goto    putX_J00      ; (P+1) clear shown message
              rxq     findIntegerBufferUserFlags
              c=0                   ; load 0
              dadd=c
              regn=c  X
              b=0     x
              s11=0                 ; disable stack lift
              rgo     putXnoFlags

;;; **********************************************************************
;;;
;;; IABS - Integer ABS, make the number positive
;;;
;;; **********************************************************************

              .name   "ABSI"
ABSI:         rxq     findIntegerBufferGetXSaveL
              st=0    Flag_Overflow
              ?st=1   Flag_2        ; unsigned mode?
              gonc    putX_J0       ; yes, done
              rxq     getSign       ; signed mode, check sign
              ?c#0    s
putX_J00:     gonc    putX_J0       ; positive
              goto    NEG10         ; negative, negate it

;;; **********************************************************************
;;;
;;; NEG - Entry point for negate, change sign.
;;;
;;; LastX is saved here which is not for the corresponding float CHS
;;; instruction, which is consistent with how it works on the HP-16C.
;;;
;;; **********************************************************************

              .name   "NEG"
NEG:          rxq     findIntegerBufferGetXSaveL
NEG10:        st=0    Flag_Overflow ; assume no overflow
              ?st=1   Flag_2        ; signed mode?
              goc     5$            ; yes
              ?a#0                  ; no, unsigned. test for zero
              goc     2$            ; non-zero
              ?b#0    x
              gonc    5$            ; zero, no overflow
2$:           st=1    Flag_Overflow ; non-zero, result is negative and
                                    ;  out of range in unsigned mode.
5$:           c=b
              c=-c    x             ; negate upper part
              acex                  ; A= buffer address and upper part
                                    ; C= lower part
              c=-c                  ; negate lower part
              gonc    6$
              a=a-1   x
6$:           regn=c  X             ; save lower result
              b=a                   ; B= buffer pointer and upper part
              ?st=1   Flag_UpperHalf
              goc     7$
              acex                  ; carry in lower part
7$:           c=m
              c=c-1
              nop
              c=c&a                 ; mask result
              c=c+c                 ; left shift
              goc     12$           ; carry means overflow (size 56)
              a=c
              c=m
              ?c#0                  ; size 56?
              gonc    putX_J0       ; yes, no overflow (if yes, we got that
                                    ;  above when doing left shift)
                                    ; carry mask==0 for size 56 (special case)
                                    ;  so a zero result would compare equal
                                    ;  and accidently assume carry, so we
                                    ;  skip doing that mistake
              ?a#c                  ; same as carry mask?
              goc     putX_J0       ; no, did not overflow
12$:          st=1    Flag_Overflow ; yes, overflow
              goto    putX_J0

;;; **********************************************************************
;;;
;;; NOT - Entry point for bit-not.
;;;
;;; **********************************************************************

              .name   "NOT"
NOT:          rxq     findIntegerBufferGetXSaveL
              bcex    x
              c=-c-1  x
              bcex    x
              acex
              c=-c-1
              regn=c  X
putX_J0:      rgo     putX

              .section Code, reorder
;;; **********************************************************************
;;;
;;; CB - Clear a bit.
;;;
;;; **********************************************************************

              .name   "CB"
CB:           nop
              nop
              gosub   argument
              .con    Operand00 + SEMI_MERGED_NO_STACK
              rxq     findIntegerBufferUserFlags_argumentValueG_rom1
              s9=1
              goto    SB10

;;; **********************************************************************
;;;
;;; SB - Set a bit.
;;;
;;; **********************************************************************

              .name   "SB"
SB:           nop
              nop
              gosub   argument
              .con    Operand00 + SEMI_MERGED_NO_STACK
              rxq     findIntegerBufferUserFlags_argumentValueG_rom1
              s9=0
SB10:         rxq     findIntegerBufferGetXSaveL
              rxq     bitMask_G
              ?s9=1                 ; SB?
              gonc    10$           ; yes
              c=-c-1                ; no, CB - invert mask
10$:          acex                  ; A= mask
              ?c#0    s             ; bit affects upper part?
              goc     20$           ; yes
              c=regn  X
              ?s9=1                 ; SB?
              goc     15$           ; no
              c=c|a                 ; yes
              goto    17$
15$:          c=c&a
17$:          regn=c  X
19$:          goto    35$

20$:          bcex    x
              ?s9=1                 ; SB?
              goc     25$           ; no
              c=c|a                 ; yes
              goto    30$
25$:          c=c&a
30$:          bcex    x
35$:          rgo     putX

;;; **********************************************************************
;;;
;;; B? - Test a bit.
;;;
;;; **********************************************************************

              .section Code, reorder
              .name   "B?"
`B?`:         nop
              nop
              gosub   argument
              .con    Operand00 + SEMI_MERGED_NO_STACK
              rxq     findIntegerBufferUserFlags_argumentValueG_rom1
              rxq     loadX
              acex
              regn=c  X
              rxq     bitMask_G
              acex                  ; A= mask
              ?c#0    s             ; bit in upper part?
              goc     10$           ; yes
              c=regn  X
5$:           c=c&a
              s7=0
              ?c#0
              golc    NOSKP
              golong  SKP
10$:          c=b     x
              goto    5$

;;; **********************************************************************
;;;
;;; MASKR - build right aligned bit mask.
;;;
;;; **********************************************************************

              .section Code, reorder
              .name   "MASKR"
MASKR:        nop
              nop
              gosub   argument
              .con    8 + SEMI_MERGED_NO_STACK
              rxq     findIntegerBufferUserFlags_argumentValueG_rom1
              s9=0
              goto    MASK10

;;; **********************************************************************
;;;
;;; MASKL - build left aligned bit mask.
;;;
;;; **********************************************************************

              .name   "MASKL"
MASKL:        nop
              nop
              gosub   argument
              .con    8 + SEMI_MERGED_NO_STACK
              rxq     findIntegerBufferUserFlags_argumentValueG_rom1
              s9=1                  ; (S9 is affected by argumentValueG)
MASK10:       rxq     liftStackS11
              rxq     bitMask_G
              switchBank 2
              b=0     x
              c=c-1                 ; convert to mask
              ?c#0
              goc     5$            ; non-zero
              ?a#0    s             ; is it actually 0?
              gonc    22$           ; yes, result is also 0
              c=c-1                 ; special case when word size is 56
              a=0     s
5$:           acex
              ?c#0    s             ; bit affect upper part?
              gonc    10$           ; no
              abex    x
              a=0
              a=a-1
10$:          ?s9=1                 ; MASKL?
              gonc    20$           ; no

12$:          bcex
              g=c                   ; G= previous high part
              c=c+c   x             ; left shift upper part
              acex
              n=c                   ; N= previous low part
              c=c+c                 ; left shift lower part
              gonc    14$
                                    ; carry between parts
              ?st=1   Flag_UpperHalf ; do we have upper part?
              gonc    17$           ; no, should be 56-bit word size
              a=a+1   x             ; carry to upper part
14$:          bcex                  ; B= lower part, A= upper part
              ?st=1   Flag_UpperHalf
              goc     15$
              abex                  ; A= lower part, B= upper part
15$:          c=m
              c=c&a
              ?st=1   Flag_UpperHalf
              gonc    16$
              abex
16$:          ?c#0
              gonc    12$           ; not done

17$:          c=g
              bcex    x
              c=n
              goto    22$
20$:          acex
22$:          regn=c  X
              rgo     putXnoFlags_rom2

;;; **********************************************************************
;;;
;;; LASTXI - Recall L register.
;;;
;;; **********************************************************************

              .section Code, reorder
              .name   "LASTXI"
LASTXI:       rxq     findIntegerBufferUserFlags_liftStackS11
              c=b
              rcr     10
              c=c+1   x
              dadd=c                ; select trailer register
              c=data

              bcex    x             ; B.X= upper part

              c=0     x
              dadd=c                ; select chip 0
              c=regn  L             ; load lower part of L
              goto    SWAPIExit

;;; **********************************************************************
;;;
;;; SWAPI - Swap IX and IY.
;;;
;;; **********************************************************************

              .name   "X<>YI"
SWAPI:        rxq     findIntegerBufferUserFlags
              c=b
              rcr     10
              c=c+1   x             ; point to trailer register
              dadd=c
              c=data

              pt=     2             ; swap upper parts
              g=c
              pt=     4
              cgex
              data=c

              c=0
              dadd=c

              pt=     0
              c=g
              bcex    x             ; B.X= X upper part

              c=regn  Y
              a=c
              c=regn  X
              regn=c  Y
              acex
SWAPIExit:    regn=c  X
putX11:       s11=1
              rgo     putXnoFlags

;;; **********************************************************************
;;;
;;; RollDown - Helper routine to roll down the stack
;;;
;;; **********************************************************************

RollDown:     rxq     findIntegerBufferUserFlags

RollDown1:    c=b
              rcr     10
              c=c+1   x
              dadd=c                ; select trailer register

              c=data
              pt=     1
              bcex    wpt           ; save upper L in B[1:0]

              pt=     9
              csr     wpt
              csr     wpt

              pt=     1
              bcex    wpt           ; put L back, save X in B[1:0]

              rcr     8
              bcex    wpt           ; X to T
              rcr     -8
              data=c                ; save updated trailer register back

              golong  RDNSUB         ; rotate normal stack

;;; **********************************************************************
;;;
;;; RDNI - Roll stack down.
;;;
;;; **********************************************************************

              .name   "RDNI"
RDNI:         rxq     RollDown
RDNExit:      c=b
              rcr     10
              c=c+1   x
              dadd=c
              c=data
              rcr     2
              bcex    x
              b=0     xs
              c=0     x
              dadd=c
              goto    putX11

;;; **********************************************************************
;;;
;;; IR^ - Roll stack up.
;;;
;;; **********************************************************************

              .name   "R^I"
RUPI:         rxq     RollDown
              rxq     RollDown1
              rxq     RollDown1
              goto    RDNExit

              .section Code, reorder
;;; **********************************************************************
;;;
;;; Rotate and shift functions.
;;;
;;; **********************************************************************

;;; We use a bitfield in B.S to configure the operation.
Bit_Rotate:   .equ    (1 << 3)
Bit_ThroughCarry: .equ (1 << 2)     ; set for RRC/RLC
Bit_Arithmetic: .equ  (1 << 1)      ; set for arithmetic shift

;;; Define a few macros to make it easy to test a bit in the bit-field
isArithmetic: .macro
              c=b     s
              c=c+c   s
              c=c+c   s
              c=c+c   s
              .endm

isRotate:     .macro
              c=b     s
              c=c+c   s
              .endm

isThroughCarry:  .macro
              c=b     s
              c=c+c   s
              c=c+c   s
              .endm

;;; ----------------------------------------
;;;
;;; Shift left
;;;
;;; ----------------------------------------

              .name   "SL"
SL:           nop                   ; Prelude for prompting function
              nop
              gosub   argument
              ;; Defaults to count 1, prevent ST input, but allow IND
              .con    Operand01 + SEMI_MERGED_NO_STACK
              c=0     s
              goto    leftShift

;;; ----------------------------------------
;;;
;;; Rotate left through carry
;;;
;;; ----------------------------------------

              .name "RLC"
RLC:          nop                   ; Prelude for prompting function
              nop
              gosub   argument
              ;; Defaults to count 1, prevent ST input, but allow IND
              .con    Operand01 + SEMI_MERGED_NO_STACK
              pt=     13
              lc      Bit_ThroughCarry
              goto    leftShift

;;; ----------------------------------------
;;;
;;; Rotate left
;;;
;;; ----------------------------------------

              .name   "RL"
RL:           nop                   ;  Prelude for prompting function
              nop
              gosub   argument
              ;; Defaults to count 1, prevent ST input, but allow IND
              .con    Operand01 + SEMI_MERGED_NO_STACK
              pt=     13
              lc      Bit_Rotate
leftShift:    switchBank 2
              bcex    s             ; B.S= configuration nibble
              rxq     findIntegerBufferUserFlags_rom2
              bcex    s
              rcr     4
              pt=     9
              bcex    pt            ; B[9]= configuration nibble
              rxq     argumentValueG
              c=b
              rcr     -4
              bcex    s             ; B.S= configuration nibble
              rxq     findIntegerBufferGetXSaveL56_rom2
              c=b     m             ; save buffer address on stack
              rcr     10 - 3
              stk=c
              c=0     m             ; prepare counter
              pt=     3
              c=g
              c=c-1   m
              goc     12$           ; done
              ?st=1   Flag_56
              goc     56$
              ?st=1   Flag_UpperHalf
              goc     640$

              ;; Loop when we have all bits in low part
32$:          bcex    m             ; put counter back in B.M
              c=0                   ; prepare to rotate carry in if needed
              ?st=1   Flag_CY
              gonc    34$
              isThroughCarry
              gonc    34$
              c=c+1                 ; carry going in
34$:                                ; we know C.S= 0 here as ThroughCarry
                                    ;  is lowest possible bit when doing
                                    ;  left shift
              acex
              c=c+c
              a=a+c
              st=0    Flag_CY
              c=m
              c=c&a
              ?c#0
              gonc    11$
              st=1    Flag_CY       ; set carry
              isRotate
              gonc    11$           ; do not rota te in immediately
              a=a+1                 ; rotate around
11$:          bcex    m
              c=c-1   m
              gonc    32$

10$:          c=stk                 ; get buffer header address
              rcr     - (10 - 3)
              bcex    m             ; put in B[12:10]
              acex                  ; write out result
              regn=c  X
12$:          rgo     putX_rom2

56$:          bcex    m
              c=0                   ; prepare to rotate carry in if needed
              ?st=1   Flag_CY
              gonc    57$
              isThroughCarry
              gonc    57$
              c=c+1                 ; carry going in
57$:          st=0    Flag_CY
                                    ; we know C.S= 0 here as ThroughCarry
                                    ;  is lowest possible bit when doing
                                    ;  left shift
              acex
              c=c+c                 ; left shift/rotate
              gonc    62$
              acex
              st=1    Flag_CY       ; got carry
              isRotate
              gonc    621$          ; do not rotate in immediately
              a=a+1                 ; rotate around
              goto    621$

640$:         goto    64$           ; relay

621$:         c=0     s             ; reset C.S after isRotate
62$:          a=a+c                 ; get potentially kept carry in
              bcex    m
              c=c-1   m
              gonc    56$
100$:         goto    10$

64$:          bcex    m             ; rotate with upper register
              c=0                   ; prepare to rotate carry in if needed
              ?st=1   Flag_CY
              gonc    66$
              isThroughCarry
              gonc    66$
              c=c+1                 ; carry going in
66$:          acex
              c=c+c
              gonc    3$            ; no carry between words
              c=a+c                 ; get carry in
              bcex    x             ; shift carry into upper word
              c=c+c   x
              c=c+1   x
              goto    4$
3$:           c=c+a                 ; get carry into lower word
              bcex    x             ; shift upper word, no carry in
              c=c+c   x
4$:           acex                  ; save A back, except for A.X that is in B.X
              c=m                   ; check carry bit of upper word
              c=c&a
              ?c#0
              gonc    8$
              st=1    Flag_CY       ; carry set, so set the carry
              isRotate              ; rotate in carry immediately?
              gonc    8$            ; no
              bcex    x             ; put carry into low position as well
              c=c+1   x
              bcex    x
8$:           abex    x             ; Restore A as low part and B.X as upper part
              bcex    m             ; Decrement loop counter
              c=c-1   m
              gonc    64$
              goto    100$

              .section Code, reorder
;;; ----------------------------------------
;;;
;;; Shift right
;;;
;;; ----------------------------------------

              .name   "SR"
SR:           nop                   ; Prelude for prompting function
              nop
              gosub   argument
              ;; Defaults to count 1, prevent ST input, but allow IND
              .con    Operand01 + SEMI_MERGED_NO_STACK
              c=0     s
              goto    rightShift

;;; ----------------------------------------
;;;
;;; Arithmetic shift right
;;;
;;; ----------------------------------------

              .name   "ASR"
ASR:          nop                   ; Prelude for prompting function
              nop
              gosub   argument
              ;; Defaults to count 1, prevent ST input, but allow IND
              .con    Operand01 + SEMI_MERGED_NO_STACK
              pt=     13
              lc      Bit_Arithmetic
              goto    rightShift

;;; ----------------------------------------
;;;
;;; Rotate right through carry
;;;
;;; ----------------------------------------

              .name   "RRC"
RRC:          nop                   ; Prelude for prompting function
              nop
              gosub   argument
              ;; Defaults to count 1, prevent ST input, but allow IND
              .con    Operand01 + SEMI_MERGED_NO_STACK
              pt=     13
              lc      Bit_ThroughCarry
              goto    rightShift

;;; ----------------------------------------
;;;
;;; Rotate right
;;;
;;; ----------------------------------------

              .name   "RR"
RR:           nop                   ; Prelude for prompting function
              nop
              gosub   argument
              ;; Defaults to count 1, prevent ST input, but allow IND
              .con    Operand01 + SEMI_MERGED_NO_STACK
              pt=     13
              lc      Bit_Rotate
rightShift:   switchBank 2
              bcex    s             ; B.S=configuration
              rxq     findIntegerBufferUserFlags_rom2
              bcex    s
              rcr     4
              pt=     9
              bcex    pt            ; B[9]= configuration nibble
              rxq     argumentValueG
              c=b                   ; C[9]= configuration nibble
              rcr     -4
              bcex    s             ; B.S= configuration nibble
              rxq     findIntegerBufferGetXSaveL56_rom2
              c=0     x             ; test for zero input
              pt=     0
              c=g
              ?c#0    x             ; zero?
              gonc    120$          ; yes, done

              c=b     s
              c=c+c   s
              c=c+c   s
              c=c+c   s             ; arithmetic shift (sign preserving)?
              gonc    1$            ; no
              rxq     setSignFlag_rom2
              c=regn  X             ; restore A= lower part of X
              a=c

;;; Shift loop starts here

1$:           c=0                   ; outgoing carry
              c=c+1   x             ; ..
              .suppress
              c=c&a                 ; to C.X

              isArithmetic
              gonc    4$            ; no

              ;; Check the sign, we preserve it by shifting in a bit at the
              ;; highest position, just like we would shift in a carry.
              ?st=1   Flag_Sign
              gonc    66$
              goto    69$           ; keep sign bit at the top

70$:          bcex    x             ; carry at position 56
              c=c+1   x
              goto    72$

4$:           isThroughCarry
              goc     67$           ; through carry
              isRotate
              gonc    66$           ; no rotate, so no carry in
              ?c#0    x             ; inspect lowest bit (which will wrap in at the top)
              goc     69$           ; carry enters
              goto    66$
67$:          ?st=1   Flag_CY       ; inspect carry in
              gonc    66$           ; nothing

              ;; Insert carry at highest location
69$:          rcr     -3            ; push outgoing carry on stack
              stk=c
              c=m                   ; get carry mask
              ?st=1   Flag_56
              goc     70$           ; carry at position 56
              ?st=1   Flag_UpperHalf
              goc     71$           ; carry in upper half
              c=c|a                 ; carry in lower half
              acex
              goto    73$

11$:          goto    1$            ; relay
120$:         goto    12$           ; relay

71$:          c=m                   ; in upper half
              abex
              c=c|a
              abex
72$:          bcex    x
73$:          c=stk                 ; get carry back
              rcr     3

66$:          st=0    Flag_CY       ; set outgoing carry
              ?c#0    x
              gonc    68$
              st=1    Flag_CY
68$:          acex
              a=0     s             ; where bits shifted out go
              bcex    x             ; copy bit that wraps from upper to lower
              cstex
              ?s0=1
              gonc    64$
              a=a+1   s
64$:          cstex
              c=c+c   x             ; handle right shift of upper part
              c=c+c   x
              c=c+c   x
              csr     x
              bcex    x
              pt=     3             ; counter for lower part
62$:          acex    s
              c=c+c   s
              acex    s
              c=c+c                 ; low part << 3
              gonc    63$
              a=a+1   s
63$:          decpt
              ?pt=    0
              gonc    62$

              csr                   ; finalize lower word
              acex    m
              acex    x

              c=0     xs            ; decrement shift counter
              c=g
              c=c-1   x
              g=c
              ?c#0    x
              goc     11$
              acex
              regn=c  X
12$:          rgo     putX_rom2

              .section Code, reorder
;;; **********************************************************************
;;;
;;; displayX - Shell entry to display integer X register
;;;
;;; This is the main display entry point routine. We make no assumptions
;;; other that the integer buffer exists (otherwise we will not be in
;;; integer mode).
;;;
;;; **********************************************************************

Flag_LocalZeroFill: .equ   Flag_UpperHalf

;;; Entry point to show program literal from digit entry. In this
;;; case we want to fetch the literal from program memory (as we
;;; lost it when writing it), as well as saving internal flags.
;;; IN: B.X-N - literal
displayPrgmLiteralDE:
              rxq fetchLiteral
              c=b
              rcr     10
              dadd=c
              c=data
              c=st
              data=c
              goto    disPRGM10

;;; Entry point to show program literal from poll vector
;;; IN: B.X-N - literal
displayPrgmLiteral:
              c=data
              st=c
disPRGM10:    st=1    Flag_PRGM
              pt=     3             ; set word size
              lc      4
              lc      0
              cnex                  ; N= updated buffer header
              a=c
              c=0     x             ; select chip 0
              dadd=c
              goto    display2

;;; Entry point with buffer address in B[12:10] and a need to save internal
;;; flags. This is used by digit entry in run mode.
displayXB10:  c=b
              rcr     10
              dadd=c
              a=c     x
              goto    dis10

              .align  4
displayX:     rxq     findIntegerBuffer
dis10:        c=data
              n=c                   ; save header in N
              rxq     loadX         ; load and mask X
dis20:        st=0    Flag_PRGM

;;; During digit entry, check for a key up after about 0.1 seconds (here).
;;; If key released, set S12 so that the key handler will not exit
;;; via resetting keyboard, but instead allow for the next key to be
;;; pressed while we are processing the current digit entry key.
;;; This is to allow for two rapid key presses.
              ?st=1   IF_DigitEntry
              gonc    12$
              releaseKey
12$:
              ;; handle window for all bases except decimal
display2:     c=n                   ; check window#
              pt=     9
              lc      0
              g=c                   ; save in G[0] for '.' around base char

              ?s1=1                 ; check for decimal, it is done differently
              goc     22$           ; hex or oct
              ?s3=1
              goc     100$          ; decimal
22$:
              rcr     -5
              c=0     m             ; C.M= # digits outside window to the right / 2
              ?c#0    s
              gonc    1$            ; window 0

18$:          c=c-1   s
              goc     1$
              pt=     1
              abex    wpt
              b=0     x
              acex
              rcr     2
              a=a+1   m
              ?s1=1
              goc     168$
                                    ; bin, window in 8 bits
19$:          acex
              goto    18$

100$:         rgo     10$           ; relay

168$:         ?s3=1
              goc     16$           ; hex
              pt=     3             ; oct
              c=0     wpt
              rcr     4
              goto    169$

16$:          pt=     5
              c=0     wpt
              rcr     6
              a=a+1   m
169$:         a=a+1   m
              a=a+1   m
              goto    19$

1$:           pt=     1             ; adjust remaining word size for window
              rcr     3
              c=c+c   x             ; scale it up
              c=c+c   x
              c=c+c   x
              acex
              cnex
              rcr     2             ; C[1:0]= word size
              acex    wpt
              c=a-c   wpt
              gonc    11$
              c=0     wpt           ; used up all quota
11$:          rcr     -2
              cnex                  ; write back updated word size
              acex                  ; restore A

              st=0    Flag_LocalZeroFill
              ?st=1   Flag_PRGM
              goc     3$            ; no zero fill in program mode due
                                    ;  to user flag
              c=regn  14            ; move user zero-fill flag to
              rcr     12            ;  local flag (outside low ST)
              cstex
              ?st=1   Flag_ZeroFill
              gonc    2$
              st=1    Flag_LocalZeroFill
2$:           cstex                 ; bring up internal flags

3$:           gosub   CLLCDE
              pt=     8             ; assume hex
              ?s3=1
              goc     20$
              pt=     6             ; assume octal
              ?s1=1
              goc     20$
              pt=     2             ; binary

20$:          ?b#0    x             ; non-zero bits outside?
              goc     25$           ; yes
              c=0
              lc      1             ; make mask
              c=c-1
              c=-c-1                ; mask above characters to be displayed
              acex
              m=c
              c=c&a
              acex
              cmex
              acex
              ?c#0
              gonc    26$           ; zero above
25$:          st=1    Flag_LocalZeroFill ; need zero fill
              c=g
              inc pt
              lc      8             ; set '.' bit for above bits
              g=c
26$:          ldi     1             ; decide on number of digits
              ?s1=1
              gonc    27$
              c=c+1   x
              c=c+1   x
              ?s3=1
              gonc    27$
              c=c+1   x
27$:          b=a     x             ; preserve A.X in B.X
              a=c     x             ; A.X= bits per digit
              c=n
              rcr     2             ; C[1:0]= word size
              pt=     0
              c=0     xs
              c=c-1   x
              goc     29$           ; window outside limit
              acex    x
28$:          inc pt
              ?pt=    8
              goc     29$           ; not more than 8 characters
              a=a-c   x
              gonc    28$
29$:          abex    x             ; restore A

              ?st=1   IF_DigitEntry
              gonc    31$
              ldi     0x1f          ; show we are in digit entry mode
              srsabc

              releaseKey

31$:          ?pt=    0             ; show digits?
              goc     61$           ; no, just an empty base

;;; Do next character. Extract the bits and right shift A depending on
;;; base to prepare it for next character
30$:          acex                  ; C[7:0]= number to display
              c=0     s             ; C.S= 1
              c=c+1   s
              ?s1=1
              goc     80$           ; oct or hex
              c=c+c                 ; bin
              c=c+c
38$:          c=c+c                 ; oct

40$:          rcr     1             ; C[7:0]= number >> base
              bcex    wpt           ; move the relevant bits to B
              c=0     x
              rcr     -1            ; C.X= bits for this digit
42$:          c=c+c                 ; align it to C[1]
              gonc    42$
              csr     x             ; and finally in C.X
              a=c     x
              ldi     10
              ?a<c    x
              gonc    44$
              ldi     '0'
              goto    45$

44$:          ldi     -9            ; A-F (A has LCD code 1)
45$:          c=a+c   x             ; make character code
              srsabc                ; and put on LCD
              dec pt
              ?b#0    wpt
              gonc    50$           ; rest is zero
              abex    wpt           ; A= put rest of bits
              ?pt=    0
              gonc    30$
              goto    60$

80$:          ?s3=1
              gonc    38$
              goto    40$           ; hex

10$:          rxq     decDigits     ; decimal
              goto    61$

50$:          ?st=1   Flag_LocalZeroFill
              gonc    60$           ; no zero fill
              ldi     '0'
52$:          ?pt=    0
              goc     60$
              srsabc
              dec pt
              gonc    52$

60$:          frsabc
;;; Done with characters, not put in base
61$:          a=0     x             ; no line# compensation
              rgo     lineAndBaseLCD

;;; ----------------------------------------------------------------------
;;;
;;; maskABx - Mask a value in B.X and A
;;;
;;; IN:  B.X - upper part of value
;;;      A - lower part of value
;;;      M = carry mask
;;;      Flag_UpperHalf valid
;;;
;;; Out: B.X/A - masked value
;;;
;;; Note: This routine exists in both
;;;
;;; ----------------------------------------------------------------------

maskABx:      .macro
              c=m
              c=c-1
              ?st=1   Flag_UpperHalf
              goc     10$
              c=c&a
              a=c
              b=0     x
              rtn

10$:          abex    x
              c=c&a
              acex    x
              abex    x
              rtn
              .endm

;;; **********************************************************************
;;;
;;; loadG - load register value by postfix argument
;;;
;;; argumentValueG - Alternative entry that loads a value, the argument
;;;    itself is the value unless it is indirect (in which case we load it)
;;;
;;; In: G - start address of number
;;;        M - carry mask
;;;        B[12:10] - buffer address
;;;
;;; Out: loadG:
;;;        B.X - upper part of argument value (register contents)
;;;        A - lower part of argument value (register contents)
;;;      argumentValueG:
;;;        G - value
;;;
;;; NOTE: Must have called findIntegerBuffer to have B[12:10] and M properly set up!
;;;       But should not save anything to L before coming here as we may
;;;       report argument error!
;;;
;;; **********************************************************************

              .section Code2, reorder
;;; Align local subroutine so we can use GSB256
;;; Note that for nibble memory we only need two consecutive registers.
;;; The worst case would be 64 bits (16 nibbles), but it still only need
;;; 2 registers no matter where we are. The reason is that it gets aligned
;;; to an even number of nibbles. Thus, it cannot be split between three
;;; registers, even though it in theory have enough span for that.
              .align  256
classify:     cstex
              a=c     x
              ldi     0x70
;              a=0     xs  (not needed as all calls are using GSB256)
              a=a-c   x
              goc     clNib         ; nibble storage
              c=stk
              c=c+1   m             ; advance return pointer
              ldi     4
              acex    x
              ?a<c    x
              goc     clStatus      ; status register
              a=a-c   x             ; A= shift count of trailer reg
              gotoc

clStatus:     dadd=c                ; select status register
              c=c+1   m
              gotoc                 ; return to (P+2)

clNib:        a=a+c   x             ; A.X= register number
classNibble:  c=b                   ; select header register
              rcr     10
              dadd=c
              c=data
              rcr     2             ; C[1:0]= word size
              c=0     xs
              c=0     m
              c=c-1   x
              c=c+c   x             ; (WS - 1) * 4
              c=c+c   x
              csr     x             ; C.X= nibbles for each entity - 1
              dadd=c                ; select chip 0
              rcr     -3
              a=c     m             ; A[3]/A[5:3]= nibbles for each entity - 1
              c=regn  13
              rcr     3
              c=0     m             ; clear nibbles above to catch register
                                    ;  overflow properly
              pt=     13            ; nibble counter offset by 2
              lc      2
              rcr     -4            ; C[13:4]= base register for data memory
              pt=     3

12$:          rcr     3             ; B[3:0]= register address before advance
              b=c     wpt
              rcr     -3
              c=a+c   pt            ; advance nibble pointer
              goc     14$           ; wrapped
              c=c+1   pt            ; no wrap, advance one more
              gonc    18$           ; still in same register
              goto    15$           ; advance register

14$:          c=c+1   pt            ; advance 1 more, will not give carry
                                    ;  as we just had it
15$:          rcr     1             ; step one register forward
              c=c+1   m
              rcr     6
              a=c     s             ; A.S= third nibble of address
              rcr     7
              a=a-1   s             ; make sure we do not overflow to 0x200
              goc     16$
              a=a-1   s
              gonc    ERRNE_J1
16$:          c=c+1   pt            ; offset by 2
              c=c+1   pt
18$:          a=a-1   x             ; decrement nibble register counter
              gonc    12$

              rcr     4             ; C.X= last register address
              dadd=c                ; select last register covered
              a=c     x             ; A.X= last register address
              c=b     wpt           ; C[3:1]= first register address
              csr     wpt           ; C.X= first register address
              c=a-c   x             ; C[0]= number of registers needed - 1
              rcr     1
              bcex    s             ; B.S= number of registers needed - 1
              c=data                ; read memory
              c=-c-1  m             ; invert many bits, but not all
              data=c
              a=c
              c=data
              ?a#c                  ; reads back good?
              goc     ERRNE_J1      ; no, does not exist
              c=-c-1  m             ; invert back
              data=c                ; restore
              c=b     wpt
              rcr     1             ; C.X= first register address
                                    ; C.S= nibble offset + 2
              c=c-1   s
              c=c-1   s             ; C.S= nibble offset
;;; Nibble classification returns with:
;;;  C.X= first register address
;;;  C.S= nibble offset in first register
;;;  B.S= number of registers needed - 1
;;; Last register is within range and exists (also selected).
              rtn

ERRNE_J1:     rgo     ERRNE_rom2

argumentValueG:
              pt=     0
              c=g
              cstex
              ?s7=1                 ; indirect?
              goc     10$           ; yes
              cstex
              a=0
              acex    x
              acex    xs
              goto    12$

10$:          s7=0                  ; reset indirect
              s9=0                  ; no extra indirection
              cstex
              g=c
              rxq     loadG
              ?b#0    x             ; check range
              goc     ERRDE_J1
              acex
              pt=     0
              g=c                   ; save in G
              acex
12$:          c=0
              ldi     65
              ?a<c    x
              rtn c
ERRDE_J1:     rgo     ERRDE_rom2

loadG:        pt=     0
              c=g
              cstex
              s9=0
              ?s7=1
              gonc    loadST
              s7=0                  ; reset indirect bit
              s9=1                  ; S9= indirect bit
loadST:       gosub   GSB256        ; classify
              goto    50$           ; (P+1) nibble storage
              goto    70$           ; (P+2) stack register
              c=data                ; (P+3) (other) status register
              a=c
              b=0     x
              goto    750$

              ;; Handle indirection
12$:          rxq     maskABx_rom2
              ?b#0    x
              goc     ERRNE_J1
              c=0     x
              acex    x
              ?a#0
              goc     ERRNE_J1
              a=c     x
              rxq     classNibble
              s9=0                  ; only indirect once

;;;  C.X= first register address
;;;  C.S= nibble offset in first register
;;;  B.S= number of registers needed - 1
50$:          dadd=c
              bcex    s             ; B.S= nibble offset
              n=c
              c=data                ; read first register
              cnex                  ; N= first register part
              c=c-1   s             ; decrement register counter
              goc     51$           ; done, one register was enough
              c=c+1   x             ; point to next register
              dadd=c                ; select next register
              a=c                   ; A= save register address
              c=data                ; read second part
              goto    52$
51$:          c=0                   ; N
52$:                                ; C-N
              a=c
              c=n                   ; A-C
              pt=     0
              goto    55$
53$:          abex    s
              acex    pt
              rcr     1
              asr
55$:          abex    s
              a=a-1   s
              gonc    53$
              abex    s
              b=a     x             ; B[1:0]= upper part

58$:          a=c
              c=0     x
              dadd=c
750$:         goto    75$

120$:         goto    12$           ; relay

              ;; Load from stack register
70$:          bcex    x             ; B.X= stack reg addr
              c=b
              rcr     10
              c=c+1   x
              dadd=c                ; select trailer register
              c=data
72$:          a=a-1   x             ; align upper part
              goc     73$
              rcr     2
              goto    72$
73$:          c=0     xs
              bcex    x
              dadd=c                ; select stack register
              c=data                ; load it
              a=c
75$:          ?s9=1
              goc     120$
maskABx_rom2: maskABx

;;; ----------------------------------------------------------------------
;;;
;;; saveG - save to memory
;;; saveMaskG - alternative entry that masks the value before saving
;;;
;;; IN: G - postfix operand
;;;     M - carry mask
;;;     B.X - upper part to save
;;;     A - lower part to save
;;;
;;; A, B, C, M, N, Q destroyed
;;; Preserves: B[12:10], ST and G
;;;
;;; Assume: B[12:10] = buffer header address
;;;         Number properly masked, or call saveMaskG to have it done.
;;;
;;; ----------------------------------------------------------------------

ERRNE_J2:     rgo     ERRNE_rom2    ; yes

saveMaskG:    rxq     maskABx_rom2
saveG:        c=0     x             ; select chip 0
              dadd=c
              acex
              regn=c  Q             ; save lower part in Q
              n=c                   ; and in N (will not survive nibble
                                    ;  indirect read)
              c=b     x             ; get upper part
              rcr     -3
              stk=c                 ; save upper part on stack

              pt=     0
              c=g
              cstex
              ?s7=1                 ; indirect?
              gonc    10$           ; no
              s7=0                  ; yes, reset indirect bit
              cstex
              g=c                   ; G= same with reset indirect
              rxq     loadG         ; load nibble address
              ?b#0    x             ; range check register address
              goc     ERRNE_J2      ; we allow 000-FFF
              c=0     x
              acex    x
              ?a#0
              goc     ERRNE_J2
              a=c     x             ; address value OK
              rxq     classNibble   ; we know it is nibble memory
              goto    50$           ; handle nibble memory

10$:          gosub   GSB256        ; classify
              goto    50$           ; (P+1) nibble storage
              goto    70$           ; (P+2) stack register
                                    ; (P+3) (other) status register
              spopnd                ; drop upper part
              c=n
              data=c
              rtn

              ;; Stack register
70$:          bcex    x             ; B.X= stack register address

              c=stk                 ; get upper part
              pt=     3
              g=c                   ; G= upper part

              pt=     12            ; align pointer with upper part in
72$:          inc pt
              inc pt
              a=a-1   x
              gonc    72$

              c=b
              rcr     10
              c=c+1   x
              dadd=c                ; select trailer register
              c=data                ; read trailer
              c=g                   ; insert upper part
              data=c                ; write back

              bcex    x             ; C.X= address of stack register
              dadd=c                ; select it
              c=n                   ; C= lower part
              data=c                ; write
              rtn

;;; Save to nibble memory
;;;  C.X= first register address
;;;  C.S= nibble offset in first register
;;;  B.S= number of registers needed - 1
50$:          bcex    s             ; B.S= nibble offset
              c=stk                 ; C[6:3]= upper part of value to save
              rcr     -4
              stk=c                 ; push first register and register count
              rcr     4 + 3         ; C[1:0]= upper part to save
              c=0     xs
              c=0     m
              c=0     s
              n=c                   ; N= second part of value
              c=0     x             ; select chip 0
              dadd=c
              c=regn  Q
              a=c                   ; A= low part of value

              pt=     0

              c=0
              cmex                  ; get carry pos
              c=c-1                 ; convert to a mask
              ?st=1   Flag_UpperHalf
              gonc    54$
              cmex                  ; partial mask is for upper part
              c=c-1
              goc     54$           ; always give carry here
;;; Value in N-A
;;; Mask in M-C  (if third register is needed, it will be one nibble, so
;;;   we do not represent it).
;;; B.S= nibble offset
;;;
;;; Now align both value and mask
51$:          bcex    s             ; restore B.S
              abex    x
              asl     x             ; B.X << 4
              abex    x
              cnex
              rcr     -1
              bcex    pt            ; move nibble up to B[0]
              rcr     1
              acex    s             ; nibble from A[13] to N[0]
              rcr     -1
              asl                   ; low part << 4
              cnex                  ; put N back, get C (mask back)

              acex                  ; A= low part of mask
              cmex                  ; C= high port of mask
              acex    s
              rcr     -1
              asl
              cmex
              acex

54$:          bcex    s
              c=c-1   s
              gonc    51$

;;; Mask and value are new aligned with data register(s)
              bcex    s             ; restore C
              c=-c-1                ; make unmasks
              cmex
              c=-c-1
              regn=c  Q             ; Q= high part of mask
              c=stk
              rcr     4
              dadd=c                ; select low data register
              rcr     -4
              stk=c
              c=data                ; read data register
              acex                  ; A= data register value
                                    ; C= low part of value to write
              cmex                  ; M= low part of value to write
                                    ; C= low part of mask
              c=c&a                 ; mask data contents
              a=c
              c=m                   ; get new contents
              c=c|a                 ; combine
              data=c                ; write back

              c=0     x             ; select chip 0
              dadd=c
              c=regn  Q             ; get high part of mask
              a=c                   ; A= second  mask

              c=stk
              rcr     4             ; C.X= register address
                                    ; C.S= register counter
              c=c-1   s
              goc     58$           ; done
              c=c+1   x             ; advance to next register
              dadd=c
              m=c                   ; M= register pointer and counter

              c=data                ; read second register
              c=c&a                 ; mask it
              a=c
              c=n
              c=c|a                 ; combine second part
              data=c                ; write back

58$:          golong  ENCP00

              .section Code2, reorder
ERRNE_rom2:   switchBank 1
              golong  ERRNE

              .section Code2, reorder
ERRDE_rom2:   switchBank 1
              golong  ERRDE

              .section Code, reorder
findIntegerBufferUserFlags_argumentValueG_rom1:
              rxq     findIntegerBufferUserFlags
argumentValueG_rom1:
              switchBank 2
              rxq     argumentValueG
              switchBank 1
              rtn

              .section Code, reorder
loadG_rom1:   switchBank 2
              rxq     loadG
              switchBank 1
              rtn

;;; ----------------------------------------------------------------------
;;;
;;; Load X register to B.X and A
;;;
;;; OUT:  B.X - upper part of X
;;;       A - lower part of X masked
;;;       SS0 up
;;; Assume: B[12:10] = buffer header address
;;;
;;; ----------------------------------------------------------------------

              .section Code, reorder
loadX:        c=b
              rcr     10
              c=c+1   x
              dadd=c                ; select trailer register
              c=data
              rcr     2             ; get upper X
              c=0     xs
              bcex    x             ; save in B[2:0]
              c=0     x
              dadd=c
              c=regn  X             ; load low part
maskCBx:      a=c
maskABx_rom1: maskABx

;;; **********************************************************************
;;;
;;; ENTERI- Integer stack enter.lift.
;;;
;;; **********************************************************************

              .section Code, reorder
              .name   "ENTERI"
ENTERI:       rxq     findIntegerBuffer
              s11=0                 ; disable stack lift
              rxq     liftStack
              rgo     exitNoUserST
                                    ; flags are not affected by ENTERI as
                                    ; we keep the same value in X

;;; ----------------------------------------------------------------------
;;;
;;; Lift the stack.
;;;
;;; Assume: B[12:10] = buffer header address
;;; Uses: A, C   selects chip 0
;;;
;;; ----------------------------------------------------------------------

              .section Code, reorder
findIntegerBufferUserFlags_liftStackS11:
              rxq     findIntegerBufferUserFlags
liftStackS11: ?s11=1                ; push flag?
              goc     liftStack     ; yes
              s11=1                 ; no, set it and do not lift stack
              golong  ENCP00

liftStack:    c=b                   ; get buffer address to A.X
              rcr     10
              c=c+1   x             ; point to register with upper bytes
              dadd=c
              c=data                ; read upper registers
              rcr     -1            ; C =  000TTZZYYXXLL1
              a=c     m             ; A.M = 00TTZZYYXX
              rcr     2             ; C =  L1000TTZZYYXXL
              acex    m             ; C =  L00TTZZYYXXXXL
              rcr     9             ; C =  ZZYYXXXXLL00TT
              c=0     x             ; C =  ZZYYXXXXLL0000
              rcr     4             ; C =  0000ZZYYXXXXLL
              c=c+1   s             ; C =  1000ZZYYXXXXLL
              data=c                ; write back

              c=0     x
              dadd=c                ; select chip 0

              c=regn  Z
              regn=c  T

              c=regn  Y
              regn=c  Z

              c=regn  X
              regn=c  Y

              rtn

              .section Code, reorder
;;; ----------------------------------------------------------------------
;;;
;;; WSIZE? - get word size
;;;
;;; ----------------------------------------------------------------------

              .name   "WSIZE?"
`WSIZE?`:     rxq     findIntegerBufferUserFlags_liftStackS11
              c=b
              rcr     10
              dadd=c
              c=data
              rcr     2
              a=c     x
              c=0
              dadd=c
              acex    x
              acex    xs
              regn=c  X
              b=0     x
              rgo     putX

              .section Code, reorder
;;; ----------------------------------------------------------------------
;;;
;;; WSIZE - set word size
;;;
;;; ----------------------------------------------------------------------

              .name   "WSIZE"
WSIZE:        nop
              nop
              gosub   argument
              ;; Defaults to word size 16, prevent ST input, but allow IND
              .con    Operand16 + SEMI_MERGED_NO_STACK
              switchBank 2
              rxq     findIntegerBufferUserFlags_rom2
              rxq     argumentValueG ; handle indirect, check 64 range
              c=0
              pt=     0
              c=g
              ?c#0    x             ; 0?
              goc     1$            ; no
              rgo     ERRDE_rom2    ; yes, do not allow
1$:           a=c     x             ; A.X= new word size
              c=b                   ; load buffer header
              rcr     10
              n=c                   ; N.X = buffer header address
              c=c+1   x             ; point to trailer
              dadd=c
              c=data
              cnex                  ; N= trailer
              dadd=c
              c=data                ; load header
              pt=     2
              cgex                  ; insert new word size, get old
              data=c                ; write back
              c=0
              pt=     0
              c=g                   ; C.X= old buffer size
              acex
              ?a<c    x             ; setting a larger word size?
              gonc    900$          ; no
                                    ; yes, extending the stack
              a=a-1   x             ; A.X= bit number for previous sign
              rxq     bitMask_rom2
              b=a     s             ; B.S= active part flag
              m=c                   ; M= (old) sign bit mask
              ldi     4 + 1         ; L + 1

10$:          c=c-1   x
              goc     30$
              dadd=c                ; select next lower register
              bcex    x
              ?b#0    s             ; sign in upper part?
              goc     15$           ; yes
              c=data                ; no, read lower part
              a=c
              ?st=1   Flag_2        ; unsigned mode?
              gonc    16$           ; yes, just mask
              c=m
              c=c&a
              ?c#0                  ; positive?
              gonc    16$           ; yes
              c=m                   ; no, sign extend
              c=c-1
              c=-c-1
              nop
              c=c|a
              data=c
              a=0                   ; A= FF
              a=a-1
              goc     11$           ; always branch
16$:          c=m                   ; unsigned or positive, clear bits outside
              c=c+c                 ; set first bit outside
              c=c-1                 ; make it a mask
              nop
              c=c&a
              data=c
              a=0                   ; A= 00
11$:          c=n                   ; write A[1:0] to upper part
              acex    x
              goto    22$

900$:         goto    90$           ; relay

15$:          c=n                   ; sign is in upper part
              a=c
              ?st=1   Flag_2        ; unsigned mode?
              gonc    20$           ; yes, zero extend
              c=m
              c=c&a
              ?c#0                  ; positive?
              gonc    20$           ; yes
              c=m                   ; no, sign extend
              c=c-1   x
              c=-c-1  x
              .suppress
              c=c|a
              goto    21$

20$:          c=m                   ; zero extend
              c=c+c   x             ; first bit outside
              c=c-1   x             ; make it a mask
              .suppress
              c=c&a
21$:          acex    m
              acex    s
22$:          acex    xs
              rcr     2
              n=c
              bcex    x
              goto    10$

30$:          c=b                   ; write back trailer
              rcr     10
              c=c+1   x
              dadd=c
              c=n
              rcr     4
              data=c
90$:
WSZ_OK:       rgo     exitNoUserST_rom2

;;; ----------------------------------------------------------------------
;;;
;;; WINDOW - set window
;;;
;;; ----------------------------------------------------------------------

;;; Make it non-programmable to allow it to be used in program mode
;;; to inspect integer literals as well. As we only allow 0-7 we
;;; use single digit input. This allows for IND, just like CAT and
;;; that picks up an ordinary decimal number from a register.
;;; A bit inconsistent, but there seems to be no simple way around
;;; it, and CAT has kind of misbehaved in a similar way from the
;;; beginning.

              .section Code, reorder
              .con    0x97, 0xf, 0x4, 0xe, 0x309, 0x117 ; WINDOW
WINDOW:       nop                   ; no programmable
              ldi     8             ; allow up to 7
              ?a<c    x
              golnc   ERRDE
              acex    x
              pt=     0
              g=c
              rxq     findIntegerBuffer
              c=st                  ; restore C[1:0]
              pt=     8
              c=g                   ; C[8]= window#
                                    ; C[9]= 0 (this is the space indent which
                                    ;          is sometimes set in I/O poll
                                    ;          after a command, here it is safe
                                    ;          to set it to 0)
              data=c
WINEXIT:      rxq     displayXB10
              gosub   displayDone
              golong  NFRC


#if  0
              .name   "PWINDOW"
PWINDOW:      nop
              nop
              rxq     Argument
              .con    Operand00
              ldi     8             ; allow up to 7
              ?a<c    x
              gonc    WSZ_DE
              rxq     findIntegerBuffer
              c=st                  ; restore C[1:0]
              pt=     8
              c=g                   ; C[8]= window#
                                    ; C[9]= 0 (this is the space indent which
                                    ;          is sometimes set in I/O poll
                                    ;          after a command, here it is safe
                                    ;          to set it to 0)
              data=c
              goto    WINEXIT
#endif

;;; ----------------------------------------------------------------------
;;;
;;; LDI - load integer, either from nibble memory, status register or
;;;       stack.
;;;
;;; ----------------------------------------------------------------------

              .section Code, reorder
              .name   "LDI"
LDI:          nop
              nop
              gosub   argument
              .con    Operand00     ; LDI 00 is default
              rxq     findIntegerBufferUserFlags
              rxq     loadG_rom1
LDI10:        acex
              n=c                   ; save value in N
              rxq     liftStackS11
              c=n
              regn=c  X
              rgo     putX

;;; ----------------------------------------------------------------------
;;;
;;; STI - store integer, either from nibble memory, status register or
;;;       stack.
;;;
;;; ----------------------------------------------------------------------

              .section Code, reorder
              .name   "STI"
STI:          nop
              nop
              gosub   argument
              .con    Operand00     ; LDI 00 is default
              rxq     findIntegerBufferUserFlags
              rxq     loadX
              switchBank 2
              rxq     saveG
              rgo     exitNoUserST_rom2

;;; ----------------------------------------------------------------------
;;;
;;; INCI - increment register contents and set sign and zero flags.
;;;
;;; ----------------------------------------------------------------------

              .section Code, reorder
              .name   "INCI"
INCI:         nop
              nop
              gosub   argument
              .con    Operand00     ; INCI 00 is default
              rxq     findIntegerBufferUserFlags
              switchBank 2
              rxq     loadG
              a=a+1
              gonc    10$
              bcex    x
              c=c+1   x
              bcex    x
10$:          rgo     DECI00

;;; ----------------------------------------------------------------------
;;;
;;; DECI - decrement register contents and set sign and zero flags.
;;;
;;; ----------------------------------------------------------------------

              .section Code, reorder
              .name   "DECI"
DECI:         nop
              nop
              gosub   argument
              .con    Operand00     ; DECI 00 is default
              rxq     findIntegerBufferUserFlags
              switchBank 2
              rxq     loadG
              a=a-1
              gonc    DECI00
              bcex    x
              c=c-1   x
              bcex    x
DECI00:       c=a
              n=c
              rxq     setFlagsABx
              c=n
              a=c
              rxq     saveG
              rgo     exitUserST_rom2

;;; ----------------------------------------------------------------------
;;;
;;; DSZI - decrement register, skip on zero.
;;;
;;; ----------------------------------------------------------------------

              .section Code, reorder
              .name   "DSZI"
DSZI:         nop
              nop
              gosub   argument
              .con    Operand00     ; DSZI 00 is default
              rxq     findIntegerBufferUserFlags
              switchBank 2
              rxq     loadG
              a=a-1                 ; decrement
              gonc    5$
              bcex    x
              c=c-1   x
              bcex    x
5$:           rxq     maskABx_rom2  ; for proper zero test
              s0=0                  ; assume zero
              ?a#0
              goc     10$
              ?b#0    x
              gonc    20$
10$:          s0=1                  ; remember non-zero
20$:          rxq     saveG         ; write back updated register
              s7=1                  ; no YES/NO in run-mode
              switchBank 1
              ?s0=1                 ; non-zero?
              golc    NOSKP         ; yes
              golong  SKP

;;; ----------------------------------------------------------------------
;;;
;;; CLRI - clear an integer register value
;;;
;;; ----------------------------------------------------------------------

              .section Code, reorder
              .name   "CLRI"
CLRI:         nop
              nop
              gosub   argument
              .con    Operand00     ; CLRI 00 is default
              rxq     findIntegerBufferUserFlags
              switchBank 2
              a=0
              b=0     x
              rxq     saveG
              rgo     exitNoUserST_rom2

;;; ----------------------------------------------------------------------
;;;
;;; SEX - Sign extend for a given word size (not bit number).
;;;
;;; ----------------------------------------------------------------------

              .section Code, reorder
              .name   "SEX"
SEX:          nop
              nop
              gosub   argument
              ;; Defaults to word size 16, prevent ST input, but allow IND
              .con    Operand16 + 0x100
              rxq     findIntegerBufferUserFlags_argumentValueG_rom1
              a=a-1   x
              golc    ERRDE         ; 0 gives DATA ERROR
              rxq     findIntegerBufferGetXSaveL
              pt=     0             ; load argument
              c=0     x
              c=g
              c=c-1   x             ; we work on word size
              a=c     x
              rxq     bitMask
              n=c
              ?a#0    s
              goc     10$           ; in upper part
              a=c
              c=regn  X
              acex
              c=c&a
              ?c#0
              gonc    5$
              c=n
              c=c-1
              c=-c-1
              nop
              c=c|a
              regn=c  X
              c=0     x
              c=c-1   x
              bcex    x
5$:           rgo     putX

10$:          a=c     x
              c=b     x
              c=c&a
              ?c#0    x
              gonc    5$
              c=n
              c=c-1   x
              c=-c-1  x
              abex    x
              c=c|a
              bcex    x
              goto    5$

;;; ----------------------------------------------------------------------
;;;
;;; BITSUM - Count bits in register operand.
;;;
;;; ----------------------------------------------------------------------

              .section Code, reorder
              .name   "BITSUM"
BITSUM:       nop
              nop
              gosub   argument
              .con    OperandX
              rxq     findIntegerBufferUserFlags
              rxq     loadG_rom1
              c=0
              acex
10$:          ?c#0
              gonc    15$
11$:          c=c+c
              gonc    11$
              a=a+1
              goto    10$
15$:          ?b#0    x
              gonc    20$
              bcex    x
              rcr     2
              goto    11$
20$:          rgo     LDI10

;;; ----------------------------------------------------------------------
;;;
;;; ALDI - Alpha load integer, either from nibble memory, status register or
;;;        stack. Appends the number to alpha register.
;;;
;;; ----------------------------------------------------------------------

              .section Code, reorder
              .name   "ALDI"
ALDI:         nop
              nop
              gosub   argument
              .con    OperandX      ; ALDI X is default
              rxq     findIntegerBufferUserFlags
              switchBank 2
              rcr     -4
              pt=     7
              bcex    wpt           ; B[7:6]= word size,
                                    ; B[5:4]= internal flags
              rxq     loadG

              c=b                   ; check for decimal mode
              rcr     5             ; C.S= base - 1
              c=c+1   s             ; hex?
              goc     1$            ; yes
              c=c-1   s
              c=c+c   s             ; decimal?
              goc     6000$         ; yes
1$:

;;; Left align the number in B.X-A
              ldi     64            ; max word size
              acex
              n=c                   ; N= lower part
              c=b
              rcr     6
              c=0     xs
              c=a-c   x             ; C.X= 64 - word size
              cnex
              a=c
              cnex
4$:           cstex                 ; ST= word size
              ?s0=1                 ; multiple of 4?
              goc     5$            ; no
              ?s1=1
              gonc    15$
5$:           bcex    x             ; left shift one step
              c=c+c   x
              acex
              c=c+c
              gonc    10$
              a=a+1   x
10$:          acex
              bcex    x

              cstex
              c=c-1   x
              goto    4$

6000$:        goto    600$          ; relay

              ;; Multiple of 4
15$:          cstex
              c=0     xs
              ?c#0    x
              gonc    20$
              c=c-1   x
16$:          acex    s             ; C.S= nibble going to upper half
              asl
              bcex    x
              rcr     -1
              bcex    x

              c=c-1   x
              c=c-1   x
              c=c-1   x
              c=c-1   x
              gonc    16$
20$:

;;; Based on word size and base, determine:
;;; - bits for first character
;;; - bits for following characters
;;; - number of characters in total

              acex
              n=c                   ; N= lower part

              c=b
              rcr     6             ; C[1:0]= word size
                                    ; C[12]= base
              c=0     xs
              a=c     x             ; A.X = word size

              rcr     -1            ; C.S= base

              ;; determine digit size
              ldi     4             ; assume hex digits (4 bits)
              c=c+c   s
              goc     30$           ; hex - 4
              c=c-1   x
              c=c+c   s
              goc     30$           ; oct - 3
              c=c-1   x
              c=c-1   x             ; bin - 1
30$:          c=0     m             ; digit counter
32$:          c=c+1   m
              a=a-c   x
              goc     34$
              ?a#0    x
              goc     32$
34$:          a=a+c   x             ; A.X= bits for first character
                                    ; C.X= bits for rest of characters
                                    ; A.M= number of digits
              c=c-1   m
40$:          m=c                   ; M.X= bits for a character (except first)
                                    ; M.M= digit counter-1

              c=b     x             ; C[1:0]= next nibble
              c=0     xs
41$:          a=a-1   x             ; C.X-N << A.X
              goc     44$
              c=c+c   x
              acex    x
              cnex
              c=c+c
              gonc    42$
              a=a+1   x
42$:          cnex
              acex    x
              goto    41$

600$:         goto    60$           ; relay

44$:          b=c     x             ; B.X= updated value
              ?st=1   Flag_ZeroFill
              goc     45$
              ?c#0    xs
              gonc    55$
              st=1    Flag_ZeroFill ; non-zero seen
45$:          rcr     2             ; C[0]= binary digit value
              pt=     1             ; convert to ASCII
              lc      3
              a=c     x
              lc      10
              ?a<c    x
              goc     50$
              ldi     7
              a=a+c   x
50$:          acex    x
              pt=     0
              g=c                   ; G= ASCII digit
              gosub   APNDNW        ; append to alpha register
55$:          c=m
              a=c     x             ; next digit size
              c=c-1   m
              gonc    40$
              rgo     exitNoUserST_rom2

;;; Display in base 10
60$:          s1=1                  ; we are coming from ALDI
              s0=1                  ; should have internal flags up, but we do
                                    ;  not have that, setting S0 suffices
              c=b     m             ; preserve buffer address on stack
              rcr     7
              stk=c
              switchBank 1
              rxq     decDigits1
              c=stk
              rcr     -7
              bcex    m
              rgo     exitNoUserST

;;; ----------------------------------------------------------------------
;;;
;;; TST - set sign and zero flags according to an integer
;;;
;;; ----------------------------------------------------------------------

              .section Code, reorder
              .name   "TST"
TST:          nop
              nop
              gosub   argument
              .con    Operand00     ; TST 00 is default
              rxq     findIntegerBufferUserFlags
              switchBank 2
              rxq     loadG
              rxq     setFlagsABx
              rgo     exitUserST_rom2

;;; ----------------------------------------------------------------------
;;;
;;; CMP - compare X to another value, basically doing  X - value, setting
;;;       flags according to the outcome
;;;
;;; ----------------------------------------------------------------------

              .section Code, reorder
              .name   "CMP"
CMP:          nop
              nop
              gosub   argument
              .con    OperandY
              rxq     findIntegerBufferUserFlags
              switchBank 2
              rxq     loadG
              st=0    Flag_CY
              st=0    Flag_Overflow
              rxq     getSign_rom2
              bcex    s             ; save operand sign in B.S
              c=regn  X             ; load X
              acex
              n=c                   ; N= low part of operand
              bcex    x
              pt=     0
              g=c                   ; G= upper part of operand
              c=b                   ; load upper part of X
              rcr     10            ;  from buffer trailer
              c=c+1   x
              dadd=c
              c=data
              rcr     2
              c=0     xs
              bcex    x
              c=0     x
              dadd=c
              rxq     getSign_rom2  ; C.S= sign of X
              abex    s
              ?a#c    s             ; same sign?
              gonc    2$            ; yes, cannot overflow
              ?st=1   Flag_2        ; in signed mode?
              gonc    2$            ; no
              st=1    Flag_Overflow ; assume overflow/mark overflow check
2$:           abex    s             ; B.S= sign(operand)

              c=n                   ; perform X - operand
              a=a-c
              gonc    5$
              bcex    x
              c=c-1   x
              gonc    4$
              st=1    Flag_CY
4$:           bcex    x
5$:           abex    x
              c=g
              c=0     xs
              a=a-c   x
              gonc    10$
              st=1    Flag_CY
10$:          abex    x
              ?b#0    xs
              gonc    12$
              st=1    Flag_CY
12$:          ?st=1   Flag_Overflow
              gonc    20$           ; cannot overflow/no overflow check
              rxq     getSign_rom2
              abex    s
              ?a#c    s             ; same sign?
              gonc    15$           ; yes, overflow (already set)
              st=0    Flag_Overflow
15$:          abex    s             ; restore A.S
20$:          rxq     setFlagsABx   ; set sign and zero flags
              rgo     exitUserST_rom2

;;; ----------------------------------------------------------------------
;;;
;;; LT? GT? LE? GE? - relative compares after CMP or SUB
;;;
;;; Note: Use simple flag tests for other compares.
;;;
;;; ----------------------------------------------------------------------

              .section Code, reorder
              .name   "LT?"
`LT?`:        c=regn  14
              rcr     12
              st=c
              ?st=1   Flag_2
              goc     LT2
              ?st=1   Flag_CY
              goc     noSkip        ; CS
skip:         s7=0
              golong  SKP
LT2:          ?st=1   Flag_Sign     ; N != V
              goc     LT3
              ?st=1   Flag_Overflow
              gonc    skip
noSkip:       s7=0
              golong  NOSKP
LT3:          ?st=1   Flag_Overflow
              gonc    noSkip
              goto    skip

              .name   "GE?"
`GE?`:        c=regn  14
              rcr     12
              st=c
              ?st=1   Flag_2
              goc     GE2
              ?st=1   Flag_CY
              gonc    noSkip        ; CC
              goto    skip

GE2:          ?st=1   Flag_Sign     ; N == V
              goc     GE3
              ?st=1   Flag_Overflow
              gonc    noSkip
              goto    skip
GE3:          ?st=1   Flag_Overflow
              goc     noSkip
              goto    skip

              .name   "LE?"
`LE?`:        c=regn  14
              rcr     12
              st=c
              ?st=1   Flag_2
              goc     LE2
              ?st=1   Flag_CY       ; unsigned: CS or Z
              goc     noSkip
              ?st=1   Flag_Zero
              goc     noSkip
              goto    skip

LE2:          ?st=1   Flag_Zero     ; Z==1, or (N != V)
              goc     noSkip
              goto    LT2

              .name   "GT?"
`GT?`:        c=regn  14
              rcr     12
              st=c
              ?st=1   Flag_2
              goc     GT2
              ?st=1   Flag_Zero     ; Z==1 or CC
              goc     skip
              ?st=1   Flag_CY
              gonc    noSkip
              goto    skip
GT2:          ?st=1   Flag_Zero     ; Z==0 and (N == V)
              goc     skip
              goto    GE2

;;; ----------------------------------------------------------------------
;;;
;;; MUL - multiply, both double and single precision
;;;
;;; ----------------------------------------------------------------------

              .section Code2, reorder
;;; Multiply 8x56
;;; IN  ST= 8 bits
;;;     M= 56 bits
;;;     B[2:0] : A = sum
;;; OUT
;;;     B[2:0] : A = updated sum
`mul8x56`:    c=0     x             ; C[1:0]= extension of M
              pt=     0
              goto    15$

10$:          cstex                 ; shift ST right
              c=c+c   x
              c=c+c   x
              c=c+c   x
              csr     x
              cstex
              c=0     xs

              c=c+c   x             ; shift M extension (C[1:0])
              cmex
              c=c+c
              gonc    11$
              cmex
              c=c+1   x             ; handle carry from M to C[1:0]
              goto    15$
11$:          cmex

15$:          ?s0=1
              gonc    20$
              cmex
              a=a+c                 ; add lower 56 bits
              gonc    16$
              abex    x
              a=a+1   x             ; handle carry
              goto    17$
16$:          abex    x
17$:          cmex
              a=a+c   x             ; add upper part
              abex    x

20$:          inc pt
              ?pt=    8
              gonc    10$
              rtn

              .section Code, reorder
              .name   "DMUL"
DMUL:         s11=1                 ; want double result
              goto    mulCommon

              .name   "MUL"
MUL:          s11=0                 ; want single result
mulCommon:    rxq     findIntegerBufferGetXSaveL0no11
              switchBank 2
              ?st=1   Flag_2
              gonc    2$
              rxq     getSignsMakePositive
2$:           c=a-c   s             ; C.S= 0 if same sign
              c=st
              rcr     -4
              stk=c

              c=b
              pt=     0
              g=c                   ; G= upper X
              rcr     10 - 3
              stk=c                 ; save buffer address


;;; Start with 56x56 multiplication.
;;; Sum= B : A  (initially 0)
;;; op1= X       we inspect bits from this one
;;; op2= M : Y   M starts as 0, we shift this one each iteration

              clrabc
              cmex
              regn=c  Q             ; Q= carry mask

              pt=     0             ; outer loop counter

              ;; main loop, 14 times
10$:          c=regn  X             ; take next nibble
              st=c                  ; nibble to ST
              rcr     1
              regn=c  X
              ldi     3             ; load counter for nibble, 4 times
              rcr     1
              c=st
              rcr     -1
              st=c

              ;; start of inner loop, 4 times
15$:          c=m
              ?s4=1                 ; lowest bit set?
              gonc    24$           ; no

              ;; Add to result
20$:          c=regn  Y             ; Update sum
              a=a+c                 ; lower part
              gonc    21$
              abex                  ; got carry
              a=a+1
              goto    22$
21$:          abex
22$:          c=m                   ; upper part
              a=a+c
              abex

              ;; shift op2 one step left
24$:          c=c+c
              m=c
              c=regn  Y
              c=c+c
              gonc    25$
              cmex
              c=c+1
              cmex
25$:          regn=c  Y

              ;; close inner loop (dealing with a nibble)
              c=st
              rcr     1
              c=c-1   s
              goc     28$           ; inner loop done

              c=c+c   x             ; right shift nibble
              c=c+c   x
              c=c+c   x
              csr     x
              rcr     -1
              st=c
              goto    15$

28$:          inc pt
              ?pt=    0
              gonc    10$

;;; Done with 56x56 MUL, the lowest 56 bits of the result in A will
;;; not be affected by the two following 8x56 multiplications.
;;; N has the upper parts, so we tuck it away there and get the
;;; two bytes at the same time.
30$:          abex                  ; A= second 56 bits of sum
              bcex
              cnex                  ; N= lower 56 bits of result
                                    ; C= buffer trailer registers
              pt=     4
              cgex                  ; G= upper part of Y
              rcr     4
              st=c                  ; ST= upper part of X

              c=0                   ; B[12:11]= high part of op1
              c=st
              rcr     3
              bcex

              ?b#0
              gonc    31$
              rxq     `mul8x56`

31$:          c=regn  X
              m=c
              pt=     0
              c=g
              st=c
              c=0     xs
              ?c#0    x
              gonc    33$
              rxq     `mul8x56`

              ;; mul 8x8
33$:          acex
              m=c                   ; M= second 56 bits of sum
              a=0
              abex    x             ; A= upper 16 bits
              c=b
              rcr     -3            ; C[1:0]= upper part of op1
              c=0     xs
              ?c#0    x
              gonc    40$           ; operand is zero
              st=c
              c=0
              pt=     0
              c=g
              ?c#0    x
              gonc    40$           ; other operand is zero
              goto    35$
32$:          rcr     -3
              cstex                 ; shift ST right
              c=c+c   x
              c=c+c   x
              c=c+c   x
              csr     x
              cstex
              rcr     3

              c=c+c                 ; shift operand left

35$:          ?s0=1
              gonc    38$
              a=a+c                 ; add to sum
38$:          inc     pt
              ?pt=    8
              gonc    32$

;;; Done, result is in A[3:0] : M : N
40$:          c=stk                 ; restore buffer pointer to B[12:10]
              rcr     -(10 - 3)
              bcex    m

              c=stk                 ; get ST and calculated sign
              rcr     4             ; C.S= calculated sign
              st=c
              st=0    Flag_Overflow

              ?st=1   Flag_2        ; are we in signed mode?
              gonc    44$           ; no
              ?c#0    s             ; result is calculated to be negative?
              gonc    44$           ; no

              s7=1                  ; yes, negate result (borrow S7, zero flag)
              cnex
              c=-c
              gonc    41$
              s7=0                  ; bit-not next
41$:          cnex
              cmex
              c=-c-1
              ?s7=1
              gonc    42$
              c=c+1
              goc     42$
              s7=0                  ; bit-not next
42$:          cmex
              acex
              c=-c-1
              ?s7=1
              gonc    43$
              c=c+1
43$:          acex

44$:          cnex                  ; N.S= calculated sign
              regn=c  X             ; put lower result in X

              ?s11=1                ; doing "DMUL"?
              goc     70$           ; yes

              ;; Next line is needed, we borrowed the stack lift flag,
              ;; now set it as we leave with stack lift enabled.
              s11=1                 ; set push flag (enable stack lift)

              ?a#0                  ; check uppermost 16 bits which are way out
                                    ;  of range for single precision MUL
              gonc    47$
              st=1    Flag_Overflow
47$:          c=regn  Q             ; get carry mask
              cmex                  ; get second 56 bits, M= carry mask
              b=0     x
              bcex    x             ; B.X= lower 12 bits of second 56 bits
                                    ; C= remaining bits of second 56 bits
              ?c#0                  ; any non-zero?
              gonc    48$           ; no
              st=1    Flag_Overflow ; yes, we overflowed
48$:          c=regn  X
              a=c                   ; A= lower 56 bits of result
              ?st=1   Flag_2        ; in 2-complement signed mode?
              gonc    50$           ; no, unsigned mode
              rxq     getSign_rom2
              b=a     s             ; preserve A.S in B.S
              a=c     s
              c=n
              ?a#c    s             ; correct result sign?
              gonc    50$           ; yes
              st=1    Flag_Overflow ; no, overflowed
              acex    s             ; A.S= desired sign
              abex    s             ; restore A.S, B.S= desired sign
              rxq     forceSign     ; force right sign
              acex                  ; X changed, write it out again
              regn=c  X
              goto    51$
50$:          abex    s             ; restore A.S
51$:          c=m                   ; get carry mask
              c=c-1
              c=-c-1                ; make unmask
              ?st=1   Flag_UpperHalf
              goc     60$
              c=c&a
              ?c#0
              gonc    55$           ; no bits outside
54$:          st=1    Flag_Overflow
55$:          rgo     putXDrop_rom2
60$:          abex    x
              c=c&a
              abex    x
              ?c#0    x
              gonc    55$
              goto    54$

70$:          acex                  ; A= lower 56 bits of result
                                    ; C[3:0]= uppermost 16 bits of result
              rcr     -3
              stk=c                 ; push uppermost 16 bits

              c=regn  Q             ; get carry mask
              cmex                  ; M= carry mask
              n=c                   ; N= second 56 bits
              bcex    x             ; B.X= upper part of lower half

              acex                  ; C= lower 56 bits of result
              regn=c  Q             ; Q= lower 56 bits of result (unmasked)
              acex                  ; A= lower 56 bits of result (to be masked)
              rxq     maskABx_rom2
              acex
              regn=c  Y             ; goes to Y

              ;; also save upper part (8 bits) to trailer register
              c=b
              pt=     0
              g=c                   ; G= upper 8 bits of Y
              rcr     10
              a=c     x             ; A.X= buffer header address
              c=c+1   x
              dadd=c                ; select trailer register
              c=data
              pt=     4             ; point to Y register byte
              c=g                   ; insert it
              data=c                ; write back

              ldi     111
              acex    x
              dadd=c                ; select buffer header
              c=data                ; read buffer header
              rcr     2
              c=0     xs            ; C.X= word size
              c=a-c   x             ; C[1:0]= 111 - word size
                                    ;   which is counter for shift loop to
                                    ;   align upper part properly
              pt=     0
              g=c                   ; G= counter

;;; Set up for shifting B.X : A : C : N
;;; where N= lower 56 bits
;;;       C= second 56 bits
;;;       A[3:0]= upper 16 bits
;;;       and the rest is 0 initially
;;;
;;; Shift '112 - wordSize' steps to left and the upper half will
;;; end up in B.X : A

              b=0     x
              c=0
              dadd=c                ; select chip 0
              c=stk
              rcr     3
              a=c
              c=regn  Q             ; get lower 56 bits
              cnex

71$:          bcex                  ; shift loop
              c=c+c   x
              acex
              c=c+c
              gonc    72$
              a=a+1   x
72$:          acex
              bcex
              c=c+c
              gonc    73$
              a=a+1
73$:          acex
              cnex
              c=c+c
              gonc    74$
              a=a+1
74$:          cnex
              acex

              pt=     0
              cgex
              pt=     1
              c=c-1   wpt
              goc     80$
              pt=     0
              cgex
              goto    71$

80$:          switchBank 1
              rxq     maskAndSave10
              rxq     setXFlags
              c=regn  Y             ; set correct Z flag
              ?c#0
              goc     82$
              c=b
              rcr     10
              c=c+1   x
              dadd=c
              c=data
              rcr     4
              c=0     xs
              ?c#0     x
              gonc    85$
82$:          st=0    Flag_Zero
85$:          rgo     exitUserST

              .section Code, reorder
;;; ----------------------------------------------------------------------
;;;
;;; DIV, RMD, DDIV, DRMD - single and double divide routine
;;;
;;; ----------------------------------------------------------------------

              .name   "DRMD"
DRMD:         lc      8 + 4
              goto    divCommon

              .name   "DDIV"
DDIV:         lc      8
              goto    divCommon

              .name   "RMD"
RMD:          lc      4
              goto    divCommon

              .name   "DIV"
DIV:          lc      0
divCommon:    rcr     2
              bcex    s             ; B.S= variant

              s0=1                  ; check for division by 0
              rxq     findIntegerBufferGetXSaveL0
              switchBank 2

;;; We always want the low part of dividend to be in Y.
;;; For double operations that means we need to swap Y with Z.
              c=b     s             ; C.S= variant
              s11=0                 ; S11 is borrowed as RMD flag
              s6=0                  ; S6 is borrowed to notify if we are doing
                                    ;  a double divide, meaning we will need the
                                    ;  Z register as input as well

              c=c+c   s             ; double operation?
              gonc    4$            ; no
              s6=1                  ; yes
4$:           c=c+c   s             ; doing remainder?
              gonc    5$            ; no
              s11=1                 ; yes
5$:           rxq     getSignsMakePositiveZ
              ?s11=1                ; doing remainder?
              goc     7$            ; yes
              a=a-c   s             ; divide, final result is negative if
                                    ;  the signs are different
                                    ; (for remainder we take the sign of the
                                    ; dividend, which already is in A.S)
7$:

;;; Basic algorithm:
;;; 0. r = 0
;;;    loop = WSIZE * 2 + 1
;;;    goto 3
;;; 1. RLC r
;;; 2. Try (r - op2), if no carry; save difference to r and set cy=1
;;;                   otherwise; keep previous r, set cy=0
;;; 3. RLC op1 (rotating in a result bit)
;;; 4. Decrement loop and go back to 1
;;;
;;; At the end, double result will be in op1 and single remainder is in r.
;;;
;;; r - N[2:0]-Q
;;; hi(op1) - N[8:6]-Z (only when doing double)
;;; lo(op1) - N[5:3]-Y
;;; op2 - N[11:9]-X
;;; sign is kept in N[13]

              c=n
              rcr     4
              a=c     x
              a=0     xs            ; A[2:0]= Y (low half)
              ?s6=1                 ; double operation?
              gonc    8$            ; no
              rcr     2             ; C[2:0]= Z (high half)
              c=0     xs
              rcr     3             ; C[13:11]= Z (high half)
              goto    9$
8$:           c=0
9$:           c=b     x             ; C[2:0]= X (upper part)
              rcr     -6
              acex    x             ; upper part of Y
              rcr     -3
              acex    s             ; get sign
              c=0     x             ; clear upper part of remainder
              n=c

              c=b
              rcr     10
              dadd=c
              c=data                ; load buffer header
              rcr     2
              c=0     xs            ; C[2:0]= WSIZE
              ?s6=1                 ; double operation?
              gonc    10$           ; no
              c=c+c   x             ; yes, double loop counter
10$:          pt=     0             ; C[2:0]= loop counter
              g=c                   ; G= loop counter

              b=0     x
              c=0                   ; select chip 0
              dadd=c
              regn=c  Q             ; low(r)= 0
              goto    40$

              ;; Main loop
20$:          g=c

              ;; RLC r
              c=n
              c=c+c   x             ; shift upper part
              n=c
              c=regn  Q
              c=c+c
              gonc    21$
              cnex
              c=c+1   x
              cnex
21$:          c=a+c   x             ; shift in carry
              regn=c  Q
              acex                  ; A= lower part of r

              ;; Try (r - op2)
              b=0     x
              c=regn  X
              a=a-c
              gonc    25$
              abex                  ; B= lower part of r (updated)
              a=a+1   x             ; borrowed
              goto    26$

200$:         goto    20$           ; relay

25$:          abex
26$:          c=n                   ; C[2:0]= upper part of r
              a=0     s             ; outgoing carry
              acex    x
              a=a-c   x             ; handle borrow
              goc     30$
              rcr     9             ; C[2:0]= upper part of op2
              a=a-c   x
              goc     30$           ; subtract not successful, use old r, cy=0
              rcr     -9            ; subtract successful, use new r
              acex    x
              n=c
              c=b
              regn=c  Q
              a=a+1   s             ; set outgoing carry

30$:          acex    s             ; C.S= outgoing carry
              c=0     x
              rcr     -1
              bcex    x             ; B.X= outgoing carry
              abex    m             ; restore B.M

40$:          ;; RLC op1
              c=n
              ?s6=1                 ; double operation?
              gonc    50$           ; no

              rcr     6             ; yes
              c=c+c   x             ; hi(op1) << 1
              n=c
              c=regn  Z
              c=c+c
              gonc    41$
              cnex
              c=c+1   x
              cnex
41$:          regn=c  Z
              c=n
              rcr     -3
              c=c+c   x             ; lo(op1) << 1
              n=c
              c=regn  Y
              c=c+c
              gonc    43$
              cnex
              c=c+1   x
              cnex
43$:          regn=c  Y

              ;; Handle carry between op1 lo -> hi parts
              ?st=1   Flag_UpperHalf
              goc     45$           ; upper part
44$:          a=c
              c=m
              ?c#0                  ; word size == 56 ?
              goc     42$           ; no, word size < 56
              c=n
              cstex
              ?s0=1
              goc     48$
              cstex
              goto    46$
48$:          cstex
              goto    49$

2000$:        goto    200$

42$:          c=c&a
              ?c#0
              gonc    46$           ; no carry
49$:          c=regn  Z             ; carry to hi(op1)
              c=c+1
              regn=c  Z
              goto    46$

45$:          c=n                   ; inspect upper part
              goto    44$

55$:          c=n                   ; make C[2:0] the high part word
                                    ;  to test outgoing carry from
              ?s6=1                 ; double operation?
              gonc    52$           ; no
              rcr     3             ; yes
              goto    52$

50$:          ;; RLC op1 single precision
              rcr     3             ; align upper part
              c=c+c   x
              n=c
              c=regn  Y
              c=c+c
              gonc    47$
              cnex
              c=c+1   x
              cnex
              goto    47$
46$:          c=regn  Y             ; shift in result bit
47$:          abex    x
              c=a+c   x
              regn=c  Y

              c=m
              a=c
              ?st=1   Flag_UpperHalf
              goc     55$
              c=regn  Y
              ?s6=1                 ; double operation?
              gonc    51$           ; no
              c=regn  Z             ; yes
51$:          ?a#0                  ; word size == 56 ?
              goc     52$           ; no
              a=a+1                 ; make bit mask = 1
              goto    55$

52$:          c=c&a
              a=0                   ; assume outgoing carry = 0
              ?c#0
              gonc    58$
54$:          a=a+1                 ; set outgoing carry

58$:          c=n                   ; normalize alignment of N
              rcr     -3
              n=c

              c=g
              c=0     xs
              c=c-1   x             ; decrement loop counter
              gonc    2000$

;;; Done with shift loop
              c=n
              bcex    s             ; B.S= final sign

              ?s11=1                ; remainder?
              goc     69$           ; yes

              st=0    Flag_CY       ; no, set carry set on remainder /= 0
              ?c#0    x
              goc     61$
              c=regn  Q
              ?c#0
              gonc    62$
61$:          st=1    Flag_CY

62$:          c=n
              st=0    Flag_Overflow

              rcr     3             ; load low part of quotient
              bcex    x             ; B[2:0]= upper part of low half
              c=regn  Y

              ?s6=1                 ; double operation?
              goc     70$           ; yes

63$:          a=c
              ?st=1   Flag_2        ; signed mode?
              gonc    67$           ; no
              ?s11=1                ; doing remainder?
              goc     64$           ; yes, do not check overflow
              rxq     getSign_rom2  ; C.S= result sign
              ?c#0    s             ; sign bit set?
              gonc    64$           ; no
              st=1    Flag_Overflow ; yes, overflowed
64$:          ?b#0    s             ; negative result?
              gonc    65$
              c=b                   ; yes, negate result
              c=-c    x
              acex
              c=-c
              gonc    68$
              a=a-1   x
68$:          b=a
              a=c
65$:          ?st=1   Flag_Overflow
              gonc    67$
              rxq     forceSign

67$:          s11=1                 ; we have borrowed the push flag,
                                    ;   it should be set so lets fix that
              acex
              regn=c  X
              rgo     putXDrop_rom2

69$:          bcex    x             ;  handle remainder
              c=regn  Q
              goto    63$

;;; Result after DDIV
;;;  N[8:6]-Z= upper half, bits need no masking
;;;  N[5:3]-Y= lower half, these bits need masking
;;;
;;;  S11 is known to be 0 and should end being set, we borrow
;;;     it to implement negation (when needed)
70$:          a=c                   ; A= lower part of low half
              rxq     maskABx_rom2

              ?st=1   Flag_2        ; signed mode?
              goc     71$           ; yes
              b=0     s             ; clear result sign
              goto    75$
71$:          ?b#0    s             ; negative result?
              gonc    75$           ; no
              c=b     x             ; negate lower half
              c=-c-1  x
              acex
              c=-c
              goc     73$
              a=a+1   x
              gonc    73$
              s11=1                 ; need to negate upper part
73$:          b=a     x
              a=c
              rxq     maskABx_rom2  ; mask again

75$:          s7=1                  ; assume zero
              ?b#0    x
              goc     76$
              ?a#0
              gonc    77$
76$:          s7=0                  ; non-zero
77$:          c=regn  Z             ; load upper half
              acex
              regn=c  Z             ; lower half to Z (will be dropped to Y)
              c=n
              rcr     6
              bcex    x             ; B[2:0]= upper part, upper half
              n=c                   ; N[2:0]= upper part, lower half

              ?b#0    s             ; negate result?
              gonc    80$           ; no
              c=b     x             ; yes, propagate negation to upper half
              c=-c-1  x
              acex
              c=-c-1
              ?s11=1
              gonc    79$
              c=c+1
              gonc    79$
              a=a+1   x
79$:          b=a     x
              a=c
80$:          ?a#0
              goc     81$
              ?b#0    x
              gonc    82$
81$:          s7=0                  ; non-zero

;;; Drop the stack and save upper part of X.
82$:          s11=1
              switchBank 1
              rxq     maskAndSave10 ; save X
              s9=0
              rxq     dropZN10
              rxq     setSignFlag
              rgo     exitUserST

;;; ----------------------------------------------------------------------
;;;
;;; getSign - get the sign of given number
;;;
;;; IN: A - low part
;;;     B.X - high part
;;;     ST.Flag_UpperHalf - properly set
;;;     M - mask
;;;
;;; OUT: C.S= 1 - negative
;;;           0 - positive
;;;      A, B.X, M, ST.Flag_UpperHalf preserved
;;;
;;; USES: C
;;;
;;; Note: This routine is duplicated in bank 1 and 2, as it is used
;;;       within both banks.
;;;       (The one in bank 1 is defined together with decDigits.)
;;;
;;; ----------------------------------------------------------------------

getSign:      .macro
              ?st=1   Flag_UpperHalf
              goc     50$
              acex                  ; sign in lower part
              cmex
              acex
              c=m
              c=c+c
              goc     19$           ; maybe negative
8$:           c=c&a
              ?c#0
              goc     20$           ; negative
10$:          c=0     s             ; positive, C.S= 0
15$:          acex                  ; C= carry mask
              cmex                  ; M= carry mask (restored)
              acex                  ; A= low part
              rtn
19$:          ?a#0                  ; word size 56?
              goc     8$            ; no
20$:          c=0     s             ; negative, C.S= 1
              c=c+1   s
              goto    15$

50$:          c=b                   ; get upper part
              c=c+c                 ; sign to carry position
              acex                  ; A[2:0]= upper part << 1
              cmex                  ; C=mask, M= lower part
              acex                  ; A= mask
              goto    8$
              .endm

              .section Code2, reorder
getSign_rom2: getSign

;;; ----------------------------------------------------------------------
;;;
;;; forceSign - force the value to a particular sign
;;;
;;; IN: A - low part
;;;     B.X - high part
;;;     ST.Flag_UpperHalf - properly set
;;;     M - mask
;;;     B.S - desired sign
;;;
;;; OUT: A, B.X - updated value
;;;      M, ST.Flag_UpperHalf preserved
;;;
;;; USES: C
;;;
;;; ----------------------------------------------------------------------

              .section Code2, reorder
forceSign:    c=m                   ; get carry mask
              ?c#0                  ; 56 bit value?
              gonc    56$           ; yes
              ?c#0    s             ; carry in highest nibble?
              goc     40$           ; yes
              c=c+c                 ; no, ((C << 3) >> 4)
              c=c+c
              c=c+c
              csr
2$:           ?b#0    s             ; reset sign?
              goc     20$           ; no
              c=-c-1                ; make unmask
              ?st=1   Flag_UpperHalf
              goc     5$
              c=c&a                 ; reset sign in lower part
3$:           a=c
              rtn
5$:           abex    x             ; reset sign in upper part
              c=c&a
7$:           acex    x
              abex    x
              rtn

20$:          ?st=1   Flag_UpperHalf
              goc     25$
              c=c|a                 ; set sign in lower part
              goto    3$
25$:          abex    x             ; set sign in upper part
              c=c|a
              goto    7$

40$:          rcr     1
              c=c+c
              c=c+c
              c=c+c
              goto    2$

56$:          pt=     13
              lc      8
              goto    2$

              .section KeyTable, rodata
              .align  4
;;; **********************************************************************
;;;
;;; Keyboard definition
;;;
;;; **********************************************************************

keyTable:
              ;; Logical column 0
              .con    0x10a         ; SIGMA+  (A digit)
              .con    0x10f         ; X<>Y    (F digit here)
              .con    BuiltinKeyKeepDigitEntry(0x0e) ; SHIFT
              KeyEntry ENTERI       ; ENTER^
              KeyEntry SUB          ; -
              KeyEntry ADD          ; +
              KeyEntry MUL          ; *
              KeyEntry DIV          ; /

              ;; Logical column 0, shifted
              KeyEntry SL           ; SIGMA+
              KeyEntry SWAPI        ; X<>Y
              .con    BuiltinKeyKeepDigitEntry(0x0e) ; SHIFT
              .con    0             ; CATALOG
              KeyEntry CMP          ; -
              KeyEntry TST          ; +
              KeyEntry DMUL         ; *
              KeyEntry DDIV         ; /

              ;; Logical column 1
              .con    0x10b         ; 1/X  (B digit)
              KeyEntry Hex          ; RDN
              .con    0             ; XEQ
              .con    0             ; right half of enter key
              .con    0x107         ; 7
              .con    0x104         ; 4
              .con    0x101         ; 1
              .con    0x100         ; 0

              ;; Logical column 1, shifted
              KeyEntry SR           ; 1/X
              KeyEntry RDNI         ; RDN
              .con    0             ; ASN
              .con    0             ; right half of enter key
              .con    BuiltinKey(0xa8) ; SF
              KeyEntry SB           ; 4
              KeyEntry AND          ; 1  (FIX key)
              KeyEntry WSIZE?       ; 0

              ;; Logical column 2
              .con    0x10c         ; SQRT  (C digit)
              KeyEntry Decimal      ; SIN
              KeyEntry STI          ; STO
              KeyEntry NEG          ; CHS
              .con    0x108         ; 8
              .con    0x105         ; 5
              .con    0x102         ; 2
              KeyEntry WINDOW       ; decimal point

              ;; Logical column 2, shifted
              KeyEntry ASR          ; SQRT
              KeyEntry RMD          ; SIN
              .con    BuiltinKey(0xcf) ; LBL
              KeyEntry NOT          ; CHS
              .con    BuiltinKey(0xa9) ; CF
              KeyEntry CB           ; 5
              KeyEntry OR           ; 2
              KeyEntry LASTXI       ; decimal point (LastX)

              ;; Logical column 3
              .con    0x10d         ; LOG   (D digit)
              KeyEntry Octal        ; COS
              KeyEntry LDI          ; RCL
              KeyEntry SEX          ; EEX
              .con    0x109         ; 9
              .con    0x106         ; 6
              .con    0x103         ; 3
              .con    0             ; R/S

              ;; Logical column 3, shifted
              KeyEntry RL           ; LOG
              KeyEntry RLC          ; COS
              .con    0             ; GTO
              .con    0             ; RTN
              .con    BuiltinKey(0xac) ; FS?
              KeyEntry B?           ; 6
              KeyEntry XOR          ; 3
              KeyEntry WSIZE        ; R/S

              ;; Logical column 4
              .con    0x10e         ; LN   (E digit)
              KeyEntry Binary       ; TAN
              .con    0             ; SST
              .con    0x1ff         ; BACKARROW
              .con    BuiltinKey(0x0c) ; MODE ALPHA
              .con    BuiltinKey(0x0c) ; MODE PRGM
              .con    BuiltinKeyKeepDigitEntry(0x0c) ; MODE USER
              .con    0             ; OFF key special

              ;; Logical column 4, shifted
              KeyEntry RR           ; LN
              KeyEntry RRC          ; TAN
              .con    0             ; BST
              KeyEntry CLXI         ; BACKARROW
              KeyEntry MASKR        ; MODE ALPHA
              KeyEntry MASKL        ; MODE PRGM
              KeyEntry EXITAPP      ; MODE USER
              .con    0             ; OFF key special

;;; ----------------------------------------------------------------------
;;;
;;; mul10 - multiply by 10
;;; shift1 - shift number one step left
;;;
;;; IN: B.X - upper part
;;;     A - lower part
;;;
;;; USES: N  (mul10)
;;;
;;; ----------------------------------------------------------------------

              .section Code, reorder
              ;; Align shift1 to allow GSB256 to be used
              ;; This is done to save one subroutine level as
              ;; RXQ uses +1 and when coming from Div10, we
              ;; do not have that to spare.
              ;; It also makes it run a bit faster as an
              ;; extra bonus.
              .align  256
shift1:       bcex                  ; shift one left
              c=c+c   x
              acex
              c=c+c
              gonc    2$
              a=a+1   x
2$:           acex
              bcex
              rtn

mul10:        gosub   GSB256        ; shift1   X * 2
              acex
              n=c                   ; save temp in N
              acex
              c=b                   ; save upper temp in B[5:3]
              rcr     3
              bcex    x
              rcr     -3
              bcex
              gosub   GSB256        ; shift1   X * 4
              gosub   GSB256        ; shift1   X * 8
              c=n
              a=a+c                 ; add (X * 2) and (X * 8)
              gonc    1$
              bcex    x
              c=c+1   x
              bcex    x
1$:           abex    x
              c=b
              rcr     3
              a=a+c   x
              abex    x
              rtn

;;; ----------------------------------------------------------------------
;;;
;;; div10 - divide by 10 using shifts.
;;;
;;; Algorithm (from Hacker's Delight):
;;; http://www.hackersdelight.org/divcMore.pdf
;;;
;;; unsigned divu10(unsigned n) {
;;;   unsigned q, r;
;;;   q = (n >> 1) + (n >> 2);
;;;   q = q + (q >> 4);
;;;   q = q + (q >> 8);
;;;   q = q + (q >> 16);
;;;   q = q + (q >> 32);
;;;   q = q >> 3;
;;;   r = n - q*10;
;;;   return q + ((r + 6) >> 4);
;;; }
;;;
;;; ----------------------------------------------------------------------

div10:        acex                  ; save n in P[9:8]:Q
              regn=c  Q
              acex
              c=regn  P
              rcr     8
              c=b     x
              rcr     -8
              regn=c  P

              gosub   GSB256        ; shift1
              gosub   GSB256        ; shift1
              acex
              n=c                   ; C.X : N = n << 2
              acex
              c=b     x
              rcr     -3
              stk=c
              gosub   GSB256        ; shift1
                                    ; B.X : A = n << 3
              c=stk
              rcr     3
              bcex    x
              rcr     1
              c=0     xs
              bcex    x
              asr
              a=c     s             ; B.X : A = n >> 1

              rcr     1             ; C.X= upper part of (n >> 2)
              abex    x             ; A.X = upper part of (n >> 1)
              a=a+c   x
              abex    x             ; B.X= upper parts ((n >> 1) + (n >> 2))

              bcex    s             ; B.S= nibble that goes between
              c=n
              csr
              c=b     s             ; C= low part of (n >> 2)

              a=a+c                 ; B.X - A = (n >> 1) + (n >> 2)
              gonc    5$
              bcex    x
              c=c+1   x
              bcex    x

5$:           c=b     x             ; q = q + (q >> 4);
              rcr     1
              c=0     xs
              abex    x
              a=a+c   x             ; add upper parts
              abex    x

              bcex    s
              c=a
              csr
              bcex    s
              a=a+c                 ; add lower parts
              gonc    10$
              bcex    x
              c=c+1   x             ; carry to upper part
              bcex    x

10$:          c=a                   ; q = q + (q >> 8);
              pt=     1
              c=b     wpt
              rcr     2
              a=a+c
              gonc    15$
              bcex    x
              c=c+1   x
              bcex    x

15$:          c=a                   ; q = q + (q >> 16);
              c=b     wpt
              rcr     2
              csr
              csr
              a=a+c
              gonc    20$
              bcex    x
              c=c+1   x
              bcex    x

20$:          c=a                   ; q = q + (q >> 32);
              c=b     wpt
              rcr     2
              pt=     5
              c=0     wpt
              rcr     6
              a=a+c
              gonc    22$
              bcex    x
              c=c+1   x
              bcex    x

22$:          gosub   GSB256        ; (shift1)   q = q >> 3;
              bcex    x
              rcr     1
              c=0     xs
              pt=     0
              g=c                   ; G= upper(q)
              bcex    x
              asr
              a=c     s

              acex                  ; save q in G:M
              m=c                   ;  (upper part was one just above)
              acex

              rxq     mul10         ; q * 10
              c=regn  P
              rcr     8
              abex    x
              acex    x
              a=a-c   x             ; r = n - q*10 (upper part)
              abex    x
              c=regn  Q
              acex
              a=a-c                 ; r = n - q*10 (lower part)
              gonc    25$
              bcex    x             ; borrow
              c=c-1   x
              bcex    x

25$:          c=0                   ; r + 6
              ldi     6
              a=a+c
              gonc    30$
              bcex    x
              c=c+1   x
              bcex    x

30$:          bcex    x             ; ((r + 6) >> 4)
              rcr     1
              c=0     xs
              bcex    x
              asr
              a=c     s

              c=g                   ; q + ((r + 6) >> 4)
              abex    x
              a=a+c   x
              abex    x
              c=m
              a=a+c
              rtn nc
              bcex    x
              c=c+1   x
              bcex    x
              rtn

;;; ----------------------------------------------------------------------
;;;
;;; decDigits - extract decimal digits for display
;;; decDigits - alternative entry that does not check program mode.
;;;
;;; IN: B.X - upper part of number
;;;     A - lower part of number
;;;     ST - internal flags up
;;;          Note: Calls from ALDI cheats here, just enough setup
;;;                is done there to make it work.
;;;          Note: We know we are in decimal mode and borrow base flags
;;;                for internal use here.
;;;     G - Window set up
;;;          Note: ALDI does not set it up, sets S1 to notify that we
;;;                are doing ALDI (digit go to alpha instead of LCD)
;;;
;;; Note: When showing on behalf of a program step, no word size is
;;;       available, so we cannot interpret it as negative as we have
;;;       no idea where the sign bit will be when running.
;;;
;;; ----------------------------------------------------------------------

              .section Code, reorder
              .align  256
getSign:      getSign
decDigits:    ?st=1   Flag_PRGM     ; program mode?
              goc     decpos        ; yes, interpret as positive number
decDigits1:   c=regn  14
              rcr     12
              cstex
              ?st=1   Flag_2        ; signed mode?
              gonc    6$
              cstex

              gosub   GSB256        ; getSign
              ?c#0    s
              gonc    decpos        ; positive
              ?st=1   Flag_UpperHalf
              goc     5$            ; negate with sign in low part
              c=m                   ; get carry pos
              c=c-1                 ; make mask
              acex                  ; A=mask, C= low part
              c=-c                  ; C= negated low part
              nop
              c=c&a                 ; mask
              acex
4$:           s0=0                  ; remember negative
              goto    decpos

5$:           c=b
              c=-c    x             ; negate upper part
              acex
              c=-c                  ; negate lower part
              gonc    3$
              a=a-1   x             ; ripple to upper part
3$:           bcex                  ; B= lower part
              c=m
              c=c-1                 ; make mask
                                    ;  (no carry possible as mask is non-zero)
              .suppress
              c=c&a
              a=c     x
              abex
              goto    4$

6$:           cstex                 ; restore flags
decpos:       b=0     xs            ; clear flag for digits above
              pt=     2             ; inspect window
              c=g
              acex
              setdec
              ?s1=1                 ; from ALDI?
              goc     500$          ; yes
              ?a#0    xs            ; window set?
              goc     500$          ; yes

;;; No window set, as we only need the lowest part of the result we can keep working in
;;; a single output register.
              pt=     0             ; assume we only do lower part (14 digits)
              ?b#0    x             ; zero upper digits?
              gonc    8$            ; yes
              m=c                   ; no, M= lower digits
              c=b     x             ; get upper digits
              rcr     2
              pt=     2
              s2=0                  ; clear overflow flag
              s3=     0             ; remember we are doing upper part

8$:           ?c#0                  ; everything zero?
              gonc    12$           ; yes

1$:           ?c#0    s             ; left align
              goc     9$
              rcr     -1
              dec pt
              goto    1$

9$:           n=c
              c=0
10$:          c=c+c                 ; Sum * 16
              gonc    31$
              s2=1
31$:          c=c+c
              gonc    32$
              s2=1
32$:          c=c+c
              gonc    33$
              s2=1
33$:          c=c+c
              gonc    34$
              s2=1
34$:          a=c
              c=n
              rcr     -1
              cnex
              c=0     x
              c=0     m
              rcr     -1
              c=c+1                 ; BCD convert
              c=c-1
              c=a+c
              gonc    11$
              s2=1                  ; set flag that we dropped bits
11$:          dec pt
              ?pt=    0
              gonc    10$

              ?s3=1                 ; done with lower digits?
              goc     12$           ; yes
              s3=1                  ; no, do lower digits
              cmex
              n=c                   ; N= lower digits
              c=m
              goto    10$

500$:         goto    50$           ; relay

12$:          sethex
              a=c                   ; result digits in A
              pt=     7
              c=0     wpt           ; clear digits area
              ?c#0                  ; something set outside?
              gonc    14$           ; no
              s2=1                  ; set flag for digits above

14$:          gosub   CLLCDE

              c=0     xs            ; move overflow flag to B.XS
              ?s2=1
              gonc    13$
              c=c+1   xs
13$:          bcex    xs
              ?st=1   IF_DigitEntry
              gonc    150$
              ldi     0x1f          ; show underscore if in digit entry
              srsabc

              ?s13=1                ; key already released?
              goc     150$          ; yes
              rst kb
              chk kb
              goc     150$          ; key still down
              s13=1                 ; say key went up
              goto    150$

;;; Window set, we have to use 2 registers here which makes a bit slower,
;;; but the good news is that this is only used when asking for another
;;; window explicitly, not when doing digit entry.
50$:          bcex                  ; B= lower part of binary number
                                    ; C[1:0] = upper part of binary number
              rcr     2
              pt=     2
              s3=0                  ; remember we are doing upper part
              n=c

              c=0                   ; initial Sum = 0
              m=c

510$:         acex    x             ; set up for looping 4 times
              ldi     3
              acex    x

520$:         c=c+c                 ; Sum * 2 upper part
              cmex
              c=c+c                 ; Sum * 2 lower part
              gonc    522$
              cmex
              c=c+1
              goto    524$

120$:         goto    12$           ; relay

522$:         cmex
524$:         a=a-1   x
              gonc    520$

              cmex
              a=c                   ; A= Sum lower part

              c=n                   ; get next digit
              rcr     -1
              cnex
              c=0     x
              c=0     m
              rcr     -1
              c=c+1                 ; BCD convert digit
              c=c-1
              c=a+c                 ; add to sum
              gonc    526$
              cmex                  ; carry
              c=c+1
              goto    528$
526$:         cmex
528$:         dec pt
              ?pt=    0
              gonc    510$

              acex
              ?s3=1                 ; done with lower digits?
              goc     540$          ; yes
              s3=1                  ; no, do lower digits
              c=b
              n=c
              acex
              goto    510$

150$:         goto    15$           ; relay

540$:         ?s1=1                 ; doing ALDI (alpha append)
              goc     80$           ; yes

              c=g                   ; get window
              c=c-1
              pt=     7
              rcr     1
              bcex    s             ; B.S= window counter
              c=m                   ; get low part
542$:         c=0     wpt
              acex    wpt
              rcr     8
              bcex    s
              c=c-1   s
              goc     544$
              bcex    s
              goto    542$

544$:         bcex    s             ; restore C
              b=0     x             ; clear upper part (we trashed it as we
                                    ;  borrowed entire B for lower part of
                                    ;  binary number), we will set B.XS if we
                                    ;  have digits outside below by exiting
                                    ;  to 12$ (120$ relay to it)
              goto    120$          ; no

15$:          pt=     0
              lc      7             ; show 8 (7+1) digits
              rcr     1
              pt=     0
20$:          ldi     0x30
              c=a+c   pt
              srsabc
              asr
              ?b#0    x             ; digit above?
              goc     22$           ; yes
              ?a#0                  ; no, are we out of digits now?
              gonc    25$           ; yes
22$:          c=c-1   s
              gonc    20$

25$:          ?s0=1                 ; positive?
              goc     27$           ; yes
              ldi     '-'           ; no, negative
              srsabc
              s0=1                  ; restore flag

26$:          ?b#0    x             ; digits above?
              rtn nc                ; no
              c=g                   ; yes, set flag in G
              cstex
              s7=1
              cstex
              g=c
              rtn
27$:          frsabc                ; space for positive
              goto    26$

;;; Appending digits to alpha register
;;; M= lower part
;;; A= upper part
80$:          sethex
              acex                  ; save A in N
              n=c
              ?s0=1                 ; positive?
              goc     82$           ; yes
              ldi     '-'
              pt=     0
              g=c
              gosub   APNDNW
82$:          ldi     28-1
              bcex    x             ; B= digit counter
              c=n
              a=c                   ; A= upper part
              c=m                   ; C= lower part
              ?c#0                  ; check for zero
              goc     84$
              ?a#0
              gonc    90$           ; zero
84$:          ?a#0    s
              goc     85$
              a=c     s
              acex
              rcr     -1
              asl
              acex
              bcex    x
              c=c-1   x
              bcex    x
              goto    84$
85$:          m=c                   ; M= lower part
              pt=     13
              lc      14-1          ; digit counter for first register
              bcex    s             ; B.S= 13 (digit counter first register)
                                    ; B.X= overall digit counter

86$:          acex    s             ; C.S= next digit value
              ldi     3
              rcr     -1
              pt=     0
              g=c
              asl
              acex                  ; save A in N
              cnex
              gosub   APNDNW
              cnex
              acex
              c=b
              c=c-1   x
              rtn c                 ; done
              c=c-1   s
              goc     87$           ; out of digits in first register
              bcex                  ; restore B
              goto    86$
87$:          bcex                  ; restore B
              c=m                   ; get lower part
              a=c
              goto    86$

90$:          ldi     '0'
              g=c
              golong  APNDNW

;;; ************************************************************
;;;
;;; Generic two argument compare functions.
;;;
;;; ************************************************************

              .section Code2
              .name   "=I"
EQ:           nop
              nop
              gosub   dualArgument
              .con    "?"
              rxq     loadDualArguments
              abex    x
              ?a#c    x
              goc     toSKP
              abex    x
              c=n
              ?a#c
              goc     toSKP
toNOSKP:      enrom1                ; followed by golong NOSKP in bank1
              nop                   ; filler (to align with golong in bank 1)
toSKP:        enrom1                ; followed by golong SKP in bank1

              .name "≠I"
NE:           nop
              nop
              gosub   dualArgument
              .con    "?"
              rxq     loadDualArguments
              abex    x
              ?a#c    x
              goc     toNOSKP
              abex    x
              c=n
              ?a#c
              goc     toNOSKP
              goto    toSKP

              .name   "<I"
LT:           nop
              nop
              gosub   dualArgument
              .con    "?"
              rxq     loadDualArgumentsRelational
toNOSKP_0:    goto    toNOSKP       ; less than (signed-wise)
toSKP_0:      goto    toSKP         ; greater than  (signed-wise)
              abex    x             ; compare
              acex    x
              ?a<c    x
              goc     toNOSKP
              ?a#c    x
              goc     toSKP
              acex    x
              abex    x
              c=n
              acex
              ?a<c
              goc     toNOSKP
              goto    toSKP

              .name   "<=I"
LE:           nop
              nop
              gosub   dualArgument
              .con    "?"
              rxq     loadDualArgumentsRelational
              goto    toNOSKP       ; less than (signed-wise)
              goto    toSKP         ; greater than (signed-wise)
              abex    x             ; compare
              ?a<c    x
              goc     toSKP_0
              ?a#c    x
              goc     toNOSKP_0
              abex    x
              c=n
              ?a<c
              goc     toSKP_0
              goto    toNOSKP_0

              .section Code1
              .shadow toNOSKP + 1
              golong  NOSKP

              .section Code1
              .shadow toSKP + 1
              golong  SKP

swapDuals:    .macro
              bcex    x
              acex
              cnex
              acex
              .endm

;;; * Out: C.X - upper part of first argument
;;; *      N   - lower part of first argument
;;; *      B.X - upper part of second argument
;;;        A   - lower part of second argument

              .section Code2, reorder
loadDualArgumentsRelational:
              c=0     s
              c=c+1   s
              bcex    s
              goto    loadDualArguments10
loadDualArguments:
              b=0     s             ; equal / not-equals style
loadDualArguments10:
              acex
              pt=     2
              g=c
              regn=c  9
              rxq     findIntegerBufferUserFlags_rom2
              rxq     loadG
              c=regn  10
              bcex    x
              regn=c  10            ; REG10.X= upper part
              c=regn   9
              pt=     0
              g=c
              acex
              regn=c  9
              rxq     loadG
              c=regn  9
              n=c
              c=regn  10
              s7=0                  ; show YES/NO in run mode
              ?b#0    s             ; equal / not-equal?
              rtnnc                 ; yes
                                    ; no, relational compare (< or <=)
              ?st=1   Flag_2        ; signed mode?
30$:          golnc   RTNP3         ; no
              rcr     -3
              stk=c
              rxq     getSign_rom2
              bcex    s
              c=stk
              rcr     3
              swapDuals
              rcr     -3
              stk=c
              ?b#0    s
              goc     10$           ; operand 2 negative
              rxq     getSign_rom2  ; operand 2 positive
              bcex    s
              c=stk
              rcr     3
              ?b#0    s
              rtnc                  ; operand 1 negative, operand 2 positive
              swapDuals             ; both positive
              goto    30$
10$:          rxq     getSign_rom2
              bcex    s
              c=stk
              rcr     3
              ?b#0    s
              golnc   RTNP2         ; operand 1 positive, operand 2 negative
              goto    30$           ; compare with arguments swapped

;;; ************************************************************
;;;
;;; <>I - register exchange
;;;
;;; Note: This routing allocates scratch from free area as the
;;;       saveG routine destroys everything
;;;
;;; ************************************************************

              .section Code2
              .name   "<>I"
EXCHANGE:     nop
              nop
              gosub   dualArgument
              .con    0
              acex
              n=c                   ; N[3:0]= register arguments
              ldi     2
              gosub   allocScratch
              goto    100$          ; (P+1) out of memory
              bcex    x
              dadd=c
              c=n
              rcr     -3            ; C[6:3]= register arguments
              pt=     5
              g=c                   ; G= first argument
              data=c                ; Scratch0[6:3]= register arguments
              rxq     findIntegerBufferUserFlags_rom2
              rxq     200$
              pt=     3
              g=c                   ; G= second argument
              rcr     -3            ; C.X= address of Scratch1
              dadd=c                ; select Scratch1
              c=n                   ; C= lower bits
              data=c                ; Scratch1= lower bits
              rxq     200$
              rcr     -3
              dadd=c                ; select Scratch1
              bsr     wpt
              bsr     wpt
              bsr     wpt           ; B.X= upper part
              c=data
              a=c                   ; A= lower part
              c=n
              data=c
              rxq     saveG
              rxq     findIntegerBufferUserFlags_rom2
                                    ; set up M register again
              gosub   scratchArea
              c=c+1   x             ; C.X= pointer to Scratch1
              bcex    x             ; B.X= pointer to Scratch1
              c=data
              pt=     5
              g=c
              bcex    x             ; B.X= upper part
              dadd=c
              c=data
              a=c
              rxq     saveG
              gosub   clearScratch  ; remove scratch to give back space, but
                                    ; also as we may have left zero in SCRATCH1,
                                    ; and having zero inside a buffer is
                                    ; considered unsafe (old card reader bug)
              rgo     exitNoUserST_rom2

100$:         golong  noRoom

200$:         rxq     loadG         ; load argument
              acex
              n=c                   ; N= lower bits
              c=b     x
              rcr     -3
              pt=     5
              bcex    wpt           ; B[5:3]= upper bits
              gosub   scratchArea
              c=c+1   x
              bcex    x             ; B.X= address of Scratch1
              c=data                ; C= Scratch0
              pt=     5
              rcr     -3            ; C[5:3]= upper bits argument
              bcex    wpt           ; B[5:3]= upper bits argument
                                    ; C[5:3]= upper bits other argument
              rcr     3
              data=c                ; Scratch0[6:3]= register arguments
              data=c                ; Scratch0[2:0]= upper bits argument 1
                                    ; C[13:11]= address of Scratch1
              rtn

;;; ************************************************************
;;;
;;; VIEWI - show register value
;;;
;;; ************************************************************

              .section Code2
              .name   "VIEWI"
VIEWI:        nop
              nop
              gosub   argument
              .con    Operand00     ; LDI 00 is default
              rxq     findIntegerBuffer_rom2
              rxq     loadG
              c=b
              rcr     10
              dadd=c
              c=data
              n=c                   ; N= buffer header
              pt=     8
              lc      0             ; reset window display
              data=c
              c=0
              dadd=c
              c=regn  14
              cstex
              s5=1                  ; set message flag, but not internal
                                    ;  display override flag (not calling
                                    ;  displayDone here, as we want backarrow
                                    ;  to clear the display
              cstex
              regn=c  14
              switchBank 1
              rgo     dis20

;;; ----------------------------------------------------------------------
;;;
;;; This NOP placed on address XCDD will allow the module to be used
;;; in page 7.
;;;
;;; 7CDD is the address that is called to see if there is an HPIL
;;; module in place.
;;;
;;; This is how Extended Function/HP41CX checks it, so it is assumed
;;; it is the way to do it. By putting a NOP there, the probe call will
;;; return and it will seem as the is no HP-IL module in place in the
;;; case we are compiled to page 7.
;;;
;;; ----------------------------------------------------------------------

              .section Legal7
              nop

;;; ----------------------------------------------------------------------
;;;
;;; Bank switchers allow external code to turn on specific banks.
;;;
;;; ----------------------------------------------------------------------

BankSwitchers: .macro
              rtn                   ; not using bank 3
              rtn
              rtn                   ; not using bank 4
              rtn
              enrom1
              rtn
              enrom2
              rtn
              .endm

              .section BankSwitchers1
             BankSwitchers

              .section BankSwitchers2
             BankSwitchers


;;; ----------------------------------------------------------------------
;;;
;;; Switch back to bank 1 and fall into deepWake
;;;
;;; ----------------------------------------------------------------------

              .section Code2
              .shadow deepWake - 1
deepWake2:    enrom1

              .section Tail2
;;; **********************************************************************
;;;
;;; Poll vectors, module identifier and checksum in page 2
;;;
;;; This is a banked ROM and poll vectors are not expected to be called.
;;;
;;; If the wrong bank is left active by accident, which may happen if we
;;; are placed next to another ROM that is not so careful, or we have a
;;; bug, we switch back to bank 1 for the very important IO poll.
;;;
;;; For all the rest we ignore it, as the power up sequence will reset
;;; to bank 1.
;;;
;;; **********************************************************************

              nop                   ; Pause
              nop                   ; Running
              nop                   ; Wake w/o key
              nop                   ; Powoff
              nop                   ; I/O
              goto    deepWake2     ; Deep wake-up
              nop                   ; Memory lost
              .con    1             ; A
              .con    '1'           ; 1
              .con    0x202         ; B (bank switched)
              .con    0x0c          ; L
              .con    0             ; checksum position

              .section Tail
;;; ----------------------------------------------------------------------
;;;
;;; Poll vector handling.
;;;
;;; We need to reclaim our buffer at power on and also the application
;;; shell.
;;;
;;; ----------------------------------------------------------------------

deepWake:     n=c
              c=0     x             ; we look for buffer # 0
              gosub   findBuffer
              goto    pollret       ; (P+1) not found
              c=data                ; (P+2) reclaim it
              cstex
              st=0    IF_DigitEntry ; clear digit entry
              cstex
              c=0     s
              c=c+1   s
              data=c
              ldi     .low12 ladybugShell
              gosub   reclaimShell

              gosub   LDSST0
pollret:      c=n
RMCK10_LJ:    golong  RMCK10

;;; **********************************************************************
;;;
;;; Poll vectors, module identifier and checksum
;;;
;;; **********************************************************************

              nop                   ; Pause
              nop                   ; Running
              nop                   ; Wake w/o key
              nop                   ; Powoff
              nop                   ; I/O
              goto    deepWake      ; Deep wake-up
              nop                   ; Memory lost
              .con    1             ; A
              .con    '1'           ; 1
              .con    0x202         ; B (bank switched)
              .con    0x20c         ; L (has secondaries)
              .con    0             ; checksum position
