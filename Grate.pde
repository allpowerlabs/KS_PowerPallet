

// Grate Shaking States - now using generic modes AUTOMATIC, MANUAL, DISABLED
// #define GRATE_SHAKE_OFF 0
// #define GRATE_SHAKE_ON 1
// #define GRATE_SHAKE_TIMED 2
// #define GRATE_SHAKE_PRATIO 3

// Grate Motor States
//#define GRATE_MOTOR_OFF 0
//#define GRATE_MOTOR_ON 1

// Grate Shaking
// Maximum interval is 1270 sec.  Multiply by 100 for 10mS precision  
#define GRATE_SHAKE_CROSS (127000)

struct {
	vnh_s * hbr;
	pwm_s * pwm;
	unsigned direction;
	unsigned fwdtime;
	unsigned revtime;
	timer_s timer;
	unsigned mode;
	unsigned long pr_accum;	// Pressure ratio accumulator
	unsigned m_good;	// Good pressure ratio accumulator rise rate
	unsigned m_bad;		// Bad pressure ratio accumulator rise rate
} grate;

vnh_s grate_hbr;

void GrateInit() {
	grate.hbr = &grate_hbr;
	grate.hbr->mota = (gpio_s) {&PORTC, 5};
	grate.hbr->motb = (gpio_s) {&PORTC, 4};
	grate.hbr->ena = (gpio_s) {&PORTC, 6};
	grate.hbr->enb = (gpio_s) {&PORTC, 6};
	vnh_reset(grate.hbr);
	
	grate.pwm = &PWM2;
	pwm_set_duty(grate.pwm, 255);
	
	GrateReset();

	GrateSwitchMode(AUTOMATIC); //set default starting state
}

void GrateReset() {
	grate.direction = FORWARD;
	grate.fwdtime = getConfig(17) * 100;
	grate.revtime = grate.fwdtime;
	
	//setup grate slopes
	grate.m_good = GRATE_SHAKE_CROSS / (getConfig(15)*50);		//divide by longest total interval in seconds
	grate.m_bad = GRATE_SHAKE_CROSS / (getConfig(16)*50);		//divide by shortest total interval in seconds

	Log_p("Grate good slope value now:");
	Logln(grate.m_good);
	Log_p("Grate bad slope value now:");
	Logln(grate.m_bad);
}

void GrateStart (void) {
	//if (grate.mode == DISABLED) return;
	switch (grate.direction) {
		case FORWARD:
			if (vnh_get_mode(grate.hbr) != VNH_FORWARD)
				vnh_forward(grate.hbr);
			timer_set(&grate.timer, grate.fwdtime);
			timer_start(&grate.timer);
			Logln("Grate: Motor on forward");
			break;
		case REVERSE:
			if (vnh_get_mode(grate.hbr) != VNH_REVERSE)
				vnh_reverse(grate.hbr);
			timer_set(&grate.timer, grate.revtime);
			timer_start(&grate.timer);
			Logln("Grate: Motor on reverse");
			break;
	}
}

void GrateStop(void) {
	if (vnh_get_mode(grate.hbr) != VNH_BRAKE) {
		vnh_brake(grate.hbr);
		timer_stop(&grate.timer);
		timer_set(&grate.timer, 0);
		Logln("Grate: Motor off");
	}
}

void GrateSwitchMode(unsigned mode) {
	if (grate.mode != mode) {
		grate.mode = mode;
		switch (mode) {
			case MANUAL:
				GrateStart();
				Logln("Grate Mode: On");
				break;
			case DISABLED:
				GrateStop();
				Logln("Grate Mode: Disabled");
				break;
			case AUTOMATIC:
				// Fall through.  Automatic is the default.
			default:
				grate.mode = AUTOMATIC;
				GrateStop();
				Logln("Grate Mode: Automatic");
				break;
		}
	}
}

unsigned GrateGetMode() {
	return grate.mode;
}

unsigned GrateGetMotorState() {
	return vnh_get_mode(grate.hbr);
}

unsigned long GrateGetAccum() {
	return grate.pr_accum;
}

void DoGrate() {
	// Check for drive system faults
	if (vnh_get_mode(grate.hbr) == VNH_FORWARD || vnh_get_mode(grate.hbr) == VNH_REVERSE) {
		Logln_p("Grate: Motor drive fault!");
		GrateSwitchMode(DISABLED);  // Disable the grate
		vnh_reset(grate.hbr);
		// Alarm
		// alarm(grate.fault_alarm);
	}
	// handle different shaking modes
	switch (grate.mode) {
		case MANUAL:	// Continuous grate shake requested by user
			return;		// Avoid timer check
		case DISABLED:	// Grate shake inhibited by user
			return;		// Nothing to do
		case AUTOMATIC:
			// TODO: Move this logic into the reactor code
			// shake only if reactor is on
			if (P_reactorLevel > OFF && T_tredLevel > COOL) {
				//condition above will leave pr_accum in the last state until conditions are met (not continuing to cycle)
				if (pRatioReactorLevel == PR_LOW) {
					grate.pr_accum = ul_addlim(grate.pr_accum, grate.m_bad, GRATE_SHAKE_CROSS);
				} else {
					grate.pr_accum = ul_addlim(grate.pr_accum, grate.m_good, GRATE_SHAKE_CROSS);
				}
				if (grate.pr_accum >= GRATE_SHAKE_CROSS) {			
					GrateStart();		//time to shake
					AshAugerStart();	// This is when we start the ash auger, too
					grate.pr_accum = 0;	// Reset pressure ratio accumulator
				}
			}
			if (!timer_read(&grate.timer)) {
				// Timer reached 0, switch off and go back to watch mode
				GrateStop();
			}
			break;
	}
}