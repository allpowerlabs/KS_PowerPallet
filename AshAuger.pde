/*
Ash Auger Control Logic
TODO:
	Disable O2 reset - done!
	Data logging, how and what
	Hack manual control mode into UI
	Add configuration settings
*/
// Stupid Arduino doesn't know how to use real C >:(
//#include "AshAuger.h"

// Ash auger time variables are in milliseconds
unsigned int ashAugerLastTime;	// This stores the last time the control logic was executed
unsigned int ashAugerRunTimer;  // This timer counts how long the auger has been in the current run state
unsigned int ashAugerControlTimer;  // This timer counts how long the auger has been in the current control state
unsigned int ashAugerRunPeriod;  // Total cycle time for the auger
unsigned int ashAugerRunLength;  // Amount of time during the cycle the auger should run.  Must be less than total cycle time.

ashAugerRunState_t ashAugerRunStateCurrent;
ashAugerRunState_t ashAugerRunStatePrevious;
ashAugerRunState_t ashAugerRunStateRequested;

ashAugerControlState_t ashAugerControlStateCurrent;
ashAugerControlState_t ashAugerControlStatePrevious;
ashAugerControlState_t ashAugerControlStateRequested;

void AshAugerRunRequest(ashAugerRunState_t s) {ashAugerRunStateRequested = s;}

void AshAugerControlRequest(ashAugerControlState_t s) {ashAugerControlStateRequested = s;}

void AshAugerInit() {
	ashAugerRunPeriod = ASH_AUGER_PERIOD_DEFAULT;
	ashAugerRunLength = ASH_AUGER_LENGTH_DEFAULT;
	AshAugerReset();
}

void AshAugerReset() {
	AshAugerRunRequest(ASH_AUGER_OFF);
	AshAugerControlRequest(ASH_AUGER_AUTO);
}

void AshAugerOn() {digitalWrite(FET_ASH_AUGER, HIGH);}
void AshAugerOff() {digitalWrite(FET_ASH_AUGER, LOW);}

void AshAugerRotateRunState() {
	ashAugerRunStatePrevious = ashAugerRunStateCurrent;
	ashAugerRunStateCurrent = ashAugerRunStateRequested;
	ashAugerRunTimer = 0;
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
				// Not much to do here...
				break;
			case ASH_AUGER_MANUAL:
				// ... or here, either.
				break;
			case ASH_AUGER_DISABLED:
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
		default:
			break;
	}
	// MANUAL and DISABLED modes don't require any internal control logic
	// Handle run state transitions at the end.
	if (ashAugerRunStateRequested != ashAugerRunStateCurrent) {
		// A new run state has been requested.
		switch (ashAugerRunStateRequested) {
			case ASH_AUGER_ON:
				AshAugerOn();
				break;
			case ASH_AUGER_OFF:
				AshAugerOff();
		}
		//Rotate run states
		AshAugerRotateRunState();
	}
}