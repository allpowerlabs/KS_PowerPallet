void DoEngine() {   
  strcpy_P(buf, engine_shutdown);
  switch (engine_state) {
    case ENGINE_OFF:
      if (control_state == CONTROL_START) {
        TransitionEngine(ENGINE_STARTING);
      }
      if (grid_tie == 1){
        if (EngineShutdownFromAlarm()){
          digitalWrite(FET_IGNITION,HIGH);
        } else {
          digitalWrite(FET_IGNITION,LOW);
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
        if (EngineOilPressureLevel == OIL_P_LOW  && millis() - oil_pressure_state > 500 && millis() - engine_state_entered > 3000){
          Log_p("Low Oil Pressure, Shutting Down Engine at: ");
          Logln(millis() - oil_pressure_state);
          setAlarm(ALARM_BAD_OIL_PRESSURE);
          TransitionEngine(ENGINE_SHUTDOWN);
        }
      }
      if (P_reactorLevel == OFF & millis() - engine_state_entered > 2500 && grid_tie != 1) { //if reactor is at low vacuum after ten seconds, engine did not catch, so turn off
        Log_p("Reactor Pressure Too Low, Engine Shutdown at :");
        Logln(millis()-engine_state_entered);
        TransitionEngine(ENGINE_SHUTDOWN);
      }
      if (Press[P_COMB] < -7472) {  
        Log_p("Reactor Pressure too high (above 30 inch water)"); Logln(buf);
        setAlarm(ALARM_HIGH_PCOMB);
        TransitionEngine(ENGINE_SHUTDOWN);
      }
      if (alarm_on[ALARM_HIGH_COOLANT_TEMP] > shutdown[ALARM_HIGH_COOLANT_TEMP]){
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
      break;
    case ENGINE_STARTING:
      if (control_state == CONTROL_OFF & millis()-control_state_entered > 100) {
        Log_p("Key switch turned off"); Logln(buf);
        TransitionEngine(ENGINE_SHUTDOWN);
      }
      if (control_state == CONTROL_ON) { // Use starter button in the standard manual control configuration (push button to start, release to stop cranking)
        TransitionEngine(ENGINE_ON);
      }
      break;
    case ENGINE_GOV_TUNING:
      if (control_state == CONTROL_OFF) {
        TransitionEngine(ENGINE_OFF);
      }
      break;
    case ENGINE_SHUTDOWN:  
      if (millis() - engine_state_entered > 3500) {
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
        //TransitionMessage("Engine: Off         ");
        break;
      case ENGINE_ON:
        digitalWrite(FET_IGNITION,HIGH);
        digitalWrite(FET_STARTER,LOW);
        Log(p_buffer); Logln_p("On"); 
        //TransitionMessage("Engine: Running    ");
        break;
      case ENGINE_STARTING:
        digitalWrite(FET_IGNITION,HIGH);
        digitalWrite(FET_STARTER,HIGH);
        Log(p_buffer); Logln_p("Starting"); 
        //TransitionMessage("Engine: Starting    ");
        break;
      case ENGINE_GOV_TUNING:
        digitalWrite(FET_IGNITION,HIGH);
        digitalWrite(FET_STARTER,LOW);
        Log(p_buffer); Logln_p("Governor Tuning"); 
        //TransitionMessage("Engine: Gov Tuning  ");
        break;
      case ENGINE_SHUTDOWN:
  //      lambda_PID.SetMode(MANUAL);
  //      SetThrottleAngle(smoothedLambda);
  //      digitalWrite(FET_IGNITION,LOW);
  //      digitalWrite(FET_STARTER,LOW);
        Log(p_buffer); Logln_p("SHUTDOWN"); 
        //TransitionMessage("Engine: Shutting down");   
        break;
    }
  } else { //Engine controlled by Deap Sea for Gridtie
    switch (new_state) {
      case ENGINE_OFF:
        Log(p_buffer); Logln_p("Off");
        digitalWrite(FET_STARTER,LOW);
        if (EngineShutdownFromAlarm()){
          digitalWrite(FET_IGNITION,HIGH);
        } else {
          digitalWrite(FET_IGNITION,LOW);
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
      case ENGINE_GOV_TUNING:     //How is this handled by Deap Sea?
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

void DoBattery() {
  #if ANA_BATT_V != ABSENT
  battery_voltage = 0.07528*(analogRead(ANA_BATT_V)-512);
  #endif
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
