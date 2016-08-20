#if 0
;;; **********************************************************************

              Programmer module for the HP-41 calculator series.

    This module provides an integer mode for the HP-41, much like what is
    available on the HP-16C.


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

    Operations (like add and shifts) uses a variant of 'FindBuffer' that
    sets up the user flags (such as sign mode, carry and zero flags).
    Examples of such routines are 'FindBufferUserFlags' and
    'FindBufferGetXSaveL'.
    These are similar to 'FindBuffer', but as said, they set up user flags
    instead of the internal flag set.
    This is the normal case.

    Exiting needs to be matched with the variant of FindBuffer used. The
    exit routines depend a lot on the flag set that is active.
    Typical use is 'PutX' which stores a new X values and sets flags, which
    means it wants user flags active.
    The few routines that used 'FindBuffer' will need to exit using Exit or
    ExitS11 (exit and set push flag). User flags are not updated in this
    case and there is no provision for a new X value.

;;; **********************************************************************
#endif


#define LFE(x)  `FAT entry: \x`
#define FATOFF(x) (LFE(x) - FatStart) / 2

;;; Make it easy to populate the key table
KeyEntry:     .macro  fun
              .con   FATOFF(fun)
              .endm

;;; Create a FAT entry with an appropriate label.
FAT:          .macro  entry
LFE(entry):   .fat    \entry
              .endm

;;; Define key code symbol for a function.
KeyCode:      .macro  fun
`\fun_Code`:  .equ    FATOFF(fun)
              .endm

;;; Define key code symbols we use
              KeyCode CLIX          ; create CLIX_Code symbol
              KeyCode Header        ; header is used for digit entry

;;; Start of function address table (start of ROM)
              .section FAT
XROMno:       .equ    16

              .con    XROMno        ; XROM number
              .con    (FatEnd - FatStart) / 2 ; number of entry points

FatStart:
              .fat    Header        ; ROM header
              FAT     FLOAT         ; mode change
              .fat    Integer
              FAT     Binary        ; base related instructions
              FAT     Octal
              FAT     Decimal
              FAT     Hex
              FAT     WSIZE
              FAT     WINDOW
              FAT     CLIX          ; clear IX
              FAT     ENTERI        ; ENTER^ on integer stack
              FAT     LASTIX
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
FatEnd:       .con    0,0

              .section Code

;;; **********************************************************************
;;;
;;; Buffer layout. The state is kept in a buffer with the following
;;; layout:
;;;
;;; 10pfTTZZYYXXLL
;;; HHSSAPWS0000II
;;;
;;;   where
;;;     HH - buffer number
;;;     SS - size of buffer
;;;     A  - #space indentation of LCD
;;;      P - window display
;;;     WS - Word size (1-64)
;;;     II - internal flags
;;;
;;;     pf - default postfix byte for current prompting instruction
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

IF_Argument:  .equ    4             ; argument entry in progress
IF_DigitEntry: .equ   5             ; Integer mode digit entry ongoing flag
IF_Integer:   .equ    6             ; Integer mode active

;;; Set when displaying integer X.
;;; This is basically the message flag as seen but the integer mode.
IF_Message: .equ 7


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
Flag_56:      .equ    9             ; set when word size is 56

BufNumber:    .equ    0             ; Try with 0! Otherwise 4 might be used?
BufSize:      .equ    2

#include "mainframe.i"

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


;;; ************************************************************
;;;
;;; ROM header.
;;;
;;; This functions doubles as the instruction that loads
;;; integer constants in program memory. It is to be followed
;;; by a text literal that embeds the actual integer literal.
;;; If it is not folled by an alpha literal, 0 is loaded.
;;;
;;; ************************************************************

              .name   "-PROG P001"  ; The name of the module
Header:       ?s13=1                ; running?
              goc     10$           ; yes
              ?s4=1                 ; no, single stepping?
              rtn nc                ; no, do nothing
10$:          rxq     FindBufferUserFlags
              rxq     LiftStackS11
              rxq     fetchLiteral
              regn=c  X
              gosub   PUTPCA        ; we already have chip 0 selected
              rgo     PutX


;;; **********************************************************************
;;;
;;; Keyboard handler. This routine is the keyboars takeover code which
;;; is done by faking a partial key sequence that is to be handled here,
;;; but in reality we will just implement a different keyboard layout.
;;;
;;; Code here heavily borrowed from NEWFCN in mainframe, at least for
;;; the first part.
;;;
;;; **********************************************************************

XROMi:        .equ    160 + (XROMno / 4)
XROMj:        .equ    64 * (XROMno % 4)

ClearDigitEntry:
              rxq     chkbuf
              nop
              cstex
              st=0    IF_DigitEntry
;              st=0    IF_Message
              cstex
              pt=     8
              lc      0             ; clear window display
                                    ;  (doing here is safe and helps getting
                                    ;   back to window 0 when leaving program
                                    ;   mode)
              data=c
              c=0                   ; select chip 0
              dadd=c
              rtn

RAK60J1:      rxq     ClearDigitEntry ; handle reassigned keys
              golong  RAK60

;;; During digit entry, we borrow Flag_56 (at a point where it is no longer
;;; needed) to keep track of programming mode
Flag_PRGM:    .equ    Flag_56

KeyHandler:   nop                   ; ignore back arrow entry (deal with it as any key)
              c=n                   ; move logical keycode
              a=c     x             ; to A[2:1]
              gosub   LDSST0
              rcr     1
              st=c
              s5=0                  ; clear PKSEQ
              c=st
              rcr     -1
              regn=c  14
              rcr     6             ; put up SS3
              st=c
              ?s4=1                 ; user mode?
              gonc    10$           ; no
              gosub   TBITMP        ; yes, test bit map
              ?c#0                  ; key reassigned?
              goc     RAK60J1       ; yes

;;; Auto assignment tests are here, but since we heavily depend on the upper
;;; part of the keyboard, it just takes too long. Entering hex digits slows
;;; down, as well as switching between different bases. These are quite cental
;;; functions, so it was decided to disable this.
;;; If it is to be put back, then there should probably be a flag to control
;;; it, but it really makes things slow and these are so central I think
;;; we are better without them here.

#if 0
              c=regn  14            ; put up SS0
              st=c
              ?s3=1                 ; prgm mode?
              goc     10$           ; yes, skip auto-assign tests
              c=n
              c=0     m
              rcr     2             ; logical row to C.S
              a=c     x             ; logical col to A.X
              ldi     0x66          ; row 0 offset
              c=c-1   s             ; row 0?
              goc     5$            ; yes
              pt=     0
              lc      11            ; set up for row 1 test
              ?c#0    s
              gonc    5$            ; row 1
              pt=     1
              lc      7             ; shifted row 0 test
              c=c+1   s
              c=c+c   s             ; shifted?
              gonc    10$           ; no
              ?c#0    s             ; not shifted row 0?
              goc     10$           ; not auto assigned
5$:           c=a+c   x             ; C.X = implied local label
              m=c                   ; save operand in M
              a=c                   ; set up A[1:0] for search
              gosub   SEARCH
              ?c#0                  ; found?
              gonc    10$           ; no
              cmex                  ; yes
              rxq     ClearDigitEntry
              golong  PARS60+1      ; skip cmex at start of PARS60
#endif

10$:                                ; key not reassigned

              c=regn  14
              st=c
              c=n                   ; retrieve logical keycode
              a=c                   ; to A[2:1]
              pt=     3
              lc      0xc           ; default table starts at ?C00
              a=c     m             ; build CLK-
              asl                   ;  CLK--
              asl                   ; CLK---
              gosub   PCTOC
              lc      3             ; C[2]= 3  (for ShiftUser below)
              pt=     5
              acex    wpt           ; merge final table address
              cxisa                 ; and fetch
              c=c-1   xs            ; a local XROM function?
              goc     KeyH20        ; yes
              c=c-1   xs            ; numeric entry key?
              goc     numEntryJ4    ; yes
              m=c                   ; no, same function as normal keyboard
              c=c-1   xs
              gonc    ShiftUser     ; does not clear digit entry
              rxq     ClearDigitEntry
PARS56_M:     c=m                   ;  restore keycode
PARS56_1:     golong  PARS56

ShiftUser:    rxq     chkbuf
              goto    PARS56_M      ; (P+1)
              rcr     -4            ; (P+2) found buffer
              a=c     s             ; LCD indentation
              gosub   ENLCD
10$:          a=a-1   s
              goc     11$
              flsabc                ; realign display
              goto    10$
11$:          gosub   ENCP00
              goto    PARS56_M

KeyCLIX:      ldi     CLIX_Code
KeyH20:       cmex                  ; handle XROM code in C[1:0]
              rxq     ClearDigitEntry
              cmex
              acex    x
              a=0     xs            ; move to A[2:0]
              pt=     3             ; build complete 2 byte XROM instruction
              lc      XROMi >> 4
              lc      XROMi & 15
              lc      XROMj >> 4
              lc      XROMj & 15
              c=a+c   x
              golong  RAK70

numEntryJ4:   goto    numEntryJ3    ; relay

;;; Backspace is pressed, we have four cases.
;;; 1. In program mode, delete the current instruction
;;; 2. If showing a message, cancel it by showing the integer X register instead.
;;; 3. If entering digits, rub out one (do CLIX if deleting to 0)
;;; 4. Perform CLIX
backSpace:    c=0     x
              dadd=c
              c=regn  14
              rcr     -2
              c=c+c   xs            ; program mode?
              gonc    10$           ; no
              ?st=1   IF_DigitEntry ; digit entry in progress?
              gonc    5$            ; no, program mode delete line

              rxq     fetchLiteral  ; yes, pick up current number
              st=1    Flag_PRGM
              goto    NumBSP10

5$:           c=regn  14
              st=c                  ; bring up SS0 for PARS56
              s5=0                  ; clear message flag to get display update
              c=st
              regn=c  14
              ldi     11            ; program mode delete
              goto    PARS56_1

10$:          st=0    Flag_PRGM
              ?st=1   IF_DigitEntry ; doing digit entry
              goc     NumBSP
              ?st=1   IF_Message    ; showing a message?
KeyCLIXJ1:    gonc    KeyCLIX       ; no, do CLIX
              rxq     DisplayXB10   ; show the underlaying X contents
              golong  NFRKB         ; return via reset keyboard

numEntryJ3:   goto    numEntryJ2    ; relay
backSpaceJ1:  goto    backSpace     ; relay

;;; Back space doing hexadecimal input
hexBSP:       asr                   ; delete hex digit
              c=b     x
              rcr     1
              acex    s
              c=0     xs
              bcex    x
              goto    dig10

              ;; Back arrow
NumBSP:       rxq     LoadX
              c=regn  X
NumBSP10:     acex                  ; load current number to B.X:A
              ?s1=1
              gonc    5$
              ?s3=1
              goc     hexBSP        ; hex
              goto    octBSP        ; oct
5$:           ?s3=1
              goc     decBSPJ1      ; dec

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
              goc     bspNoDecJ2    ; no
              ?b#0    x
              goc     bspNoDecJ2    ; no

              ;; Back arrow down to nothing left
dig20:        ?st=1   Flag_PRGM     ; in program mode?
              goc     dig25
              s11=0                 ; clear push flag in case user NULL the CLIX !!!
                                    ;  (this is not done in mainframe, but it
                                    ;   probably should have)
              goto    KeyCLIXJ1

numEntryJ2:   goto    numEntryJ1    ; relay
backSpaceJ2:  goto    backSpaceJ1   ; relay
decBSPJ1:     goto    decBSP

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

dig25:        rxq     ClearDigitEntry ; clear digit entry flags
              gosub   DATOFF        ; clear flags
              rxq     NXBYTP        ; clean up in program memory
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
              golong  ERR120        ; back up and show previous program line

backSpaceJ3:  goto    backSpaceJ2   ; relay
numEntryJ1:   goto    numEntry      ; relay
bspNoDecJ2:   goto    bspNoDecJ1    ; relay

;;; Back space doing decimal input. This is done in a slight different
;;; as taking out the last digit is somewhat more complicated compared
;;; to the other bases. This is done in backSpace10 which reconstructs
;;; the number from the remaining cached digits.
decBSP:       rxq     backSpaceLCD
              goto    dig20         ; (P+1) zero result
              rxq     backSpace10   ; (P+2) adjust number
              s1=0                  ; set by backSpace10, restore it
dig30:        rxq     saveInternalFlags
              gosub   LDSST0
              s5=1                  ; set message flag
              c=st
              regn=c  14
              ?s3=1                 ; are we in program mode?
              goc     kbDoneJ1      ; yes, done
              rcr     12            ; bring up user flags
              st=c
              rxq     SetXFlags     ; no, set flags according to X
              goto    kbDoneJ1      ; return

