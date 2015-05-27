==============
KS_PowerPallet - firmware for the All Power Labs Power Pallet(TM) PCU.
==============

Download the latest version of this source code at:

	https://github.com/allpowerlabs/KS_PowerPallet
	
=== Compatibility ===

This software is compatible with hardware version 1.09 of the Power Pallet, and
will not work properly with previous Power Pallets.  This essentially means only 
Power Pallets with a version 5 reactor.

=== Building This Software ===

This version requires avr-gcc-4.3, avr-libc-1.6.2, and Arduino-0023.  Later
versions of these tools will fail to compile this code.  Also, you will need
KSlibs and the modified versions of various Arduino libraries from:

	https://github.com/allpowerlabs/libraries

=== Change Log ===

April 28, 2015 - v1.3.1 Maintenance release

	Bug #1, Frequent auger low current alarms
		"Auger Low Current" alarms were being generated while the auger
		motor was off.  This was caused by rapid state transitions from 
		the new fuel switch and a bug in the fuel auger control logic.

	Bug #2, Auger current and fuel switch state not correctly logged
		
	Bug #6, Incorrect logging: Alarm Reset by UserNew Auger State: Off
	
	Bug #7, Message uses pound symbol: # Deap Sea controller set to:
	
	Bug #9, Added a minimum off time to the fuel switch logic to extend the life of the 
		fuel auger relays.  The default is 30 seconds, but is adjustable from 1 to 60 seconds.
	
	Bug #11, Grate motor power output low.
		Null EEPROM value wasn't handled correctly, so grate power level was 
		defaulting to 0 instead of 100.
		
	Bug #26, Servo start angle setting has no effect.
		This feature had been disabled a long time ago, probably to speed engine
		start-up on units where the filter was being bypassed while flaring.
		
	Bug #34, Can't determine current software version without power cycling automation
				
	Bug #38, Time in seconds greater than 5 chars on main screen wraps to beginning of screen
				
	Bug #39, Time displayed on log number screen incorrect
		This was caused by time being printed as a signed integer and overflowing.
	
	Bug #40, Ash auger does not turn off after grate shake correctly
		Ash auger run time was being being converted to a signed integer when read from EEPROM, 
		and the resulting overflow caused to ash auger to stay on constantly.
	
	Bug #52, Fuel auger reverse time should be .5 seconds
		This was decided as the new default during a meeting with the reactor team.
		The intent was to reduce material packing behind the auger.
		
	Bug #53, Remove unused settings from the configuration menu
		The following settings were removed from the configuration menu:
		engine_type - We are currently only supporting PP20
		relay_board - We are only supporting units with a relay board
		pratio_max- Unused
		display_per - This previously set the rate of display flashing
		pfilter_alarm - Unused
		lambda_rich - Unused
		pratio_high_boundary - Unused
		grate.revtime - Unused
		grate.duty - Unused
		
	Bug #54, Update configuration default for restriction temperature shutdown
		Restriction low temperature shutdown default was changed from 650C to 675C.
		
	Bug #55, Reduce default grate shake time to 2 seconds
		This was decided as the new default during a meeting with the reactor team.
		The intent was to reduce lofting of fines during a grate shake.
		
	Bug #56, Update configuration default for ash auger run time to 200 seconds.
		This was decided as the new default during a meeting with the reactor team.
		The intent was to reduce wear on the ash auger mechanism.
		
	Bug #57, Auger starts in reverse mode when powered up
		Testing has shown this behavior, which is intentional, to be a non-issue.  
		One modification has been made: the initial reverse pulse before going forward will 
		get its time setting from aug_rev_time, which sets the length of time the auger goes 
		backwards when an obstruction is encountered.
	
	Bug #58, Message log time stamp format is confusing
		Log time is now in seconds with no trailing decimals.
		
	Bug #60, ALARM_LOW_TRED and ALARM_TRED_LOW now each have a delay before activating.
		ALARM_LOW_TRED will not be raised until 120 seconds after the engine has gone into 
		the ON state.  ALARM_TRED_LOW will not be raised until the engine has been on for 
		180 seconds and coincides with an engine shutdown.

	ECR-000331, Excessive wear rates of gears, auger, scrolls, and motor
		See bugs #40 and #56
		
	ECR-000354, Engine starting on producer gas is slow
		See bug #26
	
	SCR-000007, Remove high Pratio alarm
	
	SCR-000010, Rename Tred to Trst
	
	SCR-000012, Remove flashing temp status
	
	SCR-000016, Auger off too long alarm goes off when auger "off".
	
	SCR-000020, Auger low current triggered when auger is off
		See bug #1
	
	SCR-000022, Add external fuel mode
		Support for external fuels has been added by refactoring the engine control logic to
		use oil pressure as an indication of a running engine instead of reactor vacuum.  

July 21, 2014 - v1.3.0 release

  * Added ash auger system. 
  * Re-wrote grate shaker code for H-bridge drive.
  * Renamed Ttred and Tbred to Trst and Tred, respectively.
  * Removed ignition on PCU start, and lean-out on shutdown, when in grid-tie 
    mode.
  * Various user interface changes
  * Innumerable under-the-hood improvements.
  * Added this lovely README file!