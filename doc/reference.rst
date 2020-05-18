*********************
Instruction reference
*********************

This chapter goes through the instructions provided by Ladybug.

.. index:: mode; flags, mode; setting, operations; mode related

Mode related
============

The following instructions control mode settings. Mode settings are
preserved if you switch out of integer mode and then back again.

Signed mode and zero filling are controlled by flags that are shared
between integer and floating point modes. If you change such flag in
floating point mode, it will affect the behavior in integer mode as
well.


INTEGER
-------

.. index:: integer mode, mode; integer

Switch to integer mode. The first time you enter integer mode the
word size is set to 16 and the number base is 16 (hexadecimal).

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


EXITAPP
-------
.. index:: float mode, mode; float, exit

Leave integer mode by exiting Ladybug and switching back to
floating point mode. This restores the keyboard and display to its
normal floating point behavior.

Technically it leaves the current active application shell and goes
back to the shell that was active before it. The very last such
shell is the standard calculator behavior.

Integer instructions still work when the Ladybug application is
inactive. What happens is that the Ladybug display and keyboard
overrides are no longer active.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


BINS
----
.. index:: binary base, base; binary


Enable base 2, work with binary integers.

Affected flags
^^^^^^^^^^^^^^

None (stack lift flag left unchanged).

OCTS
-----
.. index:: octal base, base; octal

Enable base 8, work with octal integers.

Affected flags
^^^^^^^^^^^^^^

None (stack lift flag left unchanged).


DECS
----
.. index:: decimal base, base; decimal

Enable base 10, work with decimal integers.

Affected flags
^^^^^^^^^^^^^^

None (stack lift flag left unchanged).


HEXS
----
.. index:: hexadecimal base, base; hexadecimal

Enable base 16, work with hexadecimal integers.

Affected flags
^^^^^^^^^^^^^^

None (stack lift flag left unchanged).


WSIZE _
--------
.. index:: word size; setting, setting; word size

Set word size.

Affected flags
^^^^^^^^^^^^^^

None (stack lift flag left unchanged).


WSIZE?
------

.. index:: word size; inspecting, inspecting word size

Return the active word size to X register.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


SF 02
-----
.. index:: 2-complement mode, mode; 2-complement, mode; signed, signed mode

Enable signed 2-complement mode.


CF 02
-----
.. index:: unsigned mode, mode; unsigned


Enable unsigned mode (disable signed 2-complement mode).


SF 05
-----
.. index:: zero fill mode, mode; zero fill, setting; zero fill

Enable zero fill mode.


CF 05
-----
.. index:: zero fill mode, mode; zero fill, clearing zero fill

Disable zero fill mode.


Stack operations
================
.. index:: stack operations, operations; stack

The integer stack shares the stack with the ordinary floating point
stack. As integers larger than 56 bits will not fit in a stack
register, extra storage on the side (the I/O buffer) is used to keep
track of the extra bits. Ladybug provides a set of instructions that
duplicate already existing stack manipulation operations, but which
takes the stack register extension parts in account.

.. hint::
   If you work in word size of 56 or less, you can actually use the
   corresponding built in stack manipulation instructions intended for
   floating point numbers instead. This is especially useful in a
   program as they takes less space compared to the integer mode
   counterparts.


ENTERI
------

Lift the stack, duplicate the number in X to Y and disable stack lift.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag disabled.


CLXI
----

Clear X and disable stack lift.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag disabled.


X<>YI
-----

Swap X and Y registers.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


LASTXI
------

Recall the last X register (L).

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.

RDNI
----

Rotate the stack down one step.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


R^I
---

Rotate the stack up one step.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


Arithmetic operations
=====================
.. index:: arithmetic operations, operations; arithmetic

Instructions that perform some kind of calculation, i.e. arithmetic,
logical and bit manipulation instructions, consume their arguments and
place the result on the stack. The original value of X is placed in
the L (Last X) register. If the instruction consumes more arguments
from the stack than it produces, the stack drops and the contents of
the top register (T) is duplicated.


