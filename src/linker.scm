(define memories
  '((memory Ladybug1 (position independent)
            (bank 1) (address (#x0 . #xFFF))
            (section (FAT #x0) Code Code1 KeyTable LadybugSecondary1
                     (BankSwitchers1 #xFC3)
                     (Legal7 #xCDD)
                     (Shell #xC00)
                     (LadybugFC2 #xFC2)
                     (Tail #xFDF))
            (checksum #xFFF hp41)
            (fill 0))
    (memory Ladybug2 (position independent)
            (bank 2) (address (#x0 . #xFFF))
            (section (Bank2Header #x0) Code2 LadybugSecondary2
                     (BankSwitchers2 #xFC3) (Tail2 #xFF4))
            (checksum #xFFF hp41)
            (fill 0))))
