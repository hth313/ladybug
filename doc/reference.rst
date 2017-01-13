
*********************
Instruction reference
*********************

This chapter goes through the instructions provided by Ladybug.

.. index:: mode; flags, mode; setting, operations; mode related

Mode related
============

The following instructions control mode settings. Mode settings are preserved and restored if you switch out of integer mode and then back again.

Signed mode and zero filling are controlled by flags and are shared between integer and floating point modes. If you change such flag in floating point mode, it will affect the behavior in integer mode as well.


.. index:: integer mode, mode; integer

.. object:: INTEGER

   Switch to integer mode. The first time you enter integer mode the word size is set to 16 and the number base is 16 (hexadecimal).


.. index:: float mode, mode; float

.. object:: FLOAT

   Switch to floating point mode, leaving integer mode. This restores the keyboard and display to its normal floating point behavior.

   Integer instructions in floating point mode still works, but will not display or use the dedicated keyboard.


.. index:: binary base, base; binary

.. object:: BINS

   Enable base 2, work with binary integers.


.. index:: octal base, base; octal

.. object:: OCTS

   Enable base 8, work with octal integers.


.. index:: decimal base, base; decimal

.. object:: DECS

   Enable base 10, work with decimal integers.


.. index:: hexadecimal base, base; hexadecimal

.. object:: HEXS

   Enable base 16, work with hexadecimal integers.


.. index:: word size; setting, setting; word size

.. object:: WSIZE _ _

   Set word size.


.. index:: word size; inspecting, inspecting word size

.. object:: WSIZE?

   Return the active word size to X register.


.. index:: 2-complement mode, mode; 2-complement, mode; signed, signed mode

.. object:: SF 02

   Enable signed 2-complement mode.


.. index:: unsigned mode, mode; unsigned

.. object:: CF 02

   Enable unsigned mode (disable signed 2-complement mode).


.. index:: zero fill mode, mode; zero fill, setting zero fill

.. object:: SF 05

   Enable zero fill mode.


.. index:: zero fill mode, mode; zero fill, clearing zero fill

.. object:: CF 05

   Disable zero fill mode.



.. index:: stack operations, operations; stack

Stack operations
================

The integer stack shares the stack with the ordinary floating point stack. As integers larger than 56 bits will not fit in a stack register, extra storage on the side (the I/O buffer) is used to keep track of the extra bits. Ladybug provides a set of instructions that duplicate already existing stack manipulation operations, but which takes the stack register extension parts in account.

.. hint::
   If you work in word size of 56 or less, you can actually use the corresponding built in stack manipulation instructions intended for floating point numbers instead. This is especially useful in a program as they takes less space compared to the integer mode counterparts.


.. object:: ENTERI

   Lift the stack, duplicate the number in X to Y and disable stack lift.

   .. describe:: Affected flags

   Stack lift flag disabled.


.. object:: CLXI

   Clear X and disable stack lift.

   .. describe:: Affected flags

   Stack lift flag disabled.


.. object:: X<>YI

   Swap X and Y registers.

   .. describe:: Affected flags

   None


.. object:: LASTXI

   Recall the last X register (L).

   .. describe:: Affected flags

   None


.. object:: RDNI

   Rotate the stack down one step.

   .. describe:: Affected flags

   None


.. object:: R^I

   Rotate the stack up one step.

   .. describe:: Affected flags

   None


.. index:: arithmetic operations, operations; arithmetic

Arithmetic operations
=====================

Instructions that perform some kind of calculation, i.e. arithmetic, logical and bit manipulation instructions, consume their arguments and place the result on the stack. The original value of X is placed in the L (Last X) register. If the instruction consumes more arguments from the stack than it produces, the stack drops and the contents of the top register (T) is duplicated as needed.


.. object:: ADD

   Add X with Y, the result is placed in X and the stack drops.

   .. describe:: Affected flags

   Sign, zero, overflow and carry flags set according to the result.


.. object:: SUB

   Subtract X from Y, the result is placed in X and the stack drops.

   .. describe:: Affected flags

   Sign, zero, overflow and carry flags set according to the result.


.. object:: MUL

   Multiply X with Y, the result is placed in X and the stack drops. If the operation overflows, the overflow bit is set. In signed operation, the result sign is always the correct one.

   .. describe:: Affected flags

   Sign, zero and overflow flags set according to the result. The sign flag will have the correct value of the result. Carry is not affected.


.. object:: DIV

   Divide Y by X, the quotient is placed in X and the stack drops.

   .. describe:: Affected flags

   Sign, zero and overflow flags set according to the result. The sign flag will have the correct value of the result. Carry set if remainder is non-zero, cleared otherwise.


