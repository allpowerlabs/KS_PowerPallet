void DoDisplay() {
  boolean disp_alt; // Var for alternating value display
  char config_buffer[] = "               ";
  char config_choice_buffer[] = "        ";
  
  
  
  if (millis() % (display_per*200) > (display_per*100) ) {    //  if (millis() % 2000 > 1000) {
    disp_alt = false;
  } 
  else {
    disp_alt = true;
  }
  switch (display_state) {
  case DISPLAY_SPLASH:
    //Row 0
    Disp_RC(0,0);
    Disp_PutStr(P("    Power Pallet    "));
    //Row 1
    Disp_RC(1,0);
    Disp_PutStr(P("www.allpowerlabs.org"));
    //Row 2
    Disp_RC(2,(20-strlen(CODE_VERSION))/2);
    sprintf(buf, "%s", CODE_VERSION);
    Disp_PutStr(buf);
    //Row 3
    Disp_RC(3,0);
    sprintf(buf, "%-10s     %5s", serial_num, unique_number);
    Disp_PutStr(buf);
    Disp_CursOff();
    //Transition out after delay
    if (millis()-display_state_entered>2000) {
      TransitionDisplay(DISPLAY_REACTOR);
    }
    break;
  case DISPLAY_REACTOR:
    Disp_CursOff();
    alarm_shown = alarm_queue[cur_item - 1];
    if (millis() % 10000 > 5000 && (alarm_count > 0)) {
      item_count = alarm_count;
      if (cur_item>item_count) {  //if an alarm is removed while displaying start over at beginning
        cur_item = 1;
      } 
      //Row 0
      Disp_RC(0, 0);
      if (shutdown[alarm_shown]> 0){
        sprintf(buf, "SHUTDOWN ALARM %2i/%2i", cur_item, alarm_count); 
      } 
      else {
        sprintf(buf, "      ALARM   %2i/%2i ", cur_item, alarm_count); 
      }
      Disp_PutStr(buf);
      //Row 1
      Disp_RC(1, 0);
      strcpy_P(p_buffer, (char*)pgm_read_word(&(display_alarm[alarm_shown])));
      Disp_PutStr(p_buffer);
      //Row 2
      Disp_RC(2, 0);
      strcpy_P(p_buffer, (char*)pgm_read_word(&(display_alarm2[alarm_shown])));
      Disp_PutStr(p_buffer);
      if (shutdown[alarm_shown] > 999 && engine_state == ENGINE_ON){     //anything less than 999 is a count and not a shutdown time in millisecond so don't show. 
        Disp_RC(2, 13);
        sprintf(buf, "OFF:%3i", (shutdown[alarm_shown] - alarm_start[alarm_shown] - (millis() - alarm_on[alarm_shown]))/1000);
        Disp_PutStr(buf);
      }
      //Row 3
      Disp_RC(3, 0);
      Disp_PutStr(P("NEXT ADV QUIET      "));
      if (millis() - alarm_on[alarm_shown] > 4000){ //Wait to show RESET button in case new alarm state has taken over screen.
        Disp_RC(3, 15);
        Disp_PutStr(P("RESET"));
      }
    } 
    else {
      //Row 0
      Disp_RC(0, 0);
//      if (millis()-transition_entered<2000) {
//        transition_message.toCharArray(buf,21);
//        Disp_PutStr(buf);
//      } 
//      else {
        if (disp_alt) {
          sprintf(buf, "Ttred%4i  ", Temp_Data[T_TRED]);
        } 
        else {
          sprintf(buf, "Ttred%s  ", T_tredLevel[TempLevelName]); // add spaces to erase prior
        }
        Disp_PutStr(buf);
        Disp_RC(0, 11);
        sprintf(buf, "Pcomb%4i", Press[P_COMB] / 25);
        Disp_PutStr(buf);
//      }

      //Row 1
      Disp_RC(1, 0);
      if (disp_alt) {
        sprintf(buf, "Tbred%4i  ", Temp_Data[T_BRED]);
      } 
      else {
        sprintf(buf, "Tbred%s  ", T_bredLevel[TempLevelName]); // add spaces to erase prior
      }
      Disp_PutStr(buf);
      Disp_RC(1, 11);
      sprintf(buf, "Preac%4i", Press[P_REACTOR] / 25);
      Disp_PutStr(buf);
      //Row 2
      Disp_RC(2,0);
      if (P_reactorLevel != OFF) {
        //the value only means anything if the pressures are high enough, otherwise it is just noise
        sprintf(buf, "Pratio%3i  ", int(pRatioReactor*100)); //pressure ratio
        Disp_PutStr(buf);
      } 
      else {
        Disp_PutStr(P("Pratio --  "));
      }
      Disp_RC(2, 11);
      if (true) {
        sprintf(buf, "Pfilt%4i", Press[P_FILTER] / 25);
      } 
      else {
        //TO DO: Implement filter warning
        if (pRatioFilterHigh) {
          sprintf(buf, "Pfilt Bad");
        } 
        else {
          sprintf(buf, "PfiltGood");
        }
      }
      Disp_PutStr(buf);
      //Row 3
      Disp_RC(3,0);
      switch(auger_state){ 
      case AUGER_FORWARD:
        sprintf(buf, "AugFwd%3i  ", (millis() - auger_state_entered)/1000);
        break;
      case AUGER_OFF:
        if (P_reactorLevel == OFF) {
          sprintf(buf, "AugOff%s  ", " --"); 
        } 
        else {
          sprintf(buf, "AugOff%3i  ", (millis() - auger_state_entered)/1000);  
        }
        break;
      case AUGER_REVERSE:
        sprintf(buf, "AugRev%3i  ", (millis() - auger_state_entered)/1000); 
        break;
      case AUGER_HIGH:
        sprintf(buf, "AugHi %3i  ", (millis() - auger_state_entered)/1000); 
        break;
      case AUGER_CURRENT_LOW:
        sprintf(buf, "AugLow%3i  ", (millis() - auger_state_entered)/1000);
        break;
      case AUGER_REVERSE_HIGH:
        sprintf(buf, "AugRHi%3i  ", (millis() - auger_state_entered)/1000); 
        break;
      case AUGER_ALARM:
        sprintf(buf, "AugALRM%3i ", (millis() - auger_state_entered)/1000);
        break;
      default:
        sprintf(buf, "Aug   %3i  ", (millis() - auger_state_entered)/1000);
        break;
      }
      Disp_PutStr(buf);
      Disp_RC(3, 10);
      strcpy_P(buf, half_blank);
      //sprintf(buf, "   %6i", millis()/1000);
      //if (disp_alt) {
      //  sprintf(buf, "Hz   %4i", int(CalculatePeriodHertz()));
      //} else {
      //  sprintf(buf, "Batt%5i", int(battery_voltage*10));
      //  //sprintf(buf, "Pow %5i", int(CalculatePulsePower()));
      //}
      Disp_PutStr(buf);
    } 
    if (alarm_count > 0){ //keypresses for alarms only
      if (key == 2) {
        alarm = false;
      }
      if (millis() - alarm_on[alarm_shown] > 4000){ //wait until RESET button shows up, a wait of 4 seconds is given so that 
        if (key == 3) {
          removeAlarm(alarm_shown);
          resetAlarm(alarm_shown);
          cur_item = 1; //start at beginning of alarm queue
        }
      }
    }
    break;
  case DISPLAY_ENGINE:
    Disp_CursOff();
    Disp_RC(0,0);
#if T_ENG_COOLANT != ABSENT
    sprintf(buf, "Tcool%4i  ", Temp_Data[T_ENG_COOLANT]);
#else
    sprintf(buf, "Tcool  NA  ");
#endif
    Disp_PutStr(buf);
    Disp_RC(0,11); 
    Disp_PutStr(P("           "));
    //Row 1
    Disp_RC(1,0); 
    strcpy_P(buf, blank);
    Disp_PutStr(buf);
    //Row 2
    Disp_RC(2,0); 
    strcpy_P(buf, blank);
    Disp_PutStr(buf);
    //Row 3
    Disp_RC(3,0);
    strcpy_P(buf, blank);
    Disp_PutStr(buf);
    Disp_CursOff();
    break;
  case DISPLAY_TESTING:
    Disp_CursOff();
    item_count = 1;
    //Row 0
    Disp_RC(0,0);
    Disp_PutStr(P("Testing             ")); 
    //Row 1			
    Disp_RC(1,0);
    strcpy_P(config_buffer, (char*)pgm_read_word(&(TestingStateName[testing_state])));
    sprintf(buf, "%-20s", config_buffer);
    Disp_PutStr(buf);
    //Row 2
    Disp_RC(2,0);
    switch (testing_state) {
    case TESTING_ANA_LAMBDA:
      sprintf(buf, "Value: %4i         ", int(analogRead(ANA_LAMBDA)));
      break;
    case TESTING_ANA_ENGINE_SWITCH:
      sprintf(buf, "Value: %4i         ", int(analogRead(ANA_ENGINE_SWITCH)));
      break;
    case TESTING_ANA_FUEL_SWITCH:
      sprintf(buf, "Value: %4i         ", int(analogRead(ANA_FUEL_SWITCH)));
      break;
    case TESTING_ANA_OIL_PRESSURE:
      sprintf(buf, "Value: %4i         ", int(analogRead(ANA_OIL_PRESSURE)));
      break;
      //    case TESTING_GOV_TUNING:
      //      break;
    default:
      sprintf(buf,"                   ");
    }
    Disp_PutStr(buf);
    //Row 3
    switch (cur_item) {
    case 1: // Testing 
      if (key == 2) {
        GoToNextTestingState(); //first testing state
      }
      Disp_RC(3,0);
      Disp_PutStr(P("NEXT       TEST     "));
      break;
    default:
      Disp_RC(3,0);
      Disp_PutStr(P("NEXT                "));
    }
    break;
  case DISPLAY_LAMBDA:
     Disp_CursOff();
    double P,I;
    item_count = 3;  // was 4, but moved Lambda display out of the edit path
    P=lambda_PID.GetP_Param();
    I=lambda_PID.GetI_Param();
    // Row 0
    Disp_RC(0,0);
    sprintf(buf, "LamSet%3i  ", int(ceil(lambda_setpoint*100.0)));
    Disp_PutStr(buf);
    Disp_RC(0,11);
    sprintf(buf, "Lambda%3i", int(lambda_input*100.0));
    Disp_PutStr(buf);
    //Row 1
    Disp_RC(1,0);
    sprintf(buf, "P     %3i  ", int(ceil(lambda_PID.GetP_Param()*100.0)));
    Disp_PutStr(buf);
    Disp_RC(1,11);
    sprintf(buf, "I     %3i", int(ceil(lambda_PID.GetI_Param()*100.0)));
    Disp_PutStr(buf);
    Disp_RC(2,0);
    Disp_PutStr("                    ");
    switch (cur_item) {
    case 1: // Lambda setpoint
      if (key == 2) {
        lambda_setpoint += 0.01;
        WriteLambda();
      }
      if (key == 3) {
        lambda_setpoint -= 0.01;
        WriteLambda();
      }          
      Disp_RC(0,0);
      Disp_CursOn();
      Disp_RC(3,0);
      strcpy_P(buf, menu1);
      Disp_PutStr(buf);
      break;
    case 2: //Lambda P
      if (key == 2) {
        P += 0.01;
        lambda_P[0] = P;
        WriteLambda();
      }
      if (key == 3) {
        P -= 0.01;
        lambda_P[0] = P;
        WriteLambda();
      }
      lambda_PID.SetTunings(P,I,0);
      Disp_RC(3,0);
      strcpy_P(buf, menu1);
      Disp_PutStr(buf);
      Disp_RC(1,0);
      Disp_CursOn();
      break;
    case 3: //Lambda I
      if (key == 2) {
        I += 0.1;
        lambda_I[0] = I;
        WriteLambda();
      }
      if (key == 3) {
        I -= 0.1;
        lambda_I[0] = I; 
        WriteLambda();
      }
      lambda_PID.SetTunings(P,I,0);
      Disp_RC(3,0);
      strcpy_P(buf, menu1);
      Disp_PutStr(buf);
      Disp_RC(1,11);
      Disp_CursOn();
      break;
//    case 4: //Lambda reading - because it's NOT editable, moved it out of the edit selection path.
//      Disp_RC(3,0);
//      Disp_PutStr(P("NEXT  ADV           "));
//      Disp_RC(0,11);
//      Disp_CursOn();
//      break;
    }
    break;
  case DISPLAY_GRATE: 
    Disp_CursOff();
    Disp_RC(0,0);
    Disp_PutStr(P("   Manual Control   ")); 
    Disp_RC(1,0);
    Disp_PutStr(P("Auger:              "));
    Disp_RC(1,11);
    if (auger_state == AUGER_ALARM){
      Disp_PutStr(P("OFF"));
    } 
    else {
      Disp_PutStr(P("AUTO"));
    }
    Disp_RC(2,0);
    Disp_PutStr(P("Grate:              "));
    Disp_RC(2,11);
    if (grateMode == GRATE_SHAKE_OFF){
      Disp_PutStr(P("OFF"));
    } 
    else if (grateMode == GRATE_SHAKE_PRATIO){
      Disp_PutStr(P("AUTO"));
    } 
    else {
      Disp_PutStr(P("ON"));
    }
    Disp_RC(3,0);
    Disp_PutStr(P("Next     Aug   Grate")); 
    if (key == 2) {
      config_changed = true;
      Disp_RC(1,11);
      if (auger_state == AUGER_ALARM){
        TransitionAuger(AUGER_OFF);
      } 
      else {
        TransitionAuger(AUGER_ALARM);
      }
    }
    if (key == 3) {
      config_changed = true;
      switch (grateMode) {
      case GRATE_SHAKE_OFF:
        grateMode = GRATE_SHAKE_ON;
        Logln("Grate Mode: On");
        break;
      case GRATE_SHAKE_ON:
        grateMode = GRATE_SHAKE_PRATIO;
        Logln("Grate Mode: Pressure Ratio");
        break;
      case GRATE_SHAKE_PRATIO:
        grateMode = GRATE_SHAKE_OFF;
        Logln("Grate Mode: Off");
        break;
      }
    }
    break;
  case DISPLAY_INFO:
    Disp_CursOff();
    Disp_RC(0,0);
    sprintf(buf, "%-10s     %5s", serial_num, unique_number);
    Disp_PutStr(buf);
    Disp_RC(1,0);
    sprintf(buf, "       Time:%8i", millis()/1000);
    Disp_PutStr(buf);
    Disp_RC(2,0);
    sprintf(buf, "    %12s   ", sd_data_file_name);
    Disp_PutStr(buf);
    Disp_RC(3,0);
    Disp_PutStr(P("NEXT                "));
    break;
  case DISPLAY_SERVO:   //need to add constraints for min and max?
    item_count = 2;
    testing_state = TESTING_SERVO;  //necessary so that there isn't any conflicting servo writes
    Disp_RC(0,0);
    sprintf(buf, "ServoMin%3i", int(premix_valve_closed));
    Disp_PutStr(buf);
    Disp_RC(0,11);
    sprintf(buf, " Max %3i", int(premix_valve_open));
    Disp_PutStr(buf);
    //Row 1
    Disp_RC(1,0);
    Disp_PutStr(P(" Careful of Sides!  ")); 
    Disp_RC(2,0);
    Disp_PutStr("                    ");
    switch (cur_item) {
    case 1: // Servo Min
      Servo_Mixture.write(premix_valve_closed);
      if (key == 2) {
        if (premix_valve_closed + 1 < premix_valve_open){
          premix_valve_closed += 1;
        }
      }
      if (key == 3) {
        premix_valve_closed -= 1;
      }
      Disp_RC(3,0);
      strcpy_P(buf, menu1);
      Disp_PutStr(buf);
      Disp_RC(0,0);
      Disp_CursOn();
      break;
    case 2: //Servo Max 
      Servo_Mixture.write(premix_valve_open);
      if (key == 2) {
        premix_valve_open += 1;
      }
      if (key == 3) {
        if (premix_valve_open - 1 > premix_valve_closed) {
          premix_valve_open -= 1;
        }
      }
      Disp_RC(3,0);
      strcpy_P(buf, menu1);
      Disp_PutStr(buf);
      Disp_RC(0,11);
      Disp_CursOn();
      break;
    }
    break;
  case DISPLAY_CALIBRATE_PRESSURE:
    Disp_CursOff();
    item_count = 1;
    Disp_RC(0,0);
    Disp_PutStr(P("Calibrate Pressure  "));
    Disp_RC(1,0);
    Disp_PutStr(P("Sensors to zero?    "));
    Disp_RC(2,0);
    strcpy_P(buf, blank);
    Disp_PutStr(buf);
    Disp_RC(3,0);
    Disp_PutStr(P("NEXT       YES      "));
    if (key == 2) {
      CalibratePressureSensors();
      LoadPressureSensorCalibration();
      Disp_RC(2,0);
      Disp_PutStr(P("   CALIBRATED!      "));
    }
    break;
  case DISPLAY_RELAY:
    Disp_CursOff();
    item_count = 7;
    testing_state = TESTING_SERVO;
    Disp_RC(0,0);
    sprintf(buf, "Test Relay: %1i       ", cur_item);
    Disp_PutStr(buf);
    Disp_RC(1,0);
    strcpy_P(config_buffer, (char*)pgm_read_word(&(TestingStateName[cur_item])));
    sprintf(buf, "%-20s", config_buffer);
    Disp_PutStr(buf);
    Disp_RC(2,0);
    if (config_changed == true){
      Disp_PutStr(P("State: ON           "));
    } else { 
      Disp_PutStr(P("State: OFF          "));
    }
    Disp_RC(3,0);
    Disp_PutStr(P("NEXT  ADV   ON   OFF"));
    if (key == 2) {
      relayOn(cur_item+1);
      config_changed = true;
    }
    if (key == 3) {
      relayOff(cur_item+1);
      config_changed = false;
    }
    break;
  case DISPLAY_CONFIG:
    Disp_CursOff();
    item_count = CONFIG_COUNT - 1; //sizeof(defaults)/sizeof(int);
    if (config_changed == false){
      config_var = getConfig(cur_item);
    }
    if (config_var == 255){  //EEPROM default state, not a valid choice.  Loops choice back to zero.
      config_var = 0;
    }
    if (config_var == -1){  //keeps values from being negative
      config_var = config_max[cur_item];
    }
    Disp_RC(0,0);
    Disp_PutStr(P("   Configurations   "));
    Disp_RC(1,0);
    strcpy_P(config_buffer, (char*)pgm_read_word(&(Configuration[cur_item])));
    strcpy_P(config_choice_buffer, (char*)pgm_read_word(&(Config_Choices[cur_item])));
    if (strcmp(config_choice_buffer, "+    -  ") == 0){
      sprintf(buf, "%s:%3i ", config_buffer, config_var);
    } 
    else if (strcmp(config_choice_buffer, "+5  -5  ") == 0){
      sprintf(buf, "%s:%4i ", config_buffer, config_var*5);
    } 
    else {
      if (config_var == 0){
        choice[0] = config_choice_buffer[0];
        choice[1] = config_choice_buffer[1];
        choice[2] = config_choice_buffer[2];
        choice[3] = config_choice_buffer[3];
        choice[4] = '\0';
      } 
      else {
        choice[0] = config_choice_buffer[4];
        choice[1] = config_choice_buffer[5];
        choice[2] = config_choice_buffer[6];
        choice[3] = config_choice_buffer[7];
        choice[4] = '\0';
      }
      sprintf(buf, "%s:%s", config_buffer, choice);
    }
    Disp_PutStr(buf);
    Disp_RC(2,0);
    Disp_PutStr(P("ADV to save choice  "));
    Disp_RC(3,0);
    sprintf(buf, "NEXT  ADV   %s", config_choice_buffer);
    Disp_PutStr(buf);
    if (strcmp(config_choice_buffer, "+    -  ") == 0){
      if (key == 2) {
        if (config_max[cur_item] >= config_var + 1){
          config_var += 1;
          config_changed = true;
        }
      }
      if (key == 3) {
        if (config_min[cur_item] <= config_var - 1){
          config_var -= 1;
          config_changed = true;
        }
      }
    } 
    else if (strcmp(config_choice_buffer, "+5  -5  ") == 0){
      if (key == 2) {
        if (config_max[cur_item] >= config_var + 1){
          config_var += 1;
          config_changed = true;
        }
      }
      if (key == 3) {
        if (config_min[cur_item] <= config_var - 1){
          config_var -= 1;
          config_changed = true;
        }
      }
    } 
    else {
      if (key == 2) {  
        config_var = 0;
        config_changed = true;
      }
      if (key == 3) {
        config_var = 1;
        config_changed = true;
      }
    }
    break;
    //  case DISPLAY_SD:
    //    Disp_CursOff();
    //    Disp_RC(0,0);
    //    Disp_PutStr("   Test SD Card     ");
    //    Disp_RC(1,0);
    //    Disp_PutStr("See Serial Monitor  ");
    //    Disp_RC(2,0);
    //    Disp_PutStr("for more information");
    //    Disp_RC(3,0);
    //    Disp_PutStr("NEXT            TEST");
    //    if (key == 3 and cur_item == 1) {  //only allow the button to be pressed once
    //      testSD();
    //      cur_item++;  
    //    }
    //    break;
//  case DISPLAY_PHIDGET:
//      Disp_CursOff();
////    Disp_RC(0,0);
////    sprintf(buf, "O2%4i Fu%4iKey%4i", analogRead(ANA0),analogRead(ANA1),analogRead(ANA2));
////    Disp_PutStr(buf);
////    Disp_RC(1,0);
////    sprintf(buf, "Oil%4iAug%4iTh%4i", analogRead(ANA3),analogRead(ANA4),analogRead(ANA5));
////    Disp_PutStr(buf);
////    Disp_RC(2,0);
////    sprintf(buf, "CoolT%4i Aux%4i   ", analogRead(ANA6),analogRead(ANA7));
////    Disp_PutStr(buf);  
////    Disp_RC(3,0);
////    Disp_PutStr("NEXT                ");
//    Disp_RC(0,0);
//    sprintf(buf, "Phidgits:     0:%4i", analogRead(ANA0));
//    Disp_PutStr(buf);
//    Disp_RC(1,0);
//    sprintf(buf, "1:%4i 2:%4i 3:%4i", analogRead(ANA1),analogRead(ANA2),analogRead(ANA3));
//    Disp_PutStr(buf);
//    Disp_RC(2,0);
//    sprintf(buf, "4:%4i 5:%4i 6:%4i", analogRead(ANA4),analogRead(ANA5),analogRead(ANA6));
//    Disp_PutStr(buf);  
//    Disp_RC(3,0);
//    sprintf(buf, "NEXT          7:%4i", analogRead(ANA7));
//    Disp_PutStr(buf);
//    break;
  case DISPLAY_ANA:
    Disp_CursOff();
    item_count = 7;
    //testing_state = TESTING_SERVO;
    Disp_RC(0,0);
    sprintf(buf, "Analog Input: ANA%1i  ", cur_item);
    Disp_PutStr(buf);
    Disp_RC(1,0);
    strcpy_P(config_buffer, (char*)pgm_read_word(&(TestingStateName[cur_item+8])));
    sprintf(buf, "%-20s", config_buffer);
    Disp_PutStr(buf);
    Disp_RC(2,0);
    sprintf(buf, "Value: %4i         ", int(analogRead(analog_inputs[cur_item])));
    //sprintf(buf, "Value: %4i         ", smoothed[cur_item]);
    Disp_PutStr(buf);
    Disp_RC(3,0);
    Disp_PutStr("NEXT  ADV           ");
    break;
         
    //    case DISPLAY_TEMP2:
    //      break;
    //    case DISPLAY_FETS:
    //      break;
  }
  key = -1; //important, must clear key to read new input
}