;;; Handle numeric entry
numEntry:     pt=     0
              g=c                   ; save digit number in G
              rxq     FindBuffer    ; buffer address to B[12:10]
              c=st                  ; restore C[1:0]
              acex    x             ; base - 1 to A[0]
              pt=     0             ; get digit to C[2:0]
              c=g
              c=0     xs            ; test for backspace
              c=c-1   xs
              c=c+1   x
              goc     backSpaceJ3   ; backspace
              c=c-1   x             ; restore digit
              c=0     xs

              ;; Select chip 0. We know C.X is hex F or less.
              ;; (This is needed when we start a new digit entry and push
              ;; flag is not set.)
              dadd=c
              ?a<c    pt            ; digit out of range?
              goc     digAbort      ; yes, blink and return via reset keyboard
              c=regn  14            ; are we in program mode?
              rcr     -2
              c=c+c   xs
              gonc    runMode       ; no
              rxq     prgmDigent    ; yes
              goto    dig35         ; (P+1) start digit entry
              goto    dig40         ; (P+2) ongoing digit entry

kbDoneJ1:     goto    kbDone        ; relay
bspNoDecJ1:   goto    bspNoDec      ; relay

runMode:      st=0    Flag_PRGM
              ?st=1   IF_DigitEntry ; start digit entry?
              goc     dig37         ; no
              rxq     LiftStackS11  ; check if we should lift stack

              ;; Start entry with 0, clear digit cache
dig35:        b=0     x             ; Load X (0)
              c=regn  8             ; clear decimal digits cache
              rcr     8
              c=0     x
              rcr     3
              c=0     x
              rcr     3
              regn=c  8
              c=0
              regn=c  9
              goto    dig40
dig37:        rxq     LoadX         ; load X to B.X-A
              c=regn  X
dig40:        acex                  ; A= load part of X
              ?s1=1                 ; dispatch on base
              goc     37$           ; hex or octal
              ?s3=1
              goc     decDigit      ; decimal
              goto    binDigit      ; binary
37$:          ?s3=1
              goc     hexDigit      ; hex
              goto    octDigit      ; octal

digAbort:     gosub   BLINK         ; not accepted key, blink
kbDone:       rxq     TakeOverKeyboard
              golong  NFRKB         ; return via reset keyboard


decDigit:     rxq     Mul10         ; prepare for a new decimal digit
              goto    dig50

hexDigit:     acex    s             ; prepare for a new hex digit
              bcex    x
              rcr     -1
              bcex    x
              asl
              goto    dig50

              ;; Back space used, not doing decimal
bspNoDec:     rxq     saveInternalFlags
              ?st=1   Flag_PRGM
              goc     10$
              rxq     SaveX
              goto    20$
10$:          rxq     saveLiteral
20$:          rxq     backSpaceLCD
              goto    kbDone        ; (P+1) assume we never use this, as we
                                    ;       have already testedfor 0 before
                                    ;       coming here, still we need to
                                    ;       occupy this space
              goto    kbDone        ; (P+2)

octDigit:     rxq     Shift1
              rxq     Shift1
binDigit:     rxq     Shift1
dig50:        c=0
              pt=     0
              c=g                   ; get digit
              a=a+c                 ; add digit to X
              gonc    44$
              bcex    x
              c=c+1   x
              bcex    x

44$:          rxq     AcceptAndSave ; Check if value is accepted, save it
              goto    digAbort      ; too big, blink and return

              gosub   ENCP00
              pt=     0
              c=g                   ; get new digit
              rcr     1
              bcex    s             ; B.S= new digit
              c=regn  8             ; digits, upper part
              rcr     -6
              a=c
              c=regn  9             ; digits, lower part
              a=c     s             ; nibble move between registers
              c=b     s             ;    //
              rcr     -1
              regn=c  9             ; done with low part
              c=regn  8             ; put together high part
              acex
              rcr     5
              pt=     7
              acex    wpt
              regn=c  8

              s8=0                  ; assume no digits outside
              c=0     wpt           ; test if we have digits outside display
              ?c#0
              goc     46$           ; yes
              c=regn  9             ; check lower part
              pt=     7
              c=0     wpt
              ?c#0
              gonc    48$           ; zero outside
46$:          s8=1                  ; digits outside

48$:          gosub   ENLCD
              ?st=1   IF_DigitEntry
              gonc    55$
              ldi     0x20          ; load a blank
              srsabc                ; push in blank to drop base character
              c=c-1   x
              acex    x             ; A.X = underscore
              pt=     1
50$:          frsabc                ; loop to shift off underscore
              ?a#c    wpt
              goc     50$
              goto    60$

55$:          st=1    IF_DigitEntry ; new digit entry

60$:          pt=     0
              c=g
              acex    x
              rxq     digitChar     ; convert digit to character
              slsabc                ; to LCD
              ldi     0x1f          ; with underscore
              slsabc
              c=c+1   x             ; two spaces after underscore
              slsabc
              slsabc
              slsabc
              gosub   LEFTJ         ; left justify
              acex    x             ; get the space
              ?st=1   Flag_PRGM
              goc     65$
              frsabc                ; rotate right
65$:          frsabc
              ?s8=1                 ; digits outside?
              gonc    66$           ; no
              frsabc                ; yes, set a dot
              cstex
              s6=1
              cstex
              slsabc
66$:          rxq     baseChar
              slsabc
              gosub   ENCP00        ; disable LCD
              st=1    IF_DigitEntry ; remember we are in digit entry

              rgo     dig30         ; save flags, X and return


;;; **********************************************************************
;;;
;;; Handle entry of digits in program mode.
;;;
;;; Similar to XROMs with postfix arguments, we use an XROM function
;;; before the actual binary data embedded in a string literal.
;;; Initialization consists of writing the prefix XROM and prepare a text
;;; one placeholder.
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
              ldi     0xa4          ; XROM 16,00  - A4 00
              gosub   INBYTC
              gosub   INBYT0

              gosub   INSSUB
              a=0     s
              ldi     0xf0          ; Text 0, to avoid gobbling up any following
                                    ; text wrapper literal when we replace it
              gosub   INBYTC

              c=n                   ; restore
              stk=c                 ;  return address
              pt=     0
              g=c                   ;  entered char

              rxq     FindBuffer    ; restore M, ST

              c=0                   ; start out with 0
              b=0     x
              dadd=c                ; select chip 0
              pt=     0
              rtn

;;; Load literal from program memory
50$:          c=stk                 ; return to (P+2)
              c=c+1   m
              stk=c


fetchLiteral: gosub GETPC
fetchLiteralA:
              rxq     NXBYT
              b=0     x             ; clear upper part
              rcr     -1
              c=c+1   xs            ; text wrapper?
              goc     10$           ; yes
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
              c=n                   ; C= lower part of the literal
              rtn


digitChar:    pt=     0
              ldi     10
              ?a<c    pt
              gonc    10$
              ldi     '0'           ; 0-9
              goto    20$
10$:          ldi     ('A' - 10) & 15 ; A-F
20$:          c=a+c   pt
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

saveInternalFlags:
              c=b
              rcr     10
              dadd=c
              c=data
              c=st                  ; get internal flags
              data=c                ; save them
              rtn


backSpaceLCD: c=regn  9             ; digits, lower part
              csr                   ; right shift lower part
              a=c
              c=regn  8             ; digits, upper part
              rcr     -5
              a=c     s             ; move over digit from upper to lower
              rcr     6             ; right shift upper part
              c=0     s
              regn=c  8
              rcr     8             ; test for zero
              pt=     5
              b=0     x             ; assume return zero
              ?c#0    wpt
              goc     10$           ; not zero
              ?a#0
              rtn nc                ; zero

10$:          bcex    wpt           ; B[5:0] = upper part
              c=stk                 ; return to (P+2)
              c=c+1   m
              stk=c
              acex
              regn=c  9             ; write back lower part
              ?b#0    wpt           ; zero upper part?
              gonc    12$           ; yes
              c=0     s             ; no, collapse that to pos 13
              c=c+1   s
12$:          n=c                   ; N= lower digits to be displayed
              gosub   CLLCDE
              c=c-1   x             ; underscore
              srsabc
              ldi     7             ; digit loop counter
              rcr     1             ; C[13]= loop counter
              a=c                   ; A[13]= loop counter
              c=n

20$:          a=c     x             ; loop to put digits in LCD
              rcr     1
              c=0     s
              n=c
              rxq     digitChar
              srsabc
              c=n
              ?c#0
              gonc    21$
              a=a-1   s
              gonc    20$

21$:          pt=     12            ; set G[1] if we have digits outside
              ?c#0
              gonc    22$
              c=c-1   s
22$:          g=c

              a=0     x             ; compensate line number by -1
              a=a-1   x

              frsabc                ; rotate right

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


backSpace10:  c=0                   ; clear real X
              regn=c  X
              b=0     x
              c=regn  8             ; calculate the new value for X
              n=c
              rcr     8             ; do we need to do upper part?
              pt=     5
              ?c#0    wpt
              gonc    30$           ; no
              pt=     6
              rxq     50$
30$:          c=regn  9
              n=c
              pt=     0

50$:          c=regn  X
              a=c
              c=n
52$:          regn=c  X
              ?s1=1
              gonc    53$
              rxq     Mul10
53$:          c=regn  X
              c=0     m
              c=0     x
              rcr     -1
              ?c#0    x
              gonc    54$
              s1=1                  ; seen a non-zero digit
54$:          a=a+c
              gonc    55$
              bcex    x
              c=c+1   x
              bcex
55$:          c=regn  X
              rcr     -1
              dec pt
              ?pt=    0
              gonc    52$

;;; Just save X
SaveX:        c=b
              rcr     10
              c=c+1   x
              dadd=c                ; select trailer register
              c=data
              rcr     2
              bcex    x
              bcex    xs
              rcr     -2
              data=c
              c=0
              dadd=c
              acex
              regn=c  X
              rtn


;;; **********************************************************************
;;;
;;; PutX - Put back final X, update user flags accordingly
;;; PutXDrop - Alternative entry to drop stack over Y.
;;; PutXDropCY - Alternative entry to update carry flag
;;;
;;; In: ST = carry flag valid
;;;     B[12:10] - address of header buffer register
;;;     X - lower port of result
;;;     B[2:0] - upper part of result
;;;     M - carry word
;;;
;;; **********************************************************************

PutXDropCY_0: c=0
              c=b     x
              goto    PutXDropCY_1

PutXDropCY_56:
              c=c+c
              goc     PutXDropCY_2
              goto    PutXDrop

PutXDropCY:   st=0    Flag_CY
              c=m                   ; mask for bits outside
              acex
              ?st=1   Flag_UpperHalf
              goc     PutXDropCY_0
              c=regn  X
              ?a#0                  ; 56 bits?
              gonc    PutXDropCY_56 ; yes
PutXDropCY_1: c=c&a
              ?c#0
              gonc    PutXDrop      ; no carry
PutXDropCY_2: st=1    Flag_CY

PutXDrop:     c=b                   ; select upper part register
              rcr     10
              c=c+1   x
              dadd=c
              c=data                ; drop stack, upper part
              rcr     4
              pt=     5
              csr     wpt
              csr     wpt
              rcr     -4
              data=c
              c=0     x
              dadd=c                ; select chip 0
              c=data                ; get T
              acex                  ; save in A

              c=regn  Z             ; drop stack, lower part
              regn=c  Y             ; Y = Z
              acex                  ; get T
              regn=c  Z             ; Z = T

PutX:         rxq     MaskAndSave

;;; Normal exit with loaded and modified user flags in ST.
;;; In most cases you exit via PutX or one of its friends.
ExitUserST:   c=0
              dadd=c                ; select chip 0
              c=regn  14
              rcr     12
              c=st                  ; write out user flags
              rcr     -12
              regn=c  14

;;; Exit and show display of X register in integer mode if
;;; appropriate. This will give a steadier display as it sets
;;; the message flag, compared to going out on an arbitrary
;;; operation (which all other non-integer mode instructions do).
;;; You will get the integer display in such cases too, but it
;;; will temporarily show the float X before the I/O poll routine
;;; kicks in and changes it. Going out here give a steadier result.
;;;
;;; Assume header address is in A.X and header is selected
ExitNoUserST: acex
ExitNoUserST1:
              dadd=c
              acex
              c=data                ; load buffer header
              cstex                 ; load internal flags
              ?st=1   IF_Integer    ; float mode?
              gonc    1$            ; yes, done
              ?s13=1                ; running?
              goc     1$            ; yes, done
              gosub   LDSST0        ; load SS0
              ?s3=1                 ; Program mode?
              goc     1$            ; yes, no display of X
              ?s7=1                 ; alpha mode?
              goc     1$            ; yes, no display of X
              s5=1                  ; Set message flag to get stable display
              cstex                 ;   of integer X
              regn=c  14            ; write back SS0
              acex    x             ; select buffer header, for DisplayX
              dadd=c
              acex    x
              rxq     DisplayX      ; default display of integer X register
