# Release Notes for Ladybug

## Important information

Ladybug is a bank switched module which consists of three pages. Ensure that you load it properly into your HP-41 for correct operation. The supplied `.mod` file is properly configured for this, but if you extract the pages and do it manually, be careful!


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
