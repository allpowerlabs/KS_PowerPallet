
void InitGrate() {
	grateMode = GRATE_SHAKE_PRATIO; //set default starting state
	grate_motor_state = GRATE_MOTOR_OFF; //changed to indicate state (for datalogging, etc)
	grate_val = GRATE_SHAKE_INIT; //variable that is changed and checked

	CalculateGrate();
}

void CalculateGrate() {
	//setup grate slopes
	m_grate_bad = (GRATE_SHAKE_INIT-GRATE_SHAKE_CROSS)/grate_min_interval;
	m_grate_good = (GRATE_SHAKE_INIT-GRATE_SHAKE_CROSS)/grate_max_interval;
}

void DoGrate() { // call once per second
	static unsigned int grate_timer = 0;	// Used to time grate shakes, in milliseconds
	static unsigned long last_time = 0;		// Last run time, in milliseconds
	
	// Count down the grate timer, if it's running
	if (grate_timer) {
		grate_timer = u_sublim(grate_timer, millis()-last_time, 0);
	}
	last_time = millis();
	  
	// handle different shaking modes
	switch (grateMode) {
		case GRATE_SHAKE_ON:	// Continuous grate shake requested by user
			if (grate_motor_state != GRATE_MOTOR_ON) {
				digitalWrite(FET_GRATE,HIGH);
				grate_motor_state = GRATE_MOTOR_ON;
				Logln("Grate Mode: On");
			}
			break;
		case GRATE_SHAKE_OFF:	// Grate shake inhibited by user
			if (grate_motor_state != GRATE_MOTOR_OFF) {
				digitalWrite(FET_GRATE,LOW);
				grate_motor_state = GRATE_MOTOR_OFF;
				Logln("Grate Mode: Pressure Ratio");
			}
			break;
		case GRATE_SHAKE_PRATIO:
			if (grate_motor_state != GRATE_MOTOR_OFF) {
				digitalWrite(FET_GRATE,LOW);
				grate_motor_state = GRATE_MOTOR_OFF;
				Logln("Grate Mode: Off");
			}
			if (engine_state == ENGINE_ON || engine_state == ENGINE_STARTING || P_reactorLevel != OFF) { //shake only if reactor is on and/or engine is on
			  //condition above will leave grate_val in the last state until conditions are met (not continuing to cycle)
			  if (grate_val >= GRATE_SHAKE_CROSS) { // not time to shake
				if (pRatioReactorLevel == PR_LOW) {
				  grate_val = u_sublim(grate_val, m_grate_bad, 0);
				} else {
				  grate_val = u_sublim(grate_val, m_grate_good, 0);
				}
			  }
			}
			if (grate_val <= GRATE_SHAKE_CROSS) {	//time to shake or reset
				// Timer isn't running, lets start it
				grate_timer = grate_on_interval * 1000; // Set the timer, in milliseconds
				// Switch to timed shaking mode
				grateMode = GRATE_SHAKE_TIMED;
			}
			break;
		case GRATE_SHAKE_TIMED:
			if (grate_timer) {
				// Timer's on, make sure we're shakin'
				if (grate_motor_state != GRATE_MOTOR_ON) {
					grate_motor_state = GRATE_MOTOR_ON;
					digitalWrite(FET_GRATE,HIGH);
				}
			}
			else {
				// Timer reached 0, switch off and go back to watch mode
				grate_val = GRATE_SHAKE_INIT;
				grate_motor_state = GRATE_MOTOR_OFF;
				digitalWrite(FET_GRATE, LOW);
				grateMode = GRATE_SHAKE_PRATIO;
			}
			break;
		default:
			grateMode = GRATE_SHAKE_PRATIO;
			break;
	}
}