1$:           golong  NFRC



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
              rxq     FindBuffer
              st=0    IF_DigitEntry
              cstex
              rcr     1
              bcex    s
              rcr     -1
              data=c

              ;; Fall into Exit

;;; Exit routine with X already stored properly.
;;;
;;; IN: B[12:10]
Exit:         c=b
              rcr     10
              goto    ExitNoUserST1


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
              rxq     chkbuf
              goto    CreateBuf     ; create buffer
              cstex
              ?st=1   IF_Integer
              goc     ExitNoUserSTR0 ; already in integer mode
              st=1    IF_Integer    ; enter integer mode
              cstex                 ; updated internal flags
              data=c

ExitNoUserSTR0:                     ; assume header address in A.X
              goto    ExitNoUserST

ExitS11:      s11=1                 ; enable stack lift
              goto Exit

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
;;; **********************************************************************

CreateBuf:    acex    x             ; save address of first free register
              n=c                   ; in N
              c=0                   ; select chip 0
              dadd=c
              gosub   MEMLFT        ; Check if there is room for the integer
              a=c     x             ; buffer
              ldi     BufSize
              ?a<c    x
              goc     NoRoom        ; no

              c=n                   ; yes, create it
              c=c+1   x             ; select upper part register
              dadd=c

              c=0                   ; write inital upper parts register
              c=c+1   s
              data=c

              c=n
              dadd=c                ; select header register
              acex    x             ; A[2:0]= buffer header address

              c=0
              pt=     13
              lc      BufNumber     ; build header
              lc      BufNumber
              lc      0
              lc      BufSize
              pt=     7
              lc      1             ; word size = 16
              pt=     1
              lc      (1 << IF_Integer - 4)
              lc      15            ; hex
              data=c                ; write buffer header

ExitNoUserSTR1:
              goto    ExitNoUserSTR0

NoRoom:       rxq     ErrorMessage
              .messl  "NO ROOM"
              rgo     ErrorExit

ErrorMessage: gosub   ERRSUB
              gosub   CLLCDE
              golong  MESSL


;;; **********************************************************************
;;;
;;; Restore float mode operation
;;;
;;; **********************************************************************

              .name   "FLOAT"
FLOAT:        nop                   ; non-programmable (allow mode switch in program mode)
              rxq     chkbuf
              rtn                   ; (P+1) no buffer
              cstex                 ; (P+2)
              ?st=1   IF_Integer
              rtn nc                ; already in float mode, do nothing
              st=0    IF_Integer    ; clear integer flag
              cstex
              data=c
              rtn


NoBuf:        rxq     ErrorMessage
              .messl  "NO PROG BUF"
ErrorExit:    gosub   LEFTJ
              s8=1
              gosub   MSG105
              golong  ERR110

;;; **********************************************************************
;;;
;;; Locate the integer buffer and set up carry bit in M register.
;;; Terminate with error message "NO PROG BUF: if buffer does not exist.
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
;;; Preserves: A.S, A.M B.S and N
;;; Uses: ST
;;;
;;; **********************************************************************

FindBuffer:   rxq     chkbuf
              goto    NoBuf         ; (P+1)
CarryToM:     acex    x             ; (P+2)  C.X= buffer address
              rcr     -10
              bcex    m             ; save in B[12:10]
              st=0    Flag_56
              st=0    Flag_UpperHalf
              c=data                ; load header (due to CarryToM entry)
              pt=     8             ; clear window#
              lc      0
              data=c
              rcr     6             ; align word size to C[1:0]
              acex    x
              a=0     xs
              ldi     56
              ?a<c    x             ; carry bit in low part (1-55)?
              goc     10$           ; yes
              a=a-c   x
              st=1    Flag_UpperHalf
10$:          ?a#0    x             ; is carry from 56th pos?
              gonc    30$           ; yes
              acex    x
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

30$:          c=0                   ; carry out in 56 bit register carry
              st=1    Flag_56
              goto    20$


FindBufferUserFlags:
              c=regn  14            ; bring up user flags
              rcr     12
              st=c
              rxq     FindBuffer
              cstex                 ; bring up user flags
              rtn


;;; **********************************************************************
;;;
;;; Locate the integer buffer
;;;
;;; If not found, return to (PC+1)
;;; If found, return to (PC+2) with:
;;;   C - buffer header register
;;;   A.X = address of buffer start register
;;;
;;; **********************************************************************

chkbuf:       ldi     BufNumber
              rcr     2             ; buffer number to C[12]
              pt=     12
              ldi     191           ; One below first register
              a=c
1$:           a=a+1   x             ; Start of search loop
2$:           c=0     x             ; Select chip 0
              dadd=c
              c=regn  c             ; find chain head .END.
              ?a<c    x             ; have we reached chainhead?
              rtnnc                 ; yes, return to (P+1), not found
              acex    x             ; no, select and load register
              dadd=c
              acex    x
              c=data                ; read next register
              ?c#0                  ; if it is empty, then we reached end
              rtnnc                 ; of buffer area, return to not found
                                    ; location
              c=c+1   s             ; is it a key assignment register
                                    ; (KAR)?
              goc     1$            ; yes, move to next register
              ?a#c    pt            ; no, must be a buffer, have we found
                                    ; the buffer we are searching for?
              goc     3$            ; no
              c=stk                 ; yes, fix (P+2) as return point
              c=c+1   m
              stk=c
              c=data                ; Load header register to C
              rtn

3$:           rcr     10            ; wrong buffer, skip to next
              c=0     xs
              a=a+c   x
              goto    2$


;;; **********************************************************************
;;;
;;; Find integer buffer, enable stack lift, load integer flags,
;;; save X in L, load X and mask.
;;;
;;; Out: ST = user flags
;;;      M = Carry position
;;;      ST 8 & 9 set with information about carry location
;;;      ST - user exposed flags
;;;      B[2:0] - upper part of X
;;;      B[5:3] - upper part Y
;;;      N - High part register, with X saved to L
;;;      B[12:10] - buffer header address
;;; Preserves:
;;;      B.S
;;;      G
;;;
;;; **********************************************************************

FindBufferGetXSaveL:
              s0=0                  ; no division by 0 check
FindBufferGetXSaveL0:
              rxq     FindBuffer
              cstex                 ; restore header
              n=c                   ; save header

              s11=1                 ; set push flag (enable stack lift)

              acex                  ; load hi(X) to B[2:0]
              c=c+1   x
              dadd=c
              c=data
              rcr     2
              c=0     xs
              bcex    x

              c=0     x             ; select chip 0
              dadd=c
              rxq     MaskX

              c=regn  X
              ?s0=1                 ; check for X=0?
              gonc    10$           ; no
              ?c#0
              goc     10$
              ?b#0    x
              gsubnc  ERRDE         ; 0, give "DATA ERROR"

10$:          regn=c  L             ; save X in L

              c=regn  14            ; bring up user flags
              rcr     12
              st=c

              c=b                   ; select trailer register
              rcr     10
              c=c+1
              dadd=c
              c=data

              pt=     3             ; save upper X on L
              csr     wpt
              csr     wpt
              data=c                ; save back to high(L)
              n=c                   ; save a copy in N

              c=0     x             ; select chip 0
              dadd=c
              rtn

;;; Get the signs of X and Y
getSigns:     c=regn  X
              a=c
              rxq     getSign       ; get sign of X
              c=b     x
              rcr     -4
              stk=c                 ; save sign(X) and upper(X) on stack
              c=regn  Y
              a=c
              c=n
              rcr     6             ; C[1:0]= upper Y
              bcex    x             ; B[1:0]= upper Y
              rxq     getSign
              a=c     s             ; A.S= sign(Y)
              c=stk
              rcr     4             ; C.S= sign(X)
              bcex    x             ; B.X= upper X
              rtn

;;; IN: A.X - bit number (0-63)
;;; OUT: C.X - upper part
;;;      C   - lower part
;;;      A.S - 0 if bit is in lower part
;;;            1 if bit is in upper part
;;; USES: A,C
bitMask:      ldi 64
              ?a<c    x
              gonc    50$           ; out of range
              c=0
              acex    x
              rcr     -3
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

50$:          a=0
              c=0
              rtn


;;; New value in B[2:0] and A
AcceptAndSave:
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
              rxq     SaveUpperPart
              ?st=1   IF_DigitEntry ; first digit?
              golnc   CLLCDE        ; yes
              rtn
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

              ?st=1   IF_DigitEntry ; first digit?
              goc     1$            ; no
              rxq     lineNumber    ; put up line number

1$:           rxq     NXBYTP        ; inspect program memory
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


;;; This attempts to show the current line number. To do this properly,
;;; one should call LINNUM, but it has the potential of busting basically
;;; everything an we cannot afford that, so we just use the current line
;;; number and assume that will be good enough in basically all scenarios
;;; we are going to encounter when we enter an integer literal.
lineNumber:   c=regn  15
              a=c     x
              gosub   CLLCDE
              a=0     s
              gosub   GENNUM        ; OUTPUT LINE #
              flsabc                ; rotate a space around
              golong ENCP00


;;; ----------------------------------------------------------------------
;;;
;;; Load X register to B.X and X.
;;;
;;; OUT:  B.X - upper part of X
;;;       SS0 up
;;; Assume: B[12:10] = buffer header address
;;;
;;; ----------------------------------------------------------------------

LoadX:        c=b
              rcr     10
              c=c+1   x
              dadd=c                ; select trailer register
              c=data
              rcr     2             ; get upper X
              c=0     xs
              bcex    x             ; save in B[2:0]
              c=0     x
              dadd=c

              ;; fall through to MaskX

;;; **********************************************************************
;;;
;;; MaskX - Mask X, which is held in B[2:0] and X. Assume that the carry
;;;  has already put into M and flags set to indicate where the carry takes
;;;  place.
;;;
;;; **********************************************************************

MaskX:        ?st=1   Flag_UpperHalf ; is carry in upper part?
              gonc    1$            ; no

              abex    x             ; high bits to A[2:0]
              c=m                   ; get carry
              c=c-1                 ; make it a mask
              .suppress             ; suppress warning
              c=c&a                 ; mask upper bits
              bcex    x             ; save in B[2:0]
              rtn

1$:           c=m                   ; make mask for lower part
              c=c-1
              a=c
              c=regn  X             ; read X
              c=c&a                 ; mask
              regn=c  X             ; write back
              b=0     x             ; clear upper part
              rtn


;;; ----------------------------------------------------------------------
;;;
;;; MaskAndSave - finalize result in X by masking it, update zero/sign
;;;               flags depending on value in X, and finally save the
;;;               upper part to buffer
;;;
;;; In: B[12:10] - buffer header address
;;;     X - lower part of X
;;;     B[1:0] - upper part of X
;;;     M - carry word
;;;     ST - user flags
;;;     chip 0 - selected
;;;
;;; Out: A.X - buffer header address, for calling DisplayX afterwards
;;;      ST - updated user flags
;;;
;;; ----------------------------------------------------------------------

MaskAndSave:  rxq     MaskX
              rxq     SetXFlags

SaveUpperPart:
              ;; save upper part
              c=b                   ; get buffer header address
              rcr     10
              a=c     x             ; A[2:0] - header address
              c=c+1   x
              dadd=c                ; select trailer register
              c=data                ; write upper part of X to
              rcr     2             ;  buffer
              bcex    x
              bcex    xs
              rcr     -2
              data=c
              rtn


;;; ----------------------------------------------------------------------
;;;
;;; SetXFlags - set sign/zero flags according to X.
;;; SetSignFlag - only set the sign flag.
;;;
;;; In: B.X - upper part of X
;;;     X - lower part of X
;;;     S8/S9 - set according to word size
;;;     M - carry mask
;;;
;;; Out: Sign flag in user flags set to higehst bit in X according to
;;;      word size
;;;
;;; Uses: C, A
;;;
;;; ----------------------------------------------------------------------

SetXFlags:    st=0    Flag_Zero     ; clear flags we will update

              ?b#0    x             ; check for zero result
              goc     SetSignFlag   ; non-zero
              c=regn  X
              ?c#0
              goc     SetSignFlag   ; non-zero

              st=1    Flag_Zero     ; set zero flag

