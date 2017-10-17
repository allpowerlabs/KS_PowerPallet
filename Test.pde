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
  case TESTING_RUN_ENABLE:
    turnAllOff();
    digitalWrite(FET_RUN_ENABLE,HIGH);
    break;
  case TESTING_CONDENSATE_PUMP:
    turnAllOff();
    digitalWrite(FET_CONDENSATE_PUMP,HIGH);
    break;
  case TESTING_CONDENSATE_FAN:
    turnAllOff();
    digitalWrite(FET_CONDENSATE_FAN,HIGH);
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
    digitalWrite(FET_ALARM,HIGH);
    break;
  case TESTING_ANA_LAMBDA:
    break;
  case TESTING_ANA_ENGINE_SWITCH:
    break;
  case TESTING_ANA_FUEL_SWITCH:
    break;
  case TESTING_ANA_CONDENSATE_PRESSURE:
    break;
  }
  testing_state=new_state;
}

void GoToNextTestingState() {
  switch (testing_state) {
  case TESTING_OFF:
    TransitionTesting(TESTING_FUEL_AUGER);
    break;
  case TESTING_FUEL_AUGER:
	TransitionTesting(TESTING_FUEL_REV);
    break;
  case TESTING_FUEL_REV:
    TransitionTesting(TESTING_RUN_ENABLE);
    break;
  case TESTING_RUN_ENABLE:
    TransitionTesting(TESTING_CONDENSATE_PUMP);
    break;
  case TESTING_CONDENSATE_PUMP:
    TransitionTesting(TESTING_CONDENSATE_FAN);
    break;
  case TESTING_CONDENSATE_FAN:
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
    TransitionTesting(TESTING_OFF);
    break;
  }
}

void turnAllOff(){
    digitalWrite(FET_AUGER,LOW);
    digitalWrite(FET_RUN_ENABLE,LOW);
    digitalWrite(FET_CONDENSATE_PUMP,LOW);
    digitalWrite(FET_CONDENSATE_FAN,LOW);
    digitalWrite(FET_FLARE_IGNITOR,LOW);
    digitalWrite(FET_O2_RESET,LOW);
    digitalWrite(FET_ALARM,LOW);
    digitalWrite(FET_AUGER_REV,LOW);
}




