************
Introduction
************

Welcome to the Ladybug for the HP-41 calculator! Ladybug is a powerful tool, useful when you are debugging and working on low level matters related to computers.

It provides a new mode for you HP-41 calculator to allow it to work as a customizable integer binary calculator, use different number bases, perform bitwise and logical operations in a given word size. Such operations you typically will encounter when working with computers at the lowest level.

The main goal with this module is to blend the majority of the capabilities of an HP-16C into the HP-41 environment, while taking advantage of the extra facilities provided by the HP-41. In other words, to combine the best of both worlds.


Plug-in module
==============

Ladybug is a module image that needs to be put in some module hardware, like a Clonix module, an MLDL or some kind of ROM emulator. How you do this is beyond the scope of this manual.

The image configuration is a 3x4K module. Two banks occupies a single 4K page in the memory space together with a page 4 (takeover ROM). It can be plugged into any of the expansion ports (7-F) of the HP-41 expansion space, but the page 4 must go into address page 4.


This release
============

This version, 0A is a release to early adopters, in the hope to get feedback. The instruction allocation (XROM numbers) is considered preliminary and may change.


.. index:: buffer, I/O buffer, XROM number

Resource requirements
=====================

Ladybug allocates two registers from the pool of free memory. Apart from this, it does not impose any restrictions on the environment and will run comfortable on any HP-41C, HP-41CV or HP-41CX at standard speed.

The XROM number used by this module is 16 and the private storage area is I/O buffer number 0.



Using this guide
================

This guide assumes that you have a working knowledge about:

* The HP-41 calculator, especially its RPN system.
* Have a good understanding of different number bases, working with word sizes. Basically bits as used in most computers at its lowest level.


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

Providing the HP-41 with an integer mode similar to the way it works on the HP-16C was the main design goal of this module. This means that it provides a true integer mode, both the keyboard and the display change behavior when you enter integer mode. Instead of showing floating point numbers, you will see binary integers in the number base and word size chosen.

In integer mode, your HP-41 behaves the same way as you are used to, except that the default behavior of many keys no longer perform their floating point related operations, instead they will perform integer operations. This transformation takes place both inside, as well as outside user mode. As usual, you can make key assignments in user mode to override the default behavior.

Integer operations also work in program mode. You can write programs based on integer operations, just as you can write floating point programs. In fact, with some care you can actually intermix integer and floating point operations in a program.


Copyright
=========

The Ladybug software and its manual is copyright by Håkan Thörngren 2016.

Feedback and suggestions are welcome, the author can be contacted at hth313@gmail.com