ADD
---

Add X with Y, the result is placed in X and the stack drops.

Affected flags
^^^^^^^^^^^^^^

Sign, zero, overflow and carry flags set according to the result.
Stack lift flag enabled.


SUB
---

Subtract X from Y, the result is placed in X and the stack drops.

Affected flags
^^^^^^^^^^^^^^

Sign, zero, overflow and carry flags set according to the result.
Stack lift flag enabled.


MUL
---

   Multiply X with Y, the result is placed in X and the stack drops.

Affected flags
^^^^^^^^^^^^^^

Sign, zero and overflow flags set according to the result. The sign
flag will have the correct value of the real result. Carry is not
affected.
Stack lift flag enabled.


DIV
---

Divide Y by X, the quotient is placed in X and the stack drops.

Affected flags
^^^^^^^^^^^^^^

Sign, zero and overflow flags set according to the result. The sign
flag will have the correct value of the real result. Carry set if
remainder is non-zero, cleared otherwise.
Stack lift flag enabled.


RMD
---

Divide Y by X, the remainder is placed in X and the stack drops.

Affected flags
^^^^^^^^^^^^^^

Sign, zero and overflow flags set according to the result. Carry is not affected.
Stack lift flag enabled.


NEG
---

Negate X.

In signed mode the smallest negative number does not have a
corresponding positive counterpart. Negating that number ends up
with the same number as the input. In this case the overflow flag
is set to indicate that the result could not be represented. For
all other signed values, the input is negated and the overflow flag
is cleared.

In unsigned mode, the number is negated, giving the same bit
pattern as would result in signed mode. However, as all numbers are
considered positive, a negative number can not be represented and
the overflow flag will be set to indicate this. The only case you
will not get an overflow flag is when the input is 0 (as 0 negated
is also 0).

Affected flags
^^^^^^^^^^^^^^

Sign, zero and overflow flags set according to the result.
Stack lift flag enabled.


ABSI
----

Absolute value of X.

In signed mode, negative numbers are negated to make them
positive. As negation does the same code as ``NEG``, see ``NEG``
for a discussion on how the smallest negative number behaves.

In unsigned mode all numbers are considered positive, and negation
is never done. The overflow flag is always cleared in this case.

Affected flags
^^^^^^^^^^^^^^

Sign, zero and overflow flags set according to the result.
Stack lift flag enabled.


Double operations
=================
.. index:: operations; double precision, double precision

Multiplication and divide are also available in double versions.

DMUL
----

Multiply X with Y, the double result is placed in X and Y (high part in X).

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the result. The sign flag will
have the correct value of the result. Overflow flag is cleared.
Stack lift flag enabled.


DDIV
----

Divide the double value in Z and Y (high part in Y) by X. The
double quotient result is placed in X and Y (high part in X). Stack
drops one step.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the result. Overflow flag is
cleared. Carry set if remainder is non-zero, cleared otherwise.
Stack lift flag enabled.

DRMD
----

Divide the double value in Z and Y (high part in Y) by X. The
single precision remainder result is placed in X. Stack drops two
steps.

Affected flags
^^^^^^^^^^^^^^

Sign, zero and overflow flags set according to the result. Carry is not affected.
Stack lift flag enabled.

Logical operations
==================
.. index:: logical operations, operations; logical

AND
---

Logical AND between X and Y, result is placed in X and the stack drops.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the result.
Stack lift flag enabled.

OR
--

Logical OR between X and Y, result is placed in X and the stack drops.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the result.
Stack lift flag enabled.

XOR
---

Logical XOR between X and Y, result is placed in X and the stack drops.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the result.
Stack lift flag enabled.


NOT
---

Bitwise NOT (negation) X, makes all bits the opposite.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the result.
Stack lift flag enabled.


Shift operations
================
.. index:: rotation operations, shift operations, operations; shifts, operations; rotates


SL _
----

Shift X left by the given number of steps. The most recently
shifted out bit is placed in the carry bit.

