(define memories
  '((memory Programmer1 (position independent) (bank 1) (address (#x0 . #xFFF))
              ;; Comment: Need KeyTable at a specific location
            (section (FAT #x0) Code Code1 (CodeQ0 (#x0 . #x3FF))
                     (KeyTable #xC00) (Tail #xFD4))
            (checksum #xFFF hp41)
            (fill 0))
    (memory Programmer2 (position independent) (bank 2) (address (#x0 . #xFFF))
            (section (Bank2Header #x0) Code2 (Tail2 #xFF1))
            (checksum #xFFF hp41)
            (fill 0))))