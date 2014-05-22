/*
Ash Auger Control Logic
TODO:
	Hack in VNH bridge control
	Get rid of duty cycle settings.  Should be on when reactor is running
	Add current limit and reversing settings

	To change defaults, edit AshAuger.h
*/

struct ashAuger {
	vnh_s * vnh;
	pwm_s * pwm;
	adc_s * adc;
	uint16_t low_current;
	uint16_t high_current;
	uint16_t limit_current;
	uint8_t p_gain;
	unsigned int run_period;
	unsigned int run_timer;
	ashAugerMode_t mode;
};

vnh_s ashAuger_vnh;
adc_s ashAuger_adc;

unsigned long ashAugerAutoRunTimer;


void AshAugerInit() {
	ashAuger.limit_current = 0;
	ashAuger.p_gain = 1;
	
	ashAuger.vnh = &ashAuger_vnh;
	ashAuger.vnh->mota = (gpio_s) {&PORTL, 0};
	ashAuger.vnh->motb = (gpio_s) {&PORTD, 2};
	ashAuger.vnh->ena = (gpio_s) {&PORTL, 1};
	ashAuger.vnh->enb = (gpio_s) {&PORTD, 1};
	vnh_reset(ashAuger.vnh);
	
	ashAuger.pwm = &pwm1;
	pwm_init();
	pwm_set_duty(&pwm1, 127);
	
	ashAuger.adc = &ashAuger_adc;
	ashAuger.adc->n = 1;
	
	AshAugerReset();
	
	ashAugerAutoRunTimer = 0;
	AshAugerSetMode(ASH_AUGER_AUTO);
}

void AshAugerReset() {
	ashAuger.climit = getConfig(28) * ASH_AUGER_ONEAMP;
	ashAuger.chyst = getConfig(29) * ASH_AUGER_ONEAMP;
	ashAugerAutoRunPeriod = getConfig(30) * 5000;
}

void AshAugerSetMode(ashAugerMode_t mode){
	switch (mode) {
		case ASH_AUGER_AUTO:
			Logln_p("Ash auger automatic mode");
			break;
		case ASH_AUGER_MANUAL:
			Logln_p("Ash auger manual mode");
			break;
		case ASH_AUGER_DISABLED:
			Logln_p("Ash auger disabled");
			break;
		default:
			Logln_p("Ash auger unknown mode requested!");
			break;
	}
	ashAugerMode = mode;
}

ashAugerMode_t AshAugerGetMode(){
	return ashAugerMode;
}

unsigned long limit_accum=0;

void AshAugerRun() {
	enum motor_states {
		STANDBY,
		FORWARD,
		REVERSE,
		STALL,
	};
	
	static unsigned state=STANDBY;
	static unsigned long last=0;
	static unsigned long run_timer=0;
	
	vnh_status_s status;
	
	status = vnh_get_status(&ashAuger);

	vnh_adc_tick(&ashAuger); // Moved out of interrupt landistan

	if (vnh_get_fault(&ashAuger)) limit_accum += ASH_AUGER_CLIMIT_ACCUM_UP;
	else {
		if (limit_accum > ASH_AUGER_CLIMIT_ACCUM_DOWN)
			limit_accum -= ASH_AUGER_CLIMIT_ACCUM_DOWN;
		else limit_accum = 0;
	}
	
	switch (state) {
		case STANDBY:
			if (status.mode != VNH_STANDBY) {
				vnh_standby(&ashAuger);
				run_timer = 0;
				Logln("Ash Auger Mode: Stand-by");
			}
			state = FORWARD;
			break;
		case FORWARD:
			if (status.mode != VNH_FORWARD) {
				vnh_forward(&ashAuger);
				run_timer = 0;
				Logln("Ash Auger Mode: Forward");
			}
			if (limit_accum > ASH_AUGER_CLIMIT_ACCUM_HIGH && run_timer > ASH_AUGER_FORWARD_TIME_MIN) {
				state = STALL;
			}
			break;
		case REVERSE:
			if (status.mode != VNH_REVERSE) {
				run_timer = 0;
				vnh_reverse(&ashAuger);
				Logln("Ash Auger Mode: Reverse");
			}
			if (run_timer > ASH_AUGER_REVERSE_TIME) state = FORWARD;
			break;
		case STALL:
			if (status.mode != VNH_BRAKE) {
				vnh_brake(&ashAuger);
				run_timer = 0;
				Logln("Ash Auger Mode: Brake");
			}
			if (run_timer > ASH_AUGER_STALL_TIME) state = REVERSE;
			break;
		default:
			state = STANDBY;
			break;
	}
	run_timer += millis() - last;
	last = millis();
}

void AshAugerStop() {
	vnh_status_s status;
	
	status = vnh_get_status(&ashAuger);
	
	if (status.mode != VNH_STANDBY) vnh_standby(&ashAuger);
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