.. object:: RMD

   Divide Y by X, the remainder is placed in X and the stack drops.

   .. describe:: Affected flags

   Sign, zero and overflow flags set according to the result. Carry is not affected.


.. object:: NEG

   Negate X.

   In signed mode the smallest negative number does not have a corresponding positive counterpart. Negating that number ends up with the same number as the input. In this case the overflow flag is set to indicate that the result could not be represented. For all other signed values, the input is negated and the overflow flag is cleared.

   In unsigned mode, the number is negated, giving the same bit pattern as would result in signed mode. However, as all numbers are considered positive, a negative number can not be represented and the overflow flag will be set to indicate this. The only case you will not get an overflow flag is when the input is 0 (as 0 negated is also 0).

   .. describe:: Affected flags

   Sign, zero and overflow flags set according to the result.


.. object:: ABSI

   Absolute value of X.

   In signed mode, negative numbers are negated to make them positive. As negation does the same code as ``NEG``, see ``NEG`` for a discussion on how the smallest negative number behaves.

   In unsigned mode all numbers are considered positive, and negation is never done. The overflow flag is always cleared in this case.

   .. describe:: Affected flags

   Sign, zero and overflow flags set according to the result.


.. index:: operations; double precision, double precision

Double operations
=================

Multiplication and divide are also available in double versions.

.. object:: DMUL

   Multiply X with Y, the double result is placed in X and Y (high part in X).

   .. describe:: Affected flags

   Sign and zero flags set according to the result. The sign flag will have the correct value of the result. Overflow flag is cleared.


.. object:: DDIV

   Divide the double value in Z and Y (high part in Y) by X. The double quotient result is placed in X and Y (high part in X). Stack drops one step.

   .. describe:: Affected flags

   Sign and zero flags set according to the result. Overflow flag is cleared. Carry set if remainder is non-zero, cleared otherwise.


.. object:: DRMD

   Divide the double value in Z and Y (high part in Y) by X. The single precision remainder result is placed in X. Stack drops two steps.

   .. describe:: Affected flags

   Sign, zero and overflow flags set according to the result. Carry is not affected.


.. index:: logical operations, operations; logical

Logical operations
==================

.. object:: AND

   Logical AND between X and Y, result is placed in X and the stack drops.

   .. describe:: Affected flags

   Sign and zero flags set according to the result.


.. object:: OR

   Logical OR between X and Y, result is placed in X and the stack drops.

   .. describe:: Affected flags

   Sign and zero flags set according to the result.


.. object:: XOR

   Logical XOR between X and Y, result is placed in X and the stack drops.

   .. describe:: Affected flags

   Sign and zero flags set according to the result.


.. object:: NOT

   Bitwise NOT (negation) X, makes all bits the opposite.

   .. describe:: Affected flags

   Sign and zero flags set according to the result.


.. index:: rotation operations, shift operations, operations; shifts, operations; rotates

Shift operations
================

.. object:: SL _ _

   Shift X left by the given number of steps. The most recently shifted out bit is placed in the carry bit.

   .. describe:: Postfix argument

   The number of steps to shift, or a register indirection to a nibble register which holds the number of steps to shift. Valid range is 0--64.

   .. describe:: Affected flags

   Sign and zero flags set according to the result. Carry holds the last shifted out bit.


.. object:: SR _ _

   Shift X right by the given number of steps. The most recently shifted out bit is placed in the carry bit.

   .. describe:: Postfix argument

   The number of steps to shift, or a register indirection to a nibble register which holds the number of steps to shift. Valid range is 0--64.

   .. describe:: Affected flags

   Sign and zero flags set according to the result. Carry holds the last shifted out bit.


.. object:: RL _ _

   Rotate X left by the given number of steps. Bits going out at the left end appear again at the right hand side. In other words, bits are rotated around. The most recently bit that wrapped around is also copied to the carry.

   .. describe:: Postfix argument

   The number of steps to shift, or a register indirection to a nibble register which holds the number of steps to shift. Valid range is 0--64.

   .. describe:: Affected flags

   Sign and zero flags set according to the result. Carry holds the last shifted out bit.


.. object:: RR _ _

   Rotate X right by the given number of steps. Bits going out at the right end appear again at the left hand side. In other words, bits are rotated around. The most recently bit that wrapped around is also copied to the carry.

   .. describe:: Postfix argument

   The number of steps to shift, or a register indirection to a nibble register which holds the number of steps to shift. Valid range is 0--64.

   .. describe:: Affected flags

   Sign and zero flags set according to the result. Carry holds the last shifted out bit.


