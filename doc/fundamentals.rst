*********************
Numbers and basic use
*********************

Fixed width integer numbers as used in computers are quite different from floating point numbers which aim to be an approximation of real numbers.

The fixed width indicates that we are working with numbers that have a predefined size. There is no such things as infinite numbers, instead numbers wrap around or behave in other ways when they overflow beyond their fixed width representation.

This chapter covers numeric bases, word size, 2-complement and ranges.


.. index:: numeric bases, bases; numeric, hexadecimal, decimal, octal, binary

Numeric bases
=============

Ladybug provides four numeric bases, binary (2), octal (8), decimal (10) and hexadecimal (16). Internally, numbers are represented as binary integers. The selected base controls the input and display of integers. The same binary number can be represented in any of the bases and it is easy to go between the bases. Thus, you can at any time during a calculation switch base to the one most suitable at that point. Any result (or partial result, thanks to RPN logic) can easily be shown in any available base.

Four keys (G--J) on the HP-41 keyboard represent ``HEXS``, ``DECS``, ``OCTS`` and ``BINS`` instructions that switch the base. Thus, switching base takes a single key press.

At any time a binary integer is displayed, it is displayed in the active base with a single letter at the right end of the display, indicating the active base.

The one exception to this is the ``ALDI`` instruction which appends the digits in the active base to the alpha registers, without the active base character.


.. index:: signed mode, 2-complement mode, mode; 2-complement mode; signed

2-complement
============

Binary integers can be interpreted as unsigned or signed. The signed mode used here is `2-complement <https://en.wikipedia.org/wiki/Two's_complement>`_ which is the most commonly used way of representing signed numbers on micro processors today.

In 2-complement mode, the leftmost (most significant) bit represents the sign.

In decimal mode, a negative number is displayed with a leading minus sign. In other bases, numbers are displayed without a leading minus sign, even when they are negative.

In word size 8, numbers range from -128 to 127 (decimal).


.. index:: unsigned mode, mode; unsigned

Unsigned
========

In the unsigned mode the leftmost bit adds magnitude to the number, not sign. This essentially doubles the value range.

In word size 8, numbers range from 0--255 (decimal).


.. index:: word size, sign extension

Word size
=========

You can specify word sizes from 1 to 64 bits using the ``WSIZE`` instruction. This controls the limit of numbers in the same way as is done on computers. You will often find that computers use 64, 32, 16 or even 8 bit values. If you are familiar with the internals of the HP-41, you have probably encountered other word sizes as well.

.. note::
   Using instructions outside Ladybug, it is possible to place floating point values and alpha data on the stack, even when integer mode is enabled. This have no negative effect as stack values are adjusted to fit the current word size when integer operations are applied to them. Such non-integer data is preserved as long as you do not attempt to perform integer operations on them. The exception to this rule is that when you increase the word size, in which case all values on the stack are either a sign or zero extension depending on the sign mode. This is done to preserve the numerical meaning of integer values.


.. index:: windows, display windows

Windows
=======

Depending on the number base and word size, the display may not be able to display the full number. In such cases the base letter will have a dot next to it indicating that there are more digits outside what is shown. To display such numbers you can use the window feature which is available on the dot key.

Pressing window (dot) gives a prompt for the window. The permitted range is 0--7, with 0 being the least significant part, which is what is shown by default. Simply press the desired window number to show the other parts of the number. The dots beside the base character gives feedback to whether there are more digits to the left or to the right of what is currently shown.
