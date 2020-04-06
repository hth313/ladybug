***********
Limitations
***********

This chapter covers known limitations with the current
implementation.


.. index:: printer

Printer
=======

A printer, especially in trace mode, does not work well with integer
mode.


.. index:: auto assigned keys, keys; auto assigned

Auto assigned keys
==================

The HP-41 performs automatic assignment on the two top row keys to
correspond to labels in the current program. This may slow down
response to such keys significantly.

In integer mode, this feature is disabled as the top row keys serve as
digit entry for hexadecimal values, and you most likely want digit
entry to always be responsive.

If you want to use the auto assign feature, switch to floating point
mode.