Postfix argument
^^^^^^^^^^^^^^^^

The number of steps to shift, or a register indirection to a nibble
register which holds the number of steps to shift. Valid range is
0--64.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the result. Carry holds the
last shifted out bit.
Stack lift flag enabled.


SR _
----

Shift X right by the given number of steps. The most recently shifted
out bit is placed in the carry bit.

Postfix argument
^^^^^^^^^^^^^^^^

The number of steps to shift, or a register indirection to a nibble
register which holds the number of steps to shift. Valid range is
0--64.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the result. Carry holds the
last shifted out bit.
Stack lift flag enabled.


RL _
----

Rotate X left by the given number of steps. Bits going out at the
left end appear again at the right hand side. In other words, bits
are rotated around. The most recently bit that wrapped around is
also copied to the carry.

Postfix argument
^^^^^^^^^^^^^^^^

The number of steps to shift, or a register indirection to a nibble
register which holds the number of steps to shift. Valid range is
0--64.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the result. Carry holds the
last shifted out bit.
Stack lift flag enabled.


RR _
----

Rotate X right by the given number of steps. Bits going out at the
right end appear again at the left hand side. In other words, bits
are rotated around. The most recently bit that wrapped around is
also copied to the carry.

Postfix argument
^^^^^^^^^^^^^^^^

The number of steps to shift, or a register indirection to a nibble
register which holds the number of steps to shift. Valid range is
0--64.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the result. Carry holds the
last shifted out bit.
Stack lift flag enabled.


RLC _
-----

Rotate X left by the given number of steps through carry. A bit
that is rotated out goes to the carry, the previous carry is
rotated in at the right hand side.

Postfix argument
^^^^^^^^^^^^^^^^

The number of steps to shift, or a register indirection to a nibble
register which holds the number of steps to shift. Valid range is
0--64.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the result. Carry holds the
last shifted out bit.
Stack lift flag enabled.


RRC _
-----

Rotate X right by the given number of steps through carry. A bit
that is rotated out goes to the carry, the previous carry is
rotated in at the left hand side.

Postfix argument
^^^^^^^^^^^^^^^^

The number of steps to shift, or a register indirection to a nibble
register which holds the number of steps to shift. Valid range is
0--64.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the result. Carry holds the
last shifted out bit.
Stack lift flag enabled.


ASR _
-----

Aritmetic right shift. This duplicates the sign bit as the number
is shifted right. The most recent shifted out bit is placed in the
carry.

Postfix argument
^^^^^^^^^^^^^^^^

The number of steps to shift, or a register indirection to a nibble
register which holds the number of steps to shift. Valid range is
0--64.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the result. Carry holds the
last shifted out bit.
Stack lift flag enabled.



Bitwise operations
===================
.. index:: bitwise operations, operations; bitwise


MASKL _
-------

Create a left justified bit mask (all bits set), of the width
specified in its argument.

A width of 0 results in 0, a width of 64 results in all bits set
regardless of the active word size.

Postfix argument
^^^^^^^^^^^^^^^^

The width of the mask, or a register indirection to a nibble
register which holds the width of the mask. Valid range is 0--64.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


MASKR _
-------

Create a right justified bit mask (all bits set), of the width
specified in its argument.

A width of 0 results in 0, a width of 64 results in all bits set
regardless of the active word size.

Postfix argument
^^^^^^^^^^^^^^^^

The width of the mask, or a register indirection to a nibble
register which holds the width of the mask. Valid range is 0--64.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


SEX _
-----
.. index:: sign extension


Sign extend the value in X by the word width specified in its argument.

.. code-block:: ca65

   SEX 08

Will interpret the value in X as a signed 8-bit value. If it is
negative, the value is sign extended to fit the active word size.

Postfix argument
^^^^^^^^^^^^^^^^

A word size, or a register indirection to a nibble register which
holds the word size. Valid range is 1--64.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the result.
Stack lift flag enabled.


CB _
----