.. object:: RLC _ _

   Rotate X left by the given number of steps through carry. A bit that is rotated out goes to the carry, the previous carry is rotated in at the right hand side.

   .. describe:: Postfix argument

   The number of steps to shift, or a register indirection to a nibble register which holds the number of steps to shift. Valid range is 0--64.

   .. describe:: Affected flags

   Sign and zero flags set according to the result. Carry holds the last shifted out bit.


.. object:: RRC _ _

   Rotate X right by the given number of steps through carry. A bit that is rotated out goes to the carry, the previous carry is rotated in at the left hand side.

   .. describe:: Postfix argument

   The number of steps to shift, or a register indirection to a nibble register which holds the number of steps to shift. Valid range is 0--64.

   .. describe:: Affected flags

   Sign and zero flags set according to the result. Carry holds the last shifted out bit.


.. object:: ASR _ _

   Aritmetic right shift. This duplicates the sign bit as the number is shifted right. The most recent shifted out bit is placed in the carry.

   .. describe:: Postfix argument

   The number of steps to shift, or a register indirection to a nibble register which holds the number of steps to shift. Valid range is 0--64.

   .. describe:: Affected flags

   Sign and zero flags set according to the result. Carry holds the last shifted out bit.



.. index:: bitwise operations, operations; bitwise

Bitwise operations
===================

.. object:: MASKL _ _

   Create a left justified bit mask (all bits set), of the width specified in its argument.

   A width of 0 results in 0, a width of 64 results in all bits set regardless of the active word size.

   .. describe:: Postfix argument

   The width of the mask, or a register indirection to a nibble register which holds the width of the mask. Valid range is 0--64.

   .. describe:: Affected flags

   None


.. object:: MASKR _ _

   Create a right justified bit mask (all bits set), of the width specified in its argument.

   A width of 0 results in 0, a width of 64 results in all bits set regardless of the active word size.

   .. describe:: Postfix argument

   The width of the mask, or a register indirection to a nibble register which holds the width of the mask. Valid range is 0--64.

   .. describe:: Affected flags

   None


.. index:: sign extension

.. object:: SEX _ _

   Sign extend the value in X by the word width specified in its argument.

   .. code::

      SEX 08

   Will interpret the value in X as a signed 8-bit value. If it is negative, the value is sign extended to fit the active word size.

   .. describe:: Postfix argument

   A word size, or a register indirection to a nibble register which holds the word size. Valid range is 1--64.

   .. describe:: Affected flags

   Sign and zero flags set according to the result.


.. object:: CB _ _

   Clear a single bit in X as specified by the argument.

   .. describe:: Postfix argument

   A bit number, or a register indirection to a nibble register which holds the bit number. Valid range is 0--63.

   .. describe:: Affected flags

   Sign and zero flags set according to the result.


.. object:: SB _ _

   Set a single bit in X as specified by the argument.

   .. describe:: Postfix argument

   A bit number, or a register indirection to a nibble register which holds the bit number. Valid range is 0--63.

   .. describe:: Affected flags

   Sign and zero flags set according to the result.


.. object:: B? _ _

   Test if a bit of X is set, skip next instruction in a program if the bit is not set. In keyboard mode, the result is displayed as ``YES`` or ``NO``.

   .. describe:: Postfix argument

   A bit number, or a register indirection to a nibble register which holds the bit number. Valid range is 0--63.

   .. describe:: Affected flags

   None


.. object:: BITSUM _ _

   Count the number of bits in X and place that number in X.

   .. describe:: Postfix argument

   A register, or a register indirection to a nibble register.

   .. describe:: Affected flags

   Sign and zero flags set according to the result.


.. index:: compare operations, operations; compares

Comparisons
===========

Comparing values with Ladybug differs from what you may be used to on an HP calculator. Instead of comparing X to Y, or X to 0, you test flags set by the previous operation. There are three variants to this:

#. To compare two numbers, use the ``CMP`` instruction which works similar to a compare  on a microprocessor. It performs a subtraction, setting flags according to the result and discards the numerical result. The actual comparison between two numbers starts with a  ``CMP``, followed by a flag conditional operation which conditionally skips the following instruction.

#. To compare to 0, use the ``TST`` instruction followed by a test of flag 0.

#. Furthermore, arithmetic and bit manipulation instructions set flags according to the result, making it possible to just test suitable flags after such operation.

Here are the provided instructions that are related to comparing values.


