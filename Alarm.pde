void DoAlarmUpdate() {
  //TODO: Move these into their respective object control functions, not alarm
  if ((pRatioReactorLevel == PR_LOW || pRatioReactorLevel == PR_HIGH) && P_reactorLevel != OFF && T_tredLevel != COLD) {  
    pressureRatioAccumulator += 1;
  } 
  else {
    pressureRatioAccumulator -= 5;
  }
  pressureRatioAccumulator = max(0,pressureRatioAccumulator); //keep value above 0
  pressureRatioAccumulator = min(pressureRatioAccumulator,60); //keep value below 20    
}

void DoAlarm() {
  if (auger_rev_count > alarm_start[ALARM_BOUND_AUGER]){
    setAlarm(ALARM_BOUND_AUGER);
  } 
  else {
    if (auger_state != AUGER_ALARM){
      removeAlarm(ALARM_BOUND_AUGER);
    }
  }
  if (auger_state == AUGER_CURRENT_LOW and (millis() - auger_state_entered > alarm_start[ALARM_AUGER_LOW_CURRENT])){
    setAlarm(ALARM_AUGER_LOW_CURRENT);
  } 
  else {
    if (auger_state != AUGER_ALARM){
      removeAlarm(ALARM_AUGER_LOW_CURRENT);
    }
  }
//  if (auger_state == AUGER_FORWARD and (millis() - auger_state_entered > alarm_start[ALARM_AUGER_ON_LONG])){
//    setAlarm(ALARM_AUGER_ON_LONG);
//  } 
  if ((FuelDemand == SWITCH_ON) and (millis() - fuel_state_entered > alarm_start[ALARM_AUGER_ON_LONG])){
    setAlarm(ALARM_AUGER_ON_LONG);
  } 
  else {
    if (auger_state != AUGER_ALARM){
      removeAlarm(ALARM_AUGER_ON_LONG);
    }
  }
//Reactor On Alarms:  
  if (P_reactorLevel != OFF && auger_state == AUGER_OFF and (millis() - auger_state_entered > alarm_start[ALARM_AUGER_OFF_LONG])){
    setAlarm(ALARM_AUGER_OFF_LONG);
  }  
  else { 
    if (auger_state != AUGER_ALARM){
      removeAlarm(ALARM_AUGER_OFF_LONG);
    }
  }
  if (P_reactorLevel != OFF && pressureRatioAccumulator > alarm_start[ALARM_BAD_REACTOR]) {
    setAlarm(ALARM_BAD_REACTOR);
  } 
  else {
    removeAlarm(ALARM_BAD_REACTOR);
  }
  if (P_reactorLevel != OFF && filter_pratio_accumulator > alarm_start[ALARM_BAD_FILTER]) {
    setAlarm(ALARM_BAD_FILTER);
  } 
  else {
    removeAlarm(ALARM_BAD_FILTER);
  }
#if T_LOW_FUEL != ABSENT
  if (P_reactorLevel != OFF && Temp_Data[T_LOW_FUEL] > alarm_start[ALARM_LOW_FUEL_REACTOR]) {
    setAlarm(ALARM_LOW_FUEL_REACTOR);
  } 
  else {
    removeAlarm(ALARM_LOW_FUEL_REACTOR);
  }
#endif

//Engine On Alarms
  //if (engine_state == ENGINE_ON && P_reactorLevel != OFF && T_tredLevel != HOT && T_tredLevel != EXCESSIVE) {
  if (engine_state == ENGINE_ON && P_reactorLevel != OFF && Temp_Data[T_TRED] < ttred_warn - 10) {
    setAlarm(ALARM_LOW_TRED);
  } else { 
    if (Temp_Data[T_TRED] > ttred_warn) {
      removeAlarm(ALARM_LOW_TRED);
    }
  }
  if (engine_state == ENGINE_ON && P_reactorLevel != OFF && T_bredLevel == EXCESSIVE) {
    setAlarm(ALARM_HIGH_BRED);
  } else { 
    removeAlarm(ALARM_HIGH_BRED);
  }
  if (engine_state == ENGINE_ON && Temp_Data[T_ENG_COOLANT] > high_coolant_temp){
    setAlarm(ALARM_HIGH_COOLANT_TEMP);
  }  else {
    if (alarm_on[ALARM_HIGH_COOLANT_TEMP] <= shutdown[ALARM_HIGH_COOLANT_TEMP]){
      removeAlarm(ALARM_HIGH_COOLANT_TEMP);
    }
  }
  if (engine_state == ENGINE_ON && Temp_Data[T_TRED] < tred_low_temp){
    setAlarm(ALARM_TRED_LOW);
  }  else {
    if (alarm_on[ALARM_TRED_LOW] <= shutdown[ALARM_TRED_LOW]){
      removeAlarm(ALARM_TRED_LOW);
    }
  }
  if (engine_state == ENGINE_ON && Temp_Data[T_TRED] > ttred_high){
    setAlarm(ALARM_TTRED_HIGH);
  }  else {
    if (alarm_on[ALARM_TTRED_HIGH] <= shutdown[ALARM_TTRED_HIGH]){
      removeAlarm(ALARM_TTRED_HIGH);
    }
  }
  if (engine_state == ENGINE_ON && Temp_Data[T_BRED] > tbred_high){
    setAlarm(ALARM_TTRED_HIGH);
  }  else {
    if (alarm_on[ALARM_TBRED_HIGH] <= shutdown[ALARM_TBRED_HIGH]){
      removeAlarm(ALARM_TBRED_HIGH);
    }
  }
//Low Oil Pressure alarm set in Engine state machine due to quick transition times.
//#if ANA_OIL_PRESSURE != ABSENT
//  if (engine_state == ENGINE_ON && P_reactorLevel != OFF && EngineOilPressureLevel == OIL_P_LOW && millis() - oil_pressure_state > 500  && millis() - engine_state_entered > 3000) {
//    setAlarm(ALARM_BAD_OIL_PRESSURE);
//  }  //No else statement because user needs to acknowledge and remove with a RESET button.
//#endif
#if LAMBDA_SIGNAL_CHECK == TRUE
  if (engine_state == ENGINE_ON && P_reactorLevel != OFF && lambda_input < 0.52) {
    setAlarm(ALARM_O2_NO_SIG);
  } else { 
    if (engine_state == ENGINE_ON && lambda_input > 0.52){
      removeAlarm(ALARM_O2_NO_SIG);
    }
  }
  if (engine_state == ENGINE_ON && P_reactorLevel != OFF && millis() - lambda_state_entered > alarm_start[ALARM_O2_NO_SIG] && lambda_state_entered == LAMBDA_RESTART) {
    setAlarm(ALARM_O2_NO_SIG);
  }
#endif
  
  if (alarm == true) {
    digitalWrite(FET_ALARM, HIGH);
  } 
  else { 
    digitalWrite(FET_ALARM, LOW);
  }
}

