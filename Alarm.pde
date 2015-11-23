void DoAlarmUpdate() {
  //TODO: Move these into their respective object control functions, not alarm
  // Get rid of High Pratio alarm
  //if ((pRatioReactorLevel == PR_LOW || pRatioReactorLevel == PR_HIGH) && P_reactorLevel != OFF && T_tredLevel != COLD) {
  if ((pRatioReactorLevel == PR_LOW) && P_reactorLevel != OFF && T_tredLevel != COLD) {
	pressureRatioAccumulator += 1;
  }
  else {
    pressureRatioAccumulator -= 5;
  }
  pressureRatioAccumulator = max(0,pressureRatioAccumulator); //keep value above 0
  pressureRatioAccumulator = min(pressureRatioAccumulator,60); //keep value below 20
}

void DoAlarm() {
/**************************************
	Auger Alarms:
**************************************/
// "FuelSwitch/Auger Jam"
	if (auger_rev_count > alarm_start[ALARM_BOUND_AUGER]){
		setAlarm(ALARM_BOUND_AUGER);
	}
	else {
		if (auger_state != AUGER_ALARM){
			removeAlarm(ALARM_BOUND_AUGER);
		}
	}
// "Auger Low Current"
	if (auger_state == AUGER_CURRENT_LOW and (millis() - auger_state_entered > alarm_start[ALARM_AUGER_LOW_CURRENT])){
		setAlarm(ALARM_AUGER_LOW_CURRENT);
	}
	else {
		if (auger_state != AUGER_ALARM){
			removeAlarm(ALARM_AUGER_LOW_CURRENT);
		}
	}
// "Auger on too long"
	if ((FuelDemand == SWITCH_ON) and (millis() - fuel_state_entered > alarm_start[ALARM_AUGER_ON_LONG])){
		setAlarm(ALARM_AUGER_ON_LONG);
	}
	else {
		if (auger_state != AUGER_ALARM){
			removeAlarm(ALARM_AUGER_ON_LONG);
		}
	}
/**************************************
	Reactor On Alarms:
**************************************/
	if (P_reactorLevel != OFF) {
// "Auger off too long"
		if (auger_state == AUGER_OFF and (millis() - auger_state_entered > alarm_start[ALARM_AUGER_OFF_LONG])){
			setAlarm(ALARM_AUGER_OFF_LONG);
		}
		/*
		else {
			if (auger_state != AUGER_ALARM){
				removeAlarm(ALARM_AUGER_OFF_LONG);
			}
		}
		*/
// "Bad Reactor P_ratio"
		if (pressureRatioAccumulator > alarm_start[ALARM_BAD_REACTOR]) {
			//setAlarm(ALARM_BAD_REACTOR);
		}
		else {
			removeAlarm(ALARM_BAD_REACTOR);
		}
// "Bad Filter P_ratio"
		/*
		if (filter_pratio_accumulator > alarm_start[ALARM_BAD_FILTER]) {
			setAlarm(ALARM_BAD_FILTER);
		}
		else {
			removeAlarm(ALARM_BAD_FILTER);
		}
		*/
	}
/**************************************
	Engine On Alarms
**************************************/
	if (engine_state == ENGINE_ON && P_reactorLevel != OFF) {
// "Trst low for engine"
		if ((Temp_Data[T_TRED] < ttred_warn - 10) && (engine_state_entered + alarm_start[ALARM_LOW_TRED] < millis())) {
			setAlarm(ALARM_LOW_TRED);
		}
// "Tred high for engine"
		if (T_bredLevel == EXCESSIVE) {
			setAlarm(ALARM_HIGH_BRED);
		}
// "Restriction Temp High"
		if (Temp_Data[T_TRED] > ttred_high){
			setAlarm(ALARM_TTRED_HIGH);
		}
// "Reduction Temp High"
		if (Temp_Data[T_BRED] > tbred_high){
			setAlarm(ALARM_TTRED_HIGH);
		}
// "No O2 Sensor Signal"
		if (lambda_input < 0.52) {
			setAlarm(ALARM_O2_NO_SIG);
		}
		if (millis() - lambda_state_entered > alarm_start[ALARM_O2_NO_SIG] && lambda_state_entered == LAMBDA_RESTART) {
			setAlarm(ALARM_O2_NO_SIG);
		}
	}

/**************************************
Engine warning alarm resets
**************************************/
	if (engine_state != ENGINE_ON || Temp_Data[T_TRED] > ttred_warn) {
		removeAlarm(ALARM_LOW_TRED);
	}
	if (T_bredLevel < EXCESSIVE) {
		removeAlarm(ALARM_HIGH_BRED);
	}
	if (alarm_on[ALARM_TRED_LOW] <= shutdown[ALARM_TRED_LOW]){
		removeAlarm(ALARM_TRED_LOW);
	}
	if (alarm_on[ALARM_TTRED_HIGH] <= shutdown[ALARM_TTRED_HIGH]){
		removeAlarm(ALARM_TTRED_HIGH);
	}
	if (alarm_on[ALARM_TBRED_HIGH] <= shutdown[ALARM_TBRED_HIGH]){
		removeAlarm(ALARM_TBRED_HIGH);
	}
	if (lambda_input > 0.52){
		removeAlarm(ALARM_O2_NO_SIG);
	}

/**************************************
	Alarm sounder
**************************************/
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
  Log_p("Alarm Reset by User"); Logln(buf);
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
  case ALARM_GRATE_FAULT:
	GrateReset();
	break;
  case ALARM_ASHAUGER_STUCK:
	AshAugerReset();
	break;
  case ALARM_ASHAUGER_FAULT:
	AshAugerReset();
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
