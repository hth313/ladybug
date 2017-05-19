***********
Limitations
***********

This chapter covers known limitations with the current implementation.


.. index:: clock display

Clock display
=============

The Time module and the HP-41CX offers a running clock display, which does not work with integer mode. The time is displayed but it does not update. To show the running clock, switch to floating point mode.


.. index:: printer

Printer
=======

A printer, especially in trace mode, does not work well with integer mode.


.. index:: pause operation, operations; pause

Pause
=====

If the built in ``PSE`` (pause) instruction is used, the calculator switches to floating point mode while it is executing. To get a pause that works in integer mode, use the supplied ``PSEI`` instruction. It has one limitation compared to the original ``PSE`` instruction. If you key in something that causes an error, execution will still resume after the pause expires, instead of stopping the program.


.. index:: auto assigned keys, keys; auto assigned

Auto assigned keys
==================

The HP-41 performs automatic assignment on the two top row keys to correspond to labels in the current program. This may slow down response to such keys significantly.

In integer mode, this feature is disabled as the top row keys serve as digit entry for hexadecimal values, and you most likely want digit entry to always be responsive.

If you want to use the auto assign feature, switch to floating point mode.
