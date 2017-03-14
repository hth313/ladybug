#include "mainframe.i"

;;; Just make it look empty in case the bank is left enabled.
              .section Bank2Header
              nop
              nop


;;; The tail is in the main module, as shadow relations between different
;;; compilation units are not allowed.
