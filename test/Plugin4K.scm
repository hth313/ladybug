(define memories
  '((memory LB-TEST (position independent) (bank 1) (address (#x0 . #xFFF))
            (section (ID FAT FATEND #x0) Code RPN (TAIL #xFF4))
            (checksum #xFFF hp41)
            (fill 0))
    (memory LB-TEST-2 (position independent) (bank 1) (address (#x1000 . #x1FFF))
            (section (ID2 #x1000) Code RPN (TAIL2 #x1FF4))
            (checksum #x1FFF hp41)
            (fill 0))
  ))
