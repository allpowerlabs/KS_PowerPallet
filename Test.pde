void TransitionTesting(int new_state) {
  testing_state_entered = millis();
  Serial.print("#Switching to testing state:");
  Serial.println(TestingStateName[new_state]);
  switch (new_state) {
  case TESTING_OFF:
    break;
  case TESTING_FUEL_AUGER:
    digitalWrite(FET_AUGER,HIGH);
    digitalWrite(FET_GRATE,LOW);
    digitalWrite(FET_IGNITION,LOW);
    digitalWrite(FET_STARTER,LOW);
    digitalWrite(FET_FLARE_IGNITOR,LOW);
    digitalWrite(FET_O2_RESET,LOW);
    digitalWrite(FET_ALARM,LOW); // FET6 can't generate PWM due to Servo library using the related timer
    break;
  case TESTING_GRATE:
    digitalWrite(FET_AUGER,LOW); 
    digitalWrite(FET_GRATE,HIGH);
    digitalWrite(FET_IGNITION,LOW);
    digitalWrite(FET_STARTER,LOW);
    digitalWrite(FET_FLARE_IGNITOR,LOW);
    digitalWrite(FET_O2_RESET,LOW);
    digitalWrite(FET_ALARM,LOW); // FET6 can't generate PWM due to Servo library using the related timer
    break;
  case TESTING_ENGINE_IGNITION:
    digitalWrite(FET_AUGER,LOW);
    digitalWrite(FET_GRATE,LOW);
    digitalWrite(FET_IGNITION,HIGH);
    digitalWrite(FET_STARTER,LOW);
    digitalWrite(FET_FLARE_IGNITOR,LOW);
    digitalWrite(FET_O2_RESET,LOW);
    digitalWrite(FET_ALARM,LOW); // FET6 can't generate PWM due to Servo library using the related timer
    break;
  case TESTING_STARTER:
    digitalWrite(FET_AUGER,LOW);
    digitalWrite(FET_GRATE,LOW);
    digitalWrite(FET_IGNITION,LOW);
    digitalWrite(FET_STARTER,HIGH);
    digitalWrite(FET_FLARE_IGNITOR,LOW);
    digitalWrite(FET_O2_RESET,LOW);
    digitalWrite(FET_ALARM,LOW); // FET6 can't generate PWM due to Servo library using the related timer
    break;	
  case TESTING_FLARE_IGNITOR:
    digitalWrite(FET_AUGER,LOW);
    digitalWrite(FET_GRATE,LOW);
    digitalWrite(FET_IGNITION,LOW);
    digitalWrite(FET_STARTER,LOW);
    digitalWrite(FET_FLARE_IGNITOR,HIGH);
    digitalWrite(FET_O2_RESET,LOW);
    digitalWrite(FET_ALARM,LOW); // FET6 can't generate PWM due to Servo library using the related timer
    break;
  case TESTING_O2_RESET:
    digitalWrite(FET_AUGER,LOW);
    digitalWrite(FET_GRATE,LOW);
    digitalWrite(FET_IGNITION,LOW);
    digitalWrite(FET_STARTER,LOW);
    digitalWrite(FET_FLARE_IGNITOR,LOW);
    digitalWrite(FET_O2_RESET,HIGH);
    digitalWrite(FET_ALARM,LOW); // FET6 can't generate PWM due to Servo library using the related timer
    break;
  case TESTING_ALARM:
    digitalWrite(FET_AUGER,LOW);
    digitalWrite(FET_GRATE,LOW);
    digitalWrite(FET_IGNITION,LOW);
    digitalWrite(FET_STARTER,LOW);
    digitalWrite(FET_FLARE_IGNITOR,LOW);
    digitalWrite(FET_O2_RESET,LOW);
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