SetSignFlag:  st=0    Flag_Sign
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


;;; **********************************************************************
;;;
;;; XOR - Entry point for exclusive OR between X and Y.
;;;
;;; **********************************************************************

              .name   "XOR"
XOR:          rxq     FindBufferGetXSaveL
              c=regn  X             ; XOR lower part of X with Y
              acex
              c=regn  Y
              b=c
              c=c|a
              bcex
              c=c&a
              c=-c-1
              abex
              c=c&a
              regn=c  X

              c=n                   ;  do upper part
              rcr     4
              a=c     x
              rcr     2
              b=c     x
              c=c|a
              bcex    x
              c=c&a
              c=-c-1  x
aoxfix_0:     abex    x             ; A[1:0] - upper part of X
              c=c&a
aoxfix:       bcex    x
              b=0     xs            ; B[2:0] - upper result
aoxfix_2:     rgo     PutXDrop


;;; **********************************************************************
;;;
;;; OR - Entry point for OR between X and Y.
;;;
;;; **********************************************************************

              .name   "OR"
OR:           rxq     FindBufferGetXSaveL
              c=regn  X             ; OR lower part of X with Y
              a=c
              c=regn  Y
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
AND:          rxq     FindBufferGetXSaveL
              c=regn  X             ; AND lower part of X with Y
              a=c
              c=regn  Y
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
SUB:          c=0 s
              c=c+1   s
              goto    ADD_2

;;; **********************************************************************
;;;
;;; ADD - Entry point for ADD X and Y.
;;;
;;; **********************************************************************

              .name   "ADD"
ADD:          c=0     s
ADD_2:        bcex    s             ; B.S= ADD/SUB flag
              rxq     FindBufferGetXSaveL
              c=regn  X
              ?b#0    s             ; doing SUB?
              gonc    2$            ; no
              bcex    x             ; yes, negate X
              c=-c-1  x
              bcex    x
              c=-c
2$:           regn=c  X
              rxq     getSigns
              st=0    Flag_Overflow ; prepare overflow flag
              st=0    Flag_56       ; borrow 56 flag

              ?a#c    s             ; same sign?
              goc     5$            ; no, will not overflow
              st=1    Flag_Overflow ; assume overflow
              st=1    Flag_56       ; check overflow later
              bcex    s             ; save flag to check against

5$:           c=regn  X
              a=c
              c=regn  Y
              c=c+a
              gonc    10$           ; no carry
              bcex    x             ; carry to upper part
              c=c+1   x
              bcex    x
10$:          regn=c  X             ; save lower part
              c=n                   ; deal with upper part
              rcr     4
              acex    x
              a=a+b   x
              abex    x

              ?st=1   Flag_56       ; check for overflow?
              gonc    20$           ; no
              c=regn  X
              a=c
              rxq     getSign
              abex    s
              ?a#c    s             ; different sign?
              goc     20$           ; yes, overflow (we have correct flag)
              st=0    Flag_Overflow
20$:          rgo     PutXDropCY


;;; **********************************************************************
;;;
;;; CLIX - Entry point for clear integer X register, and disable stack lift.
;;;
;;; **********************************************************************

              .name   "CLIX"
CLIX:         rxq     FindBuffer
              st=0    IF_DigitEntry
              cstex
              data=c
              c=0                   ; load 0
              dadd=c
              regn=c  X
              b=0     x
              s11=0                 ; disable stack lift
putx_CLIX:    rgo    PutX


;;; **********************************************************************
;;;
;;; IABS - Integer ABS, make the number positive
;;;
;;; **********************************************************************

              .name   "ABSI"
ABSI:         rxq     FindBufferGetXSaveL
              st=0    Flag_Overflow
              ?st=1   Flag_2
              goc     putx_CLIX
              goto    NEG10


;;; **********************************************************************
;;;
;;; NEG - Entry point for negate, change sign.
;;;
;;; LastX is saved here which is not for the corresponding float CHS
;;; instruction, which is consistent with how it works on the HP-16C.
;;;
;;; **********************************************************************

              .name   "NEG"
NEG:          rxq     FindBufferGetXSaveL
NEG10:        st=0    Flag_Overflow ; assume no overflow
              ?st=1   Flag_2        ; signed mode?
              goc     5$            ; yes
              st=1    Flag_Overflow ; no, unsigned, set overflow as a
                                    ;  remainder that the negative number
                                    ;  is out of range of unsigned mode
5$:           c=regn  X
              c=-c
              regn=c  X
              a=c
              bcex    x
              c=-c-1  x
              bcex    x

              ?st=1   Flag_UpperHalf
              gonc    10$
              abex    x
10$:          c=m
              c=c-1
              nop
              c=c&a                 ; mask result
              c=c+c                 ; left shift
              a=c
              c=m
              ?a#c                  ; same as carry mask?
              goc     putx_CLIX     ; no, did not overflow
              st=1    Flag_Overflow ; yes, overflow
              goto    putx_CLIX


;;; **********************************************************************
;;;
;;; NOT - Entry point for bit not.
;;;
;;; **********************************************************************

              .name   "NOT"
NOT:          rxq     FindBufferGetXSaveL
              bcex    x
              c=-c-1  x
              bcex    x
              c=regn  X
              c=-c-1
              regn=c  X
              goto    putx_CLIX


;;; **********************************************************************
;;;
;;; LASTIX - Recall L register.
;;;
;;; **********************************************************************

              .name   "LASTIX"
LASTIX:       rxq     FindBufferUserFlags
              st=0    IF_DigitEntry
              cstex
              rxq     LiftStackS11
              c=b
              rcr     10
              c=c+1   x
              dadd=c                ; select trailer reg
              c=data

              bcex    x             ; B.X= upper part
              b=0     xs

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
SWAPI:        rxq     FindBufferUserFlags

              c=b
              rcr     10
              c=c+1   x             ; point to trailer reg
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
              bcex                  ; B.X= X upper part

              c=regn  Y
              acex
              c=regn  X
              regn=c  Y
              acex
SWAPIExit:    regn=c  X
PutX11:       s11=1
              rgo     PutX


;;; **********************************************************************
;;;
;;; RollDown - Helper routine to roll down the stack
;;;
;;; **********************************************************************

RollDown:     rxq     FindBufferUserFlags

RollDown1:    c=b
              rcr     10
              c=c+1   x
              dadd=c                ; select trailer reg

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

              golong  R_SUB         ; rotate normal stack


;;; **********************************************************************
;;;
;;; RDNI - Roll stack down.
;;;
;;; **********************************************************************

              .name   "RDNI"
RDNI:         rxq     RollDown
              rxq     RollDown1
              rxq     RollDown1

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
              goto    PutX11


;;; **********************************************************************
;;;
;;; IR^ - Roll stack up.
;;;
;;; **********************************************************************

              .name   "IR^"
RUPI:         rxq     RollDown
              goto    RDNExit

;;; **********************************************************************
;;;
;;; Rotate and shift functions.
;;;
;;; **********************************************************************

;;; We use a bitfield in B.S to configure the operation.
Bit_Rotate:   .equ    (1 << 3)
Bit_ThroughCarry: .equ (1 << 2)     ; set for RRC/RLC
Bit_Arithmetic: .equ  (1 << 1)      ; set for arithmetic shift

;;; Define a few macros to make it easy to test a bit in the bitfield
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
              rxq     Argument
              .con    Operand01
              c=0     s
              goto    LeftShift

;;; ----------------------------------------
;;;
;;; Rotate left through carry
;;;
;;; ----------------------------------------

              .name "RLC"
RLC:          nop                   ; Prelude for prompting function
              nop
              rxq     Argument
              .con    Operand01
              pt=     13
              lc      Bit_ThroughCarry | Bit_Rotate
              goto    LeftShift

;;; ----------------------------------------
;;;
;;; Rotate left
;;;
;;; ----------------------------------------

RLExit:       rgo     ExitS11

              .name   "RL"
RL:           nop                   ;  Prelude for prompting function
              nop
              rxq     Argument
              .con    Operand01
              pt=     13
              lc      Bit_Rotate
LeftShift:    ?b#0    m             ; 00 operand?
              gonc    RLExit        ; yes, do nothing
              bcex    s             ; B.S= configuration flags
              rxq     FindBufferGetXSaveL
              c=b     m             ; save buffer address on stack
              rcr     10 - 3
              stk=c
              c=regn  X             ; get X
              a=c                   ; A= X
              c=0     m             ; prepare counter
              pt=     3
              c=g
              c=c-1   m
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
              rcr     - (10 - 7)
              bcex    m             ; put in B[12:10]
              acex                  ; write out result
              regn=c  X
              rgo     PutX

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


;;; ----------------------------------------
;;;
;;; Shift right
;;;
;;; ----------------------------------------

              .name   "SR"
SR:           nop                   ; Prelude for prompting function
              nop
              rxq     Argument
              .con    Operand01
              c=0     s
              goto    RightShift

;;; ----------------------------------------
;;;
;;; Arithmetic shift right
;;;
;;; ----------------------------------------

              .name   "ASR"
ASR:          nop                   ; Prelude for prompting function
              nop
              rxq     Argument
              .con    Operand01
              pt=     13
              lc      Bit_Arithmetic
              goto    RightShift

;;; ----------------------------------------
;;;
;;; Rotate right through carry
;;;
;;; ----------------------------------------

              .name   "RRC"
RRC:          nop                   ; Prelude for prompting function
              nop
              rxq     Argument
              .con    Operand01
              pt=     13
              lc      Bit_ThroughCarry | Bit_Rotate
              goto    RightShift

;;; ----------------------------------------
;;;
;;; Rotate right
;;;
;;; ----------------------------------------

RRExit:       rgo     ExitS11

              .name   "RR"
RR:           nop                   ; Prelude for prompting function
              nop
              rxq     Argument
              .con    Operand01
              pt=     13
              lc      Bit_Rotate
RightShift:   ?b#0    m             ; 00 operand?
              gonc    RRExit
              bcex    s             ; B.S=configuration
              rxq     FindBufferGetXSaveL
              c=b     s
              c=c+c   s
              c=c+c   s
              c=c+c   s             ; arithmetic shift (sign preserving)?
              gonc    90$           ; no
              rxq     SetSignFlag

90$:          c=regn  X             ; prepare for loop, load lower part
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

4$:           isRotate
              gonc    66$           ; no rotate, so no carry in
              isThroughCarry
              goc     67$           ; through carry
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
62$:          c=c+c                 ; low part << 3
              gonc    63$
              acex    s
              c=c+c   s
              acex    s
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
              rgo     PutX


;;; **********************************************************************
;;;
;;; DisplayX - Display the X register
;;;
;;; In: As after chkbuf, we know the integer buffer exists.
;;;     A[2:0] buffer header address (CarryToM will move it to B[12:10])
;;;     buffer header selected
;;;
;;; **********************************************************************

Flag_LocalZeroFill: .equ   Flag_UpperHalf

              ;; Entry point to show program literal
              ;; IN: B.X-N - literal
DisplayLiteral:
              st=1    Flag_PRGM
              c=m
              dadd=c                ; select buffer header
              c=data
              pt=     7             ; set word size
              lc      4
              lc      0
              cnex                  ; N= updated buffer header
              a=c
              c=0     x             ; select chip 0
              dadd=c
              goto    Display2

DisplayXB10:  c=b
              rcr     10
              dadd=c
              a=c     x
DisplayX:     c=data                ; get buffer header
              st=c                  ; bring up internal flags
              st=0    IF_Message
              c=st
              data=c
              n=c                   ; save header in N
              rxq     CarryToM      ; get carry mask
              rxq     LoadX         ; load and mask X
              st=0    Flag_PRGM
              st=0    Flag_LocalZeroFill
              c=regn  14            ; move user zero-fill flag to
              rcr     12            ;  local flag (outside low ST)
              st=c
              ?st=1   Flag_ZeroFill
              gonc    10$
              st=1    Flag_LocalZeroFill
10$:          rxq     SetXFlags     ; set zero/sign flags to match X
              c=regn  14            ; write back user flags
              rcr     12
              c=st
              rcr     -12
              regn=c  14

              c=n                   ; bring up internal flags
              st=c

              c=regn  X
              a=c

              ;; handle window for all bases except decimal
Display2:     c=n                   ; check window#
              pt=     9
              lc      0
              g=c                   ; save in G[0] for '.' around base char
              rcr     -5
              ?c#0    s
              gonc    17$           ; window 0

              ?s1=1
              goc     18$           ; hex or oct
              ?s3=1
              goc     100$          ; decimal

