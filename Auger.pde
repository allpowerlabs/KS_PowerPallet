void AugerInit() {
	current_low_boundary = getConfig(4);
	current_high_boundary = getConfig(5);

	AugerCurrentLevelBoundary[CURRENT_OFF][0] = 0;
	AugerCurrentLevelBoundary[CURRENT_OFF][1] = 10;
	AugerCurrentLevelBoundary[CURRENT_LOW][0] = 10;
	AugerCurrentLevelBoundary[CURRENT_LOW][1] = current_low_boundary;
	AugerCurrentLevelBoundary[CURRENT_ON][0] = current_low_boundary;
	AugerCurrentLevelBoundary[CURRENT_ON][1] = current_high_boundary;
	AugerCurrentLevelBoundary[CURRENT_HIGH][0] = current_high_boundary;
	AugerCurrentLevelBoundary[CURRENT_HIGH][1] = 750;

	fuel_last_fill = 0;
	fuel_switch_hysteresis = getConfig(34) * 1000;
}

// This function is called when a user resets an auger alarm.
void AugerReset(void) {
	fuel_state_entered = millis();
    TransitionAuger(AUGER_OFF);
}

void DoAuger() {
  checkAuger();
  switch (auger_state) {
  case AUGER_OFF:
    if (FuelDemand == SWITCH_ON) { //&& P_reactorLevel > OFF) {
        TransitionAuger(AUGER_STARTING);
    }
    if (P_reactorLevel == OFF) {
      auger_state_entered = millis(); //reset to zero if no vacuum and auger off
    }
    if (millis() - auger_state_entered > ALARM_AUGER_OFF_LONG.shutdown && engine_state == ENGINE_ON){
      Logln_p("Auger off too long");
      TransitionAuger(AUGER_ALARM);
    }
	if ((millis() - auger_state_entered) % 60000 > 59000) {  //pulse every minute of auger off...
      Logln_p("Pulsing Auger");
      TransitionAuger(AUGER_PULSE);
    }
    break;
  case AUGER_CURRENT_LOW:
    if (FuelDemand == SWITCH_OFF) {
      TransitionAuger(AUGER_OFF);
    }
    if (AugerCurrentLevel != CURRENT_LOW && AugerCurrentLevel != CURRENT_OFF && millis() - auger_state_entered > 500){ //switch forward instead?
      TransitionAuger(AUGER_FORWARD);
    }
    if ((millis() - auger_state_entered) > ALARM_AUGER_LOW_CURRENT.shutdown){  //turn engine and auger off if auger current low for 3 minutes
      TransitionAuger(AUGER_ALARM);
        Logln_p("Low Auger Current for too long");
    }
    break;
  case AUGER_STARTING:  //disregard all current readings while starting, pulse in reverse for a moment
    if (millis() - auger_state_entered > aug_rev_time){
      TransitionAuger(AUGER_FORWARD);
    }
    break;
  case AUGER_FORWARD:
    if (FuelDemand == SWITCH_OFF) {
      TransitionAuger(AUGER_OFF);
    }
      if (AugerCurrentLevel == CURRENT_HIGH  && millis() - auger_state_entered > 500){
        TransitionAuger(AUGER_HIGH);
      }
      if (AugerCurrentLevel >= CURRENT_LOW && millis() - auger_state_entered > 500){
		TransitionAuger(AUGER_CURRENT_LOW);
      }
    if ((millis() - auger_state_entered) > ALARM_AUGER_ON_LONG.shutdown){  //turn engine and auger off if auger runs non-stop for too long, use auger_direction_entered???
      TransitionAuger(AUGER_ALARM);
		Logln_p("Auger on too long");
    }
    break;
  case AUGER_HIGH:
    if (FuelDemand == SWITCH_OFF) {
      TransitionAuger(AUGER_OFF);
    }
    if (AugerCurrentLevel != CURRENT_HIGH){
      TransitionAuger(AUGER_FORWARD);
    }
    if (millis() - auger_state_entered > 500){
      TransitionAuger(AUGER_REVERSE);
    }
    break;
  case AUGER_REVERSE:
    if (FuelDemand == SWITCH_OFF) {
      TransitionAuger(AUGER_OFF);
    }
    if (millis() - auger_state_entered > 500  && AugerCurrentLevel == CURRENT_HIGH){
      TransitionAuger(AUGER_REVERSE_HIGH);
    }
    if (millis() - auger_direction_entered > aug_rev_time){
      TransitionAuger(AUGER_FORWARD);
    }
    if (auger_rev_count > ALARM_BOUND_AUGER.shutdown){  //catch oscillating auger from broken Fuel Switch
      Logln_p("Auger Bound or broken Fuel Switch, stopping Auger");
      TransitionAuger(AUGER_ALARM);
    }
    break;
  case AUGER_REVERSE_HIGH:
    if (FuelDemand == SWITCH_OFF) {
      TransitionAuger(AUGER_OFF);
    }
    if (AugerCurrentLevel != CURRENT_HIGH){
      TransitionAuger(AUGER_REVERSE);
    }
    if (millis() - auger_state_entered > 500){
      TransitionAuger(AUGER_FORWARD);  //skip Auger starting as it has an initial reverse pulse
    }
    break;
  case AUGER_ALARM:  //Auger will remain off until rebooted with a reset from front panel display
    break;
  case AUGER_PULSE:
    if (millis() - auger_pulse_entered > auger_pulse_time){
      if (auger_pulse_state == 1){
        TransitionAuger(AUGER_PULSE);
      }
      else {
        TransitionAuger(AUGER_OFF);
      }
    }
    if (AugerCurrentLevel == CURRENT_HIGH && millis() - auger_pulse_entered > 500){
      if (auger_pulse_state == 1){  //if in reverse...try going forward
        TransitionAuger(AUGER_PULSE);
      }
      else {
        TransitionAuger(AUGER_OFF);
      }
    }
    break;
  case AUGER_MANUAL_FORWARD:
    if (AugerCurrentLevel == CURRENT_HIGH  && millis() - auger_state_entered > 500){
      TransitionAuger(AUGER_HIGH);
    }
    break;
  }
}


