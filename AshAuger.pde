/*
Ash Auger Control Logic

	To change defaults, edit AshAuger.h
*/

struct ashAuger {
	vnh_s * vnh;
	pwm_s * pwm;
	adc_s * adc;
	unsigned low_current;		// Below this the motor is probably faulty or disconnected
	unsigned high_current;		// Above this we are pushing too hard
	unsigned limit_current;		// Current must be limited to this level by PWM
	unsigned oc_accum;
	unsigned p_gain;
	unsigned run_period;	// This is how long we run in auto mode
	unsigned run_timer;		// Time how long we've been running 
	unsigned drive_timer;	//  Time in the current drive state
	ashAugerMode_t mode;		// Run modes are AUTO, MANUAL, and DISABLED
	enum drive_state {
		STANDBY,
		FORWARD,
		FORWARD_BRAKE,
		REVERSE,
		REVERSE_BRAKE
	}
};

vnh_s ashAuger_vnh;
adc_s ashAuger_adc;

void AshAugerRun();

void AshAugerInit() {
	// Initialize H-bridge
	ashAuger.vnh = &ashAuger_vnh;
	ashAuger.vnh->mota = (gpio_s) {&PORTL, 0};
	ashAuger.vnh->motb = (gpio_s) {&PORTD, 2};
	ashAuger.vnh->ena = (gpio_s) {&PORTL, 1};
	ashAuger.vnh->enb = (gpio_s) {&PORTD, 1};
	vnh_reset(ashAuger.vnh);
	// Initialize PWM
	ashAuger.pwm = &pwm1;
	// Initialize ADC
	ashAuger.adc = &ashAuger_adc;
	ashAuger.adc->n = 1;
	// Reset control values
	AshAugerReset();
	// Switch to AUTO mode
	AshAugerSwitchMode(ASH_AUGER_AUTO);
}

void AshAugerReset() {
	ashAuger.limit_current = getConfig(28) * ASH_AUGER_ONEAMP;
	ashAuger.low_current = getConfig(29) * ASH_AUGER_ONEAMP;
	ashAuger.high_current = getConfig(30) * ASH_AUGER_ONEAMP;
	ashAuger.run_period = getConfig(31) * 5000;
	ashAuger.p_gain = 1;
	ashAuger.run_timer = 0;
	ashAuger.drive_timer = 0;
	ashAuger.oc_accum = 0;
}

void AshAugerSwitchMode(ashAugerMode_t mode){
	switch (mode) {
		case ASH_AUGER_AUTO:
			AshAugerStart();
			Logln_p("Ash auger control: automatic");
			break;
		case ASH_AUGER_MANUAL:
			AshAugerStart();
			Logln_p("Ash auger control: manual");
			break;
		case ASH_AUGER_DISABLED:
			AshAugerStop();
			Logln_p("Ash auger control: disabled");
			break;
		default:
			Logln_p("Ash auger on fire!");
			break;
	}
	ashAuger.mode = mode;
}

ashAugerMode_t AshAugerGetMode(){
	return ashAuger.mode;
}

void AshAugerStart() {
	// Don't reset the drive state of a running auger
	if (ashAuger.drive_state == STANDBY)
		ashAuger.drive_state = FORWARD;
	// Restart the run timer
	ashAuger.run_timer = ashAuger.run_period;
}

void AshAugerStop() {
	ashAuger.drive_state = STANDBY;
	ashAuger.run_timer = 0;
}

