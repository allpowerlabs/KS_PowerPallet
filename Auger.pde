//Auger as State machine:
void DoAuger() {
  checkAuger();
  switch (auger_state) {
    case AUGER_OFF:
      if (FuelDemand) {
        if (relay_board == 1){
          TransitionAuger(AUGER_STARTING);
        } else {
          TransitionAuger(AUGER_FORWARD);
        }
      }
      if (P_reactorLevel == OFF) {
        auger_state_entered = millis(); //reset to zero if no vacuum and auger off
      }
      break;
    case AUGER_CURRENT_LOW:
      if (FuelDemand == SWITCH_OFF) {
        TransitionAuger(AUGER_OFF);
      }
      if (AugerCurrentLevel != CURRENT_LOW){ //switch forward instead?
        TransitionAuger(AUGER_FORWARD);
      } 
      if ((millis() - auger_state_entered) > 180000){  //turn engine and auger off if auger current low for 3 minutes
        TransitionAuger(AUGER_ALARM);
        if (engine_state == ENGINE_ON){
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
      if (AugerCurrentLevel == CURRENT_LOW){
        TransitionAuger(AUGER_CURRENT_LOW);
      } 
      if ((millis() - auger_state_entered) > 360000){  //turn engine and auger off if auger runs none stop for 6 minutes.  Account for current changes??
        TransitionAuger(AUGER_ALARM);
        if (engine_state == ENGINE_ON){
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
        auger_rev_count = 0;
      }
      if (auger_rev_count > 20){  //catch oscillating auger from broken Fuel Switch
        Serial.println("# Auger Bound or broken Fuel Switch, stopping Auger");
        TransitionAuger(AUGER_ALARM);
        TransitionEngine(ENGINE_SHUTDOWN);
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
  }
}


void TransitionAuger(int new_state) {
  //can look at auger_state for "old" state before transitioning at the end of this method
  auger_state_entered = millis();
  switch (new_state) {
    case AUGER_OFF:
      AugerOff();
      Serial.println("# New Auger State: Off");
      TransitionMessage("Auger: Off         ");
      auger_rev_count = 0;
      break;
    case AUGER_STARTING:
      AugerReverse(); //start in reverse for a few moments to reduce bridging 
      Serial.println("# New Auger State: Starting Forward");  
      TransitionMessage("Auger: Starting      "); 
      break;
    case AUGER_FORWARD:
      AugerForward();
      Serial.println("# New Auger State: Forward");
      TransitionMessage("Auger: Forward      ");
      break;
    case AUGER_HIGH:
      Serial.print("Current:");
      Serial.print(AugerCurrentValue);
      Serial.print(" current_low_boundary:");
      Serial.print(current_low_boundary);
      Serial.print(" current_high_boundary:");
      Serial.print(current_high_boundary);
      Serial.println("# New Auger State: Forward, Current High");
      TransitionMessage("Auger: Current High ");
      break;
    case AUGER_REVERSE:
      auger_reverse_entered = millis();
      AugerReverse();
      Serial.println("# New Auger State: Reverse");
      TransitionMessage("Auger: Reverse      ");
      break;
    case AUGER_REVERSE_HIGH:
      Serial.println("# New Auger State: Reverse High Current"); 
      TransitionMessage("Auger: Reverse High"); 
      auger_rev_count++;
      break; 
    case AUGER_CURRENT_LOW:
      Serial.print("Current:");
      Serial.print(AugerCurrentValue);
      Serial.print(" current_low_boundary:");
      Serial.print(current_low_boundary);
      Serial.print(" current_high_boundary:");
      Serial.print(current_high_boundary);
      Serial.println("# New Auger State: Current Low");
      TransitionMessage("Auger: Low Current");
      break;
    case AUGER_ALARM:
      AugerOff();
      Serial.println("# New Auger State: Alarmed, Off");
      TransitionMessage("Auger: Off          ");
      break;   
  }
  auger_state=new_state;
}

void checkAuger(){
  FuelSwitchValue = analogRead(ANA_FUEL_SWITCH); // switch voltage, 1024 if on, 0 if off
  if (FuelSwitchValue > 600){
    FuelDemand = SWITCH_ON;
  } else {
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


////Old  Non State Machine Code:
//void DoAuger() {
//  if (relay_board == 0){  //when relay board is present auger current sensing is enabled
//    AugerCurrentValue = -195*(analogRead(ANA_AUGER_CURRENT)-518); //convert current sensor V to mA
//    if (AugerCurrentValue > AugerCurrentLevelBoundary[AUGER_OFF][0] && AugerCurrentValue < AugerCurrentLevelBoundary[AUGER_OFF][1]) {
//      AugerCurrentLevel = AUGER_OFF;
//      auger_on = false;
//    }
//    if (AugerCurrentValue > AugerCurrentLevelBoundary[AUGER_ON][0] && AugerCurrentValue < AugerCurrentLevelBoundary[AUGER_ON][1]) {
//      AugerCurrentLevel = AUGER_ON;
//      auger_on = true;
//    }
//    if (AugerCurrentValue > AugerCurrentLevelBoundary[AUGER_HIGH][0] && AugerCurrentValue < AugerCurrentLevelBoundary[AUGER_HIGH][1]) {
//      AugerCurrentLevel = AUGER_HIGH;
//      auger_on = true;
//    }
//  }
//  
//  #if ANA_FUEL_SWITCH != ABSENT
//  FuelSwitchValue = analogRead(ANA_FUEL_SWITCH); // switch voltage, 1024 if on, 0 if off
//  if (FuelSwitchValue > 600) {
//    FuelSwitchLevel = SWITCH_ON;
//    auger_on = true;
//  } else {
//    FuelSwitchLevel = SWITCH_OFF;
//    auger_on = false;
//  }
////  if (FuelSwitchValue > FuelSwitchLevelBoundary[SWITCH_OFF][0] && FuelSwitchValue < FuelSwitchLevelBoundary[SWITCH_OFF][1]) {
////    FuelSwitchLevel = SWITCH_OFF;
////    auger_on = false;
////  }
////  if (FuelSwitchValue > FuelSwitchLevelBoundary[SWITCH_ON][0] && FuelSwitchValue < FuelSwitchLevelBoundary[SWITCH_ON][1]) {
////    FuelSwitchLevel = SWITCH_ON;
////    auger_on = true;
////  }
//  #endif
//  
//  #if FET_AUGER != ABSENT && ANA_FUEL_SWITCH != ABSENT
//  if (auger_on) {
//    if (AugerCurrentLevel == AUGER_HIGH){
//      digitalWrite(FET_AUGER, LOW);
//      digitalWrite(FET_AUGER_REV, HIGH);   //Reversing Auger
//      auger_rev = millis();
//    }  
//    else {
//    digitalWrite(FET_AUGER,HIGH);
//    }
//    auger_on = true;
//  } 
//  else {
//      digitalWrite(FET_AUGER,LOW);
//      auger_on = false;
//   }
//
//  if (millis() - auger_rev >= Aug_Rev_time){
//    digitalWrite(FET_AUGER_REV, LOW);
//    auger_rev = 0;
//    auger_on = false;
//  }
//  #endif
//}
