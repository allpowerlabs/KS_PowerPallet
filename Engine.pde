/*
	Engine states: OFF, ON, START
	OFF - Ignition and starter are off.  No sensor checks are performed.
	ON - Ignition is on, starter is off.  Oil pressure is monitored.
	START - Ignition and starter are on.  Oil pressure is not monitored.  After
		30 seconds in start mode, engine is returned to off state.
*/

struct {
	unsigned ignition_pin;		// Pin number of ignition
	unsigned starter_pin;		// Pin number of starter
	unsigned grid_tie;			// 1 for grid-tie controller
	unsigned ext_fuel;			// 1 for external fuel
	unsigned control_state;		// OFF, ON, START
	timer_s timer;				// Control timer

} engine;

void DoEngine() {
	strcpy_P(buf, engine_shutdown);
	switch (engine_state) {
		case ENGINE_OFF:
			if (control_state == CONTROL_START) {
				TransitionEngine(ENGINE_STARTING);
			}
			if (grid_tie == 1){
				if (EngineShutdownFromAlarm()){
					digitalWrite(FET_STARTER,HIGH);
				} else {
					digitalWrite(FET_STARTER,LOW);
				}
			}
			break;
		case ENGINE_ON:
			if (control_state == CONTROL_OFF & millis()-control_state_entered > 100) {
				Log_p("Key switch turned off"); Logln(buf);
				TransitionEngine(ENGINE_SHUTDOWN);
			}
			if (control_state == CONTROL_START) {
				TransitionEngine(ENGINE_STARTING);
			}
			if (grid_tie != 1) {
				// Shut the engine off if the oil pressure is low
				if ((EngineOilPressureLevel == OIL_P_LOW) && (millis() - oil_pressure_state > 500) && (millis() - engine_state_entered > 1000)){
					// If we've been running for more than 10 seconds and the oil pressure has gone low, raise an alarm
					if ((millis() - engine_state_entered) > 10000) setAlarm(ALARM_BAD_OIL_PRESSURE);
					Logln_p("Low Oil Pressure, Shutting Down Engine!");
					// Shut off the ignition IMMEDIATELY, instead of waiting for the intake to purge
					TransitionEngine(ENGINE_OFF);
				}
			}
			if (Temp_Data[T_ENG_COOLANT] > high_coolant_temp){
				setAlarm(ALARM_HIGH_COOLANT_TEMP);
				Log_p("Engine coolant temp too high"); Logln(buf);
				TransitionEngine(ENGINE_SHUTDOWN);
			}
			if (alarm_on[ALARM_TRED_LOW] > shutdown[ALARM_TRED_LOW]){
				Log_p("Reduction zone temp too low"); Logln(buf);
				TransitionEngine(ENGINE_SHUTDOWN);
			}
			if (alarm_on[ALARM_TTRED_HIGH] > shutdown[ALARM_TTRED_HIGH]){
				Log_p("Top of reduction zone temp too high"); Logln(buf);
				TransitionEngine(ENGINE_SHUTDOWN);
			}
			if (alarm_on[ALARM_TBRED_HIGH] > shutdown[ALARM_TBRED_HIGH]){
				Log_p("Bottom of reduction zone temp too high"); Logln(buf);
				TransitionEngine(ENGINE_SHUTDOWN);
			}
			if (Press[P_COMB] < -7472) {
				Log_p("Reactor Pressure too high (above 30 inch water)"); Logln(buf);
				setAlarm(ALARM_HIGH_PCOMB);
				TransitionEngine(ENGINE_SHUTDOWN);
			}
			if (auger_state == AUGER_ALARM) {
				TransitionEngine(ENGINE_SHUTDOWN);
			}
			break;
		case ENGINE_STARTING:
			if (control_state == CONTROL_OFF & millis()-control_state_entered > 100) {
				Log_p("Key switch turned off"); Logln(buf);
				TransitionEngine(ENGINE_SHUTDOWN);
			}
			// Use starter button in the standard manual control configuration (push button to start, release to stop cranking)
			if (control_state == CONTROL_ON) {
				TransitionEngine(ENGINE_ON);
			}
			break;
		case ENGINE_GOV_TUNING:
			if (control_state == CONTROL_OFF) {
				TransitionEngine(ENGINE_OFF);
			}
			break;
		case ENGINE_SHUTDOWN:
			// Don't delay shutdown for grid tie
			if (grid_tie || (millis() - engine_state_entered > 3500)) {
				TransitionEngine(ENGINE_OFF);
			}
			break;
	}
}

