void DoControlInputs() {
  int control_input = analogRead(ANA_ENGINE_SWITCH);
  if (grid_tie == 0){
    if (abs(control_input-10)<20) { //"engine off"
      if (control_state != CONTROL_OFF) {
        control_state_entered = millis();
      }
      control_state = CONTROL_OFF;
    }
    if (abs(control_input-1023)<20) { //"engine off"
      if (control_state != CONTROL_OFF) {
        control_state_entered = millis();
      }
      control_state = CONTROL_OFF;
    }
    if (abs(control_input-683)<20) { //"engine on" and starter button pressed
      if (control_state != CONTROL_START) {
        control_state_entered = millis();
      }
      control_state = CONTROL_START;
    }
    if (abs(control_input-515)<20) { //"engine on"
      if (control_state != CONTROL_ON) {
        control_state_entered = millis();
      }
      control_state = CONTROL_ON;
    }
  } else {  //Controlled by Deapsea 
    if (control_input > 515){ 
     if (control_state == CONTROL_OFF){
       control_state = CONTROL_START;
       control_state_entered = millis();
       Logln_p("# Deap Sea controller set to: Start");
     }
     if (control_state == CONTROL_START && (millis() - control_state_entered >= 500)){
       control_state = CONTROL_ON;
       Logln_p("# Deap Sea controller set to: On");
     }
    } else {
      if (control_state != CONTROL_OFF) {
        control_state_entered = millis();
        control_state = CONTROL_OFF;
        Logln_p("# Deap Sea controller set to:  Off");
      }
    } 
  }
}

void smoothAnalog(int channel){  //channel is the analog channel,  filterval is the number of past channelvalues to average over.
  float ana_signal = analogRead(channel);
  channel = getAnaArray(channel);
  float smoothed_value = smoothed[channel];
  float filterval = smoothed_filters[channel];
  if (filterval > 0){
    if (ana_signal > smoothed_value){
          smoothed_value = smoothed_value + (ana_signal - smoothed_value)/filterval;
    } else {
          smoothed_value = smoothed_value - (smoothed_value - ana_signal)/filterval;
    }
  } else {
    smoothed_value = ana_signal;
  }
  smoothed[channel] = int(smoothed_value);
}

int getAnaArray(int channel){
  int ana_channel;
  switch (channel){
    case ANA0:
      ana_channel = 0;
      break;
    case ANA1:
      ana_channel = 1;
      break;
    case ANA2:
      ana_channel = 2;
      break;
    case ANA3:
      ana_channel = 3;
      break;
    case ANA4:
      ana_channel = 4;
      break;
    case ANA5:
      ana_channel = 5;
      break;
    case ANA6:
      ana_channel = 6;
      break;
    case ANA7:
      ana_channel = 7;
      break;
  }
  return ana_channel;
}
