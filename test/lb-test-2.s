              .section ID2
              .con    0x3ff         ; Must be non-zero or the mainframe
                                    ; may decide to reset program pointer
                                    ; to top of RAM.
              .con    0

              .section TAIL2
              .con    0             ; Pause
              .con    0             ; Running
              .con    0             ; Wake w/o key
              .con    0             ; Powoff
              .con    0             ; I/O
              .con    0             ; Deep wake-up
              .con    0             ; Memory lost
              .text   "A02T"        ; Identifier T2-0A
              .con    0             ; checksum position
