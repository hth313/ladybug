************
Introduction
************

Welcome to the Ladybug module for the HP-41 calculator! Ladybug is a powerful
tool, intended to be useful when you are debugging or working with low
level matters related to computers.

Ladybug provides a new mode for you HP-41 calculator which allows it
to work as a customizable integer binary calculator. It makes it easy
to work in different number bases, perform arithmetic, bitwise and
logical operations in a given fixed word size. Operations that you
typically will encounter when working with computers at its lowest
level.

The main goal with this module is to blend the majority of the
capabilities of an HP-16C into the HP-41 environment, while taking
advantage of the extra facilities provided by the HP-41. In other
words, to combine the best of both worlds.


Plug-in module
==============

Ladybug is a module image that needs to be put in some programmable
plug-in module hardware. This can be a Clonix module, an MLDL or some
kind of ROM emulator. You need to consult the documentation of ROM
emulation hardware for this.

It is also possible to use Ladybug on HP-41 emulators.

The Ladybug image is a 2x4K module. Two banks occupies a single 4K
page in the normal memory expansion space (page 7--F).

You must also load the separate OS4 module in page 4 for Ladybug to work.

This release
============

This version, 1A is the first that uses the new OS4 module.

.. index:: buffer, I/O buffer, XROM number

Resource requirements
=====================

Ladybug allocates two registers from the free memory pool. Apart from
this, it does not impose any restrictions on the environment and will
run comfortable on any HP-41C, HP-41CV, HP-41CX or HP-41CL.

The XROM number used by this module is 16 and the private storage area
is I/O buffer number 0.



Using this guide
================

This guide assumes that you have a working knowledge about:

* The HP-41 calculator, especially its RPN system.
* Have a good understanding of different number bases and working with
  different word sizes. Basically bits as used in most computers at
  its lowest level.


Further reading
===============

If you feel that you need to brush up your background knowledge, here are some suggested reading:

* The *Owner's Manuals* supplied with the HP-41, Hewlett Packard Company.
* *HP-16C Computer Scientist Owner's Handbook*, Hewlett Packard Company.
* *Hacker's Delight*, Henry S. Warren, Addison-Wesley, 2003, 2012.
* *Extend your HP-41*, W Mier-Jedrzejowicz, 1985.


As always, learning by doing tends to work best. Insert fresh batteries into your HP-41 and put it to work, it is a great tool, despite being some 30+ years old.


Integer mode
============

Providing the HP-41 with an integer mode similar to the way it works
on the HP-16C is the main design goal of this module. When the integer
mode is enabled, both the keyboard and the display change
behavior. Instead of showing floating point numbers, you will see
binary integers in the number base and word size chosen.

In integer mode, your HP-41 behaves in the same way as you are used
to, except that many keys perform integer operations instead of their
previous floating point operations. This transformation takes place
both inside, as well as outside user mode. As usual, you can make key
assignments in user mode to override the default behavior.

Integer operations also work in program mode. You can write programs
based on integer operations, just as you can write floating point
programs. In fact, with some care you can actually intermix integer
and floating point operations in a program.


License
=======

The Ladybug software and its manual is copyright by Håkan Thörngren.
It was previously (2018-2019) released under the BSD 3-clause license,
but it is changed with version 1A.

MIT License

Copyright (c) 2020 Håkan Thörngren

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

The name
========

The Ladybug name derives from that it is a useful tool for debugging
at very low levels, using a calculator that is powered by Lady sized
batteries. A ladybug is also a cute little animal.


Acknowledgments
===============

Thanks to Robert Meyer for contributing the overlay for i41CX+ emulator (iPhone).


Feedback
========

Feedback and suggestions are welcome, the author can be contacted at
hth313@gmail.com
