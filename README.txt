==============
KS_PowerPallet - firmware for the All Power Labs Power Pallet(TM) PCU.
==============

Download the latest version of this source code at:

	https://github.com/allpowerlabs/KS_PowerPallet
	
=== Compatibility ===

This software is compatible with hardware version 1.09 of the Power Pallet, and
will not work properly with previous Power Pallets.

=== Building This Software ===

This version requires avr-gcc-4.3, avr-libc-1.6.2, and Arduino-0023.  Later
versions of these tools will fail to compile this code.  Also, you will need
KSlibs and the modified versions of various Arduino libraries from:

	https://github.com/allpowerlabs/libraries

=== Change Log ===
July 21, 2014 - v1.3.0 release
  * Added ash auger system. 
  * Re-wrote grate shaker code for H-bridge drive.
  * Renamed Ttred and Tbred to Trst and Tred, respectively.
  * Removed ignition on PCU start, and lean-out on shutdown, when in grid-tie 
    mode.
  * Various user interface changes
  * Innumerable under-the-hood improvements.
  * Added this lovely README file!