18$:          c=c-1   s
              goc     17$
              pt=     1
              abex    wpt
              b=0     x
              acex
              rcr     2
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
              goto    19$

16$:          pt=     5
              c=0     wpt
              rcr     6
              goto    19$


17$:          ?s3=1                 ; hex or dec?
              gonc    1$            ; yes
              ?s1=1
              gonc    100$          ; decimal

1$:           gosub   CLLCDE
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
              rcr     6             ; C[1:0]= word size
              c=0     xs
              c=c-1   x
              acex    x
              pt=     0
28$:          inc pt
              ?pt=    8
              goc     29$           ; not more than 8 characters
              a=a-c   x
              gonc    28$
29$:          abex    x             ; restore A

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
              rcr     -1            ; C.X= bits for this digit,
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
              rxq     lineAndBaseLCD
              goto    90$

10$:          rxq     Div10LCD      ; decimal
              goto    61$

90$:          gosub   LDSST0        ; Set message flag to prevent the normal float
              s5=1                  ; display of X from corrupting what we really want
              c=st                  ; to see.
              regn=c  14

              ;; Fall into TakeOverKeyboard below

;;; ************************************************************
;;;
;;; Take over keyboard.
;;;
;;; This is done by setting partial key sequence flag and storing
;;; our own keyboard handler on stack.
;;; Depending on when and if I/O poll vector is done or if a key
;;; press skips it, we may already have set up. This condition
;;; is checked by inspecting the partial key flag.
;;;
;;; ************************************************************

;;; NOTE: Fall through from above! If making changes in this routine,
;;;       also check that it is consistent with its use from above!
TakeOverKeyboard:
              c=stk                 ; save return address in A
              a=c     m
              c=0     x             ; Load flag register
              dadd=c
              c=regn  14
              rcr     1
              st=c
              ?s5=1                 ; PKSEQ already set?
              goc     50$           ; yes, do not plant take over address
              s5=1                  ; no, set PKSEQ
              c=st
              rcr     -1
              regn=c  14            ; write updated flag back
              gosub   PCTOC         ; put KeyHandler return address on stack
              rcr     3             ; for dispatching from (faked) partial key sequence
              ldi     .low10 KeyHandler
              rcr     -3
              stk=c
              acex    m
              stk=c

;;; Partial key sequence will right shift the LCD. There is nothing we can
;;; do to prevent it. This causes the following problems:
;;; 1. If the LCD is all spaces, it will enter an infinite loop. This will
;;;    happen if you CLA AVIEW.
;;; 2. Any arbitrary message may be shown with leading and trailing spaces,
;;;    such information is lost and the LCD becomes right justified.
;;;    This is not normally a problem, as the next key usually cause new
;;;    contents for the LCD, but pressing SHIFT or USER will not rewrite
;;;    contents and the display becomes right justfied.
;;;
;;; We work arund these problems by checking the display before we hand it
;;; off to the key sequence parser. If the display have a non-space character
;;; in the rightmost position, it is safe.
;;; Otherwise we count the number of spaces starting from left and store
;;; the count in the buffer. The KeyHandler can then make use of this to
;;; recreate the display if needed.
;;; If the display contains all spaces, we store a single small '.' in the
;;; rightmost position to prevent an inifinite loop.
;;;
;;; Note: It should be possible to work around orignal displays by putting
;;;       a character outside its character set in the rightmost position.
;;;       Such character should look like a blank and test as a non-space,
;;;       unfortunately Halfnut displays does not have a character with
;;;       property. Rather than trying to keep the displays apart, I
;;;       settled for a single solution and have to assume the display
;;;       behave like on a Halfnut.

              rxq     chkbuf
              rtn                   ; (P+1) should not happen
              pt=     9             ; (P+2) clean LCD indentation
              lc      0
              data=c
              b=a     x             ; save buffer address

              gosub   ENLCD
              ldi     ' '
              a=c     x
              frsabc                ; check rightmost position
              ?a#c    x
              goc     8$            ; not a space, safe

              a=0     s
5$:           a=a+1   s
              goc     7$
              frsabc
              ?a#c    x
              gonc    5$

15$:          b=a     s             ; save counter
16$:          flsabc                ; realign display
              a=a-1   s
              gonc  16$

20$:          c=0     x             ; unselect LCD
              pfad=c
              c=b     x
              dadd=c                ; select buffer
              c=data
              rcr     -4
              c=b     s             ; save indentation in buffer
              rcr     4
              data=c
              goto    9$

7$:           ldi     0x60          ; '.'
8$:           slsabc
9$:           golong   ENCP00

50$:          acex    m
              gotoc


;;; **********************************************************************
;;;
;;; Load - Load bits pointed out by pointer and a.x
;;;
;;; In: a.x = start address of number
;;;     m = header register
;;;     pt = start nibble in that register
;;; Out: b:c = Register read, right aligned but not normalized
;;;      a.x = end address of number
;;;      pt = 0
;;;
;;; **********************************************************************

Load:         acex    x
              dadd=c
              acex    x
              c=data                ; load low data nibbles
              bcex                  ; put it to b

              acex    x             ; select register with upper nibbles
              c=c+1   x
              dadd=c
              acex    x

              c=data                ; load upper part to c
              bcex                  ; b:c now have unaligned nibbles

1$:           ?pt=    0             ; right justify nibbles to c[7:0]
              rtnc
              rcr     1             ; right shift low part
              bcex
              rcr     1             ; right shift upper part
              bcex
              bcex    s             ; trickle down nibble
              decpt
              goto    1$


;;; **********************************************************************
;;;
;;; ENTERI- Integer stack enter.lift.
;;;
;;; **********************************************************************

              .name   "ENTERI"
ENTERI:       rxq     FindBuffer
              s11=0                 ; disable stack lift
              rxq     LiftStack
              rgo     Exit          ; flags are not affected by ENTERI as
                                    ; we keep the same value in X


;;; ----------------------------------------------------------------------
;;;
;;; Lift the stack.
;;;
;;; Assume: B[12:10] = buffer header address
;;; Uses: A, C   selects chip 0
;;;
;;; ----------------------------------------------------------------------

LiftStackS11: ?s11=1                ; push flag?
              goc     LiftStack     ; yes
              s11=1                 ; no, set it and do not lift stack
              rtn

LiftStack:    c=b                   ; get buffer address to A.X
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


;;; ----------------------------------------------------------------------
;;;
;;; WSIZE - set word size
;;;
;;; ----------------------------------------------------------------------

              .name   "WSIZE"
WSIZE:        nop
              nop
              rxq     Argument
              .con    Operand16
              ?a#0    x
WSZ_DE:       golnc   ERRDE
              ldi     65
              ?a<c    x
              gonc    WSZ_DE
              rxq     FindBuffer
              c=st                  ; restore C[1:0]
              pt=     6
              c=g
              data=c
WSZ_OK:       rgo     Exit


;;; ----------------------------------------------------------------------
;;;
;;; WINDOW - set window
;;;
;;; ----------------------------------------------------------------------

;;; Make it non-programmable to allow it to be used in program mode
;;; to inspect integer literals as well. As we only allow 0-7 we
;;; use single digit input.

              .con    0x97, 0xf, 0x4, 0xe, 0x309, 0x117 ; WINDOW
WINDOW:       nop
              ldi     8             ; allow up to 7
              ?a<c    x
              gonc    WSZ_DE
              acex    x
              pt=     0
              g=c
              rxq     FindBuffer
              c=st                  ; restore C[1:0]
              pt=     8
              c=g                   ; C[8]= window#
                                    ; C[9]= 0 (this is the space indent which
                                    ;          is sometimes set in I/O poll
                                    ;          after a command, here it is safe
                                    ;          to set it to 0)
              data=c
              goto    WSZ_OK


#if  0
              .name   "PWINDOW"
PWINDOW:       nop
              nop
              rxq     Argument
              .con    Operand00
              ldi     8             ; allow up to 7
              ?a<c    x
              gonc    WSZ_DE
              rxq     FindBuffer
              c=st                  ; restore C[1:0]
              pt=     8
              c=g                   ; C[8]= window#
                                    ; C[9]= 0 (this is the space indent which
                                    ;          is sometimes set in I/O poll
                                    ;          after a command, here it is safe
                                    ;          to set it to 0)
              data=c
              goto    WSZ_OK
#endif

;;; ----------------------------------------------------------------------
;;;
;;; MUL - multiply, both double and single precision
;;;
;;; ----------------------------------------------------------------------

;;; As we do not use Flag_56 in this routine, we use it to mark if
;;; we are doing second time around.
Flag_DoingUpper: .equ    Flag_56

;;; We borrow the push flag for marking if we are doing DMUL or MUL.
;;; The input of this flag is irrelevant here and we will set it
;;; before exiting back to mainframe.
Flag_DoubleMul:    .equ    11

;;; However, FindBufferGetXSaveL sets it, so we borrow the Flag_56
;;; initially, check the code below.
Flag_DoubleMul_Early: .equ Flag_56

              .name   "DMUL"
DMUL:         st=1    Flag_DoubleMul_Early ; want double result
              goto    MulCommon

              .name   "MUL"
MUL:          st=0    Flag_DoubleMul_Early ; want single result
MulCommon:    rxq     FindBufferGetXSaveL

              st=0    Flag_DoubleMul     ; move Flag_DoubleMul_Early -> Flag_DoubleMul
              ?st=1   Flag_DoubleMul_Early
              gonc    0$
              st=1    Flag_DoubleMul

0$:           st=0    Flag_DoingUpper

              rxq     getSigns
              c=a-c   s             ; C.S= 0 if same sign
              c=st
              rcr     -4
              stk=c
              c=0
              cnex                  ; clear upper 16 bits of both 128 bits
                                    ;   result and op1.
                                    ; this also gets buffer trailer register
                                    ;   (saved there by FindBufferGetXSaveL)

              pt=     4             ; point to op1[14]
              g=c                   ; G= op1[15:14]

;;; Multiply op1 (from Y) with op2 (from X)
;;; First part takes care of lower registers
;;; op1 is in    N[7:4] : M : Y
;;; result is in N[3:0] : B : A   (initially cleared)
;;; X = nibbles from op2

              c=b
              rcr     10 - 3
              stk=c                 ; push buffer address
              rcr     - (10 - 3) - 3
              stk=c                 ; push op2[15:14] for now

              pt=     0             ; counter for 14 nibbles

              a=0                   ; clear result[27:0]
              b=0

              c=g                   ; we know C=0 and PT=0
              cmex                  ; M= op1[15:14]
              regn=c  Q             ; preserve mask in Q

              ;; take next nibble
10$:          c=regn  X
              ?c#0
              gonc    400$          ; 0, skip the rest
              st=c                  ; nibble to ST
              rcr     1
              c=0     s             ; ensure we get all 0 as soon as done
              regn=c  X

              gosub   PCTOC

;;; DO NOT insert any code here, like relay jumps, we rely heavily
;;; on the particular instructions in this sequence!!!!
              stk=c                 ; push my own PC
              ?s0=1                 ; test bits, just shift if zero
              gonc    30$
              goto    20$
              ?s1=1
              gonc    30$
              goto    20$
              ?s2=1
              gonc    30$
              goto    20$
              ?s3=1
              gonc    30$

              ;; Add to result
20$:          c=regn  Y             ; C -> A,  B -> C, A -> B
              bcex
              a=a+b                 ; add to to result
              gonc    22$           ; no carry
              c=c+1                 ; handle carry
              gonc    22$
              cnex                  ; carry ripples further to result[31:28]
              c=c+1
              cnex
22$:          b=a                   ; B= result[13:0]
              a=c                   ; A= result[27:14]
              c=m                   ; get op1[27:14]
              a=a+c                 ; add to result[27:14]
              gonc    24$           ; no carry

              c=n                   ; carry to result[31:28]
              c=c+1
              goto    25$           ; could use a lot of cnex here, but
                                    ; instruction count would be same, and
                                    ; the goto opens up for relays
              ;; relays
400$:         goto    40$
100$:         goto    10$

24$:          c=n
25$:          acex
              cnex                  ; save A, get second copy of N
              c=0     x
              rcr     4             ; C[3:0] is op1[31:28]
              c=0     s             ; rest of C is cleared
              c=a+c                 ; add to result
              cnex                  ; save N, get A back
              acex                  ; put back to A
              abex                  ; put result[27:0] in their correct places

              ;; shift op1 one step left
30$:          acex
              cnex                  ; save A in N
              rcr     1
              c=c+c   m             ; op1[31:28] << 1
              a=c
              c=m
              c=c+c                 ; op1[27:14] << 1
              gonc    32$
              a=a+1   m             ; carry to op1[31:28]
