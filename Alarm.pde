struct alarm * alarm_list_head;  // Pointer to head of alarm queue
struct alarm * alarm_list_tail;  // Pointer to tail of alarm queue
unsigned int alarm_count;

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
	if (auger_rev_count > ALARM_BOUND_AUGER.delay){
		setAlarm(&ALARM_BOUND_AUGER);
	}
	else {
		if (auger_state != AUGER_ALARM){
			removeAlarm(&ALARM_BOUND_AUGER);
		}
	}
// "Auger Low Current"
	if (auger_state == AUGER_CURRENT_LOW and (millis() - auger_state_entered > ALARM_AUGER_LOW_CURRENT.delay)){
		setAlarm(&ALARM_AUGER_LOW_CURRENT);
	}
	else {
		if (auger_state != AUGER_ALARM){
			removeAlarm(&ALARM_AUGER_LOW_CURRENT);
		}
	}
// "Auger on too long"
	if ((FuelDemand == SWITCH_ON) and (millis() - fuel_state_entered > ALARM_AUGER_ON_LONG.delay)){
		setAlarm(&ALARM_AUGER_ON_LONG);
	}
	else {
		if (auger_state != AUGER_ALARM){
			removeAlarm(&ALARM_AUGER_ON_LONG);
		}
	}
/**************************************
	Reactor On Alarms:
**************************************/
	if (P_reactorLevel != OFF) {
// "Auger off too long"
		if (auger_state == AUGER_OFF and (millis() - auger_state_entered > ALARM_AUGER_OFF_LONG.delay)){
			setAlarm(&ALARM_AUGER_OFF_LONG);
		}
		/*
		else {
			if (auger_state != AUGER_ALARM){
				removeAlarm(ALARM_AUGER_OFF_LONG);
			}
		}
		*/
// "Bad Reactor P_ratio"
/*
		if (pressureRatioAccumulator > ALARM_BAD_REACTOR.delay) {
			setAlarm(&ALARM_BAD_REACTOR);
		}
		else {
			removeAlarm(&ALARM_BAD_REACTOR);
		}
*/
	}
/**************************************
	Engine On Alarms
**************************************/
	if (engine_state == ENGINE_ON && P_reactorLevel != OFF) {
// "Trst low for engine"
		if ((Temp_Data[T_TRED] < ttred_warn - 10) && (engine_state_entered + ALARM_LOW_TRED.delay < millis())) {
			setAlarm(&ALARM_LOW_TRED);
		}
// "Tred high for engine"
		if (T_bredLevel == EXCESSIVE) {
			setAlarm(&ALARM_HIGH_BRED);
		}
// "Restriction Temp High"
		if (Temp_Data[T_TRED] > ttred_high){
			setAlarm(&ALARM_TTRED_HIGH);
		}
// "Reduction Temp High"
		if (Temp_Data[T_BRED] > tbred_high){
			setAlarm(&ALARM_TBRED_HIGH);
		}
// "No O2 Sensor Signal"
		if (lambda_input < 0.52) {
			setAlarm(&ALARM_O2_NO_SIG);
		}
		if (millis() - lambda_state_entered > ALARM_O2_NO_SIG.delay && lambda_state_entered == LAMBDA_RESTART) {
			setAlarm(&ALARM_O2_NO_SIG);
		}
	}

/**************************************
Engine warning alarm resets
**************************************/
	if (engine_state != ENGINE_ON || Temp_Data[T_TRED] > ttred_warn) {
		removeAlarm(&ALARM_LOW_TRED);
	}
	if (T_bredLevel < EXCESSIVE) {
		removeAlarm(&ALARM_HIGH_BRED);
	}
	if (ALARM_TRED_LOW.on <= ALARM_TRED_LOW.shutdown){
		removeAlarm(&ALARM_TRED_LOW);
	}
	if (ALARM_TTRED_HIGH.on <= ALARM_TTRED_HIGH.shutdown){
		removeAlarm(&ALARM_TTRED_HIGH);
	}
	if (ALARM_TBRED_HIGH.on <= ALARM_TBRED_HIGH.shutdown){
		removeAlarm(&ALARM_TBRED_HIGH);
	}
	if (lambda_input > 0.52){
		removeAlarm(&ALARM_O2_NO_SIG);
	}

/**************************************
	Alarm sounder
**************************************/
	if (annoying) {
		digitalWrite(FET_ALARM, HIGH);
	}
	else {
		digitalWrite(FET_ALARM, LOW);
	}
}

void setAlarm (struct alarm * alarm){
	if (alarm->on == 0){
		Log_p("Alarm: ");
		strcpy_P(p_buffer, alarm->message);
		Logln(p_buffer);
		alarm->on = millis();
		// Link alarm to the head of the alarm list
		if (alarm_list_head) {
			alarm->next = alarm_list_head;
			alarm_list_head->prev = alarm;
		}
		alarm_list_head = alarm;
		alarm->prev = 0;
		alarm_count++;
		annoying = 1;
	}
}

void removeAlarm (struct alarm * alarm){
	if (alarm->on > 0) {
		Log_p("Removing Alarm: ");
		strcpy_P(p_buffer, alarm->message);
		Logln(p_buffer);
		alarm->on = 0;
		// Unlink the alarm from the alarm list
		if (alarm->prev) {
			alarm->prev->next = alarm->next;
		}
		if (alarm->next) {
			alarm->next->prev = alarm->prev;
		}
		if (alarm_list_head == alarm) {
			alarm_list_head = alarm->next;
		}
		alarm_count--;
	}
	if (alarm_count == 0) { annoying = 0; }
}

// This function is called when a user resets an alarm
void resetAlarm (struct alarm * alarm) {
	Logln_p("Alarm Reset by User");
	if (alarm->reset) {
		alarm->reset();
	}
	removeAlarm(alarm);
}

void silenceAlarm (struct alarm * alarm) {
	alarm->silenced = 1;
}

void silenceAllAlarms(void) {
	annoying = 0;
}

struct alarm * getActiveAlarm(void) {
	struct alarm * n = alarm_list_head;
	return n;
}

struct alarm * getNextAlarm (struct alarm * alarm) {
	if (alarm && alarm->next) {
		return alarm->next;
	} else {
		return alarm_list_head;
	}
}

unsigned int getAlarmCount(void) {
	return alarm_count;
}

long getAlarmShutdownTime (struct alarm * alarm) {
	if (alarm->on) {
		return (alarm->on + alarm->shutdown) - millis();
	} else {
		return INT_MAX;
	}
}
