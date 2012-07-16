//Auger as State machine:
void DoAuger() {
  checkAuger();
  switch (auger_state) {
    case AUGER_OFF:
      if (FuelSwitchValue > 600) {
        TransitionAuger(AUGER_STARTING);
      }
      break;
    case AUGER_STARTING:  //disregard all current readings while starting
      if (millis() - auger_state_entered > 500){
        TransitionAuger(AUGER_FORWARD);
      }
      break;
    case AUGER_FORWARD:
      if (FuelSwitchValue <= 600) {
        TransitionAuger(AUGER_OFF);
      }
      if (AugerCurrentLevel == CURRENT_HIGH){
        TransitionAuger(AUGER_HIGH);
      } 
      if ((millis() - auger_state_entered) > 360000){  //turn engine and auger off if auger runs none stop for 6 minutes.  Account for current changes??
        TransitionAuger(AUGER_ALARM);
        TransitionEngine(ENGINE_SHUTDOWN);
      }
      break;
    case AUGER_HIGH:
      if (FuelSwitchValue < 600) {
        TransitionAuger(AUGER_OFF);
      }
      if (AugerCurrentLevel != CURRENT_HIGH){
        TransitionAuger(AUGER_FORWARD);
      }
      if (millis() - auger_state_entered > 500){ //set to variable for threshold??
        TransitionAuger(AUGER_STARTING_REVERSE);
      }
      break;
    case AUGER_STARTING_REVERSE:  //disregard all current readings while starting
      if (millis() - auger_state_entered > 500){
        TransitionAuger(AUGER_REVERSE);
      }
      break;
    case AUGER_REVERSE:
      if (AugerCurrentLevel == CURRENT_HIGH){
        TransitionAuger(AUGER_REVERSE_HIGH);
      }
      if (millis() - auger_reverse_entered > aug_rev_time - 500){
        TransitionAuger(AUGER_OFF);
      }
      break;
    case AUGER_REVERSE_HIGH:
      if (AugerCurrentLevel != CURRENT_HIGH){
        TransitionAuger(AUGER_REVERSE);
      }
      if (millis() - auger_state_entered > 500){ //set to variable for threshold??
        if (AugerCurrentLevel == CURRENT_HIGH){
          TransitionAuger(AUGER_OFF);
        }  else {
          TransitionAuger(AUGER_REVERSE);
        }
      }
      break; 
   case AUGER_ALARM:  //Auger will remain off until rebooted
     break;   
  }
}


void TransitionAuger(int new_state) {
  //can look at auger_state for "old" state before transitioning at the end of this method
  auger_state_entered = millis();
  switch (new_state) {
    case AUGER_OFF:
      digitalWrite(FET_AUGER,LOW);
      digitalWrite(FET_AUGER_REV, LOW);
      Serial.println("# New Auger State: Off");
      TransitionMessage("Auger: Off         ");
      break;
    case AUGER_STARTING:
      digitalWrite(FET_AUGER,HIGH);
      digitalWrite(FET_AUGER_REV, LOW);
      Serial.println("# New Auger State: Starting Forward");  //is this necessary??
      TransitionMessage("Auger: Starting      "); //is this necessary??
      break;
    case AUGER_FORWARD:
      Serial.println("# New Auger State: Forward");
      TransitionMessage("Auger: Forward      ");
      break;
    case AUGER_HIGH:
      Serial.println("# New Auger State: Forward, Current High");
      TransitionMessage("Auger: Current High ");
      break;
    case AUGER_STARTING_REVERSE:
      auger_reverse_entered = millis();
      digitalWrite(FET_AUGER,LOW);
      digitalWrite(FET_AUGER_REV, HIGH);
      Serial.println("# New Auger State: Starting Reverse");  //is this necessary??
      TransitionMessage("Auger: Starting Reverse "); //is this necessary??
      break;
    case AUGER_REVERSE:
      Serial.println("# New Auger State: Reverse");
      TransitionMessage("Auger: Reverse      ");
      break;
    case AUGER_REVERSE_HIGH:
      Serial.println("# New Auger State: Reverse High Current"); //is this necessary??
      TransitionMessage("Auger: Reverse High"); //is this necessary??
      break; 
    case AUGER_ALARM:
      digitalWrite(FET_AUGER,LOW);
      digitalWrite(FET_AUGER_REV, LOW);
      Serial.println("# New Auger State: On too long, turning Off");
      TransitionMessage("Auger: Off          ");
      break;   
  }
  auger_state=new_state;
}

void checkAuger(){
  FuelSwitchValue = analogRead(ANA_FUEL_SWITCH); // switch voltage, 1024 if on, 0 if off
  if (relay_board == 0){     //when relay board is present auger current sensing is enabled
    //AugerCurrentValue = -195*(analogRead(ANA_AUGER_CURRENT)-518);    //convert current sensor V to mA
    AugerCurrentValue = analogRead(ANA_AUGER_CURRENT);
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