32$:          acex
              m=c
              c=regn  Y
              c=c+c                 ; op1[13:0] << 1
              gonc    34$
              a=a+1                 ; carry to op1[27:14]
34$:          regn=c  Y             ; save op1[13:0]
              acex                  ; C= op1[27:14]
              cmex                  ; M= op1[27:14], C.M= op1[31:28]
              rcr     -1            ; realign
              cnex                  ; N= op1[31:28], get saved A
              a=c                   ; restore A

              ;; See if we should inspect next nibble
              c=stk
              c=c+1   m
              cxisa                 ; ?s0-2  has xs non zero, ?s3=1 is zero
              ?c#0    xs            ; pointing to '?s3=1', meaning we
                                    ;   have checked all bits in nibble?
              gonc    39$           ; yes
              c=c+1   m             ; no, advance pointer
              c=c+1   m
              stk=c                 ; 3 times each iteration
              c=c+1   m             ; point to next flag test instruction
              gotoc

39$:          dec     pt
              ?pt=    0
1000$:        gonc    100$

;;; After inner loops, we still may have op2[15:14] on stack to deal
;;; with. We may also have exited inner loops early and op1 may need
;;; to be shifted a certain multiples of 4 (indicated by PT)
40$:          ?st=1   Flag_DoingUpper ; done with op2[15:14]?
              goc     60$           ; yes

              st=1    Flag_DoingUpper ; mark for second round

              c=stk                 ; pop op2[15:14]
              rcr     3
              c=0     xs
              ?c#0    x             ; is op2[15:14] zero?
              gonc    60$           ; yes, no need to work on them

              regn=c  X             ; save last op2 nibbles in X

              ?pt=    0             ; does op1 need to be adjusted?
              goc     55$           ; no

              c=regn  Y             ; get op1[13:0]
              bcex                  ; save in B
              cnex                  ; save B in N
              rcr     -3
              stk=c                 ; push result[31:28]
              rcr     4 + 3         ; align op1[31:28] to digit 0
              acex
              cmex

;;; B= op1[13:0]
;;; C= op1[27:14]
;;; A= op1[31:28]
;;; Previous A and B are saved in N and M
50$:          bcex    s             ; ripple highest nibble
              abex    s             ;  to next register
              b=0     s

              rcr     -1            ; shift all registers, rotating
                                    ; in incoming nibble (in S pos)
                                    ; to lowest digit
              acex
              rcr     -1
              acex

              bcex
              rcr     -1
              bcex

              dec pt
              ?pt=    0
              gonc    50$

              cmex                  ; reverse the order to restore op1 as
              acex                  ;  well as A and B
              rcr     -7
              c=stk
              rcr     3
              cnex
              bcex
              regn=c  Y

55$:          pt=     2             ; loop around two times
              goto    1000$         ; go back to loop

;;; Done looping around, we have result in N[3:0] : B : A
;;; Buffer address and ST+sign is on stack.
;;; Now we need to get back to carry mask flag to M
60$:          acex                  ; put lower result in X
              regn=c  X

              c=regn  Q             ; get mask back
              m=c

              c=stk                 ; restore buffer pointer to B[12:10]
              rcr     -(10 - 3)
              bcex                  ; C= result[27:14]

              ?st=1   Flag_DoubleMul ; doing "DMUL"?
              goc     900$          ; yes, never gives carry

              ;; Next line is needed, Flag_DoubleMul is the same flag, and we
              ;; borrow it, now set it as we leave with stack lift enabled.
              s11=1                 ; set push flag (enable stack lift)

;;; Collapse all high bits together in a single nibble [2]
              ?c#0    xs            ; test digit 2
              gonc    65$           ; it is zero
              c=0     xs            ; non-zero, make it 1 to ensure no overflow
              c=c+1   xs            ;  when adding to it

65$:          ?c#0    m             ; collapse upper bits to digit 2
              gonc    66$
              c=c+1   xs

66$:          ?c#0    s
              gonc    67$
              c=c+1   xs

67$:          a=c
              c=n
              pt=     3
              ?c#0    wpt
              gonc    68$
              a=a+1   xs

68$:          b=a     x             ; B[2:0]= final upper part
              c=regn  X
              a=c                   ; A= lower part
              c=stk                 ; get ST and calculated sign
              rcr     4
              st=c
              n=c                   ; N.S= calculated sign
              st=0    Flag_Overflow
              ?st=1   Flag_2
              gonc    70$           ; unsigned mode
              a=c    s              ; A.S= calculated sign
              rxq     getSign
              ?a#c    s             ; correct result sign?
              gonc    70$           ; yes
              st=1    Flag_Overflow ; no, overflowed
                                    ; set correct sign
              c=b
              rcr     10
              dadd=c
              c=data
              rcr     6
              c=0     xs            ; C.X= word size
              c=c-1   x             ; C.X= word size - 1
              acex    x             ; A.X= word size - 1
              c=0     x
              dadd=c
              rxq     bitMask
              b=a     s             ; part flag
              a=c                   ; A= sign bit mask
              c=n
              ?c#0    s             ; set sign?
              goc     120$          ; yes
              acex
              c=-c-1                ; make sign unmask
              acex
              ?b#0    s             ; sign in upper part?
              goc     105$          ; yes
              c=regn  X
              c=c&a                 ; clear sign bit
              goto    72$

900$:         goto    90$           ; relay

105$:         c=b     x             ; in upper part
              c=c&a                 ; set sign
              goto    71$

120$:         ?a#0    s             ; sign in upper part?
              goc     125$          ; yes
              c=regn  X
              c=c|a
72$:          regn=c  X
              goto    70$

125$:         c=b     x             ; get upper part
              c=c|a                 ; set sign
71$:          bcex    x             ; put back

70$:          ?st=1   Flag_UpperHalf
              goc     75$
              ?b#0    x
              goc     78$           ; overflowed
              c=regn  X
              a=c
76$:          c=m
              c=c-1                 ; make unmask
              c=-c-1
              nop
              c=c&a
              ?c#0
              gonc    79$

78$:          st=1    Flag_Overflow
79$:          rgo     PutXDrop

75$:          a=0                   ; test upper part
              a=b     x
              goto    76$

;;; Save double result
;;; We have result in N[3:0] : C : A
90$:          ;; Next line is needed, Flag_DoubleMul is the same flag, and we
              ;; borrow it, now set it as we leave with stack lift enabled.
              s11=1                 ; set push flag (enable stack lift)

              regn=c  Q             ; save middle part in Q
              bcex    x             ; B.X= upper part of lower half

              c=stk                 ; restore flags
              rcr     4
              st=c
              st=1    Flag_Overflow ; always clear overflow

              acex                  ; low part
              regn=c  X             ; X=low part
              regn=c  Y             ; save in Y
              rxq     MaskX
              c=regn  Y             ; get low part back
              a=c                   ; A= low part
              c=regn  X             ; get masked value back
              regn=c  Y             ; low part goes to Y

              c=b
              rcr     10
              c=c+1   x             ; C.X= address of buffer trailer
              dadd=c
              c=data
              rcr     4             ; C[1:0]= old upper Y
              bcex    x
              bcex    xs            ; C[1:0]= new upper Y
              rcr     -4
              data=c                ; write back

;;; Value is in B.X - N[3:0] - Q - A, we now shift upper part
;;; so that it resides in B.X-N.
;;; To do this we shift 112 - WS steps to the left
              c=b
              rcr     10
              dadd=c                ; select buffer header
              rcr     -4
              stk=c                 ; save buffer on stack

              b=a                   ; B= low part
              ldi     112
              a=c     x
              c=data
              rcr     6             ; get word size
              c=a-c   x             ; A.X= 112 - WS
              pt=     0
              g=c                   ; G= counter
              c=0
              dadd=c
              abex                  ; A= first part
              c=regn  Q             ; C= second part
;;; B.X - N - C - A
              goto    99$
91$:          pt=     0             ; start of loop
              cgex

              bcex
              c=c+c   x
              bcex
              cnex
              c=c+c
              gonc    92$
              bcex
              c=c+1   x
              bcex
92$:          cnex
              c=c+c
              gonc    93$
              cnex
              c=c+1
              cnex
93$:          acex
              c=c+c
              gonc    94$
              acex
              c=c+1
              goto    99$
94$:          acex

99$:          pt=     0             ; decrement counter
              cgex
              pt=     1
              c=c-1   wpt
              gonc    91$

              c=n
              regn=c  X
              c=stk                 ; get buffer pointer back
              rcr     -6
              bcex    m
              rgo     PutX


;;; ----------------------------------------------------------------------
;;;
;;; DIV, RMD, DDIV, DRMD - single and double divide routine
;;;
;;; ----------------------------------------------------------------------

Flag_RMD:     .equ    Flag_Zero     ; we borrow flags here
Flag_DoubleDiv:  .equ    Flag_Sign

              .name   "DRMD"
DRMD:         lc      8 + 4
              goto    DIVCommon

              .name   "DDIV"
DDIV:         lc      8
              goto    DIVCommon

              .name   "RMD"
RMD:          lc      4
              goto    DIVCommon

              .name   "DIV"
DIV:          lc      0
DIVCommon:    rcr     2
              bcex    s             ; B.S= variant

              s0=1                  ; check for division by 0
              rxq     FindBufferGetXSaveL0

;;; We always want the low part of dividend to be in Y.
;;; For double operations that means we need to swap Y with Z.
              c=b     s             ; C.S= variant
              st=0    Flag_DoubleDiv
              st=0    Flag_RMD

              c=c+c   s             ; double operation?
              gonc    4$            ; no

              st=1    Flag_DoubleDiv   ; yes
              c=regn  Y
              a=c
              c=regn  Z
              acex
              regn=c  Y
              acex
              regn=c  Z
4$:
              c=c+c   s             ; doing remainder?
              gonc    5$            ; no
              st=1    Flag_RMD      ; yes
5$:

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

              c=n
              rcr     4
              a=c     x
              a=0     xs            ; A[2:0]= Y
              ?st=1   Flag_DoubleDiv
              gonc    7$

              rcr     2             ; doing double, swap Y and Z
              c=0     xs            ; C[2:0]= Z
              acex    x             ; do the swap
              c=0     m
              c=0     s
              rcr     3
              goto    8$
7$:           c=0
8$:           c=b     x             ; hi(X)
              rcr     -6
              acex    x             ; hi(Y)
              rcr     -3
              n=c

              c=b
              rcr     10
              dadd=c
              c=data                ; load buffer header
              rcr     6
              c=0     xs            ; C[2:0]= WSIZE
              ?st=1   Flag_DoubleDiv
              gonc    10$
              c=c+c   x
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
              c=c+c                 ; shift upper part
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
              ?st=1   Flag_DoubleDiv
              gonc    50$           ; single precision

              rcr     6             ; double precision
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
              c=c&a
              ?c#0
              gonc    46$           ; no carry
              c=regn  Z             ; carry to hi(op1)
              c=c+1
              regn=c  Z
              goto    46$

2000$:        goto    200$

45$:          c=n                   ; inspect upper part
              goto    44$

55$:          c=n                   ; make C[2:0] the high part word
              ?st=1   Flag_DoubleDiv ;  to test ougoing carry from
              gonc    52$
              rcr     3
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
              ?st=1   Flag_DoubleDiv
              gonc    52$
              c=regn  Z
52$:          c=c&a
              a=0                   ; assume outgoing carry = 0
              ?c#0
              gonc    58$
              a=a+1                 ; set outgoing carry

58$:          c=n                   ; normalize alignment of N
              rcr     -3
              n=c

              c=g
              c=0     xs
              c=c-1   x             ; decrement loop counter
              gonc    2000$

              c=n

              ?st=1   Flag_RMD      ; remainder?
              goc     65$           ; yes

              st=0    Flag_CY       ; no, set carry set on remainder /= 0
              ?c#0    x
              goc     61$
              c=regn  Q
              ?c#0
              gonc    62$
61$:          st=1    Flag_CY

62$:          c=n
              ?st=1   Flag_DoubleDiv
              goc     70$

              rcr     3
              bcex    x
              c=regn  Y
64$:          regn=c  X
              rgo     PutX

65$:          bcex    x
              c=regn  Q
              goto    64$

70$:          ;;; @@@ need help here!!!
              ;; do upper parts
              rcr     6
              bcex    x
              c=regn  Z
              goto    64$


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
;;; ----------------------------------------------------------------------


getSign:      ?st=1   Flag_UpperHalf
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
19$:          ?a#0                  ; word size 56 ?
              goc     8$            ; no
