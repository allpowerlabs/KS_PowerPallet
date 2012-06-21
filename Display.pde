void DoDisplay() {
  boolean disp_alt; // Var for alternating value display
  char buf[20];
  if (millis() % 2000 > 1000) {
    disp_alt = false;
  } 
  else {
    disp_alt = true;
  }
  switch (display_state) {
  case DISPLAY_SPLASH:
    //Row 0
    Disp_RC(0,0);
    if (GCU_version == V2) {
      Disp_PutStr("   KS GCU V 2.0    ");
    } 
    else if (GCU_version == V3) {
      Disp_PutStr("    KS PCU V 3.0    ");
    }
    //Row 1
    Disp_RC(1,0);
    Disp_PutStr("www.allpowerlabs.org");
    //Row 2
    Disp_RC(2,0);
    sprintf(buf, "        %s        ", CODE_VERSION);
    Disp_PutStr(buf);
    //Row 3
    Disp_RC(3,0);
    Disp_PutStr("                    ");
    Disp_CursOff();
    //Transition out after delay
    if (millis()-display_state_entered>2000) {
      TransitionDisplay(DISPLAY_REACTOR);
    }
    break;
  case DISPLAY_REACTOR:
    Disp_CursOff();
    //Row 0
    Disp_RC(0, 0);
    if (millis()-transition_entered<2000) {
      transition_message.toCharArray(buf,21);
      Disp_PutStr(buf);
    } 
    else {
      if (disp_alt) {
        sprintf(buf, "Ttred%4i  ", Temp_Data[T_TRED]);
      } 
      else {
        sprintf(buf, "Ttred%s", T_tredLevel[TempLevelName]);
      }
      Disp_PutStr(buf);
      Disp_RC(0, 11);
      sprintf(buf, "Pcomb%4i", Press[P_COMB] / 25);
      Disp_PutStr(buf);
    }
    //Row 1
    Disp_RC(1, 0);
    if (disp_alt) {
      sprintf(buf, "Tbred%4i  ", Temp_Data[T_BRED]);
    } 
    else {
      sprintf(buf, "Tbred%s", T_bredLevel[TempLevelName]);
    }
    Disp_PutStr(buf);
    Disp_RC(1, 11);
    sprintf(buf, "Preac%4i", Press[P_REACTOR] / 25);
    Disp_PutStr(buf);

    //Row 2
    Disp_RC(2,0);
    if (P_reactorLevel != OFF) {
      //the value only means anything if the pressures are high enough, otherwise it is just noise
      sprintf(buf, "Pratio %3i  ", int(pRatioReactor*100)); //pressure ratio
      Disp_PutStr(buf);
    } 
    else {
      Disp_PutStr("Pratio --  ");
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
    if (millis() % 4000 > 2000 & alarm != ALARM_NONE) {
      Disp_RC(3,0);
      Disp_PutStr(display_alarm[alarm]);
    } 
    else {
      Disp_RC(3,0);
      if (auger_on) {
        sprintf(buf, "Aug On%3i  ", auger_on_length);
      } 
      else {  
        sprintf(buf, "AugOff%3i  ", auger_off_length);                                                                                                                                                                                                                                                                                                                                                                                                                           
      }
      Disp_PutStr(buf);
      sprintf(buf, "         ");
      //if (disp_alt) {
      //  sprintf(buf, "Hz   %4i", int(CalculatePeriodHertz()));
      //} else {
      //  sprintf(buf, "Batt%5i", int(battery_voltage*10));
      //  //sprintf(buf, "Pow %5i", int(CalculatePulsePower()));
      //}
      Disp_RC(3, 11);
      Disp_PutStr(buf);
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
    Disp_PutStr("           ");
    //Row 1
    Disp_RC(1,0); 
    Disp_PutStr("                    ");
    //Row 2
    Disp_RC(2,0); 
    Disp_PutStr("                    ");
    //Row 3
    Disp_RC(3,0);
    Disp_PutStr("                    ");
    Disp_CursOff();
    break;
  case DISPLAY_TESTING:
    Disp_CursOff();
    item_count = 1;
    //Row 0
    Disp_RC(0,0);
    Disp_PutStr("Testing             "); 
    //Row 1			
    Disp_RC(1,0);
    sprintf(buf, "Test:%-15s", TestingStateName[testing_state]);
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
      Disp_PutStr("NEXT       TEST     ");
      break;
    default:
      Disp_RC(3,0);
      Disp_PutStr("NEXT                ");
    }
    break;
  case DISPLAY_LAMBDA:
    double P,I;
    item_count = 4;
    P=lambda_PID.GetP_Param();
    I=lambda_PID.GetI_Param();
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
      Disp_PutStr("NEXT  ADV   +    -  ");
      break;
    case 2: //Lambda reading
      Disp_RC(3,0);
      Disp_PutStr("NEXT  ADV           ");
      Disp_RC(0,11);
      Disp_CursOn();
      break;
    case 3: //Lambda P
      if (key == 2) {
        P += 0.01;
        WriteLambda();
      }
      if (key == 3) {
        P -= 0.01;
        WriteLambda();
      }
      lambda_PID.SetTunings(P,I,0);
      Disp_RC(3,0);
      Disp_PutStr("NEXT  ADV   +    -  ");
      Disp_RC(1,0);
      Disp_CursOn();
      break;
    case 4: //Lambda I
      if (key == 2) {
        I += 0.1;
        WriteLambda();
      }
      if (key == 3) {
        I -= 0.1;
        WriteLambda();
      }
      lambda_PID.SetTunings(P,I,0);
      Disp_RC(3,0);
      Disp_PutStr("NEXT  ADV   +    -  ");
      Disp_RC(1,11);
      Disp_CursOn();
      break;
    }
    break;
  case DISPLAY_GRATE: 
    int vmin,vmax;
    item_count = 4;
    Disp_RC(0,0);
    sprintf(buf, "GraMin%3i  ", grate_min_interval);
    Disp_PutStr(buf);
    Disp_RC(0,11);
    sprintf(buf, "GraMax%3i", grate_max_interval);
    Disp_PutStr(buf);
    //Row 1
    Disp_RC(1,0);
    sprintf(buf, "GraLen%3i  ", grate_on_interval);
    Disp_PutStr(buf);
    Disp_RC(1,11);
    if (grate_motor_state == GRATE_MOTOR_OFF) {  
      Disp_PutStr("Grate Off");
    } 
    else {
      Disp_PutStr("Grate  On");
    }
    Disp_RC(2,0);
    Disp_PutStr("                    ");
    switch (cur_item) {
    case 1: // Grate Min Interval
      vmin = max(0,grate_on_interval);
      vmax = grate_max_interval;
      if (key == 2) {

        grate_min_interval += 3;
        grate_min_interval = constrain(grate_min_interval,vmin,vmax);
        CalculateGrate();
        WriteGrate();
      }
      if (key == 3) {
        grate_min_interval -= 3;
        grate_min_interval = constrain(grate_min_interval,vmin,vmax);
        CalculateGrate();
        WriteGrate();
      }
      Disp_RC(3,0);
      Disp_PutStr("NEXT  ADV   +    -  ");
      Disp_RC(0,0);
      Disp_CursOn();
      break;
    case 2: //Grate Interval
      vmin = max(grate_on_interval,grate_min_interval);
      vmax = 255*3;
      if (key == 2) {
        grate_max_interval += 3;
        grate_max_interval = constrain(grate_max_interval,vmin,vmax);
        CalculateGrate();
        WriteGrate();
      }
      if (key == 3) {
        grate_max_interval -= 3;
        grate_max_interval = constrain(grate_max_interval,vmin,vmax);
        CalculateGrate();
        WriteGrate();
      }
      Disp_RC(3,0);
      Disp_PutStr("NEXT  ADV   +    -  ");
      Disp_RC(0,11);
      Disp_CursOn();
      break;
    case 3: //Grate On Interval
      vmin = 0;
      vmax = min(grate_min_interval,255);
      if (key == 2) {
        grate_on_interval += 1;
        grate_on_interval = constrain(grate_on_interval,vmin,vmax);
        CalculateGrate();
        WriteGrate();
      }
      if (key == 3) {
        grate_on_interval -= 1;
        grate_on_interval = constrain(grate_on_interval,vmin,vmax);
        CalculateGrate();
        WriteGrate();
      }
      Disp_RC(3,0);
      Disp_PutStr("NEXT  ADV   +    -  ");
      Disp_RC(1,0);
      Disp_CursOn();
      break;
    case 4: //Grate
      if (key == 2) {
        grate_motor_state = GRATE_MOTOR_OFF;
      }
      if (key == 3) {
      grate_val = GRATE_SHAKE_CROSS;
      }
      Disp_RC(3,0);
      Disp_PutStr("NEXT  ADV  OFF   ON ");
      Disp_RC(1,11);
      Disp_CursOn();
      break; 
    }
    break;
  case DISPLAY_SERVO:   //need to add constraints for min and max?
    item_count = 2;
    Disp_RC(0,0);
    sprintf(buf, "ServoMin%3i", int(premix_valve_closed));
    Disp_PutStr(buf);
    Disp_RC(0,11);
    sprintf(buf, " Max %3i", int(premix_valve_open));
    Disp_PutStr(buf);
    //Row 1
    Disp_RC(1,0);
    Disp_PutStr(" Careful of Sides!  "); 
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
      Disp_PutStr("NEXT  ADV   +    -  ");
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
      Disp_PutStr("NEXT  ADV   +    -  ");
      Disp_RC(0,11);
      Disp_CursOn();
      break;
    }
    break;
    case DISPLAY_CALIBRATE_PRESSURE:
      item_count = 1;
      Disp_RC(0,0);
      Disp_PutStr("Calibrate Pressure  ");
      Disp_RC(1,0);
      Disp_PutStr("Sensors to zero?    ");
      Disp_RC(2,0);
      Disp_PutStr("                    ");
      Disp_RC(3,0);
      Disp_PutStr("NEXT       YES      ");
      if (key == 2) {
        CalibratePressureSensors();
        LoadPressureSensorCalibration();
        Disp_RC(2,0);
        Disp_PutStr("   CALIBRATED!      ");
      }
      case DISPLAY_RELAY:
      item_count = 1;
      int relays = 7;
      Disp_RC(0,0);
      sprintf(buf, "Test Relay: %1i", relay_num);
      Disp_PutStr(buf);
      Disp_RC(1,0);
      Disp_PutStr("                    ");
      Disp_RC(2,0);
      Disp_PutStr("                    ");
      Disp_RC(3,0);
      Disp_PutStr("NEXT  ADV   ON   OFF");
      if (key == 1) {
        relayOff(relay_num);
        if (relay_num <= relays) {
           relay_num += 1;
        } else { 
          relay_num = 0;
        }
      }
      if (key == 2) {
        relayOn(relay_num);
        Disp_RC(1,0);
        Disp_PutStr("         ON         ");
      }
      if (key == 2) {
        relayOff(relay_num);
        Disp_RC(1,0);
        Disp_PutStr("         OFF        ");
      }

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
    break;
  case DISPLAY_ENGINE:
    break;
  case DISPLAY_LAMBDA:
    cur_item = 1;
    break;
  case DISPLAY_GRATE:
    cur_item = 1;
    break;
  case DISPLAY_TESTING:
    cur_item = 1;
    break;
  case DISPLAY_SERVO:
    cur_item = 1;
    break;
  case DISPLAY_CALIBRATE_PRESSURE:
    cur_item = 1;
    break;
  case DISPLAY_RELAY:
    cur_item = 1;
    relay_num = 0;
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
      if (engine_state == ENGINE_OFF) {
        TransitionDisplay(DISPLAY_TESTING);
      } 
      else {
        TransitionDisplay(DISPLAY_REACTOR);
      }
      break;
    case DISPLAY_TESTING:
      if (engine_state == ENGINE_OFF){
        TransitionDisplay(DISPLAY_SERVO);
      } else {
      TransitionDisplay(DISPLAY_REACTOR);
      TransitionTesting(TESTING_OFF);
      }
      break;
    case DISPLAY_SERVO:
      WriteServo();
      TransitionDisplay(DISPLAY_CALIBRATE_PRESSURE);  //assume that engine state is off because we are already in DISPLAY_SERVO
      break;
    case DISPLAY_CALIBRATE_PRESSURE:                 //assume that engine state is off
      TransitionDisplay(DISPLAY_RELAY);
      break;
    case DISPLAY_RELAY:
      TransitionDisplay(DISPLAY_REACTOR);
      break;
    }
    key = -1; //key caught
  }
  if (key == 1) {
    cur_item++;
    if (cur_item>item_count) {
      cur_item = 1;
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

void TransitionMessage(String t_message) {
  transition_message = t_message;
  transition_entered = millis();
}


