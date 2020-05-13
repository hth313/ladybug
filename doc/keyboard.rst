
.. index:: keyboard layout

***********
Application
***********

Ladybug makes use of the application shell concept from the OS4 module
to redefine the HP-41 keyboard to be somewhat different compared to
normal, while still retaining essentially all behavior you are used
to. The default display behavior is also changed to display integer
number in the selected base.

.. image:: calculator.png
   :height: 560

The alpha mode keyboard is also slightly modified and hass the
``ALDI`` function where ``ARCL`` normally is.

.. index:: activation

Activation
==========

Once Ladybug has been plugged into your calculator, simply execute the
``INTEGER`` instruction to enable integer mode.


.. index:: deactivation

Deactivation
============

Once activated, the HP-41 stays in integer mode until you execute the
``EXITAPP`` instruction. This can be done by pressing the shift key
followed by the USER key. It is also possible to execute the
``EXITAPP`` instruction using the ``XEQ`` key and spell it out as
usual.

Another way to disable Ladybug is to turn the calculator off and
unplug the module.

The shifted USER key can also be used in alpha mode to exit integer
mode.

Secondary functions
===================

Ladybug makes use of the secondary functions feature of OS4. To access
these functions you need the Boost module installed which contains
replacements for the ``XEQ`` and ``ASN`` functions to allow keyboard
access to the secondary functions in the same way as ordinary
functions.