Clear a single bit in X as specified by the argument.

Postfix argument
^^^^^^^^^^^^^^^^

A bit number, or a register indirection to a nibble register which
holds the bit number. Valid range is 0--63.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the result.
Stack lift flag enabled.


SB _
----

Set a single bit in X as specified by the argument.

Postfix argument
^^^^^^^^^^^^^^^^

A bit number, or a register indirection to a nibble register which
holds the bit number. Valid range is 0--63.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the result.
Stack lift flag enabled.


B? _
----

Test if a bit of X is set, skip next instruction in a program if
the bit is not set. In keyboard mode, the result is displayed as
``YES`` or ``NO``.

Postfix argument
^^^^^^^^^^^^^^^^

A bit number, or a register indirection to a nibble register which
holds the bit number. Valid range is 0--63.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


BITSUM _
--------

Count the number of bits in X and place that number in X.

Postfix argument
^^^^^^^^^^^^^^^^

A register, or a register indirection to a nibble register.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the result.
Stack lift flag enabled.


Compare and test
================
.. index:: compare operations, operations; compares

Comparing values with Ladybug offers a way that is more like it works
on machine instruction sets, which differs from what you may be used
to on an HP calculator. Instead of comparing X to Y, or X to 0, you
test flags set by the previous operation. There are three variants to
this:

#. To compare two numbers, use the ``CMP`` instruction which works
   similar to a compare  on a microprocessor. It performs a
   subtraction, setting flags according to the result and discards the
   numerical result. The actual comparison between two numbers starts
   with a  ``CMP``, followed by a flag conditional operation which
   conditionally skips the following instruction.

#. To compare to 0, use the ``TST`` instruction followed by a test of flag 0.

#. Furthermore, arithmetic and bit manipulation instructions set flags
   according to the result, making it possible to just test suitable
   flags after such operation.

There is now also a set of HP-41 compare instructions (``=I``, ``≠I``,
``<I`` and ``<=I``). In program mode they either execute the following
line or skips it, depending on the outcome of the test. In keyboard
mode ``YES`` or ``NO`` is displayed. Current sign mode is obeyed.

Here are the provided instructions that are related to comparing values:


CMP _
-----

The argument specifies a register value that is subtracted
from X. The result is dropped, but flags are set according to the
result. Useful for comparing X to any value.

Postfix argument
^^^^^^^^^^^^^^^^

A register, or a register indirection to a nibble register.

Affected flags
^^^^^^^^^^^^^^

Sign, zero, overflow and carry flags are set according to result of
the subtraction.
Stack lift flag enabled.


TST _
-----

The argument specifies a register value that will affect the sign
and zero flags. Useful for testing if any register value is zero,
positive or negative.

Postfix argument
^^^^^^^^^^^^^^^^

A register, or a register indirection to a nibble register.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the value in the register.
   Stack lift flag enabled.


GE?
---

Perform next instruction in a program if the previous ``CMP``
instruction indicates that X is greater than or equal to the other
value, otherwise skip next line. Current sign mode is obeyed. In
keyboard mode, ``YES`` or ``NO`` is displayed.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


GT?
---

Perform next instruction in a program if the previous ``CMP``
instruction indicates that X is greater than the other value,
otherwise skip next line. Current sign mode is obeyed. In keyboard
mode, ``YES`` or ``NO`` is displayed.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


LE?
---

Perform next instruction in a program if the previous ``CMP``
instruction indicates that X is less than or equal to the other
value, otherwise skip next line. Current sign mode is obeyed. In
keyboard mode, ``YES`` or ``NO`` is displayed.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


LT?
---

Perform next instruction in a program if the previous ``CMP``
instruction indicates that X is less than the other value,
otherwise skip next line. Current sign mode is obeyed. In keyboard
mode, ``YES`` or ``NO`` is displayed.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


=I _ _
------

Test if two register operands are equal

Two postfix arguments
^^^^^^^^^^^^^^^^^^^^^

