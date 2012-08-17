void DoEngine() {   
  switch (engine_state) {
    case ENGINE_OFF:
      if (control_state == CONTROL_START) {
        TransitionEngine(ENGINE_STARTING);
      }
      break;
    case ENGINE_ON:
      if (control_state == CONTROL_OFF & millis()-control_state_entered > 100) {
        Serial.println("# Key switch turned off, Engine Shutdown.");
        TransitionEngine(ENGINE_SHUTDOWN);
      }
      if (control_state == CONTROL_START) {
        TransitionEngine(ENGINE_STARTING);
      }
      if (EngineOilPressureLevel == OIL_P_LOW  && millis() - oil_pressure_state > 500 && millis() - engine_state_entered > 3000){
        Serial.print("# Low Oil Pressure, Shutting Down Engine at: ");
        Serial.println(millis() - oil_pressure_state);
        setAlarm(ALARM_BAD_OIL_PRESSURE);
        TransitionEngine(ENGINE_SHUTDOWN);
      }
      if (P_reactorLevel == OFF & millis()-engine_state_entered > 2500) { //if reactor is at low vacuum after ten seconds, engine did not catch, so turn off
        Serial.print("# Reactor Pressure Too Low, Engine Shutdown at :");
        Serial.println(millis()-engine_state_entered);
        TransitionEngine(ENGINE_SHUTDOWN);
      }
      break;
    case ENGINE_STARTING:
      if (control_state == CONTROL_OFF & millis()-control_state_entered > 100) {
        Serial.println("# Key switch turned off, Engine Shutdown.");
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
      if (millis()-engine_state_entered > 4000) {
        TransitionEngine(ENGINE_OFF);
      }
      break;
  }
}

void TransitionEngine(int new_state) {
  //can look at engine_state for "old" state before transitioning at the end of this method
  engine_state_entered = millis();
  switch (new_state) {
    case ENGINE_OFF:
      digitalWrite(FET_IGNITION,LOW);
      digitalWrite(FET_STARTER,LOW);
      Serial.println("# New Engine State: Off");
      TransitionMessage("Engine: Off         ");
      break;
    case ENGINE_ON:
      digitalWrite(FET_IGNITION,HIGH);
      digitalWrite(FET_STARTER,LOW);
      Serial.println("# New Engine State: On");
      TransitionMessage("Engine: Running    ");
      break;
    case ENGINE_STARTING:
      digitalWrite(FET_IGNITION,HIGH);
      digitalWrite(FET_STARTER,HIGH);
      Serial.println("# New Engine State: Starting");
      TransitionMessage("Engine: Starting    ");
      break;
    case ENGINE_GOV_TUNING:
      digitalWrite(FET_IGNITION,HIGH);
      digitalWrite(FET_STARTER,LOW);
      Serial.println("# New Engine State: Governor Tuning");
      TransitionMessage("Engine: Gov Tuning  ");
      break;
    case ENGINE_SHUTDOWN:
//      lambda_PID.SetMode(MANUAL);
//      SetThrottleAngle(smoothedLambda);
      digitalWrite(FET_IGNITION,LOW);
      digitalWrite(FET_STARTER,LOW);
      Serial.println("# New Engine State: SHUTDOWN");
      TransitionMessage("Engine: Shutting down");   
      break;
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

void DoBattery() {
  #if ANA_BATT_V != ABSENT
  battery_voltage = 0.07528*(analogRead(ANA_BATT_V)-512);
  #endif
}

int getPSI(int pressure_reading){  //returns oil pressure in PSI for 20k
  return (pressure_reading-512)/-2;  //alternately use : analogRead(ANA_OIL_PRESSURE) instead of passing pressure_reading
}

