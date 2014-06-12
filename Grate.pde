
struct {
	vnh_s * hbr;
	pwm_s * pwm;
	unsigned direction;
	unsigned fwdtime;
	unsigned revtime;
	timer_s timer;
	unsigned mode;
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

	GrateSwitchMode(GRATE_SHAKE_PRATIO); //set default starting state
}

void GrateStart (void) {
	switch (grate.direction) {
		case FORWARD:
			if (vnh_get_mode(grate.hbr) != VNH_FORWARD)
				vnh_forward(grate.hbr);
			timer_set(&grate.timer, grate.fwdtime);
			timer_start(&grate.timer); 
			break;
		case REVERSE:
			if (vnh_get_mode(grate.hbr) != VNH_REVERSE)
				vnh_reverse(grate.hbr);
			timer_set(&grate.timer, grate.revtime);
			timer_start(&grate.timer);
			break;
	}
}

void GrateStop(void) {
	vnh_brake(grate.hbr);
	timer_stop(&grate.timer);
	timer_set(&grate.timer, 0);
}

void GrateReset() {
	//setup grate slopes
	m_grate_bad = (GRATE_SHAKE_INIT-GRATE_SHAKE_CROSS)/grate_min_interval;
	m_grate_good = (GRATE_SHAKE_INIT-GRATE_SHAKE_CROSS)/grate_max_interval;
	
	grate.direction = FORWARD;
	grate.fwdtime = grate_on_interval * 100;
	grate.revtime = grate_on_interval * 100;
}

void GrateSwitchMode(unsigned mode) {
	if (grate.mode != mode) {
		grate.mode = mode;
		switch (mode) {
			case GRATE_SHAKE_ON:
				GrateStart();
				grate_motor_state = GRATE_MOTOR_ON;
				Logln("Grate Mode: On");
				break;
			case GRATE_SHAKE_OFF:
				GrateStop();
				grate_motor_state = GRATE_MOTOR_OFF;
				Logln("Grate Mode: Disabled");
				break;
			case GRATE_SHAKE_PRATIO:
				GrateStop();
				grate_val = GRATE_SHAKE_INIT;
				grate_motor_state = GRATE_MOTOR_OFF;
				Logln("Grate Mode: Pressure Ratio");
				break;
			case GRATE_SHAKE_TIMED:
				GrateStart();
				grate_motor_state = GRATE_MOTOR_ON;
				Logln("Grate Mode: Timed Shake");
				break;
			default:
				GrateStop();
				grate_val = GRATE_SHAKE_INIT;
				grate_motor_state = GRATE_MOTOR_OFF;
				Logln("Grate Mode: Pressure Ratio");
				break;
		}
	}
}

unsigned GrateGetMode() {
	return grate.mode;
}

void DoGrate() { // call once per second	  
	// handle different shaking modes
	switch (grate.mode) {
		case GRATE_SHAKE_ON:	// Continuous grate shake requested by user
			break;
		case GRATE_SHAKE_OFF:	// Grate shake inhibited by user
			break;
		case GRATE_SHAKE_PRATIO:
			if (engine_state == ENGINE_ON || engine_state == ENGINE_STARTING || (P_reactorLevel > OFF && T_tredLevel > COOL)) { //shake only if reactor is on and/or engine is on
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
				// Switch to timed shaking mode
				GrateSwitchMode(GRATE_SHAKE_TIMED);
				AshAugerStart();	// This is when we start the ash auger, too
			}
			break;
		case GRATE_SHAKE_TIMED:
			if (!timer_read(&grate.timer)) {
				// Timer reached 0, switch off and go back to watch mode
				GrateStop();
				GrateSwitchMode(GRATE_SHAKE_PRATIO);
			}
			break;
	}
}