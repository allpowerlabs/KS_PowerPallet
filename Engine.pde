void DoEngine() {   //add shutdown, servo wide open, lean system, kill engine.
  switch (engine_state) {
    case ENGINE_OFF:
      if (control_state == CONTROL_START) {
        TransitionEngine(ENGINE_STARTING);
      }
      SetThrottleAngle(0);
      break;
    case ENGINE_ON:
      if (control_state == CONTROL_OFF & millis()-control_state_entered > 100) {
        TransitionEngine(ENGINE_OFF);
      }
      if (control_state == CONTROL_START) {
        TransitionEngine(ENGINE_STARTING);
      }
      DoGovernor();
      if (P_reactorLevel == OFF & millis()-engine_state_entered > 10000) { //if reactor is at low vacuum after ten seconds, engine did not catch, so turn off
        TransitionEngine(ENGINE_OFF);
      }
      if (P_reactorLevel == OIL_P_LOW && millis()-engine_state_entered>10000) {  //if reactor is at low oil pressure for more than 10 seconds (3 seconds past low oil alarm), turn off engine.
        TransitionEngine(ENGINE_OFF);
      }
//      #ifdef INT_HERTZ
//      if (CalculatePeriodHertz() < 20) { // Engine is not on
//        TransitionEngine(ENGINE_OFF);
//      }
//      #endif
      break;
    case ENGINE_STARTING:
      if (control_state == CONTROL_OFF & millis()-control_state_entered > 100) {
        TransitionEngine(ENGINE_OFF);
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
  }
  engine_state=new_state;
}

void DoOilPressure() {
  if (engine_type == 1){  //20k has analog oil pressure reader
    EngineOilPressureValue = analogRead(ANA_OIL_PRESSURE);  
    if (EngineOilPressureValue > EngineOilPressureLevelBoundary[OIL_P_LOW][0] && EngineOilPressureValue < EngineOilPressureLevelBoundary[OIL_P_LOW][1]) {
      EngineOilPressureLevel = OIL_P_LOW;
    }
    if (EngineOilPressureValue > EngineOilPressureLevelBoundary[OIL_P_HIGH][0] && EngineOilPressureValue < EngineOilPressureLevelBoundary[OIL_P_HIGH][1]) {
      EngineOilPressureLevel = OIL_P_HIGH;
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

