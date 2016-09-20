
*****
Flags
*****

Flags are fundamental to the integer mode. Flags are used to control behavior and give  information about the result of operations.

Flags 0-5 are given special purpose by the integer mode. These flags are used because most are visible in the display, which makes it easy to see the flags while doing manual operations.

Some logic is intended in the assignment of the flag numbers, which makes it easier to remember them.


.. index :: mode flags, flags; mode, zero fill mode, mode; zero fill
.. index :: 2-complement mode, signed mode; mode; 2-complement

Mode flags
==========

Two user flags control the mode. Setting flag 2 enables 2-complement signed mode. Clearing flag 2 enables unsigned mode.

Flag 5 is used to control zero fill of numbers. Zero filling means that all digits in the selected base are always shown. Leading zeros are used fill out the word if needed.

In decimal mode, zero fill has no effect.

If the number is larger than can be displayed, the window feature will enable a dot before the base character to indicate more digits available than is shown. This only happens if there is any non-zero digit above what is shown and works that way even in zero fill mode. This is to make it easy to see if there is anything of real interest there and prevents the need from constantly inspecting upper windows only to find zero digits.


.. index:: carry flag, flags; carry

Carry flag
==========

The carry flag is significant to most micro processors. It carries the bit out of a an addition, or the borrow into a subtraction. It is also used in shift operations as the spill bit shifted or rotated out.

Here it is assigned to flag 3, which if you straighten and mirror it resembles a C.

.. index:: overflow flag, flags; overflow

Overflow flag
=============

The overflow flag (called out-of-range flag in the HP-16C), tells if the operation overflowed. It is most commonly used in signed mode to signal that the result bits are not enough to hold the real result. For an addition and subtraction, it means that the sign of the result is incorrect (opposite). Flag 4 is assigned as the overflow flag.


.. index:: zero flag, flags; zero
.. index:: sign flag, flags; sign

Sign and zero flags
===================

Sign and zero flags are very common on micro processors (but not present in the HP-16C). Here they are available with their usual meaning.

The zero flag is represented by flag 0 and is set when the last operation results in 0.

The sign flag is the most significant bit of the result. In signed mode this is the actual sign of the result. For decimal numbers, such numbers are displayed with a leading minus sign.

Flag 1 is used for sign, because it is a bit just copied from the result and it signals negative sign when this bit is 1.

.. note::
   The zero flag is set to indicate that the representable part of the result is zero. If you add two numbers so that they produce a carry out, but the lower parts consists of only 0 bits, the zero flag is set. Mathematically, the result is not zero, but this is how micro processors work, numbers wrap. You also have the carry flag and the overflag to inspect in order to interpret a result properly.
