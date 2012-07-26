void DoEngine() {   
  switch (engine_state) {
    case ENGINE_OFF:
      if (control_state == CONTROL_START) {
        TransitionEngine(ENGINE_STARTING);
      }
      SetThrottleAngle(0);
      break;
    case ENGINE_ON:
      if (control_state == CONTROL_OFF & millis()-control_state_entered > 100) {
        TransitionEngine(ENGINE_SHUTDOWN);
      }
      if (control_state == CONTROL_START) {
        TransitionEngine(ENGINE_STARTING);
      }
      if (EngineOilPressureLevel == OIL_P_LOW  && millis() - oil_pressure_state > 500 && millis() - engine_state_entered > 3000){
        Serial.println("# Low Oil Pressure, Shutting Down Engine");
        TransitionEngine(ENGINE_SHUTDOWN);
      }
      DoGovernor();
      if (P_reactorLevel == OFF & millis()-engine_state_entered > 10000) { //if reactor is at low vacuum after ten seconds, engine did not catch, so turn off
        TransitionEngine(ENGINE_SHUTDOWN);
      }
      if (P_reactorLevel == OIL_P_LOW && millis()-engine_state_entered>10000) {  //if reactor is at low oil pressure for more than 10 seconds (3 seconds past low oil alarm), turn off engine.
        TransitionEngine(ENGINE_SHUTDOWN);
      }
//      #ifdef INT_HERTZ
//      if (CalculatePeriodHertz() < 20) { // Engine is not on
//        TransitionEngine(ENGINE_OFF);
//      }
//      #endif
      break;
    case ENGINE_STARTING:
      if (control_state == CONTROL_OFF & millis()-control_state_entered > 100) {
        TransitionEngine(ENGINE_SHUTDOWN);
      }
      SetThrottleAngle(100); // % open
//      #ifdef INT_HERTZ
//        // Use RPM detection to stop cranking automatically
//        if (CalculatePeriodHertz() > 40) { //if engine is caught, stop cranking
//          TransitionEngine(ENGINE_ON);
//        }
//        if (engine_end_cranking < millis()) { //if engine still has not caught, stop cranking
//          TransitionEngine(ENGINE_OFF);
//        }
//      #else
        // Use starter button in the standard manual control configuration (push button to start, release to stop cranking)
        if (control_state == CONTROL_ON) {
          TransitionEngine(ENGINE_ON);
        }
//      #endif
      break;
    case ENGINE_GOV_TUNING:
      if (control_state == CONTROL_OFF) {
        TransitionEngine(ENGINE_OFF);
      }
      break;
    case ENGINE_SHUTDOWN:  
      //lambda_PID.SetMode(MANUAL);
      SetThrottleAngle(100); // % open
      if (control_state == CONTROL_OFF & millis()-control_state_entered > 100) {
        TransitionEngine(ENGINE_OFF);
      }
      break;
    case ENGINE_PRESSURE_LOW:
      if (millis() - engine_state_entered > 500){
        
        TransitionEngine(ENGINE_SHUTDOWN);
      }
      
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
      engine_end_cranking = millis() + engine_crank_period;
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
      //servo wide open, lean system, kill engine.
      Serial.println("# New Engine State: SHUTDOWN");
      TransitionMessage("Engine: Shutting down");   
      break;
  }
  engine_state=new_state;
}

void DoOilPressure() {
  if (engine_type == 1){  //20k has analog oil pressure reader
    EngineOilPressureValue = get20kPSI(analogRead(ANA_OIL_PRESSURE));  
    if (EngineOilPressureValue <= low_oil_psi){
      EngineOilPressureLevel = OIL_P_LOW;
      oil_pressure_state = millis();
    } else {
      EngineOilPressureLevel = OIL_P_NORMAL;
      oil_pressure_state = 0;
    }
  } else {
    EngineOilPressureValue = analogRead(ANA_OIL_PRESSURE);
    if (EngineOilPressureValue < 500){
      EngineOilPressureLevel = OIL_P_LOW;
      oil_pressure_state = millis();
    } else {
      EngineOilPressureLevel = OIL_P_NORMAL;
      oil_pressure_state = 0;
    }
  }
  
}

void DoGovernor() {
  governor_input = CalculatePeriodHertz();
  governor_PID.SetTunings(governor_P[0], governor_I[0], governor_D[0]);
  governor_PID.Compute();
  SetThrottleAngle(governor_output);
}

void InitGovernor() {
  governor_setpoint = 1.0;
  governor_PID.SetMode(AUTO);
  governor_PID.SetSampleTime(20);
  governor_PID.SetInputLimits(0,60);
  governor_PID.SetOutputLimits(0,100);
  governor_output = 0;
}

void SetThrottleAngle(double percent) {
 Servo_Throttle.write(throttle_valve_closed + percent*(throttle_valve_open-throttle_valve_closed));
 //servo2_pos = percent;
}

void DoBattery() {
  #if ANA_BATT_V != ABSENT
  battery_voltage = 0.07528*(analogRead(ANA_BATT_V)-512);
  #endif
}

int get20kPSI(int pressure_reading){  //returns oil pressure in PSI for 20k
  return (pressure_reading-512)/-2;  //alternately use : analogRead(ANA_OIL_PRESSURE) instead of passing pressure_reading
}

