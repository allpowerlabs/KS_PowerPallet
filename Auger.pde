void DoAuger() {
  checkAuger();
  switch (auger_state) {
  case AUGER_OFF:
    if (FuelDemand == SWITCH_ON) {
      if (relay_board == 1){
        TransitionAuger(AUGER_STARTING);
      } 
      else {
        TransitionAuger(AUGER_FORWARD);
      }
    }
    if (P_reactorLevel == OFF) {
      auger_state_entered = millis(); //reset to zero if no vacuum and auger off
    }
    if (millis() - auger_state_entered > shutdown[ALARM_AUGER_OFF_LONG] && engine_state == ENGINE_ON){
      Serial.println("# Auger off too long, Engine Shutdown.");
      TransitionEngine(ENGINE_SHUTDOWN);
    } 
    if ((millis() - auger_state_entered) % 60000 > 59000) {  //pulse every minute of auger off
      Serial.println("# Pulsing Auger");
      TransitionAuger(AUGER_PULSE);
    } 
    break;
  case AUGER_CURRENT_LOW:
    if (FuelDemand == SWITCH_OFF) {
      TransitionAuger(AUGER_OFF);
    }
    if (AugerCurrentLevel != CURRENT_LOW && AugerCurrentLevel != CURRENT_OFF){ //switch forward instead?
      TransitionAuger(AUGER_FORWARD);
    } 
    if ((millis() - auger_state_entered) > shutdown[ALARM_AUGER_LOW_CURRENT]){  //turn engine and auger off if auger current low for 3 minutes
      TransitionAuger(AUGER_ALARM);
      if (engine_state == ENGINE_ON){
        Serial.println("# Low Auger Current for too long, Engine Shutdown.");
        TransitionEngine(ENGINE_SHUTDOWN);
      }
    }
    break;
  case AUGER_STARTING:  //disregard all current readings while starting, pulse in reverse for a moment
    if (millis() - auger_state_entered > 500){
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
    if (AugerCurrentLevel == CURRENT_LOW or AugerCurrentLevel == CURRENT_OFF){
      TransitionAuger(AUGER_CURRENT_LOW);
    } 
    if ((millis() - auger_state_entered) > shutdown[ALARM_AUGER_ON_LONG]){  //turn engine and auger off if auger runs none stop for too long
      TransitionAuger(AUGER_ALARM);
      if (engine_state == ENGINE_ON){
        Serial.println("# Auger on too long, Engine Shutdown");
        TransitionEngine(ENGINE_SHUTDOWN);
      }
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
    if (millis() - auger_state_entered > 500  && AugerCurrentLevel == CURRENT_HIGH){
      TransitionAuger(AUGER_REVERSE_HIGH);
    }
    if (millis() - auger_reverse_entered > aug_rev_time){
      TransitionAuger(AUGER_FORWARD);
    }
    if (auger_rev_count > 20){  //catch oscillating auger from broken Fuel Switch
      Serial.println("# Auger Bound or broken Fuel Switch, stopping Auger");
      TransitionAuger(AUGER_ALARM);
      if (engine_state == ENGINE_ON){
        Serial.println("# Auger Oscillations, Engine Shutdown");
        TransitionEngine(ENGINE_SHUTDOWN);
      }
    }
    break;
  case AUGER_REVERSE_HIGH:
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
      } else {
        TransitionAuger(AUGER_OFF);
      }
    }  
    break;
  }
}


void TransitionAuger(int new_state) {
  //can look at auger_state for "old" state before transitioning at the end of this method
  if (new_state != AUGER_PULSE) {
    auger_state_entered = millis();
  }
  switch (new_state) {
  case AUGER_OFF:
    AugerOff();
    Serial.println("# New Auger State: Off");
    //TransitionMessage("Auger: Off         ");
    auger_rev_count = 0;
    auger_pulse_state = 0;
    break;
  case AUGER_STARTING:
    AugerReverse(); //start in reverse for a few moments to reduce bridging 
    Serial.println("# New Auger State: Starting Forward");  
    //TransitionMessage("Auger: Starting      "); 
    break;
  case AUGER_FORWARD:
    AugerForward();
    Serial.println("# New Auger State: Forward");
    //TransitionMessage("Auger: Forward      ");
    break;
  case AUGER_HIGH:
    //Serial.print("Current:");
    //Serial.print(AugerCurrentValue);
    //Serial.print(" current_low_boundary:");
    //Serial.print(current_low_boundary);
    //Serial.print(" current_high_boundary:");
    //Serial.println(current_high_boundary);
    Serial.println("# New Auger State: Forward, Current High");
    //TransitionMessage("Auger: Current High ");
    break;
  case AUGER_REVERSE:
    auger_reverse_entered = millis();
    AugerReverse();
    Serial.println("# New Auger State: Reverse");
    //TransitionMessage("Auger: Reverse      ");
    break;
  case AUGER_REVERSE_HIGH:
    Serial.println("# New Auger State: Reverse High Current"); 
    //TransitionMessage("Auger: Reverse High"); 
    auger_rev_count++;
    break; 
  case AUGER_CURRENT_LOW:
    //Serial.print("Current:");
    //Serial.print(AugerCurrentValue);
    //Serial.print(" current_low_boundary:");
    //Serial.print(current_low_boundary);
    //Serial.print(" current_high_boundary:");
    //Serial.println(current_high_boundary);
    Serial.println("# New Auger State: Current Low");
    //TransitionMessage("Auger: Low Current");
    break;
  case AUGER_ALARM:
    AugerOff();
    Serial.println("# New Auger State: Alarmed, Off");
    //TransitionMessage("Auger: Off          ");
    break; 
  case AUGER_PULSE:
    Serial.println("# New Auger State: Pulse");
    if (auger_pulse_state == 0){
      AugerReverse();
    } else {
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
    FuelDemand = SWITCH_ON;
  } 
  else {
    FuelDemand = SWITCH_OFF;
  }
  if (relay_board == 1){     //when relay board is present auger current sensing is enabled
    AugerCurrentValue = (10*(analogRead(ANA_AUGER_CURRENT)-120))/12;  //convert from analog values to current (.1A) values
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
}

void AugerReverse(){
  if (relay_board == 1){ 
    digitalWrite(FET_AUGER,LOW);
    digitalWrite(FET_AUGER_REV, HIGH);
  }
}

void AugerForward(){
  digitalWrite(FET_AUGER, HIGH);
  if (relay_board == 1){ 
    digitalWrite(FET_AUGER_REV, LOW);
  }
}

void AugerOff(){
  digitalWrite(FET_AUGER,LOW);
  if (relay_board == 1){ 
    digitalWrite(FET_AUGER_REV, LOW);
  }
}