.. object:: CMP _ _

   The argument specifies a register value that is subtracted from X. The result is dropped, but flags are set according to the result. Useful for comparing X to any value.

   .. describe:: Postfix argument

   A register, or a register indirection to a nibble register.

   .. describe:: Affected flags

   Sign, zero, overflow and carry flags are set according to result of the subtraction.


.. object:: TST _ _

   The argument specifies a register value that will affect the sign and zero flags. Useful for testing if any register value is zero, positive or negative.

   .. describe:: Postfix argument

   A register, or a register indirection to a nibble register.

   .. describe:: Affected flags

   Sign and zero flags set according to the value in the register.


.. object:: GE?

   Perform next instruction in a program if the previous ``CMP`` instruction indicates that X is greater than or equal to the other value, otherwise skip next line. Current sign mode is obeyed. In keyboard mode, ``YES`` or ``NO`` is displayed.

   .. describe:: Affected flags

   None


.. object:: GT?

   Perform next instruction in a program if the previous ``CMP`` instruction indicates that X is greater than the other value, otherwise skip next line. Current sign mode is obeyed. In keyboard mode, ``YES`` or ``NO`` is displayed.

   .. describe:: Affected flags

   None


.. object:: LE?

   Perform next instruction in a program if the previous ``CMP`` instruction indicates that X is less than or equal to the other value, otherwise skip next line. Current sign mode is obeyed. In keyboard mode, ``YES`` or ``NO`` is displayed.

   .. describe:: Affected flags

   None


.. object:: LT?

   Perform next instruction in a program if the previous ``CMP`` instruction indicates that X is less than the other value, otherwise skip next line. Current sign mode is obeyed. In keyboard mode, ``YES`` or ``NO`` is displayed.

   .. describe:: Affected flags

   None


.. index:: memory operations, operations; memory

Memory related instructions
===========================


.. object:: LDI _ _

   Load X from the specified register.

   .. describe:: Postfix argument

   A register, or a register indirection to a nibble register.

   .. describe:: Affected flags

   Sign and zero flags set according to the value loaded.


.. object:: STI _ _

   Store X in the specified register.

   .. describe:: Postfix argument

   A register, or a register indirection to a nibble register.

   .. describe:: Affected flags

   None


.. object:: DECI _ _

   Subtract one from the register specified in the argument.

   .. describe:: Postfix argument

   A register, or a register indirection to a nibble register.

   .. describe:: Affected flags

   Sign and zero flags set according to the new value.


.. object:: DSZI _ _

   Subtract one from the register specified in the argument, skip next instruction if the result is zero. This is useful for implementing loops. Flags are not affected.

   .. describe:: Postfix argument

   A register, or a register indirection to a nibble register.

   .. describe:: Affected flags

   None


.. object:: INCI _ _

   Add one to the register specified in the argument.


   .. describe:: Postfix argument

   A register, or a register indirection to a nibble register.

   .. describe:: Affected flags

   Sign and zero flags set according to the new value.


.. object:: CLRI _ _

   Clear the contents of the specified register.

   .. describe:: Postfix argument

   A register, or a register indirection to a nibble register.

   .. describe:: Affected flags

   None


Miscellaneous instructions
==========================

.. index:: alpha register operations, operations; alpha register

.. object:: ALDI _ _

   Append a register value to the alpha register obeying the current word size, selected base, active sign mode and zero fill flag.

   .. describe:: Postfix argument

   A register, or a register indirection to a nibble register.

   .. describe:: Affected flags

   None


.. index:: pause operation, operations; pause

.. object:: PSEI _ _

   Integer pause instruction. Works very much like the existing ``PSE`` instruction, but runs with the integer mode active. This instruction takes an argument which controls the duration of the pause.

   The length of the pause in seconds is approximately the value divided by 7. An argument of 00 behaves as 07 and gives a pause of about 1 second, similar to the built in ``PSE`` instruction.

   When a key is pressed, the pause is restarted. The pause length is limited to 64 (about 9 seconds), which is probably longer than you want in most cases.

   .. describe:: Postfix argument

   The pause duration, or a register indirection to a nibble register which holds the pause duration. Valid range is 0--64.

   .. describe:: Affected flags

   None


.. index:: window, display windows

.. object:: WINDOW _

   This instruction makes it possible to view different parts of a number that is too large to show in the display. Dots around the base character indicates whether there are digits not shown on either side of the currently shown window. This is a non-programmable instruction to make it possible to inspect numbers (literals) in program mode as well.

   .. describe:: Postfix argument

   The window number, 0--7. The rightmost window is 0, this is also what is shown by default.