void DoAshAuger() {
	static unsigned long last_run;
	unsigned long lapse;
	unsigned duty; 
	unsigned vnh_mode;
	unsigned current;
	
	// Update timers
	lapse = millis() - last_run;
	last_run = millis();
	ashAuger.run_timer = u_sublim(ashAuger.run_timer, lapse, 0);
	ashAuger.drive_timer = u_sublim(ashAuger.drive_timer, lapse, 0);
	
	// Current control
	duty = pwm_get_duty(ashAuger->pwm);
	vnh_mode = vnh_get_mode(ashAuger->vnh);
	current = adc_read(ashAuger_adc);
	// Only modify duty cycle and over-current accumulator in FWD or REV
	if (vnh_mode == VNH_FORWARD || vnh_mode == VNH_REVERSE) {
		// TO-DO: Make this PI control
		// Ramp up when below target
		if (current < ashAuger->limit_current) 
			duty = u_addlim(duty, ashAuger->p_gain, PWM_MAX);
		// Otherwise, ramp down
		else 
			duty = u_sublim(duty, ashAuger->p_gain, 0);
		// Set duty cycle
		pwm_set_duty(ashAuger->pwm, duty);
		
		// Obstruction detection
		if (current > ashAuger->high_current)
			ashAuger.oc_accum += ASH_AUGER_ACCUM_RISE;
		else
			ashAuger.oc_accum -= ASH_AUGER_ACCUM_FALL;
	}
	// Check for a completely stuck auger
	if (ashAuger.oc_accum > ASH_AUGER_ACCUM_FAULT) {
		AshAugerSwitchMode(ASH_AUGER_DISABLED);  // Disable the auger
		// Ring the alarm, like Tenor Saw
	}
	// Stop the ash auger when the timer runs out in AUTO mode
	if (ashAuger.mode == ASH_AUGER_AUTO) {
		if (!run_timer) AshAugerStop();
	}
	
	/* 
	Drive state handling.
	The basic strategy is to go forward until we encounter an obstruction.  We 
	then brake, reverse for a moment, brake again, and resume going forward.  
	There's a minimum forward time, so we don't reverse more than we go forward
	when the auger is stuck.  Over-current is cumulative, so we can raise an
	alarm if the auger can't come unbound.
	*/
	switch (ashAuger.drive_state) {
		case STANDBY:
			if (vnh_mode != VNH_STANDBY) {
				vnh_standby(&ashAuger.vnh);
				ashAuger.oc_accum = 0;  // Reset accumulator when at rest
				Logln("Ash Auger Motor: Stand-by");
			}
			break;
		case FORWARD:
			if (vnh_mode != VNH_FORWARD) {
				vnh_forward(&ashAuger.vnh);
				ashAuger.drive_timer = ASH_AUGER_FORWARD_TIME;
				Logln("Ash Auger Motor: Forward");
			}
			// Try for some amount of time before giving up in a stall
			if (!ashAuger.drive_timer && (ashAuger.oc_accum > ASH_AUGER_ACCUM_STALL)) {
				ashAuger.drive_state = FORWARD_BRAKE;
			}
			break;
		case FORWARD_BRAKE:
			if (vnh_mode != VNH_BRAKE) {
				vnh_brake(&ashAuger.vnh);
				ashAuger.drive_timer = ASH_AUGER_BRAKE_TIME;
				Logln("Ash Auger Motor: Brake");
			}
			if (!ashAuger.drive_timer) {
				ashAuger.drive_state = REVERSE;
			}
			break;
		case REVERSE:
			if (vnh_mode != VNH_REVERSE) {
				vnh_reverse(&ashAuger.vnh);
				ashAuger.drive_timer = ASH_AUGER_REVERSE_TIME;
				Logln("Ash Auger Motor: Reverse");
			}
			// Reverse until the timer runs out
			if (!ashAuger.drive_timer) {
				ashAuger.drive_state = REVERSE_BRAKE;
			}
			break;
		case REVERSE_BRAKE:
			if (vnh_mode != VNH_BRAKE) {
				vnh_brake(&ashAuger.vnh);
				ashAuger.drive_timer = ASH_AUGER_BRAKE_TIME;
				Logln("Ash Auger Motor: Brake");
			}
			if (!ashAuger.drive_timer) {
				ashAuger.drive_state = FORWARD;
			}
			break;
		default:
			state = STANDBY;
			break;
	}
}
