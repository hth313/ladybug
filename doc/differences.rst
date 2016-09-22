*************************
Differences to the HP-16C
*************************

Being inspired by the HP-16C there are a lot of similarities between the Ladybug module for the HP-41 and the HP-16C. Apart from the obvious differences, such as form factor, battery life, alpha capabilities on the HP-41 and dedicated decorated keyboard on the HP-16C, there are a lot more subtle differences, which are discussed in this chapter.



.. index:: flags

Flags
=====

Flags are arranged differently. The reason for this is the annunciators 0-4 on the HP-41 that we can take advantage of to provide additional feedback compared to the HP-16C. The arrangement was inspired by making it logical, rather than trying to be compatible with the HP-16C.

The sign and zero flags are very common on micro processors and gives additional feedback, being shown on the annunciators. It also allows for implementing compares in a way more similar to micro processors, rather than keeping with the calculator style compares between X and Y (or X and 0).


.. index:: compares

Compares
========

Compares on the HP-16C is done using traditional HP calculator operations, by providing a set of operations that compares between X and Y, and X to 0. Ladybug works more like a micro processor. It provides a ``CMP`` instruction that compares X to any register value and set flags accordingly. After ``CMP`` you can interpret the result using a flag test operation ``FC?``,  ``FS?`` or some of the built in relation test instruction like ``LT?`` and friends.
It is also possible to use the ``TST`` instruction, or rely on the flags set after doing an operation.

.. note::
  ``CMP Y`` subtracts Y from X, which is the opposite order compared to ``SUB``.


Co-existing modes
=================

The HP-16C keeps the floating point and integer modes quite separate. Changing between the modes affect stack contents and word sizes. On the HP-41 the integer mode is basically a keyboard and display shell, the functional behavior remains the same even if you switch mode.

As a result, the mode separation is not as strict and stack register values are not normally pruned when changing mode, as we will discuss next.


.. index:: word size; affecting stack, sign extension

Word size change affecting stack
================================

The HP-16C truncates values on the stack according to the active word size. Changing a word size to a smaller one and then back will not preserve all value bits. Ladybug preserves value bits on the stack.

Increasing the word size in signed mode will cause a sign extension of all registers on the stack with Ladybug. The HP-16C does not perform sign extensions.

Sign extending the stack is the only time when Ladybug goes around and alter all the values on the stack. This is because sign extending tends to be a natural thing to do, as it preserves the numeric value.

The reason that it is not always done, is that the HP-41 at any time can perform floating point operations, and keeping the stack properly masked would be a quite elaborate task that would get in the way with the ability to keep floating point values around. The HP-16C has an easier task here, as it has a more strict separation between floating point mode and integer mode.

In Ladybug, numbers are masked as needed when they are used as input to operations, not because they are laying around somewhere.


.. index:: postfix operands, operands

Postfix operands
================

Ladybug takes advantage of the prompting functions on the HP-41 to allow for accessing stack registers in the same ways as numeric registers. Indirection can also be done on any register, not just the single index register on the HP-16C.


.. index:: zero fill mode, mode; zero fill, setting zero fill

Zero fill mode
==============

With Ladybug, the zero fill mode does not indicate available digits above the current window if they are all zero. The HP-16C will always indicate that there is more to see, even if it just fill 0 digits.

The reason for this difference is that it is believed that instantly knowing if there is anything non-zero to see outside the display is more useful, than to be constantly reminded that the word size is actually larger than what can be shown in a single display.


.. index:: 1-complement mode, mode; 1-complement, signed mode

One complement mode
===================

The one complement mode is not present in Ladybug.


.. index:: windows, display windows

Window display
==============

The window display only provides for moving a full window at a time, not by single digits which is also available on the HP-16C.

The keyboard layout to do this does not require shift keys, which makes it somewhat easier to work with windows with Ladybug, compared to the HP-16C.


.. index:: operations; double precision, double precision

Double divide
=============

Double divide will result in a double quotient. The HP-16C gives a single word quotient, or an error if a double result would have been needed. Giving the full quotient is believed to be more useful, but changes may be needed to HP-16C programs that uses ``DDIV``.


.. index:: status; machine, machine status

Machine status
==============

There is currently no machine status display in Ladybug. Most of the information about the status is already visible in the display, the rest can be queried using ``WSIZE?`` or ``FS? 05`` for zero fill mode.


Square root
===========

Ladybug does not offer an integer square root function, which is present on the HP-16C.


.. index:: floating point conversions, conversions; floating point

Floating point conversions
==========================

There are no support for floating point number conversions built in to Ladybug at this point. It is something that is considered for a future extension.


.. index:: postfix operands, operands; postfix, prompting instructions, instructions; prompting

Prompting instructions
=======================

Ladybug takes full advantage of the prompting facility of the HP-41. Instructions such as ``MASKL`` and ``WSIZE`` prompt for their argument and are not limited to take it from the X register. To get the same behavior as on the HP-16C, use the indirect X postfix argument:

.. code-block:: ca65

   MASKL IND X

Shift operations prompt for the shift count, which makes it unnecessary to have two instructions to implement the same shift operation, as is done on the HP-16C.

.. note::
   No savings would be made by making two instructions, as the default behavior of the semi-merged shift instructions is to shift by 1. In other words, the shift instructions do dual duty as shift by one and shift by arbitrary number of steps.


Left justify
============

Is currently not present in Ladybug.
