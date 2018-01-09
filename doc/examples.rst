********************
Programming examples
********************


This chapter goes through some programming snippets and examples to
give a feeling about how the instructions work.


Left justify
============

To left justify the number, one can take advantage of the sign flag
which will be set when the leftmost bit is set. To avoid an infinite
loop, one need to test the input value in X for zero. The following
code snippet performs a left justify:

.. code-block:: ca65

   TST X     ; set sign and zero flags according to X
   FS? 00    ; zero?
   GTO 00    ; yes, done
   LBL 01    ; no, loop to left justify
    FS? 01   ; negative?
    GTO 00   ; yes, done
    SL  01   ; shift left, setting flags
    GTO 01
   LBL 00
