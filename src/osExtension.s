;;; **********************************************************************
;;;
;;;           OS extension for the HP-41 series.
;;;
;;;
;;; **********************************************************************

#include "mainframe.i"

;;; ----------------------------------------------------------------------
;;;
;;; Main take over entry point.
;;;
;;; ----------------------------------------------------------------------

              .section Header4
              c=stk                 ; inspect return address
              rcr     1             ; C.XS= lower nibble
              c=c+c   xs
              golc    DSWKUP+2      ; deep wake up

lightWake:    ldi     0x2fd         ; PACH11
              dadd=c                ; enable nonexistent data chip 2FD
              pfad=c                ; enable display
              flldc                 ; non-destructive read
              gosub   MEMCHK
              ldi     8             ; I/O service
              gosub   ROMCHK
              chk kb
              golc    0x1a6
              golong  0x18a
