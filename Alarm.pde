void DoAlarmUpdate() {
  //TODO: Move these into their respective object control functions, not alarm
  if ((pRatioReactorLevel == PR_LOW || pRatioReactorLevel == PR_HIGH) && P_reactorLevel != OFF) {
    pressureRatioAccumulator += 1;
  } 
  else {
    pressureRatioAccumulator -= 5;
  }
  pressureRatioAccumulator = max(0,pressureRatioAccumulator); //keep value above 0
  pressureRatioAccumulator = min(pressureRatioAccumulator,20); //keep value below 20    
}

void DoAlarm() {
  if (auger_rev_count > 10){
    Serial.println("# Auger Bound or broken Fuel Switch");
    setAlarm(ALARM_BOUND_AUGER);
  } 
  else {
    removeAlarm(ALARM_BOUND_AUGER);
  }
  if (auger_state == AUGER_CURRENT_LOW and (millis() - auger_state_entered > 60000)){
    Serial.println("# Auger Low Current too long");
    setAlarm(ALARM_AUGER_LOW_CURRENT);
  } 
  else {
    removeAlarm(ALARM_AUGER_LOW_CURRENT);
  }
  if (auger_state == AUGER_FORWARD and (millis() - auger_state_entered > auger_on_alarm_point)){
    Serial.println("# Auger on too long");
    setAlarm(ALARM_AUGER_ON_LONG);
  } 
  else {
    removeAlarm(ALARM_AUGER_ON_LONG);
  }
  if (P_reactorLevel != OFF) { //alarm only if reactor is running
    if (auger_state == AUGER_OFF and (millis() - auger_state_entered > auger_off_alarm_point)){
      Serial.println("# Auger off too long");
      setAlarm(ALARM_AUGER_OFF_LONG);
    }  
    else {
      removeAlarm(ALARM_AUGER_OFF_LONG);
    }
    if (pressureRatioAccumulator > 100) {
      Serial.println("# Pressure Ratio is bad");
      setAlarm(ALARM_BAD_REACTOR);
    } 
    else {
      removeAlarm(ALARM_BAD_REACTOR);
    }
    if (filter_pratio_accumulator > 100) {
      Serial.println("# Filter or gas flow may be blocked");
      setAlarm(ALARM_BAD_FILTER);
    } 
    else {
      removeAlarm(ALARM_BAD_FILTER);
    }
#if T_LOW_FUEL != ABSENT
    if (Temp_Data[T_LOW_FUEL] > 230) {
      Serial.println("# Reactor fuel may be low");
      setAlarm(ALARM_LOW_FUEL_REACTOR);
    } 
    else {
      removeAlarm(ALARM_LOW_FUEL_REACTOR);
    }
#endif
  }
  if (engine_state == ENGINE_ON) {
    if (T_tredLevel != HOT && T_tredLevel != EXCESSIVE) {
      Serial.println("# T_tred too low for running engine");
      setAlarm(ALARM_LOW_TRED);
    }
    if ((Temp_Data[T_BRED] == EXCESSIVE)) {
      Serial.println("# T_bred too high for running engine");
      setAlarm(ALARM_HIGH_BRED);
    }
#if ANA_OIL_PRESSURE != ABSENT
    if (EngineOilPressureLevel == OIL_P_LOW && millis() - oil_pressure_state > 500  && millis() - engine_state_entered > 3000) {
      Serial.println("# Bad oil pressure");
      setAlarm(ALARM_BAD_OIL_PRESSURE);
    }
#endif
#if LAMBDA_SIGNAL_CHECK == TRUE
    if (lambda_input < 0.52) {
      Serial.println("# No O2 Sensor Signal");
      setAlarm(ALARM_O2_NO_SIG);
    }
    if (millis() - lambda_state_entered > 30000 && lambda_state_entered == LAMBDA_RESTART) {
      Serial.println("# No O2 Signal for more than 30 seconds");
      setAlarm(ALARM_O2_NO_SIG);
    }
#endif
  }

  if (alarm = true) {
    digitalWrite(FET_ALARM, HIGH);
  } 
  else { 
    digitalWrite(FET_ALARM, LOW);
  }
}

void setAlarm(int alarm){
  if (alarm_on[alarm] == 0){
    alarm_on[alarm] = millis();
    alarm = true;
    setAlarmQueue();
  }
}

void removeAlarm(int alarm){
  if (alarm_on[alarm] > 0) {
    alarm_on[alarm] = 0;
    setAlarmQueue();
    if (alarm_count == 0){
      alarm = false;
    }
    switch (alarm) {  //reset faults that kicked off alarm state.  Seperate function only for user intervention??
    case ALARM_AUGER_ON_LONG:
      TransitionAuger(AUGER_OFF);
      break;
    case ALARM_AUGER_OFF_LONG:
      TransitionAuger(AUGER_OFF);
      break;
    case ALARM_BAD_REACTOR:
      pressureRatioAccumulator = 0;
      break;
    case ALARM_BAD_FILTER:
      filter_pratio_accumulator = 0;
      break;
    case ALARM_LOW_FUEL_REACTOR:
      break;
    case ALARM_LOW_TRED:
      break;
    case ALARM_HIGH_BRED:
      break;
    case ALARM_BAD_OIL_PRESSURE:
      break;
    case ALARM_O2_NO_SIG:
      TransitionLambda(LAMBDA_NO_SIGNAL);
      break;
    case ALARM_AUGER_LOW_CURRENT:
      TransitionAuger(AUGER_OFF);
      break;
    case ALARM_BOUND_AUGER:
      TransitionAuger(AUGER_OFF);
      break;
    }
  }
}

void setAlarmQueue(){
  alarm_count = 0;
  for (int x = 0; x < sizeof(alarm_on)/sizeof(unsigned long); x++){
    if (alarm_on[x] != 0){
      alarm_queue[alarm_count] = alarm_on[x];
      alarm_count++;
    }
  }
}