20$:          c=0     s             ; negative, C.S= F
              c=c+1   s
              goto    15$

50$:          c=b                   ; get upper part
              c=c+c                 ; sign to carry position
              acex                  ; A[2:0]= upper part << 1
              cmex                  ; C=mask, M= lower part
              acex                  ; A= mask
              goto    8$


              .section Code
;;; ----------------------------------------------------------------------
;;;
;;; Argument - Handle numerical arguments for functions in external
;;; XROMs
;;;
;;; Start MCODE function as follows:
;;; XADR  nop
;;;       nop
;;;       rxq     Argument
;;;       con     DefaultOperand
;;;       nop               ; if register arg else any nonzero word
;;;
;;; IN: SS0 UP, CHIP0 selected
;;; OUT: If register:
;;;       c - register value (selected)
;;;       n - its address
;;;       m - X register
;;;      If num argument: (0-127)
;;;       st - numeric argument
;;;       a[2:0] - numeric argument
;;;       b.m - numeric argument
;;;       g - numeric argument
;;;
;;; If there is no argument, it defaults to the X register (IND X)
;;;
;;; ----------------------------------------------------------------------

Argument:     ?s13=1                ; running?
              goc     3$            ; yes
              ?s4=1                 ; single step?
              gonc    91$           ; no

;;; We are executing the instruction from program memory
3$:           rxq     NXBYTP        ; examine argument byte
              b=a                   ; save address
              a=c     x             ; save operand byte

;;; Entry point for executing from keyboard, in which case JF_Argument
;;; must be set and the argument is in A[1:0]
50$:          c=0     s             ; flag for register/numeric argument
              c=stk
              cxisa                 ; get default argument
              m=c                   ; save for possible use
              c=c+1   m             ; update return address (skip over default argument)
              stk=c
              cxisa
              ?c#0    x
              goc     1$
              c=c+1   s             ; register operand
1$:           bcex    s             ; store register operand flag in b.s
              ?st=1   IF_Argument   ; argument already known (before coming here)?
              gonc    2$            ; no
              c=n                   ; yes, move argument to C[1:0]
              goto    8$

91$:          goto    9$            ; relay

2$:           ldi     Text1
              ?a#c    x             ; argument?
              gonc    7$            ; yes
              c=m                   ; no, use default argument instead
              goto    8$
7$:           abex    wpt           ; argument follows in program
              gosub   INCAD
              gosub   PUTPC         ; store new pc (skip over Text1 instruction)
              gosub   GTBYT         ; get argument
8$:           st=c
              ?b#0    s             ; numerical arg?
              golc    ADRFCH        ; yes, register argument
              ?s7=1                 ; no, indirect?
              gonc    97$           ; no
              s7=0                  ; yes
              gosub   ADRFCH
              gosub   ADRFCH
              gosub   BCDBIN
              st=c
              c=stk                 ; put return address to NFRPU on
              a=c                   ; stack again
              c=0
              pt=     4
              lc      15
              stk=c
              acex
              stk=c
97$:          c=0
              dadd=c                ; select chip 0
              c=st                  ; get numeric argument
              pt=     0
              g=c                   ; put in G
              a=c                   ; and A
              rcr     -3            ; and finally to
              bcex    m             ; B.M
              rtn

51$:          goto    50$           ; relay

88$:          spopnd
              rgo     NoBuf

;;; ----------------------------------------------------------------------
;;;
;;; User executes the instruction from the keyboard
;;;
;;; ----------------------------------------------------------------------

9$:           rxq     chkbuf
              goto    88$           ; (P+1) no buf
                                    ; (P+2)

;;; Load IF_Argument flag to ST register. If it is set, then we are coming
;;; here the second time knowing the argument byte.
;;; In that case we also want to reset it as we are done with argument handing.
;;; On the other hand, if it is cleared, we set it to signal that we are looking
;;; for the argument.
;;; All boils down to that we want the current value of the IF_Argument flag,
;;; and want to store it back toggled.
              st=c
              ?st=1   IF_Argument   ; toggle flag
              goc     12$
              st=1    IF_Argument
              goto    13$
12$:          st=0    IF_Argument
13$:          cstex
              data=c                ; save back toggled flag
              ?st=1   IF_Argument   ; (inspecting previous value of flag)
              goc     51$           ; with IF_Argument set indicating found

              acex    x             ; store default argument in trailer
              c=c+1   x
              dadd=c                ; select trailer register
              c=stk
              cxisa                 ; C[1:0] = default argument
              c=c+1   m             ; bump return address
              stk=c
              pt=     0
              g=c
              c=data                ; get trailer
              pt=     10
              c=g                   ; put default arg into 'pf' field
              data=c                ; write back

              gosub   LDSST0        ; argument not obtained yet
              ?s3=1                 ; program mode?
              gonc    30$           ; no
              gosub   INSSUB        ; prepare for insert
              a=0     s             ; clear count of successful inserts
              c=regn  10            ; insert instruction in program memory
              rcr     3
              gosub   INBYTC
              c=regn  10
              rcr     1
              gosub   INBYTC
              gosub   LDSST0

;;; ************************************************************************
;;;
;;; If we are in program mode, fool the calculator that we are executing
;;; <sigma>REG function. The IF_Argument flag has already been set above
;;; to signal to the I/O interrupt to change the 0x99 byte to 0xf1 (text 1).
;;; If not program mode, set up for prompting the current MCODE instruction
;;; and re-execute it with argument bit set to indicate that argument
;;; has been found.
;;;
;;; In other words, from the keyboard we will execute Argument twice, but
;;; in program mode we insert the instruction immediately and make it appear
;;; as we are executing <sigma>REG instead. Once that has been properly
;;; inserted into the program, we alter it to be the postfix argument.
;;;
;;; **********************************************************************

30$:          c=regn  10
              m=c
              ?s3=1                 ; program mode?
              gonc    40$           ; no
              pt=     4             ; yes sigma<reg> byte
              lc      9
              lc      9
              regn=c  10
              clrst
              s4=1                  ; insert bit
              goto    45$
40$:          clrst                 ; run mode
              s5=1
45$:          s0=1                  ; normal prompt
              pt=     0
              c=st
              g=c                   ; save PTEMP2
              gosub   OFSHFT
              c=regn  15            ; display line#
              bcex    x
              gosub   CLLCDE
              ?s4=1
              gonc    49$
              abex    x
              gosub   DSPLN+8       ; display line#
49$:          c=m
              rcr     1
              gosub   GTRMAD
              nop
              acex
              rcr     11
              gosub   PROMF2        ; prompt string
              golong  PAR110        ; go to parse


              .section Code
;;; **********************************************************************
;;;
;;; Increment and get next byte from program memory.
;;;
;;; **********************************************************************

NXBYTP:       gosub   GETPC
NXBYT:        gosub   INCAD
              gosub   GTBYT
              c=0     xs
              ?c#0    x
              rtnc
              goto    NXBYT         ; skip null


              .section Code
;;; **********************************************************************
;;;
;;; Right justify display
;;;
;;; Leaves rightmost char in C[2:0] and 32 in A[2:0] (blank)
;;; Assume: LCD enabled
;;; Uses: A[2:0], C[2:0], PT=1
;;;
;;; **********************************************************************

RightJustify:
              ldi     ' '
              pt=     1
              a=c     x
1$:           frsabc
              ?a#c    wpt
              gonc    1$
              flsabc
              rtn

              .section Code
;;; **********************************************************************
;;;
;;; I/O poll vector. This is the main take over poll vector we employ.
;;; We take advantage that this poll vector is called before we go to
;;; light sleep. The mainframe code will have set up the state and display
;;; at that point to have the desired look and behavior for the next key
;;; press. We intercept it and change it to look the way we want it to,
;;; if needed.
;;;
;;; **********************************************************************

pollio:       ?s3=1                 ; program mode?
              goc     prgm          ; yes

              rxq     chkbuf        ; locate integer buffer
              goto    romrtn        ; (P+1) no integer buffer exists
                                    ; (P+2)
              cstex                 ; bring up internal flags
              st=0    IF_Argument   ; reset argument flag (not being active)
              cstex
              data=c                ; write back to buffer
              cstex                 ; bring up internal flags again
              ?st=1   IF_Integer    ; in integer mode?
              gonc    romrtn        ; no, ordinary floating point operating mode
              cstex                 ; integer mode, restore SS0
              ?s5=1                 ; message flag?
              goc     TakeOver      ; yes, do not touch the display
              rxq     DisplayX      ; show integer display
              gosub   ANNOUT        ; ensure annunciators are up to date,
                                    ;   DisplayX may update sign/zero flags
              goto    ReconstructReturnRomCheck

romrtn:       gosub   LDSST0
romrtn2:      c=n
              goto    RelayRMCK10

TakeOver:     cstex
              st=1    IF_Message    ; not showing X
              cstex
              data=c
              rxq     TakeOverKeyboard

;;; We need to repair registers here for ROMCHK
ReconstructReturnRomCheck:
              gosub   LDSST0        ; put up SS0
              gosub   PCTOC         ; rtn to romcheck
                                    ; since we had no place to
              pt=     5             ; store c-reg, it must be
              lc      0xF           ; constructed here!!
              lc      0xF
              lc      8
              pt=     10
              lc      0             ; rtn address
              lc      1
              lc      8
              lc      0xA
RelayRMCK10:  golong  RMCK10

;;; Program mode returns here with reconstruction of C register for RMCK10, but
;;; first we need to plant the keyboard takeover, unless we are in alpha mode
ProgramReturn: ?s9=1                ; in integer mode?
              gonc    ReconstructReturnRomCheck ; no
              rxq     TakeOverKeyboard
              goto    ReconstructReturnRomCheck

;;; Program mode, we may need to adjust some instructions to look the way
;;; they should.
prgm:         ?s12=1                ; private?
              goc     romrtn        ; yes

              rxq     chkbuf        ; locate integer buffer
              goto    romrtn        ; (P+1) no integer buffer exists
                                    ; (P+2)
              st=c
              st=0    IF_Argument   ; reset argument flag
              cstex                 ; keep old argument flag in ST
              data=c                ; write back

              ;; Use S9 for integer flag, as all registers are clobbered
              ;; below. This seems to be the only bit left free, apart from
              ;; the flag out (tone) register...
              s9=0
              cstex
              ?st=1   IF_Integer
              gonc    1$
              s9=1
1$:           cstex

              acex                  ; get buffer address
              n=c                   ; save in N for literal display
              c=c+1   x             ; point to trailer register
              dadd=c
              c=data                ; get the default postfix byte
              rcr     10
              m=c                   ; save in M[1:0]

              c=0     x             ; select chip 0
              dadd=c
              c=regn  15            ; Do not look for argument
              c=c-1   x             ; if LINNUM=0
              gonc    4$
              goto    ProgramReturn ; get a relay

8$:           gosub   GETPC         ; abort entry of semi-merged instruction
              gosub   DELLIN        ;  remove the XROM instruction as well
              gosub   PUTPC
              gosub   BSTEP
              gosub   DFRST8
3$:           goto    ProgramReturn


4$:           ?s10=1                ; ROM?
              goc     10$           ; yes, no need to change it

              ?st=1   IF_Argument   ; check if inserting prompt
              gonc    10$           ; no

;;; Now change byte from $99 to $f1!!
              rxq     NXBYTP
              b=a
              a=c     x
              ldi     0x99
              ?a#c    x             ; MCODE prompt?
              goc     8$            ; no - it was aborted
              ldi     Text1
              abex                  ; get addr again
              gosub   PTBYTA        ; store text1

              gosub   INCADA        ; step forward to postfix byte
              gosub   GTBYTA
              acex
              cmex
              pt=     1
              ?a#c    wpt           ; same as default?
              goc     5$            ; no
              cmex                  ; yes, restore address to postfix byte
              a=c
              c=0     x             ; null
              gosub   PTBYTA        ; erase it
              gosub   DECADA        ; address of text 1
              c=0     x
              gosub   PTBYTA        ; clear it too
              gosub   PUTPC         ; go to previous line
              gosub   BSTEP
5$:           gosub   DFRST8        ; bring text1 line up

;;; ***********************************************
;;; See if current line is an MCODE prompt function
;;; ***********************************************

10$:          rxq     NXBYTP
              b=a     wpt
              a=c     x
              ldi     0xa0
              ?a<c    x
              goc     90$           ; no xrom function
              ldi     0xa9
              ?a<c    x
