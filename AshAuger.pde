/*
Ash Auger Control Logic
TODO:
	Hack in VNH bridge control
	Get rid of duty cycle settings.  Should be on when reactor is running
	Add current limit and reversing settings

	To change defaults, edit AshAuger.h
*/

#ifndef ARDUINO
#include "Config.h"
#include "AshAuger.h"
#endif

vnh_s ashAuger;
ashAugerMode_t ashAugerMode;

unsigned long ashAugerAutoRunTimer;

// Interrupt service routine for dealing with the ash auger H-bridge
ISR(TIMER5_COMPA_vect) {
	vnh_tick(&ashAuger);
}
// Init routine for timer 5, which we use for monitoring the H-bridge
void timer5_init() {
	// Timer 5 control registers
	TCCR5A = 0;
	TCCR5B = _BV(WGM52) | _BV(CS51) | _BV(CS50);  //CTC mode, clk/64 (4uS)
	TCCR5C = 0;
	// Timer 5 output compare registers
	OCR5AH = ASH_AUGER_PERIOD_HI;
	OCR5AL = ASH_AUGER_PERIOD_LO;
	// Timer 5 interrupt mask
	TIMSK5 = _BV(OCIE5A); // Output compare A interrupt enable
}

void AshAugerInit() {
	ashAuger.mota = (gpio_s) {&PORTL, 0};
	ashAuger.motb = (gpio_s) {&PORTD, 2};
	ashAuger.ena = (gpio_s) {&PORTL, 1};
	ashAuger.enb = (gpio_s) {&PORTD, 1};
	ashAuger.pwm = (gpio_s) {&PORTL, 2};
	ashAuger.adc = 7;
	ashAuger.mod.ramp = 1;
	ashAuger.mod.target = VNH_MOD_MAX;
	ashAuger.mod.mode = VNH_PWM_SOFT;
	ashAuger.climit = ASH_AUGER_CLIMIT;
	ashAuger.chyst = ASH_AUGER_CHYST;
	//ashAuger.pwm_stop = timer5_stop;
	//ashAuger.pwm_start = timer5_start;
	vnh_reset(&ashAuger);
	
	//timer5_init();
	
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