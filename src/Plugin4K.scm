(define memories
  '((memory Page4K (position independent) (bank 1) (address (#x0 . #xFFF))
              ;; Comment: Need KeyTable at a specific location
            (section (FAT #x0) Code (CodeQ0 (#x0 . #x3FF))
                     (KeyTable #xC00) (Tail #xFD4))
            (checksum #xFFF hp41)
            (fill 0))))
