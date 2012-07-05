void DoAuger() {
  if (relay_board == 0){  //when relay board is present auger current sensing is enabled
    AugerCurrentValue = -195*(analogRead(ANA_AUGER_CURRENT)-518); //convert current sensor V to mA
    if (AugerCurrentValue > AugerCurrentLevelBoundary[AUGER_OFF][0] && AugerCurrentValue < AugerCurrentLevelBoundary[AUGER_OFF][1]) {
      AugerCurrentLevel = AUGER_OFF;
      auger_on = false;
    }
    if (AugerCurrentValue > AugerCurrentLevelBoundary[AUGER_ON][0] && AugerCurrentValue < AugerCurrentLevelBoundary[AUGER_ON][1]) {
      AugerCurrentLevel = AUGER_ON;
      auger_on = true;
    }
    if (AugerCurrentValue > AugerCurrentLevelBoundary[AUGER_HIGH][0] && AugerCurrentValue < AugerCurrentLevelBoundary[AUGER_HIGH][1]) {
      AugerCurrentLevel = AUGER_HIGH;
      auger_on = true;
    }
  }
  
  #if ANA_FUEL_SWITCH != ABSENT
  FuelSwitchValue = analogRead(ANA_FUEL_SWITCH); // switch voltage, 1024 if on, 0 if off
  if (FuelSwitchValue > 600) {
    FuelSwitchLevel = SWITCH_ON;
    auger_on = true;
  } else {
    FuelSwitchLevel = SWITCH_OFF;
    auger_on = false;
  }
//  if (FuelSwitchValue > FuelSwitchLevelBoundary[SWITCH_OFF][0] && FuelSwitchValue < FuelSwitchLevelBoundary[SWITCH_OFF][1]) {
//    FuelSwitchLevel = SWITCH_OFF;
//    auger_on = false;
//  }
//  if (FuelSwitchValue > FuelSwitchLevelBoundary[SWITCH_ON][0] && FuelSwitchValue < FuelSwitchLevelBoundary[SWITCH_ON][1]) {
//    FuelSwitchLevel = SWITCH_ON;
//    auger_on = true;
//  }
  #endif
  
  #if FET_AUGER != ABSENT && ANA_FUEL_SWITCH != ABSENT
  if (auger_on) {
    if (AugerCurrentLevel == AUGER_HIGH){
      digitalWrite(FET_AUGER, LOW);
      digitalWrite(FET_AUGER_REV, HIGH);   //Reversing Auger
      auger_rev = millis();
    }  
    else {
    digitalWrite(FET_AUGER,HIGH);
    }
    auger_on = true;
  } 
  else {
      digitalWrite(FET_AUGER,LOW);
      auger_on = false;
   }

  if (millis() - auger_rev >= Aug_Rev_time){
    digitalWrite(FET_AUGER_REV, LOW);
    auger_rev = 0;
    auger_on = false;
  }
  #endif
}


//DoAuger as State machine:

//void DoAuger() {
//  switch (auger_state) {
//    case AUGER_OFF:
//      if () {
//      }
//      break;
//  }
//}
//
//void TransitionAuger(int new_state) {
//  //can look at auger_state for "old" state before transitioning at the end of this method
//  auger_state_entered = millis();
//  switch (new_state) {
//    case AUGER_OFF:
//      digitalWrite(FET_AUGER,LOW);
//      Serial.println("# New Auger State: Off");
//      TransitionMessage("Auger: Off         ");
//      break;
//      
//  }
//  auger_state=new_state;
//}

