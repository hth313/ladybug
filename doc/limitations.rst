***********
Limitations
***********

This chapter covers known limitations in the current implementation.


.. index:: clock display

Clock display
=============

The Time module and the HP-41CX offers a running clock display, which does not work with integer mode. The clock starts, but immediately stops updating. To use the clock, switch to floating point mode.


.. index:: printer

Printer
=======

A printer, especially in trace mode, does not work well with integer mode.


.. index:: pause operation, operations; pause

Pause
=====

If the built in ``PSE`` (pause) instruction is used, the calculator switches to floating point mode while it is executing. To get a pause that works in integer mode, use the supplied ``PSEI`` instruction. It has one limitation compared to the original ``PSE`` instruction. If you key in something that causes an error, execution will resume after the pause expires, instead of stopping the program.


.. index:: auto assigned keys, keys; auto assigned

Auto assigned keys
==================

The HP-41 performs automatic assignment on the two top row keys to correspond to labels in the current program. This may slow down operation significantly.

In integer mode, this feature is disabled as the top row keys serve as digit entry for hexadecimal values, and you most likely want digit entry to be responsive.

If you want to use this feature, switch to floating point mode.