void TransitionDisplay(int new_state) {
  //Enter
  display_state_entered = millis();
  switch (new_state) {
  case DISPLAY_SPLASH:
    break;
  case DISPLAY_REACTOR:
    cur_item = 1;
    break;
  case DISPLAY_ENGINE:
    break;
  case DISPLAY_LAMBDA:
    cur_item = 1;
    break;
  case DISPLAY_GRATE:
    config_changed = false;
    //cur_item = 1;
    break;
  case DISPLAY_TESTING:
    cur_item = 1;
    break;
  case DISPLAY_INFO:
    break;
  case DISPLAY_SERVO:
    cur_item = 1;
    break;
  case DISPLAY_CALIBRATE_PRESSURE:
    cur_item = 1;
    break;
  case DISPLAY_RELAY:
    turnAllOff();
    TransitionAuger(AUGER_OFF);  //reboot auger states
    cur_item = 0;
    break; 
  case DISPLAY_CONFIG: 
    cur_item = 0;
    config_changed = false;
    break;
    //  case DISPLAY_PHIDGET: 
    //    break;
  case DISPLAY_SD:
    cur_item = 1;
    break;
  case DISPLAY_ANA:
    cur_item = 0;
    break;
  }
  display_state=new_state;
}

void DoKeyInput() {
  int k;
  k =  Kpd_GetKeyAsync();
  if (key == -1) { //only update key if it has been cleared
    key = k;
  }
  if (key == 0) {
    switch (display_state) {
    case DISPLAY_SPLASH:
      TransitionDisplay(DISPLAY_REACTOR);
      break;
    case DISPLAY_REACTOR:
      TransitionDisplay(DISPLAY_LAMBDA);
      break;
    case DISPLAY_ENGINE:
      TransitionDisplay(DISPLAY_REACTOR);
      break;
    case DISPLAY_LAMBDA:
      TransitionDisplay(DISPLAY_GRATE);
      break;
    case DISPLAY_GRATE:
      grateMode = GRATE_SHAKE_PRATIO;
      if (config_changed == true){
        TransitionDisplay(DISPLAY_REACTOR);
      } else {
        TransitionDisplay(DISPLAY_INFO);
      }
      break;
    case DISPLAY_INFO:
      if (engine_state == ENGINE_OFF) {
        TransitionDisplay(DISPLAY_RELAY);
      } 
      else {
        TransitionDisplay(DISPLAY_REACTOR);
      }
      break;
    case DISPLAY_TESTING:
      turnAllOff();
      if (engine_state == ENGINE_OFF){
        TransitionDisplay(DISPLAY_SERVO);
      } 
      else {
        TransitionTesting(TESTING_OFF);
        TransitionDisplay(DISPLAY_REACTOR);
      }
      break;
    case DISPLAY_RELAY:
      turnAllOff();
      if (engine_state == ENGINE_OFF) {
        TransitionDisplay(DISPLAY_ANA);
      } 
      else {
        TransitionDisplay(DISPLAY_REACTOR);
      }
      break;
    case DISPLAY_ANA:
      if (engine_state == ENGINE_OFF) {
        TransitionDisplay(DISPLAY_SERVO);
      } 
      else {
        TransitionDisplay(DISPLAY_REACTOR);
      }
      break;
    case DISPLAY_SERVO:
      WriteServo();
      TransitionDisplay(DISPLAY_CALIBRATE_PRESSURE);  //assume that engine state is off because we are already in DISPLAY_SERVO
      TransitionTesting(TESTING_OFF);
      break;
    case DISPLAY_CALIBRATE_PRESSURE:                 //assume that engine state is off
      //      TransitionDisplay(DISPLAY_RELAY);
      //      break;
      //    case DISPLAY_RELAY:
      TransitionDisplay(DISPLAY_CONFIG);
      TransitionTesting(TESTING_OFF);
      break;
    case DISPLAY_CONFIG:
      //      TransitionDisplay(DISPLAY_PHIDGET);
      //      break;
      //    case DISPLAY_PHIDGET:
      //      TransitionDisplay(DISPLAY_SD);
      //      break;
      //    case DISPLAY_SD:
      TransitionDisplay(DISPLAY_REACTOR);
      break;
    }
    key = -1; //key caught
  }
  if (key == 1) {
    if (display_state == DISPLAY_CONFIG and config_changed == true){
      saveConfig(cur_item, config_var);
      update_config_var(cur_item);
      config_changed = false;
    }
    if (display_state == DISPLAY_RELAY){
      config_changed = false;
      turnAllOff();
    }
    cur_item += 1;
    if (cur_item > item_count) {
      switch (display_state) {
        case DISPLAY_CONFIG:
        case DISPLAY_RELAY:
        case DISPLAY_ANA:
          cur_item = 0;
          break;
        default:
          cur_item = 1;
          break;
      }
    } 
    key = -1; //key caught
  }
}

