
******************
Memory and storage
******************

Instructions that manipulate memory work in many ways similar to its floating point counterparts, with a few key differences.

Accessing memory locations on the HP-41 breaks down to two categories. Numbered data storage registers and stack registers. Using synthetic programming, there is actually a third category, status registers, which allows access to the internal state of the HP-41.

In addition to this, you can also perform indirection on any of these locations to refer to a numbered storage register.


.. index:: nibble memory, storage memory, memory; nibble, memory; storage

Nibble memory
=============

In integer mode, the data storage size is based on the selected word size. The size required is rounded up to the nearest full nibble (multiple of 4 bits).

In the floating point mode, data storage registers are always 56-bits wide (14 nibbles).

The same data register area is shared by the floating point and integer modes.

In integer mode it means that with word size 8, each storage value needs 2 nibbles. Starting at floating point register 0, the first 7 (56/8=7) integer registers overlap with the first floating point register. Integer register 0 is in the rightmost two nibbles of floating point register 0, the following registers are allocated one by one as long as the are nibbles available.

In word size 32, nibble register 0 is inside floating point register 0, nibble register 1 takes the first 24 (56-32=24) bits from register 0, and 8 bits from floating point register 1.

Changing the word size effectively changes the boundaries used in the storage register area, but will not alter the contents of the memory in any way. It just changes the interpretation of the data memory area.

Mixing floating point registers operations and nibble register operations in the same program is possible, but will require some care.


.. index:: stack registers, registers; stack

Stack registers
===============

Accessing stack registers in integer mode takes the extension part of the stack registers held in the I/O buffer in account and allows for accessing full 64-bit stack values.


.. index:: status registers, registers; status

Status registers
================

These are only available using synthetic programming and are treated as fixed 56-bit storage registers. Using them with integer mode makes most sense in word size 56, but they can be accessed in any word size. For larger word sizes, values are truncated to 56 bits. For smaller word sizes, values are truncated to the selected word size.


.. index:: register indirection, indirection; register

Register indirection
====================

Register indirection in integer mode works conceptionally as before, but uses the integer value in the storage location to point to a numeric nibble memory register.

The range of nibble storage registers that can be accessed is 0--4095. Actual amount of available memory may put limitations on this, but for small word sizes it is possible to get quite far. With word size 4, addressing the entire allowed range requires 292 registers, which is possible on an HP-41.


Memory manipulation
===================

In addition to ``LDI`` and ``STI`` to load and store integers, the ``DECI`` and ``INCI`` operations make it easy to add or subtract one to a register. As these operations also set zero and sign flags, it is simple to implement loops based on an integer counter.
Loops may also be implemented using the ``DSZI`` which does both decrement and skip next instruction on zero.