This function performs an equality compare between two registers.
In program mode it skips over the next instruction if the two
operands are not equal. In keyboard mode it displays ``YES`` or
``NO``.
This is a secondary function.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


≠I _ _
------

Test if two register operands are not equal

Two postfix arguments
^^^^^^^^^^^^^^^^^^^^^

This function performs an equality compare between two registers.
In program mode it skips over the next instruction if the two
operands are equal. In keyboard mode it displays ``YES`` or
``NO``.
This is a secondary function.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


<I _ _
------

Test if the first register operand is less than the second
register operand

Two postfix arguments
^^^^^^^^^^^^^^^^^^^^^

This function performs an less-than compare between two
registers, obeying current sign mode.
In program mode it skips over the next instruction if the test
is not true. In keyboard mode it displays ``YES`` or ``NO``.
This is a secondary function.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


<=I _ _
-------

Test if the first register operand is less than or equal to the
second register operand

Two postfix arguments
^^^^^^^^^^^^^^^^^^^^^

This function performs an less-than-or-equal compare between two
registers, obeying current sign mode.
In program mode it skips over the next instruction if the test
is not true. In keyboard mode it displays ``YES`` or ``NO``.
This is a secondary function.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


.. note::

   The two operand compare operations takes allows for comparing two
   arbitrary register operands. If you want to compare greater-than,
   simply swap the operands and use the corresponding less-than function.


Memory related instructions
===========================
.. index:: memory operations, operations; memory

LDI _
-----

Load X from the specified register.

Postfix argument
^^^^^^^^^^^^^^^^

A register, or a register indirection to a nibble register.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the value loaded.
Stack lift flag enabled.


STI _
-----

Store X in the specified register.

Postfix argument
^^^^^^^^^^^^^^^^

A register, or a register indirection to a nibble register.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


<>I _ _
-------

Exchange between two registers

Two postfix arguments
^^^^^^^^^^^^^^^^^^^^^

This function performs a register to register exchange, using
arbitrary registers, or register indirect operands.
This is a secondary function.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


VIEWI _
-------

View the specified register without affecting the stack.

Postfix argument
^^^^^^^^^^^^^^^^

A register, or a register indirection to a nibble register.
This is a secondary function.

Affected flags
^^^^^^^^^^^^^^

None


DECI _
------

Subtract one from the register specified in the argument.

Postfix argument
^^^^^^^^^^^^^^^^

A register, or a register indirection to a nibble register.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the new value.
Stack lift flag enabled.


DSZI _
------

Subtract one from the register specified in the argument, skip next
instruction if the result is zero. This is useful for implementing
loops. Flags are not affected.

Postfix argument
^^^^^^^^^^^^^^^^

A register, or a register indirection to a nibble register.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


INCI _
------

Add one to the register specified in the argument.


Postfix argument
^^^^^^^^^^^^^^^^

A register, or a register indirection to a nibble register.

Affected flags
^^^^^^^^^^^^^^

Sign and zero flags set according to the new value.
Stack lift flag enabled.


CLRI _
------

Clear the contents of the specified register.

Postfix argument
^^^^^^^^^^^^^^^^

A register, or a register indirection to a nibble register.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.


Miscellaneous instructions
==========================

.. index:: alpha register operations, operations; alpha register

ALDI _
------

Append a register value to the alpha register obeying the current
word size, selected base, active sign mode and zero fill flag.

Postfix argument
^^^^^^^^^^^^^^^^

A register, or a register indirection to a nibble register.

Affected flags
^^^^^^^^^^^^^^

Stack lift flag enabled.



WINDOW _
--------
.. index:: window, display windows


This instruction makes it possible to view different parts of a
number that is too large to show in the display. Dots around the
base character indicates whether there are digits not shown on
either side of the currently shown window. This is a
non-programmable instruction to make it possible to inspect numbers
(literals) in program mode as well.

Postfix argument
^^^^^^^^^^^^^^^^

The window number, 0--7. The rightmost window is 0, which is what
is shown by default.