void DoHeartBeat() {
  if (millis() % 50 > 5) {
    bitSet(PORTJ, 7);
  } 
  else {
    bitClear(PORTJ, 7);
  }
  //PORTJ ^= 0x80;    // toggle the heartbeat LED
}

//void TransitionMessage(String t_message) {
//  transition_message = t_message;
//  transition_entered = millis();
//}

void saveConfig(int item, int state){  //EEPROM:  0-499 for internal states, 500-999 for configurable states, 1000-4000 for data logging configurations.
  if (item == 0  and state == 1){
    resetConfig();
  }
  if (item > 0){  //skip first config 
    int old_state = EEPROM.read(499+item);
    if(state != old_state){
      EEPROM.write(499+item, state);
      delay(5); //ensure that value is not read until EERPROM has been fully written (~3.3ms)
    }
  }
}

int getConfig(int item){
  int value = 0;
  if (item > 0){  //Config item zero is 'Reset to Defaults?' so skip
    value = int(EEPROM.read(499+item));
    if (value == 255){  //values hasn't been saved yet to EEPROM, go with default value saved in defaults[]
      value = defaults[item];
      EEPROM.write(499+item, value);
      config_changed = true;
    }
  }
  return value;
}

void update_config_var(int var_num){
  switch (var_num) {
  case 0:
    Logln_p("Updating Configurations to Defaults");
    for (int i=1; i<CONFIG_COUNT; i++){
      update_config_var(i);
    }
    break;
  case 1:
    engine_type = getConfig(1);
    regs[MB_CONFIG1] = engine_type;
    if (engine_type == 0){
        shutdown[ALARM_AUGER_OFF_LONG] = shutdown[ALARM_AUGER_OFF_LONG] * 2;  //10k power pallet goes through fuel slower, give it more time.
    }
    break;
  case 2:
    relay_board = getConfig(2);
    regs[MB_CONFIG2] = relay_board;
    break;
  case 3:
    aug_rev_time = getConfig(3)*100;
    regs[MB_CONFIG3] = aug_rev_time;
    break;
  case 4:
    current_low_boundary = getConfig(4); 
    AugerCurrentLevelBoundary[CURRENT_LOW][1] = current_low_boundary; 
    AugerCurrentLevelBoundary[CURRENT_ON][0] = current_low_boundary+5;
    regs[MB_CONFIG4] = current_low_boundary;
    break;
  case 5:
    current_high_boundary = getConfig(5);
    AugerCurrentLevelBoundary[CURRENT_ON][1] = current_high_boundary - 5; 
    AugerCurrentLevelBoundary[CURRENT_HIGH][0] = current_high_boundary;
    regs[MB_CONFIG5] = current_high_boundary;
    break;
  case 6:
    low_oil_psi = getConfig(6);
    regs[MB_CONFIG6] = low_oil_psi;
    break;
  case 7:
    save_datalog_to_sd = getConfig(7);
    regs[MB_CONFIG7] = save_datalog_to_sd;
    break;
  case 8:
    pratio_max = getConfig(8)*5;
    alarm_start[ALARM_BAD_REACTOR] = pratio_max;
    regs[MB_CONFIG8] = pratio_max;
    break;
  case 9:
    high_coolant_temp = getConfig(9);
    regs[MB_CONFIG9] = high_coolant_temp;
    break;
  case 10:
    display_per = getConfig(10);
    regs[MB_CONFIG10] = display_per;
    break;
  case 11:
    tred_low_temp = getConfig(11)*5;
    regs[MB_CONFIG11] = tred_low_temp;
    break;
  case 12:
    ttred_high = getConfig(12)*5;
    regs[MB_CONFIG12] = ttred_high;
    break;
  case 13:
    tbred_high = getConfig(13)*5;
    regs[MB_CONFIG13] = tbred_high;
    break;
  case 14:
    pfilter_alarm = getConfig(14);
    alarm_start[ALARM_BAD_FILTER] = pfilter_alarm;
    regs[MB_CONFIG14] = pfilter_alarm;
    break;
  case 15:
    grate_max_interval = getConfig(15)*5;  //longest total interval in seconds
    regs[MB_CONFIG15] = grate_max_interval;
    CalculateGrate();
    break;
  case 16:
    grate_min_interval = getConfig(16)*5;
    regs[MB_CONFIG16] = grate_min_interval;
    CalculateGrate();
    break;
  case 17:
    grate_on_interval = getConfig(17); 
    regs[MB_CONFIG17] = grate_on_interval;
    CalculateGrate();
    break;
  case 18:
    servo_start = getConfig(18);
    regs[MB_CONFIG18] = servo_start;
    break;
  case 19:
    lambda_rich = getConfig(19);
    regs[MB_CONFIG19] = lambda_rich;
    break;
  case 20:
    use_modbus = getConfig(20);
    regs[MB_CONFIG20] = use_modbus;
    break;
  case 21:
    m_baud = getConfig(21);
    regs[MB_CONFIG21] = m_baud;
    break;
  case 22:
    m_parity = getConfig(22);
    regs[MB_CONFIG22] = m_parity;
    break;
  case 23:
    m_address = getConfig(23);
    regs[MB_CONFIG23] = m_address;
    break;
  case 24:
    grid_tie = getConfig(24);
    break;
  case 25:
    pratio_low_boundary = getConfig(25);
    pratio_low = pratio_low_boundary/100.0;
    pRatioReactorLevelBoundary[1][0] = pratio_low;
    pRatioReactorLevelBoundary[2][1] = pratio_low;
    //regs[MB_CONFIG24] = m_pratio_low_boundary;
    break;
  case 26:
    ttred_warn = getConfig(26)*5;
    break;
  case 27:
    pratio_high_boundary = getConfig(27);
    pratio_high = pratio_high_boundary/100.0;
    pRatioReactorLevelBoundary[0][0] = pratio_high;
    pRatioReactorLevelBoundary[1][1] = pratio_high;
    break;
  }
}

void resetConfig() {  //sets EEPROM configs back to untouched state
  int default_count = sizeof(defaults)/sizeof(int);
  for (int i=1; i < default_count; i++){
    EEPROM.write(499+i, defaults[i]);
  }
}



