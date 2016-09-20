**************
Implementation
**************

This chapter is aimed to give an understanding of how the HP-41 has been extended to work with integer numbers.


.. index:: buffer, I/O buffer, XROM number

I/O buffer
==========

The HP-41 stack uses 56-bit values. Such values are most often floating point numbers, but alpha data and non-normalized numbers are also possible.

To make it possible to work with up to 64-bit integers, an I/O buffer is used to store the extra bits. The lower 56 bits are stored in the ordinary stack and the buffer provides storage for the remaining bits.

A buffer is a private storage area allocated from the free memory area, much like Time module alarms.

Stack space is shared with the ordinary floating point stack and the extra bits (when needed), are kept in the buffer. Instructions that work on the stack, such as ``ENTER`` and ``RDN`` have an integer counterpart instruction that works on the full 64-bit value.

.. note::
   If you are using a word size of 56 or less, you can use the floating point counterpart instructions for stack manipulations, as they behave the same. This makes most sense in a program as those instructions are shorter (occupy less memory space).

As the lower 56 bits are stored in the normal stack registers, it makes it easier to interact with the ordinary 56-bit calculator registers for special purposes. The main disadvantage is that instructions such as ``CAT 4``, ``TIME`` and ``DATE`` that leaves a number in X register, which will corrupt the integer stack if word size is larger than 56.

.. hint::
   If you corrupt the stack in this way, you can usually recover most of it by executing the floating point ``RDN`` instruction.

In addition to the extra bits for the stack, the buffer keeps track of all other things related to the integer mode. The complete integer state is preserved when you turn your calculator off. In fact, turning the HP-41 off and on will not cause the HP-41 to leave the integer mode. Integer mode stays active until you make an explicit switch to floating point mode (just press the gold shift key and the ``PI`` (0) key to get out of integer mode).

If you unplug the module with the Programmer, the next time you turn the HP-41 on, it will reclaim the buffer registers and make them available in the free memory pool.
