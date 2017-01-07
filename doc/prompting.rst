**********************
Prompting instructions
**********************

The HP-41 operating system allows for extension (XROM) instructions to prompt for arguments, but this only works when executed from the the keyboard. There is no support for storing such instructions together with its operand in programs.

This module offers an extension called semi-merged instructions that allows XROM instructions to have operands in programs. It is called semi-merged because the instructions are not fully merged like the built in prompting instructions.


Executing a prompting instruction will make it to prompt for its argument. Outside program mode, this is no problem as it was always supported. In program mode, the instruction and its postfix operand will be inserted in the program as a semi-merged instruction.


.. index:: postfix operands, operands; postfix, prompting instructions, instructions; prompting

Postfix operands
================

The postfix operand is a byte that cannot be safely stored directly in the program memory. The reason is that it can be any byte, even the first byte of a multi-byte instruction, which would consume innocent bytes following it, potentially making a total mess of the program memory.

The solution used here is to wrap the operand byte in a wrapper that makes it safe. The wrapper used is the alpha literal wrapper. Thus, an instruction such as ``SL`` (shift left) consists of two visible instructions in program memory:

.. code-block:: ca65

   10 ...
   11 SL 36
   12 "$"
   13 ...

Note that the ``SL 36`` instruction is fully shown as a merged instruction, but it is followed by its wrapped postfix byte (36 corresponds to ASCII $).

This also works when using indirect addressing:

.. code-block:: ca65

   10 ...
   11 SL IND Z
   12 "*"
   13 ...

As the ``SL`` instruction is a two byte XROM instruction followed by a single letter ASCII constant, the whole instruction requires four bytes of program memory.

When executed, the text literal is simply skipped and have no effect on the alpha register.

.. note::
   It is intentional that the postfix byte is shown. While it can be possible to hide it somewhat, it is judged to be better to actually show what is going on. This provides better control over program memory editing, as the postfix part actually does take a program step and will not be considered merged when following an instruction that skips the next line. (You may still be able to use it after such skip instruction, but it will execute the text literal in this case, altering the alpha register.)


.. index:: default operands, operands; default

Default operand
===============

If the postfix operand is missing, the instruction reverts to a default behavior. For a shift instruction, it means shift one step:

.. code-block:: ca65

   10 ...
   11 SL 01
   12 ...        ; not a single letter text literal

Such instruction costs two bytes (the XROM itself without any postfix operand). It executes as a single shift as shown. As it is a single instruction, it also works well following a test instruction.

If you enter the ``SL 01`` instruction, it takes advantage of the default and does not store a postfix byte in program memory.

If you delete the postfix operand from program memory, the instruction that used it will change to its default behavior, which can be seen when the instruction is shown.

.. note::
   Some care is needed when using default behavior with prompting instructions. It will still look for its argument and if you have a single character alpha constant that you intended to be an alpha constant, then it will become part of the previous instruction. This should seldom happen, but if it does, the easiest way to deal with it is by rearranging instructions.


.. index:: single stepping

Single stepping
===============

When you single step a semi-merged instruction in run mode (to execute the program step by step), it works properly, but visual feedback of the instruction when the ``SST`` key is pressed and held, is just the bare instruction without any postfix operand.


.. index:: integer literals, literals; integers

Integer literals
================

To store an integer literal in a program, just type it in when you are in program mode. This takes the selected base in account, word size 64 and no zero filling. This is because it cannot really know what the word size will be when the program is executed later.

To enter an integer literal in another base, switch out of program mode, change the base and switch program mode back on.

Integers in programs are always displayed using the current base. If you enter a hexadecimal number at one point, then edit the program at a later point in decimal mode, you will see the hexadecimal number displayed as a decimal number.

Numbers that are to larger than 8 digits will turn on the dot by the base character to indicate that the number is larger than is shown. The window feature can be used to inspect other parts of the number, just as you can do outside program mode.

Storing integer literals in a program works in a similar way as prompting instructions. A special ``#LIT`` instruction is used to prefix the literal, and the literal is encoded as a binary alpha string on the following line.

If you single step past the shown integer literal, the alpha literal is shown:

.. code-block:: ca65

    10 ...
    11 F80     H
    12 "**"
    13 ..

The default behavior for ``#LIT`` is to act as 0. As the postfix alpha literal can be of variable length, it is somewhat more likely to end up interfering with a following alpha literal in a program compared to the single byte postfix instructions.


.. note::
   As program editing sometimes can be a bit slow on the HP-41 and you may briefly see the ``#LIT`` instruction. The name was picked to avoid clashes with other things, yet give some hint what it is about when briefly seen.
