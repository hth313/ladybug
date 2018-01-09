**************
Implementation
**************

This chapter aims to give an understanding of how the HP-41 has been
extended to work with integer numbers.


.. index:: buffer, I/O buffer, XROM number

I/O buffer
==========

The HP-41 stack uses 56-bit values. Such values are most often
floating point numbers, but alpha data and non-normalized numbers are
also possible.

To make it possible to work with up to 64-bit integers, an I/O buffer
is used to store the extra bits. The lower 56 bits are stored in the
ordinary stack and the buffer provides storage for the remaining
bits.

A buffer is a private storage area allocated from the free memory
area, much like Time module alarms.

Stack space is shared with the ordinary floating point stack and the
extra bits (when needed), are kept in the buffer. Instructions that
work on the stack, such as ``ENTER`` and ``RDN`` have an integer
counterpart instruction that works on the full 64-bit value.

.. note::
   If you are using a word size of 56 or less, you can use the
   floating point counterpart instructions for stack manipulations, as
   they behave the same. This makes most sense in a program as those
   instructions are shorter (occupy less memory space) and execute
   faster.

As the lower 56 bits are stored in the normal stack registers, it
makes it easier to interact with the ordinary 56-bit calculator
registers for special purposes. The main disadvantage is that
instructions such as ``CAT 4``, ``TIME`` and ``DATE`` that leaves a
number in X register, which will corrupt the integer stack if word
size is larger than 56.

.. hint::
   If you corrupt the stack in this way, you can usually recover most
   of it by executing the floating point ``RDN`` instruction.

In addition to the extra bits for the stack, the buffer keeps track of
all other things related to the integer mode. The complete integer
state is preserved when you turn your calculator off. In fact, turning
the HP-41 off and on will not cause the HP-41 to leave the integer
mode. Integer mode stays active until you make an explicit switch to
floating point mode (just press the gold shift key and the ``PI`` (0)
key to get out of integer mode).

If you unplug Ladybug, the next time you turn the HP-41 on, the HP-41
will reclaim the buffer registers and make them available in the free
memory pool.


Keboard layout
==============

The keyboard layout uses the existing similar functions on keys
whenever possible. However, the stack manipulation operations ``RDN``
and ``X<>Y`` are moved to shifted keys as it was judged more important
to have access to all digit entry keys without pressing shift.

The base change keys are ordered in the same way as on the HP-16C and
are located after the F digit.

The window key is the dot key. It was selected because the display
uses dots to indicate presence of more windows. It is also very close
to the 0--3 keys, so you will find the typical argument keys close to
the window selection key.

The bit set, clear and test instructions are located on the row below
the corresponding flag operations.

Negation is the same thing as ``CHS``, bitwise ``NOT`` is on the same
key (shifted) as it is closely related to negation.

Shift and rotate operations are plentiful. They are arranged together
on the upper part of the keyboard.

Double ``MUL`` and ``DIV`` operations are the shifted variant of the
corresponding key.

``CMP`` is actually a subtract operation, so it is on the shifted
``SUB`` key. ``TST`` is related to ``CMP``, so it was placed next to
it. These keys are also where comparisons are on the floating point
keyboard, so that also makes some sense.

The logical operations are held together in the usual order you say
them, AND, OR, XOR, which also is the alphabetical order.

When you feel that you need to work with floating point numbers, you
probably want to use that PI constant, so the ``FLOAT`` operation to
switch to floating point mode is on the PI key.

Sign extension is on the ``EEX`` key, which is almost spelled the
same.
