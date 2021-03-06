(define memories
  '((memory Ladybug1 (position independent)
            (bank 1) (address (#x0 . #xFFF))
            (section (FAT #x0) Code Code1 KeyTable LadybugSecondary1
                     (BankSwitchers1 #xFC3)
                     (Legal7 #xCDD)
                     (Shell #xC00)
                     (LadybugFC2 #xFC2)
                     (Tail #xFDB))
            (checksum #xFFF hp41)
            (fill 0))
    (memory Ladybug2 (position independent)
            (bank 2) (address (#x0 . #xFFF))
            (section (Bank2Header #x0) Code2 LadybugSecondary2
                     (BankSwitchers2 #xFC3) (Tail2 #xFF4))
            (checksum #xFFF hp41)
            (fill 0))
    ;; Boost
    (memory Boost1 (position independent)
            (bank 1) (address (#x0 . #xFFF))
            (section (BoostFAT #x0) BoostCode BoostCode1 BoostTable
                     BoostSecondary1
                     (ExtensionHandlers #xF00)
                     (CAT7Shell #xF04)
                     (CatShell #xF0C)
                     (DelayShell #xF14)
                     (KeyInputShell #xF1C)
                     (BoostBankSwitchers1 #xFC3)
                     (BoostLegal7 #xCDD)
                     RPN (BoostFC2 #xFC2) (BoostPoll #xFCE) (BoostPollPart2 #xFB6))
            (checksum #xFFF hp41)
            (fill 0))
    (memory Boost2 (position independent)
            (bank 2) (address (#x0 . #xFFF))
            (section (BoostHeader2 #x0) BoostCode2
                     BoostSecondary2
                     (BoostBankSwitchers2 #xFC3)
                     (BoostTail2 #xFF4))
            (checksum #xFFF hp41)
            (fill 0))    ;; Mainframe
    (memory NUT0 (bank 1) (address (#x0 . #xFFF))
            (section (QUAD0 #x0) (QUAD1 #x400) (QUAD2 #x800) (QUAD3 #xC00))
            (checksum #xFFF hp41)
            (fill 0))
    (memory NUT1 (bank 1) (address (#x1000 . #x1FFF))
            (section (QUAD4 #x1000) (QUAD5 #x1400) (QUAD6 #x1800) (QUAD7 #x1C00))
            (checksum #x1FFF hp41)
            (fill 0))
    (memory NUT2 (bank 1) (address (#x2000 . #x2FFF))
            (section (QUAD8 #x2000) (QUAD9 #x2400) (QUAD10 #x2800) (QUAD11 #x2C00))
            (checksum #x2FFF hp41)
            (fill 0))
    (memory XFUNS3 (bank 1) (address (#x3000 . #x3FFF))
            (section PAGE3)
            (checksum #x3FFF hp41)
            (fill 0))
    (memory TIME (bank 1) (address (#x5000 . #x5FFF))
            (section CXTIME)
            (checksum #x5FFF hp41)
            (fill 0))
    (memory XFUNS5 (bank 2) (address (#x5000 . #x5FFF))
            (section PAGE5_2)
            (checksum #x5FFF hp41)
            (fill 0))
    ;; OS4
    (memory OS4 (bank 1) (address (#x4000 . #x4FFF))
            (section (Header4 #x4000) code code1
                     (fixedEntries #x4d00)
                     (keycode #x4a40)
                     (OS4BankSwitchers1 #x4fc3)
                     (NOV64 #x4100)
                     (entry #x4f00)
                     (TailOS4 #x4ffb))
            (checksum #x4FFF hp41)
            (fill 0))
    (memory OS4-2 (bank 2) (address (#x4000 . #x4FFF))
            (section (Header4_2 #x4000)
                     code2
                     (NOV64_B2 #x4100)
                     (OS4BankSwitchers2 #x4fc3)
                     (TailOS4_2 #x4ffb))
            (checksum #x4FFF hp41)
            (fill 0)))
  )
