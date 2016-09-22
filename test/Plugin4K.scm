(define memories
  '((memory LB-TEST (position independent) (bank 1) (address (#x0 . #xFFF))
              ;; Comment: Need KeyTable at a specific location
            (section (ID FAT FATEND #x0) Code RPN (TAIL #xFF4))
            (checksum #xFFF hp41)
            (fill 0))))
