#include "mainframe.h"

              .public `FAT entry: LIFT?`
              .public `FAT entry: NOLIFT?`
              .public `FAT entry: NOLIFT`
              .section ID
              .con    17            ; XROM
              .con    .fatsize FatEnd ; number of entry points
              .fat    Header
`FAT entry: LIFT?`:
              .fat    stackLift
`FAT entry: NOLIFT?`:
              .fat    noStackLift
`FAT entry: NOLIFT`:
              .fat    disableStackLift

              .section FATEND
FatEnd:       .con    0, 0


              .section Code
              .name "-LB TEST 1A"
Header:       rtn

              .name   "NOLIFT"
disableStackLift:                   ; disable stack lift without disturbing stack
              s11=0                 ; clear push flag
              golong  NFRC          ; do not affect push flag (cannot RTN here!!)

              .name   "LIFT?"
stackLift:    s7=0                  ; test if stack lift enabled
              ?s11=1
              goc     toNOSKP
              goto    toSKP

              .name   "NOLIFT?"
noStackLift:  s7=0                  ; test is stack lift disabled
              ?s11=1
toNOSKP:      golnc   NOSKP
toSKP:        golong  SKP

              .section TAIL
              .con    0             ; Pause
              .con    0             ; Running
              .con    0             ; Wake w/o key
              .con    0             ; Powoff
              .con    0             ; I/O
              .con    0             ; Deep wake-up
              .con    0             ; Memory lost
              .text   "A1TL"        ; Identifier LT-1A
              .con    0             ; checksum position