90$:          gonc    3$            ; no xrom function
              abex
              gosub   INCAD
              gosub   GTBYT
              rcr     2
              c=b     x
              rcr     -2

              b=a     wpt           ; B[3:0]= program pointer
              acex    x             ; A.X= lower 1 & half of XROM fcn code
              ldi     0x3ff         ; C.X = (A) 400
              c=c+1   x
              ?a#c    x             ; header function (literal wrapper)?
              gonc    80$           ; yes
              acex    x             ; no, restore 1.5 function code to C.X
              gosub   GTRMAD
900$:         goto    90$           ; could not find it
              ?s3=1
              goc     90$           ; user code
              acex
              rcr     11
              cxisa
              ?c#0    x             ; check if 2 nops
              goc     90$           ; no
              c=c+1   m
              cxisa
              ?c#0    x
              goc     90$

;;; **********************************************************************
;;;
;;; We have found an MCODE function with postfix argument.
;;; Now display it properly with its postfix argument.
;;;
;;; **********************************************************************

              c=c+1   m             ; skip past rxq
              c=c+1   m
              c=c+1   m
              c=c+1   m
              cxisa                 ; get default argument
              n=c                   ; save it in case we need it
              gosub   DFRST8        ; display normal line
              gosub   ENLCD
              rxq     RightJustify
              acex                  ; add a blank
              slsabc
              gosub   ENCP00
              rxq     NXBYTP
              gosub   INCAD
              rxq     NXBYT         ; get next byte
              b=a
              a=c     x
              ldi     Text1
              ?a#c    x             ; is it a text 1?
              gonc    35$           ; yes
              c=n                   ; no, use default argument instead
              goto    36$
35$:          abex
              gosub   INCAD
              gosub   GTBYT         ; get argument
36$:          gosub   ROW930        ; display argument
              goto    900$


;;; **********************************************************************
;;;
;;; This is the header function, which is how we implement literals.
;;; The literal comes after it.
;;;
;;; **********************************************************************

80$:          abex    wpt           ; A[3:0] program pointer
              c=n                   ; get buffer address
              m=c
              rxq     fetchLiteralA ; fetch the literal
              rxq     DisplayLiteral
              goto    900$


              .section KeyTable
;;; **********************************************************************
;;;
;;; Keyboard definition
;;;
;;; **********************************************************************

              ;; Logical column 0
              .con    0x10a         ; SIGMA+  (A digit)
              .con    0x10f         ; X<>Y    (F digit here)
              .con    0x30e         ; SHIFT
              KeyEntry ENTERI       ; ENTER^
              KeyEntry SUB          ; -
              KeyEntry ADD          ; +
              KeyEntry MUL          ; *
              KeyEntry DIV          ; /

              ;; Logical column 0, shifted
              KeyEntry SL           ; SIGMA+
              KeyEntry SWAPI        ; X<>Y
              .con    0x30e         ; SHIFT
              .con    0x200         ; CATALOG
              KeyEntry RMD          ; -
              KeyEntry DRMD         ; +
              KeyEntry DMUL         ; *
              KeyEntry DDIV         ; /

              ;; Logical column 1
              .con    0x10b         ; 1/X  (B digit)
              KeyEntry Hex          ; RDN
              .con    0x2e0         ; XEQ
              .con    0             ; right half of enter key
              .con    0x107         ; 7
              .con    0x104         ; 4
              .con    0x101         ; 1
              .con    0x100         ; 0

              ;; Logical column 1, shifted
              KeyEntry SR           ; 1/X
              KeyEntry RDNI         ; RDN
              .con    0x20f         ; ASN
              .con    0             ; right half of enter key
              .con    0x2a8         ; SF
              .con    0             ; 4
              KeyEntry AND        ; 1  (FIX key)
              KeyEntry FLOAT        ; 0

              ;; Logical column 2
              .con    0x10c         ; SQRT  (C digit)
              KeyEntry Decimal      ; SIN
              .con    0             ; STO
              KeyEntry NEG          ; CHS
              .con    0x108         ; 8
              .con    0x105         ; 5
              .con    0x102         ; 2
              .con    0             ; decimal point

              ;; Logical column 2, shifted
              KeyEntry RL           ; SQRT
              .con    0             ; SIN
              .con    0x2cf         ; LBL
              KeyEntry NOT          ; CHS
              .con    0x2a9         ; CF
              .con    0             ; 5
              KeyEntry OR           ; 2
              KeyEntry LASTIX       ; decimal point (LastX)

              ;; Logical column 3
              .con    0x10d         ; LOG   (D digit)
              KeyEntry Octal        ; COS
              .con    0             ; RCL
              KeyEntry WINDOW       ; EEX
              .con    0x109         ; 9
              .con    0x106         ; 6
              .con    0x103         ; 3
              .con    0x205         ; R/S

              ;; Logical column 3, shifted
              KeyEntry RR           ; LOG
              KeyEntry RLC          ; COS
              .con    0x2d0         ; GTO
              .con    0x285         ; EEX
              .con    0x2ac         ; FS?
              KeyEntry XOR          ; 6
              KeyEntry XOR          ; 3
              KeyEntry WSIZE        ; R/S

              ;; Logical column 4
              .con    0x10e         ; LN   (E digit)
              KeyEntry Binary       ; TAN
              .con    0x208         ; SST
              .con    0x1ff         ; BACKARROW
              .con    0x20c         ; MODE ALPHA
              .con    0x20c         ; MODE PRGM
              .con    0x30c         ; MODE USER
              .con    0             ; OFF key special

              ;; Logical column 4, shifted
              KeyEntry ASR          ; LN
              KeyEntry RRC          ; TAN
              .con    0x207         ; BST
              KeyEntry CLIX         ; BACKARROW
              .con    0x20c         ; MODE ALPHA
              .con    0x20c         ; MODE PRGM
              .con    0x30c         ; MODE USER
              .con    0             ; OFF key special


              .section Code

              ;; Align Shift1 to allow GSB256 to be used
              ;; This is done to save one subroutine level as
              ;; RXQ uses +1 and when coming from Div10, we
              ;; do not have that to spare.
              ;; It also makes it run a bit faster as an
              ;; extra bonus.
              .align  256
Shift1:       bcex                  ; shift one left
              c=c+c   x
              acex
              c=c+c
              gonc    2$
              a=a+1   x
2$:           acex
              bcex
              rtn

Mul10:        gosub   GSB256        ; Shift1   *2
              acex
              n=c                   ; save temp in N
              acex
              c=b                   ; save upper temp in B[5:3]
              rcr     3
              bcex    x
              rcr     -3
              bcex
              gosub   GSB256        ; Shift1   X * 4
              gosub   GSB256        ; Shift    X * 8
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


Sum2:         .macro
              acex
              c=c+c
              acex
              c=c+c
              gonc    1$
              a=a+1
1$:
              .endm

              .section Code
              .align  256
accBCD:       cnex                  ; N= digit to add
              acex                  ; A= upper part
              cmex                  ; M= old A, C= low part

              setdec
              Sum2                  ; Sum * 16
              Sum2
              Sum2
              Sum2

              acex                  ; A= low part
              cnex                  ; save N, get digit

              c=0     x
              c=0     m
              rcr     -1
              c=c+1                 ; BCD convert digit
              c=c-1

              c=a+c                 ; add to sum
              gonc    20$
              cnex
              c=c+1
              cnex
20$:          cmex
              acex
              sethex
              rtn


Div10LCD:     c=regn  14
              rcr     12
              cstex
              ?st=1   Flag_2        ; signed mode?
              gonc    6$            ; no
              cstex

              rxq     getSign
              ?c#0    s
              gonc    7$            ; positive
              ?st=1   Flag_UpperHalf
              goc     5$
                                    ; negate with sign in low part
              c=m                   ; get carry pos
              c=c-1                 ; make mask
              acex                  ; A=mask, C= low part
              c=-c                  ; C= negated low part
              nop
              c=c&a                 ; mask
4$:           acex
              s0=0                  ; remember negative
              goto    7$

5$:           c=m                   ; negate with sign in upper part
              c=c-1
              abex
              acex
              c=-c-1  x             ; invert bits in upper part
              acex
              c=c&a                 ; mask upper part
              abex
              acex
              c=-c                  ; negate lower part
              goto    4$

6$:           cstex                 ; restore flags
7$:           c=0
              m=c
              n=c
              ?b#0    x
              gonc    30$
              c=b
              rcr     2
              gosub   GSB256        ; accBCD
              c=b
              rcr     1
              gosub   GSB256        ; accBCD
8$:           pt=     0
10$:          acex    s
              asl
              gosub   GSB256        ; accBCD
              dec pt
              ?pt=    0
              gonc    10$

              gosub   CLLCDE

              c=n
              bcex                  ; B= high part
              c=m
              a=c                   ; A= low part
              c=st                  ; save ST in G
              cgex                  ; handle window
              st=c
              rcr     1

15$:          c=c-1   s
              goc     16$
              m=c                   ; save counter
              acex                  ; right shift 9 digits
              pt=     8
              c=0     wpt
              rcr     9             ; low part
              acex
              c=b
              rcr     -5            ; upper part
              c=c|a                 ; combine
              acex
              b=0                   ; clear upper part
              c=m                   ; load counter again
              goto    15$

30$:          pt=     8             ; test lower 32 bits
              c=0
              lc      1
              c=c-1
              nop
              c=c&a
              ?a#c                  ; values > 32 bits?
              goc     8$            ; yes, do all 14 digits
              pt=     8             ; no, settle for 8 digits
              acex
              rcr     -6            ; left align A
              acex
              goto    10$


16$:          ?b#0                  ; check for digit above window
              goc     18$           ; yes
              b=a
              pt=     8
              b=0     wpt
              ?b#0
              gonc    19$           ; no

18$:          s7=1                  ; set flag for digits above

19$:          pt=     0
              lc      8             ; show 9 (8+1) digits
              rcr     1
              pt=     0
20$:          ldi     0x30
              c=a+c   pt
              srsabc
              asr
              ?s7=1                 ; digit above?
              goc     22$           ; yes
              ?a#0                  ; no, are we out of digits now?
              gonc    25$           ; yes
22$:          c=c-1   s
              gonc    20$

25$:          cstex
              cgex                  ; save dot info in G
              cstex                 ; restore ST
              ?s0=1                 ; positive?
              goc     26$           ; yes
              ldi     '-'           ; no, negative
              srsabc
              s0=1                  ; restore flag
              rtn
26$:          frsabc
              rtn


              .section Tail
;;; ----------------------------------------------------------------------
;;;
;;; Poll vector handling.
;;;
;;; We need to reclaim our buffer at power on. Also reset all entry in
;;; progress flags as all such things are reset when the HP41 goes to
;;; sleep.
;;;
;;; We use the I/O poll vector to do several things. It maintains the
;;; integer display when the previous event was not one of our own
;;; actions. We also handle the program edit mode here, displaying
;;; semi-merged steps as combined instructions as well as fixing up
;;; entered semi-merged instructions.
;;; As I/O poll is called during partial key entry, we are not allowed
;;; to use more than one sub-routine level if partial key is active
;;; (unless we decide to end it).
;;; We take a first stage look at the situation here to judge the current
;;; status. Return quickly partial key entry is active or some other
;;; activity that we quickly can tell we do not need to do anything
;;; further. Otherwise, we take a longer jump back to do the more in
;;; depth processing.
;;;
;;; ----------------------------------------------------------------------


DeepWake:     n=c
              rxq     chkbuf
              goto    pollret       ; (P+1) not found
              c=c+1   s             ; (P+2) reclaim it

              cstex
              st=0    IF_DigitEntry ; end digit entry
              cstex

              cstex
              st=0    IF_Argument   ; not looking for argument
              cstex

              data=c
              c=0
              dadd=c
pollret:      c=n
RMCK10_LJ:    golong  RMCK10

rpollio:      ?s13=1                ; running?
              goc RMCK10_LJ
              n=c                   ; save C for ROMCHK
              c=regn  d             ; get flags
              c=c+c   xs
              c=c+c   xs
              goc     pollret       ; Data entry in progress
              c=c+c   xs
              goc     pollret       ; Partial key entry in progress
              ?s7=1                 ;
              goc     pollret       ; Alpha mode
              rgo     pollio


;;; **********************************************************************
;;;
;;; Poll vectors, module identifier and checksum
;;;
;;; **********************************************************************

              .con    0             ; Pause
              .con    0             ; Running
              .con    0             ; Wake w/o key
              .con    0             ; Powoff
              goto    rpollio       ; I/O
              goto    DeepWake      ; Deep wake-up
              .con    0             ; Memory lost
              .text   "A1RP"        ; Identifier PR-1A
              .con    0             ; checksum position
