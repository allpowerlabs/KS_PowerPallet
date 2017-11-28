/*
	Engine states: OFF, ON, START
	OFF - Ignition and starter are off.  No sensor checks are performed.
	ON - Ignition is on, starter is off.  Oil pressure is monitored.
	START - Ignition and starter are on.  Oil pressure is not monitored.  After
		30 seconds in start mode, engine is returned to off state.
*/

void DoControlInputs() {
	int control_input = analogRead(ANA_ENGINE_SWITCH);
    if (control_input > 515){
		if (control_state == CONTROL_OFF){
			control_state = CONTROL_START;
			control_state_entered = millis();
			Logln_p("Deep Sea controller set to: Start");
		}
		if (control_state == CONTROL_START && (millis() - control_state_entered >= 5000)){
			control_state = CONTROL_ON;
			Logln_p("Deep Sea controller set to: On");
		}
    } else {
		if (control_state != CONTROL_OFF) {
			control_state_entered = millis();
			control_state = CONTROL_OFF;
			Logln_p("Deep Sea controller set to:  Off");
		}
    }

}

void DoEngine() {
  strcpy_P(buf, engine_shutdown);
  switch (engine_state) {
    case ENGINE_OFF:
      if (control_state == CONTROL_START) {
        TransitionEngine(ENGINE_STARTING);
      }
      break;
    case ENGINE_ON:
		if (control_state == CONTROL_OFF & millis()-control_state_entered > 100) {
			Log_p("Engine turned off"); Logln(buf);
			TransitionEngine(ENGINE_SHUTDOWN);
		}
		if (control_state == CONTROL_START) {
			TransitionEngine(ENGINE_STARTING);
		}
		if (Temp_Data[T_ENG_COOLANT] > high_coolant_temp) {
  			Log_p("Engine coolant temp too high"); Logln(buf);
  			setAlarm(&ALARM_HIGH_COOLANT_TEMP);
  			TransitionEngine(ENGINE_SHUTDOWN);
  		}
		if ((P_reactorLevel != OFF) && (Temp_Data[T_TRED] < tred_low_temp) && (engine_state_entered + ALARM_TRED_LOW.shutdown < millis())) {
			Log_p("Reduction zone temp too low"); Logln(buf);
			setAlarm(&ALARM_TRED_LOW);
			TransitionEngine(ENGINE_SHUTDOWN);
		}
		if (ALARM_TTRED_HIGH.on > ALARM_TTRED_HIGH.shutdown){
			Log_p("Top of reduction zone temp too high"); Logln(buf);
			TransitionEngine(ENGINE_SHUTDOWN);
		}
		if (ALARM_TBRED_HIGH.on > ALARM_TBRED_HIGH.shutdown){
			Log_p("Bottom of reduction zone temp too high"); Logln(buf);
			TransitionEngine(ENGINE_SHUTDOWN);
		}
		if (Press[P_COMB] < -7472) {
			Log_p("Reactor Pressure too high (above 30 inch water)"); Logln(buf);
			setAlarm(&ALARM_HIGH_PCOMB);
			TransitionEngine(ENGINE_SHUTDOWN);
		}
		if (auger_state == AUGER_ALARM) {
			TransitionEngine(ENGINE_SHUTDOWN);
		}
		if (engine_shutdown_alarm) {
			engine_shutdown_alarm = NULL;
			TransitionEngine(ENGINE_SHUTDOWN);
		}
	break;
    case ENGINE_STARTING:
		if (control_state == CONTROL_OFF & millis()-control_state_entered > 100) {
			Log_p("Engine turned off"); Logln(buf);
			TransitionEngine(ENGINE_SHUTDOWN);
		}
		if (control_state == CONTROL_ON) {
			TransitionEngine(ENGINE_ON);
		}
		break;
    case ENGINE_SHUTDOWN:
		if ((millis() - engine_state_entered > 3500)) {
			TransitionEngine(ENGINE_OFF);
		}
		break;
  }
}

void TransitionEngine(int new_state) {
	strcpy_P(p_buffer, new_engine_state);
	//can look at engine_state for "old" state before transitioning at the end of this method
	engine_state_entered = millis();

	switch (new_state) {
		case ENGINE_OFF:
			Log(p_buffer); Logln_p("Off");
			digitalWrite(FET_RUN_ENABLE,LOW);
			break;
		case ENGINE_ON:
			Log(p_buffer); Logln_p("On");
			digitalWrite(FET_RUN_ENABLE,LOW);
			break;
		case ENGINE_STARTING:
			Log(p_buffer); Logln_p("Starting");
			digitalWrite(FET_RUN_ENABLE,LOW);
			break;
		case ENGINE_SHUTDOWN:
			Log(p_buffer); Logln_p("Shutdown");
			digitalWrite(FET_RUN_ENABLE,HIGH);
			break;
	}
	engine_state=new_state;
}

// This function prints a message to the log and signals to the engine state machine that it should shut down
void ShutdownEngine (struct alarm * alarm) {
	Log_p("Engine Shutdown From Alarm: ");
	strcpy_P(p_buffer, alarm->message);
	Logln(p_buffer);

	engine_shutdown_alarm = alarm;
}
