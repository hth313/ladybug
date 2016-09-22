#include "mainframe.i"

;;; Just make it look empty in case the bank is left enabled.
              .section Bank2Header
              nop
              nop

              .section Tail2
;;; **********************************************************************
;;;
;;; Poll vectors, module identifier and checksum
;;;
;;; This is a banked ROM and poll vectors are not expected to be called.
;;; If they are, we switch back to to bank 1.
;;;
;;; **********************************************************************

10$:          enrom1
              golong  RMCK10

              goto    10$           ; Pause
              goto    10$           ; Running
              goto    10$           ; Wake w/o key
              goto    10$           ; Powoff
              goto    10$           ; I/O
              goto    10$           ; Deep wake-up
              goto    10$           ; Memory lost
                                    ; Identifier PR-1A
              .con    1             ; A
              .con    '0'           ; 0
              .con    0x202         ; B (bank switched)
              .con    0x0c          ; L
              .con    0             ; checksum position
