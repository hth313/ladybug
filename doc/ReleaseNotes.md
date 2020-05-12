# Release Notes for Ladybug

## Important information

Ladybug is a bank switched module which consists of two pages. Ensure
that you load it properly into your HP-41 for correct operation. The
supplied `.mod` file is properly configured for this, but if you
extract the pages and do it manually, be careful!

With version 1A you need to load the OS4 module in page 4 for Ladybug
to work. You will also need the Boost module to access the secondary
functions in Ladybug.

## Version 1A

Update to use OS4, May X, 2020.

### Notes

* The previous page 4 module is removed in this version. Instead you
  need to install the separate OS4 module in page 4.

* Thanks to the new shell mechanism in OS4, the CLOCK function now
  works properly.

* The PSEI function is removed in this version and is replaced by the
  more generic PAUSE function in the Boost module.

### Corrections

* Starting entry of a number and then erasing digits up to the last
  one and holding down the key displays CLXI and then NULL. This is a
  somwehat strange situation in that we rubbed out the last character,
  but decided not to do it. The standard behavior when entering
  floating point numbers is to put 0 in X and enable stack lift, which
  I believe is incorrect. It should either put 0 in X and disable
  stack lift (so that the next number replaces the 0 which represent
  the cancelled input), or it should leave the last digit and not exit
  digit entry. Ladybug had a third behavior in that it left the last
  digit, ended digit entry and disabled stack lift. This has now been
  changed so that 0 is put in X and stack lift is disabled.

* ALDI did not append anything to the alpha register if the value was
  0, base was anything except decimal and zero-fill was inactive.

## Version 0C

Minor update, September 29, 2019.

### Corrections

* The ON poll vector code that reclaims the integer buffer would leave
  some other DADD selected than SS0 if there is no integer buffer
  around. This violates the ROMCHK protocol. Further down the line, if
  another module had a power ON poll vector that assumed SS0 was up
  (as it may do), it would incorrectly access some register in the
  buffer area, potentially even program registers.

* Add timing annotation on the PSEI loop to make it run at the desired
  speed on the HP-41CL (also when turbo mode is enabled).

* Semi-merged postfix arguments turned into single digit form when a
  printer was connected.


## Version 0B

Minor update, May 19, 2017.

### Notes

* Includes an overlay for i41CX+ emulator (iPhone) contributed by Robert Meyer.

* A `.pdf` version of the documentation is now part of the distribution.

* Various updates have been made to the documentation.

### Corrections

* The buffer created by Ladybug is no longer removed by "`PACK`" or "`GTO ..`". The buffer would be removed if such operation was invoked before turning the calculator off (at least once).

* Ladybug now works properly with very early HP-41C calculators.

* No longer crashes if another module misbehaves and leave a secondary bank enabled when returning to the operating system, and that module is located in such a way that the bank switch mechanism is shared with Ladybug.

* Minor change to the `.mod` file metadata to avoid any possible confusion to the module reader on how to group and locate the pages.


## Version 0A

Original release for early adaptors, January 10, 2017.
