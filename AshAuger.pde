/*
Ash Auger Control Logic
TODO:
	Disable O2 reset - done!  Now do it better...
	Data logging, how and what - done
	Hack manual control mode into UI - done
	Add configuration settings - done
*/

#ifndef ARDUINO
#include "Config.h"
#include "AshAuger.h"
#endif

// Ash auger time variables are in milliseconds
unsigned long ashAugerLastTime;	// This stores the last time the control logic was executed
unsigned long ashAugerRunTimer;  // This timer counts how long the auger has been in the current run state
unsigned long ashAugerControlTimer;  // This timer counts how long the auger has been in the current control state

unsigned long ashAugerRunPeriod;  // Total cycle time for the auger
unsigned long ashAugerRunLength;  // Amount of time during the cycle the auger should run.  Must be less than total cycle time.

ashAugerRunState_t ashAugerRunStateCurrent;
ashAugerRunState_t ashAugerRunStatePrevious;
ashAugerRunState_t ashAugerRunStateRequested;

ashAugerControlState_t ashAugerControlStateCurrent;
ashAugerControlState_t ashAugerControlStatePrevious;
ashAugerControlState_t ashAugerControlStateRequested;

void AshAugerRunRequest(ashAugerRunState_t s) {ashAugerRunStateRequested = s;}
ashAugerRunState_t AshAugerRunState() {return ashAugerRunStateCurrent;}
void AshAugerControlRequest(ashAugerControlState_t s) {ashAugerControlStateRequested = s;}
ashAugerControlState_t AshAugerControlState() {return ashAugerControlStateCurrent;}

void AshAugerInit() {
	//ashAugerRunPeriod = ASH_AUGER_PERIOD_DEFAULT;
	//ashAugerRunLength = ASH_AUGER_LENGTH_DEFAULT;
	AshAugerReset();
	AshAugerRunRequest(ASH_AUGER_OFF);
	AshAugerControlRequest(ASH_AUGER_AUTO);
}

void AshAugerReset() {
	// getConfig(28) is period in 5-second increments
	// getConfig(29) is % duty cycle
	ashAugerRunPeriod = (unsigned long) getConfig(28) * 5000;  // Avoid casting error 
	ashAugerRunLength = (ashAugerRunPeriod * getConfig(29)) / 100;
}

void AshAugerOn() {digitalWrite(FET_ASH_AUGER, HIGH);}
void AshAugerOff() {digitalWrite(FET_ASH_AUGER, LOW);}

void AshAugerRotateRunState() {
	ashAugerRunStatePrevious = ashAugerRunStateCurrent;
	ashAugerRunStateCurrent = ashAugerRunStateRequested;
	ashAugerRunTimer = 0;  // Here's where we reset the run timer
}
void AshAugerRotateControlState() {
	ashAugerControlStatePrevious = ashAugerControlStateCurrent;
	ashAugerControlStateCurrent = ashAugerControlStateRequested;
	ashAugerControlTimer = 0;
}


void DoAshAuger() {
	/*
		Order of operations:
			Control state transitions
			Control logic
			Run state transitions
	*/
	unsigned int loopDelay;
	
	loopDelay = (millis() - ashAugerLastTime);
	ashAugerLastTime = millis();
	// Do control state transitions first so we can take action immediately after
	if (ashAugerControlStateRequested != ashAugerControlStateCurrent) {
		// A new control state has been requested.  
		switch (ashAugerControlStateRequested) {
			case ASH_AUGER_AUTO:
				Logln_p("Ash auger automatic mode");
				// Not much to do here...
				break;
			case ASH_AUGER_MANUAL:
				Logln_p("Ash auger manual mode");
				// ... or here, either.
				break;
			case ASH_AUGER_DISABLED:
				Logln_p("Ash auger disabled");
				// Blorp!
				break;
			default:
				break;
		}
		//Rotate control states
		AshAugerRotateControlState();	
	}
	// This is the logic for AUTO control mode
	switch (ashAugerControlStateCurrent) {
		case ASH_AUGER_AUTO:
			ashAugerRunTimer += loopDelay; // Increment auger run timer
			// Do checks to see if we should transition run state
			switch (ashAugerRunStateCurrent) {
				case ASH_AUGER_OFF:
					// Is it time to start the auger?
					if (ashAugerRunTimer > (ashAugerRunPeriod - ashAugerRunLength)) 
						AshAugerRunRequest(ASH_AUGER_ON);
					break;
				case ASH_AUGER_ON:
					// Have we reached the end of the run cycle?
					if (ashAugerRunTimer > ashAugerRunLength) 
						AshAugerRunRequest(ASH_AUGER_OFF);
					break;
				default:
					break;
			}
			break;
		case ASH_AUGER_MANUAL:
			AshAugerRunRequest(ASH_AUGER_ON);
			break;
		case ASH_AUGER_DISABLED:
			AshAugerRunRequest(ASH_AUGER_OFF);
			break;
		default:
		// MANUAL and DISABLED modes don't require any internal control logic
			break;
	}
	// Handle run state transitions at the end.
	if (ashAugerRunStateRequested != ashAugerRunStateCurrent) {
		// A new run state has been requested.
		switch (ashAugerRunStateRequested) {
			case ASH_AUGER_ON:
				Logln_p("Ash auger ON");
				AshAugerOn();
				break;
			case ASH_AUGER_OFF:
				Logln_p("Ash auger OFF");
				AshAugerOff();
		}
		//Rotate run states
		AshAugerRotateRunState();
	}
}