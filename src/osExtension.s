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
              goc     deepWake

lightWake:    gosub   PACH11
              ldi     8             ; I/O service
              gosub   ROMCHK
              chk kb
              golc    0x1a6
              golong  0x18a


deepWake:     golong  DSWKUP+2
