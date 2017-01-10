************
Introduction
************

Welcome to Ladybug for the HP-41 calculator! Ladybug is a powerful tool, intended to be useful when you are debugging or working with low level matters related to computers.

Ladybug provides a new mode for you HP-41 calculator which allows it to work as a customizable integer binary calculator. It makes it easy to work in different number bases, perform arithmetic, bitwise and logical operations in a given fixed word size. Operations that you typically will encounter when working with computers at its lowest level.

The main goal with this module is to blend the majority of the capabilities of an HP-16C into the HP-41 environment, while taking advantage of the extra facilities provided by the HP-41. In other words, to combine the best of both worlds.


Plug-in module
==============

Ladybug is a module image that needs to be put in some programmable plug-in module hardware. This can be a Clonix module, an MLDL or some kind of ROM emulator. You need to consult the documentation of ROM emulation hardware for this.

It is also possible to use Ladybug on HP-41 emulators.

The Ladybug image is a 3x4K module. Two banks occupies a single 4K page in the normal memory expansion space, together with a page 4 (takeover ROM). It can be plugged into any of the expansion ports (7-F) of the HP-41 expansion space, but the page 4 image must be placed in address page 4.


This release
============

This version, 0A is a release to early adopters, in the hope to get feedback. The instruction allocation (XROM numbers) is currently considered preliminary and may change in the future.


.. index:: buffer, I/O buffer, XROM number

Resource requirements
=====================

Ladybug allocates two registers from the free memory pool. Apart from this, it does not impose any restrictions on the environment and will run comfortable on any HP-41C, HP-41CV or HP-41CX at standard speed.

The XROM number used by this module is 16 and the private storage area is I/O buffer number 0.



Using this guide
================

This guide assumes that you have a working knowledge about:

* The HP-41 calculator, especially its RPN system.
* Have a good understanding of different number bases and working with different word sizes. Basically bits as used in most computers at its lowest level.


Further reading
===============

If you feel that you need to brush up your background knowledge, here are some suggested reading:

* The *Owner's Manuals* supplied with the HP-41, Hewlett Packard Company.
* *HP-16C Computer Scientist Owner's Handbook*, Hewlett Packard Company.
* *Hacker's Delight*, Henry S. Warren, Addison-Wesley, 2003, 2012.
* *Extend your HP-41*, W Mier-Jedrzejowicz, 1985.


As always, learning by doing tends to work best. Put fresh batteries into your HP-41 and put it to work, it is a great tool, despite being some 30+ years old.


Integer mode
============

Providing the HP-41 with an integer mode similar to the way it works on the HP-16C is the main design goal of this module. When the integer mode is enabled, both the keyboard and the display change behavior. Instead of showing floating point numbers, you will see binary integers in the number base and word size chosen.

In integer mode, your HP-41 behaves in the same way as you are used to, except that many keys perform integer operations instead of their previous floating point operations. This transformation takes place both inside, as well as outside user mode. As usual, you can make key assignments in user mode to override the default behavior.

Integer operations also work in program mode. You can write programs based on integer operations, just as you can write floating point programs. In fact, with some care you can actually intermix integer and floating point operations in a program.


License
=======

The Ladybug software and its manual is copyright by Håkan Thörngren 2017 under the BSD 3-clause license.

| Copyright (c) 2017, Håkan Thörngren
| All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the <organization> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


The name
========

The Ladybug name derives from that it is a useful tool for debugging at very low levels, using a calculator that is powered by Lady sized batteries. A ladybug is also a cute little animal.


Feedback
========

Feedback and suggestions are welcome, the author can be contacted at hth313@gmail.com
