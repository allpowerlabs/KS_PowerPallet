/*
Ash Auger Control Logic

	To change defaults, edit AshAuger.h
*/

struct ashAuger {
	vnh_s * vnh;
	pwm_s * pwm;
	adc_s * adc;
	uint16_t low_current;		// Below this the motor is probably disconnected
	uint16_t high_current;		// Above this we are pushing too hard
	uint16_t limit_current;		// Current must be limited to this level by PWM
	uint8_t p_gain;
	unsigned int run_period;	// This is how long we run in auto mode
	unsigned int run_timer;		
	ashAugerMode_t mode;		// Modes are AUTO, MANUAL, and DISABLED
	
};

vnh_s ashAuger_vnh;
adc_s ashAuger_adc;

void AshAugerAuto();

void AshAugerInit() {
	ashAuger.vnh = &ashAuger_vnh;
	ashAuger.vnh->mota = (gpio_s) {&PORTL, 0};
	ashAuger.vnh->motb = (gpio_s) {&PORTD, 2};
	ashAuger.vnh->ena = (gpio_s) {&PORTL, 1};
	ashAuger.vnh->enb = (gpio_s) {&PORTD, 1};
	vnh_reset(ashAuger.vnh);
	
	ashAuger.pwm = &pwm1;
	pwm_init();
	
	ashAuger.adc = &ashAuger_adc;
	ashAuger.adc->n = 1;
	
	AshAugerReset();
	
	AshAugerSetMode(ASH_AUGER_AUTO);
}

void AshAugerReset() {
	ashAuger.limit_current = getConfig(28) * ASH_AUGER_ONEAMP;
	ashAuger.low_current = getConfig(29) * ASH_AUGER_ONEAMP;
	ashAuger.high_current = getConfig(30) * ASH_AUGER_ONEAMP;
	ashAuger.run_period = getConfig(31) * 5000;
	ashAuger.p_gain = 1;
	ashAuger.run_timer = 0;
}

void AshAugerSetMode(ashAugerMode_t mode){
	switch (mode) {
		case ASH_AUGER_AUTO:
			Logln_p("Ash auger control: automatic");
			break;
		case ASH_AUGER_MANUAL:
			Logln_p("Ash auger control: manual");
			break;
		case ASH_AUGER_DISABLED:
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

void AshAugerAuto(unsigned long lapse) {
	
	switch (state) {
		case STANDBY:
			if (vnh_get_mode(&ashAuger.vnh) != VNH_STANDBY) 
				vnh_standby(&ashAuger.vnh);
				Logln("Ash Auger Motor: Stand-by");
			}
			break;
		case FORWARD:
			if (vnh_get_mode(&ashAuger.vnh) != VNH_FORWARD) {
				vnh_forward(&ashAuger.vnh);
				Logln("Ash Auger Motor: Forward");
			}
			break;
		case REVERSE:
			if (vnh_get_mode(&ashAuger.vnh) != VNH_REVERSE) {
				vnh_reverse(&ashAuger.vnh);
				Logln("Ash Auger Motor: Reverse");
			}
			break;
		case BRAKE:
			if (vnh_get_mode(&ashAuger.vnh) != VNH_BRAKE) {
				vnh_brake(&ashAuger.vnh);
				Logln("Ash Auger Motor: Brake");
			}
			break;
		default:
			state = STANDBY;
			break;
	}
}

void AshAugerStop() {
	if (vnh_get_mode(&ashAuger.vnh) != VNH_STANDBY) 
		vnh_standby(&ashAuger.vnh);
}

void DoAshAuger() {
	static unsigned long last_run;
	ashAugerAutoRunTimer = u_sublim(ashAugerAutoRunTimer, millis() - last_run, 0);
	last_run = millis();
	switch (ashAugerMode) {
		case ASH_AUGER_AUTO:
			if ((P_reactorLevel > OFF) && (T_tredLevel > COLD) && ashAugerAutoRunTimer) {
				AshAugerRun();			}
			else {
				AshAugerStop();
				ashAugerAutoRunTimer = 0;
			}
			break;
		case ASH_AUGER_MANUAL:
			AshAugerRun();
			break;
		case ASH_AUGER_DISABLED:
			AshAugerStop();
			break;
		default:
			break;
	}
}

void AshAugerSetTimer(unsigned int t) {
	ashAugerAutoRunTimer = t;
}	
