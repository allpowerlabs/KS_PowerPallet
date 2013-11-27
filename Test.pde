void TransitionTesting(int new_state) {
  testing_state_entered = millis();
  Log_p("Switching to testing state:");
  strcpy_P(p_buffer, (char*)pgm_read_word(&(TestingStateName[new_state])));
  Logln(p_buffer);
  switch (new_state) {
  case TESTING_OFF:
    break;
  case TESTING_FUEL_AUGER:
    turnAllOff();
    digitalWrite(FET_AUGER,HIGH);
    break;
  case TESTING_FUEL_REV:
    turnAllOff();
    digitalWrite(FET_AUGER_REV, HIGH);
    break;
  case TESTING_GRATE:
    turnAllOff(); 
    digitalWrite(FET_GRATE,HIGH);
    break;
  case TESTING_ENGINE_IGNITION:
    turnAllOff();
    digitalWrite(FET_IGNITION,HIGH);
    break;
  case TESTING_STARTER:
    turnAllOff();
    digitalWrite(FET_STARTER,HIGH);
    break;	
  case TESTING_FLARE_IGNITOR:
    turnAllOff();
    digitalWrite(FET_FLARE_IGNITOR,HIGH);
    break;
  case TESTING_O2_RESET:
    turnAllOff();
    digitalWrite(FET_O2_RESET,HIGH);
    break;
  case TESTING_ALARM:
    turnAllOff();
    digitalWrite(FET_ALARM,HIGH); // FET6 can't generate PWM due to Servo library using the related timer
    break;
  case TESTING_ANA_LAMBDA:
    break;
  case TESTING_ANA_ENGINE_SWITCH:
    break;
  case TESTING_ANA_FUEL_SWITCH:
    break;
  case TESTING_ANA_OIL_PRESSURE:
    break;
  }
  testing_state=new_state;
}

void GoToNextTestingState() {
  switch (testing_state) {
  case TESTING_OFF:
    TransitionTesting(TESTING_FUEL_AUGER);
    //DoTesting();
    break;
  case TESTING_FUEL_AUGER:
    if (relay_board == 1){  //AUGER Reverse only on relay board
      TransitionTesting(TESTING_FUEL_REV);
    } else {
      TransitionTesting(TESTING_GRATE);
    }
    break;
  case TESTING_FUEL_REV:
    TransitionTesting(TESTING_GRATE);
    break;
  case TESTING_GRATE:
    TransitionTesting(TESTING_ENGINE_IGNITION);
    break;
  case TESTING_ENGINE_IGNITION:
    TransitionTesting(TESTING_STARTER);
    break;
  case TESTING_STARTER:
    TransitionTesting(TESTING_FLARE_IGNITOR);
    break;	
  case TESTING_FLARE_IGNITOR:
    TransitionTesting(TESTING_O2_RESET);
    break;
  case TESTING_O2_RESET:
    TransitionTesting(TESTING_ALARM);
    break;
  case TESTING_ALARM:
    digitalWrite(FET_ALARM,LOW);
    TransitionTesting(TESTING_ANA_LAMBDA); 
    break;
  case TESTING_ANA_LAMBDA:
    TransitionTesting(TESTING_ANA_ENGINE_SWITCH);
    break;
  case TESTING_ANA_ENGINE_SWITCH:
    TransitionTesting(TESTING_ANA_FUEL_SWITCH);
    break;
  case TESTING_ANA_FUEL_SWITCH:
    TransitionTesting(TESTING_ANA_OIL_PRESSURE);
    break;
  case TESTING_ANA_OIL_PRESSURE:
    TransitionTesting(TESTING_OFF);
    break;
  }
}

void turnAllOff(){
    digitalWrite(FET_AUGER,LOW);
    digitalWrite(FET_GRATE,LOW);
    digitalWrite(FET_IGNITION,LOW);
    digitalWrite(FET_STARTER,LOW);
    digitalWrite(FET_FLARE_IGNITOR,LOW);
    digitalWrite(FET_O2_RESET,LOW);
    digitalWrite(FET_ALARM,LOW); // FET6 can't generate PWM due to Servo library using the related timer
    digitalWrite(FET_AUGER_REV,LOW);
}