void setAlarm(int alarm_num){
  if (alarm_on[alarm_num] == 0){
    strcpy_P(p_buffer, (char*)pgm_read_word(&(display_alarm[alarm_num])));
    Logln(p_buffer);
    alarm_on[alarm_num] = millis();
    alarm = true;
    setAlarmQueue();
  }
}

void removeAlarm(int alarm_num){
  if (alarm_on[alarm_num] > 0) {
    Log_p("Removing: ");
    strcpy_P(p_buffer, (char*)pgm_read_word(&(display_alarm[alarm_num])));
    Logln(p_buffer);
    alarm_on[alarm_num] = 0;
    setAlarmQueue();
    if (alarm_count == 0){
      alarm = false;
    }
  }
}

void setAlarmQueue(){
  alarm_count = 0;
  for (int x = 0; x < ALARM_NUM; x++){  //sizeof(alarm_on)/sizeof(unsigned long)
    if (alarm_on[x] > 0){
      alarm_queue[alarm_count] = x;
      alarm_count++;
    }
  }
}

void resetAlarm(int alarm_num){
  Log_p("Alarm Reset by User");
  switch (alarm_num) {  //reset faults that kicked off alarm state.  Seperate function only for user intervention??
  case ALARM_AUGER_ON_LONG:
    fuel_state_entered = millis();
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
  case ALARM_HIGH_PCOMB:
    break;
  case ALARM_HIGH_COOLANT_TEMP:
    break;
  case ALARM_TRED_LOW:
    break;
  }
}

int getAlarmBin(){
  int bin = 0;
  if (alarm_count>0){
    for(int i=0; i<alarm_count; i++){
      bitSet(bin, alarm_queue[i]);
    }
  }
  return bin;
}
