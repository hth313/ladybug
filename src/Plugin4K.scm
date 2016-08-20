(define memories
  '((memory Page4K (position independent) (bank 1) (address (#x0 . #xFFF))
              ;; Comment: Need KeyTable at a specific location
            (section (FAT #x0) Code (KeyTable #xC00) (Tail #xFD4))
            (checksum #xFFF hp41)
            (fill 0))))
