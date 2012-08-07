void DoControlInputs() {
  int control_input = analogRead(ANA_ENGINE_SWITCH);
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
}

void smoothAnalog(int channel){  //channel is the analog channel,  filterval is the number of past channelvalues to average over.
  float ana_signal = analogRead(channel);
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