void TransitionEngine(int new_state) {
  strcpy_P(p_buffer, new_engine_state);
  //can look at engine_state for "old" state before transitioning at the end of this method
  engine_state_entered = millis();
  if (grid_tie == 0){
    switch (new_state) {
      case ENGINE_OFF:
        digitalWrite(FET_IGNITION,LOW);
        digitalWrite(FET_STARTER,LOW);
        Log(p_buffer); Logln_p("Off");
        break;
      case ENGINE_ON:
        digitalWrite(FET_IGNITION,HIGH);
        digitalWrite(FET_STARTER,LOW);
        Log(p_buffer); Logln_p("On");
        break;
      case ENGINE_STARTING:
        digitalWrite(FET_IGNITION,HIGH);
        digitalWrite(FET_STARTER,HIGH);
        Log(p_buffer); Logln_p("Starting");
        break;
      case ENGINE_GOV_TUNING:
        digitalWrite(FET_IGNITION,HIGH);
        digitalWrite(FET_STARTER,LOW);
        Log(p_buffer); Logln_p("Governor Tuning");
        break;
      case ENGINE_SHUTDOWN:
        Log(p_buffer); Logln_p("SHUTDOWN");
        break;
    }
  } else { //Engine controlled by Derp Sea for Gridtie
    switch (new_state) {
      case ENGINE_OFF:
        Log(p_buffer); Logln_p("Off");
        digitalWrite(FET_STARTER,LOW);
        if (EngineShutdownFromAlarm()){
          digitalWrite(FET_STARTER,HIGH);
        } else {
          digitalWrite(FET_STARTER,LOW);
        }
        break;
      case ENGINE_ON:
        Log(p_buffer); Logln_p("On");
        digitalWrite(FET_IGNITION,LOW);
        digitalWrite(FET_STARTER,LOW);
        break;
      case ENGINE_STARTING:
        Log(p_buffer); Logln_p("Starting");
        digitalWrite(FET_IGNITION,LOW);
        digitalWrite(FET_STARTER,LOW);
        break;
      case ENGINE_GOV_TUNING:     //How is this handled by Derp Sea?
        Log(p_buffer); Logln_p("Gov Tuning");
        digitalWrite(FET_IGNITION,LOW);
        digitalWrite(FET_STARTER,LOW);
        break;
      case ENGINE_SHUTDOWN:
        Log(p_buffer); Logln_p("Shutdown");
        digitalWrite(FET_IGNITION,LOW);
        digitalWrite(FET_STARTER,LOW);
        break;
    }
  }
  engine_state=new_state;
}

void DoOilPressure() {
	smoothAnalog(ANA_OIL_PRESSURE);
	if (engine_type == 1){  //20k has analog oil pressure reader
		//EngineOilPressureValue = getPSI(analogRead(ANA_OIL_PRESSURE));
		EngineOilPressureValue = getPSI(smoothed[getAnaArray(ANA_OIL_PRESSURE)]);
			if (EngineOilPressureValue <= low_oil_psi && EngineOilPressureLevel != OIL_P_LOW){
			EngineOilPressureLevel = OIL_P_LOW;
			oil_pressure_state = millis();
		}
		if (EngineOilPressureValue > low_oil_psi && EngineOilPressureLevel != OIL_P_NORMAL){
		EngineOilPressureLevel = OIL_P_NORMAL;
		oil_pressure_state = 0;
	}
	} else {
		EngineOilPressureValue = analogRead(ANA_OIL_PRESSURE);
		if (EngineOilPressureValue <= 500 && EngineOilPressureLevel != OIL_P_LOW){
			EngineOilPressureLevel = OIL_P_LOW;
			oil_pressure_state = millis();
		}
		if (EngineOilPressureValue > 500 && EngineOilPressureLevel != OIL_P_NORMAL){
			EngineOilPressureLevel = OIL_P_NORMAL;
			oil_pressure_state = 0;
		}
	}

}

int getPSI(int pressure_reading){  //returns oil pressure in PSI for 20k
	return (pressure_reading-512)/-2;  //alternately use : analogRead(ANA_OIL_PRESSURE) instead of passing pressure_reading
}

boolean EngineShutdownFromAlarm() {
  boolean alarms = false;
  for (int i=0; i< ALARM_NUM; i++){
    if ((shutdown[i]>0) && (alarm_on[i] >= shutdown[i])){
      alarms = true;
      break;
     }
  }
  return alarms;
}