void TransitionAuger(int new_state) {
  //const prog_char new_auger_state[] PROGMEM = "New Auger State: ";
  strcpy_P(p_buffer, new_auger_state);
  //can look at auger_state for "old" state before transitioning at the end of this method
  if (new_state != AUGER_PULSE && auger_state != AUGER_PULSE) {
    auger_state_entered = millis();
  }
  switch (new_state) {
  case AUGER_OFF:
    AugerOff();
    Log(p_buffer);
    Logln_p("Off");
    auger_rev_count = 0;
    auger_pulse_state = 0;
    break;
  case AUGER_STARTING:
    AugerReverse(); //start in reverse for a few moments to reduce bridging
    Log(p_buffer);
    Logln_p("Starting Forward");
    break;
  case AUGER_FORWARD:
    if (auger_state != AUGER_HIGH){
      auger_direction_entered = millis();
    }
    AugerForward();
    Log(p_buffer);
    Logln_p("Forward");
    break;
  case AUGER_HIGH:
    Log(p_buffer);
    Logln_p("Forward, Current High");
    break;
  case AUGER_REVERSE:
    if (auger_state != AUGER_REVERSE_HIGH){
      auger_direction_entered = millis();
    }
    Log(p_buffer);
    Logln_p("Reverse");
    AugerReverse();
    auger_rev_count++;
    Logln_p("Auger Rev Count Incremented to ");
    Logln(auger_rev_count);
    break;
  case AUGER_REVERSE_HIGH:
    Log(p_buffer);
    Logln_p("Reverse High Current");
    break;
  case AUGER_CURRENT_LOW:
    Log(p_buffer);
    Logln_p("Current Low");
    break;
  case AUGER_ALARM:
    AugerOff();
    Log(p_buffer);
    Logln_p("Alarmed, Off");
    break;
  case AUGER_PULSE:
    Log(p_buffer);
    Logln_p("Pulse");
    if (auger_pulse_state == 0){
      AugerReverse();
    }
    else {
      AugerForward();
    }
    auger_pulse_entered = millis();
    auger_pulse_state++;
    break;
  }
  auger_state=new_state;
}

void checkAuger(){
	FuelSwitchValue = analogRead(ANA_FUEL_SWITCH); // switch voltage, 1024 if on, 0 if off
	if (FuelSwitchValue > 600){
		if (FuelDemand == SWITCH_OFF && (fuel_last_fill + fuel_switch_hysteresis < millis())){
			fuel_state_entered = millis();
			FuelDemand = SWITCH_ON;
		}
	}
	else {
		if (FuelDemand == SWITCH_ON){
			fuel_state_entered = millis();
			fuel_last_fill = millis();
			FuelDemand = SWITCH_OFF;
		}
	}
    AugerCurrentValue = (u_sublim(analogRead(ANA_AUGER_CURRENT), 120, 0) * 10)/12;  //convert from analog values to current (.1A) values
    if (AugerCurrentValue > AugerCurrentLevelBoundary[CURRENT_OFF][0] && AugerCurrentValue < AugerCurrentLevelBoundary[CURRENT_OFF][1]) {
		AugerCurrentLevel = CURRENT_OFF;
    }
    if (AugerCurrentValue > AugerCurrentLevelBoundary[CURRENT_LOW][0] && AugerCurrentValue < AugerCurrentLevelBoundary[CURRENT_LOW][1]) {
		AugerCurrentLevel = CURRENT_LOW;
    }
    if (AugerCurrentValue > AugerCurrentLevelBoundary[CURRENT_ON][0] && AugerCurrentValue < AugerCurrentLevelBoundary[CURRENT_ON][1]) {
		AugerCurrentLevel = CURRENT_ON;
    }
    if (AugerCurrentValue > AugerCurrentLevelBoundary[CURRENT_HIGH][0] && AugerCurrentValue < AugerCurrentLevelBoundary[CURRENT_HIGH][1]) {
		AugerCurrentLevel = CURRENT_HIGH;
    }
}

void AugerReverse(){
    digitalWrite(FET_AUGER,LOW);
    digitalWrite(FET_AUGER_REV, HIGH);
}

void AugerForward(){
	digitalWrite(FET_AUGER, HIGH);
    digitalWrite(FET_AUGER_REV, LOW);
}

void AugerOff(){
	digitalWrite(FET_AUGER,LOW);
    digitalWrite(FET_AUGER_REV, LOW);
}



