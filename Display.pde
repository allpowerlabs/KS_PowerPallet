struct alarm * alarm_shown;  // Pointer to currently displayed alarm

void DoDisplay() {
  char config_buffer[] = "               ";
  char config_choice_buffer[] = "        ";

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
	if (alarm_shown) {
		TransitionDisplay(DISPLAY_ALARM);
		return;
	}
	item_count = 0;
    Disp_CursOff();

	//Row 0
	Disp_RC(0, 0);
	sprintf(buf, "Trst %4i  ", Temp_Data[T_TRED]);
	Disp_PutStr(buf);
	Disp_RC(0, 11);
	sprintf(buf, "Pcomb%4i", Press[P_COMB] / 25);
	Disp_PutStr(buf);

	//Row 1
	Disp_RC(1, 0);
	sprintf(buf, "Tred %4i  ", Temp_Data[T_BRED]);
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
	if (engine_state == ENGINE_SHUTDOWN) {
		Disp_RC(3,0);
		Disp_PutStr("      SHUTDOWN      ");
	} else {
		Disp_RC(3,0);
		if ((getAlarmCount() > 0) && (millis() % 1000 > 500)) {
			sprintf(buf, "NEXT ALARM");
		} else {
			sprintf(buf, "NEXT      ");
		}
		Disp_PutStr(buf);
		Disp_RC(3,10);
		sprintf(buf, " T: %6lu", millis() / 1000);
		Disp_PutStr(buf);
	}
    break;
  case DISPLAY_LAMBDA:
     Disp_CursOff();
    item_count = 3;  // was 4, but moved Lambda display out of the edit path
    // Row 0
    Disp_RC(0,0);
	sprintf(buf, "Lambda   ");
    Disp_PutStr(buf);
	Disp_PutStr(dtostrf(lambda_input, 6, 3, buf));
	// Row 1
    Disp_RC(1,0);
    sprintf(buf, "Setpoint ", lambda_setpoint);
    Disp_PutStr(buf);
	Disp_PutStr(dtostrf(lambda_setpoint, 6, 3, buf));
    // Row 2
    Disp_RC(2,0);
	sprintf(buf, "P  "); Disp_PutStr(buf);
	Disp_PutStr(dtostrf(lambda_P[0], 6, 2, buf));
	sprintf(buf, " I  "); Disp_PutStr(buf);
	Disp_PutStr(dtostrf(lambda_I[0], 6, 2, buf));
	// Row 3
	Disp_RC(3,0);
    strcpy_P(buf, menu1);
    Disp_PutStr(buf);
    switch (cur_item) {
    case 1: // Lambda setpoint
      if (key == 2) {
        lambda_setpoint += LAMBDA_SETPOINT_ADJUSTMENT;
        WriteLambda();
      }
      if (key == 3) {
        lambda_setpoint -= LAMBDA_SETPOINT_ADJUSTMENT;
        WriteLambda();
      }
      Disp_RC(1,0);
      Disp_CursOn();
      break;
    case 2: //Lambda P
      if (key == 2) {
        lambda_P[0] += 0.01;
		lambda_PID.SetTunings(lambda_P[0], lambda_I[0], 0);
        WriteLambda();
      }
      if (key == 3) {
        lambda_P[0] -= 0.01;
		lambda_PID.SetTunings(lambda_P[0], lambda_I[0], 0);
        WriteLambda();
      }
      Disp_RC(2,0);
      Disp_CursOn();
      break;
    case 3: //Lambda I
      if (key == 2) {
        lambda_I[0] += 0.1;
		lambda_PID.SetTunings(lambda_P[0], lambda_I[0], 0);
        WriteLambda();
      }
      if (key == 3) {
        lambda_I[0] -= 0.1;
		lambda_PID.SetTunings(lambda_P[0], lambda_I[0], 0);
        WriteLambda();
      }
      Disp_RC(2,10);
      Disp_CursOn();
      break;
    }
    break;
  case DISPLAY_GRATE:
	displayManualMode();
    break;
  case DISPLAY_INFO:
    Disp_CursOff();
    Disp_RC(0,0);
    sprintf(buf, "%-10s     %5s", serial_num, unique_number);
    Disp_PutStr(buf);
    Disp_RC(1,(20-strlen(CODE_VERSION))/2);
    sprintf(buf, "%s", CODE_VERSION);
    Disp_PutStr(buf);
    Disp_RC(2,0);
    sprintf(buf, "    %12s   ", sd_data_file_name);
    Disp_PutStr(buf);
    Disp_RC(3,0);
	sprintf_P(buf, PSTR("NEXT       T: %6lu"), millis()/1000);
	Disp_PutStr(buf);
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
      config_var = Config[cur_item].max;
    }
    Disp_RC(0,0);
    Disp_PutStr(P("   Configurations   "));
    Disp_RC(1,0);
    strcpy_P(config_buffer, Config[cur_item].label);
    strcpy_P(config_choice_buffer, Config[cur_item].choices);
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
        if (Config[cur_item].max >= config_var + 1){
          config_var += 1;
          config_changed = true;
        }
      }
      if (key == 3) {
        if (Config[cur_item].min <= config_var - 1){
          config_var -= 1;
          config_changed = true;
        }
      }
    }
    else if (strcmp(config_choice_buffer, "+5  -5  ") == 0){
      if (key == 2) {
        if (Config[cur_item].max >= config_var + 1){
          config_var += 1;
          config_changed = true;
        }
      }
      if (key == 3) {
        if (Config[cur_item].min <= config_var - 1){
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

	case DISPLAY_ALARM:
		if (!alarm_shown) {
			TransitionDisplay(DISPLAY_REACTOR);
			return;
		}
		item_count = 0;
		Disp_CursOff();

		//Row 0
		Disp_RC(0, 0);
		if (alarm_shown->shutdown > 0){
			sprintf(buf, "SHUTDOWN ALARM      "); //%2i/%2i", cur_item, getAlarmCount());
		}
		else {
			sprintf(buf, "      ALARM         "); //%2i/%2i ", cur_item, getAlarmCount());
		}
		Disp_PutStr(buf);

		//Row 1
		Disp_RC(1, 0);
		strcpy_P(p_buffer, alarm_shown->message);
		Disp_PutStr(p_buffer);

		//Row 2
		Disp_RC(2, 0);
		if (alarm_shown->message2) {
			strcpy_P(p_buffer, alarm_shown->message2);
		} else {
			strcpy_P(p_buffer, blank);
		}
		Disp_PutStr(p_buffer);
		if (alarm_shown->shutdown > 999 && engine_state == ENGINE_ON){     //anything less than 999 is a count and not a shutdown time in millisecond so don't show.
			Disp_RC(2, 13);
			sprintf(buf, "OFF:%3i", (millis() - alarm_shown->on - alarm_shown->shutdown - alarm_shown->delay)/1000);
			Disp_PutStr(buf);
		}

		//Row 3
		Disp_RC(3, 0);
		Disp_PutStr(P("EXIT"));

		if (getAlarmCount() > 1) { Disp_PutStr(P(" ADV  ")); }
		else { Disp_PutStr(P("      ")); }

		Disp_RC(3, 9);
		if (annoying) { Disp_PutStr(P("QUIET ")); }
		else {Disp_PutStr(P("      "));}

		Disp_RC(3, 15);
		//Wait to show RESET button in case new alarm state has taken over screen.
		if (millis() - alarm_shown->on > 4000){
			Disp_PutStr(P("RESET"));
		}
		else {
			Disp_PutStr(P("     "));
		}

		// Special key handling for alarm display
		if (key == 2) {
			silenceAllAlarms();
		}
		//wait until RESET button shows up
		if (key == 3 && (millis() - alarm_shown->on > 4000)) {
			resetAlarm(alarm_shown);
			alarm_shown = getNextAlarm(alarm_shown); //start at beginning of alarm queue
		}
		break;
  }
  key = -1; //important, must clear key to read new input
}

void TransitionDisplay(int new_state) {
	//Enter
	display_state_entered = millis();
	config_changed = false;
	cur_item = 0;
	switch (new_state) {
	case DISPLAY_LAMBDA:
	case DISPLAY_SERVO:
	case DISPLAY_CALIBRATE_PRESSURE:
		cur_item = 1;
		break;
	case DISPLAY_RELAY:
		turnAllOff();
		TransitionAuger(AUGER_ALARM);  //stop the auger control
		break;
	default:
		break;
	}
	display_state=new_state;
	Disp_Clear(); // Clear display between menus
}

void DoKeyInput() {
  if (key == -1) { //only update key if it has been cleared
    key = Kpd_GetKeyAsync();
  }
  if (key == 0) {
    switch (display_state) {
    case DISPLAY_SPLASH:
      TransitionDisplay(DISPLAY_REACTOR);
      break;
    case DISPLAY_REACTOR:
	  if (cur_item < 1)
		TransitionDisplay(DISPLAY_GRATE);
      break;
    case DISPLAY_LAMBDA:
      TransitionDisplay(DISPLAY_INFO);
      break;
    case DISPLAY_GRATE:
	  if(GrateGetMode() == MANUAL) {  // Grate shaker got left on
		GrateSwitchMode(AUTOMATIC);  // Turn it off
	  }
      if (config_changed == true){
        TransitionDisplay(DISPLAY_REACTOR);
      } else {
        TransitionDisplay(DISPLAY_LAMBDA);
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
    case DISPLAY_RELAY:
      turnAllOff();
	  TransitionAuger(AUGER_OFF);
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
      TransitionDisplay(DISPLAY_CONFIG);
      TransitionTesting(TESTING_OFF);
      break;
    case DISPLAY_CONFIG:
      TransitionDisplay(DISPLAY_REACTOR);
      break;
	case DISPLAY_ALARM:
		alarm_shown = 0;
		TransitionDisplay(DISPLAY_REACTOR);
    }
    key = -1; //key caught
  }
  if (key == 1) {
	cur_item++;
	switch (display_state) {
	case DISPLAY_GRATE:
		return;  // Key handling happens in DisplayManualMode()
	case DISPLAY_CONFIG:
		if (config_changed) {
			saveConfig(cur_item, config_var);
			update_config_var(cur_item);
			config_changed = false;
		}
		while (Config[cur_item].choices == reserved) {
			cur_item ++;  // Skip over any reserved configs
		}
		break;
	case DISPLAY_RELAY:
		config_changed = false;
		turnAllOff();
		break;
	case DISPLAY_REACTOR:
	case DISPLAY_ALARM:
		alarm_shown = getNextAlarm(alarm_shown);
		break;
	}

    if (cur_item > item_count) {
      switch (display_state) {
		case DISPLAY_REACTOR:
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
      value = Config[item].def;
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
  case 7:
    save_datalog_to_sd = getConfig(7);
    regs[MB_CONFIG7] = save_datalog_to_sd;
    break;
  case 9:
    high_coolant_temp = getConfig(9);
    regs[MB_CONFIG9] = high_coolant_temp;
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
  case 15:
    regs[MB_CONFIG15] = getConfig(15)*5;
    GrateConfig();
    break;
  case 16:
    regs[MB_CONFIG16] = getConfig(16)*5;
    GrateConfig();
    break;
  case 17:
    regs[MB_CONFIG17] = getConfig(17);
    GrateConfig();
    break;
  case 18:
    servo_start = getConfig(18);
    regs[MB_CONFIG18] = servo_start;
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
  case 28:
    AshAugerReset();
	break;
  case 29:
    AshAugerReset();
	break;
  case 30:
	AshAugerReset();
	break;
  case 31:
	AshAugerReset();
	break;
  case 32:
	GrateConfig();
	break;
  case 33:
	GrateConfig();
	break;
  case 34:
	fuel_switch_hysteresis = getConfig(34) * 1000;
	break;
  default:
	break;
  }
}

void resetConfig() {  //sets EEPROM configs back to untouched state
  unsigned i;
  while (!(Config[i].label == 0 && Config[i].choices == 0))
	{
		saveConfig(i, Config[i].def);
		i++;
	}
}

void displayManualMode() {
	static int currentFunction;
	int modeAdv = 0; // Flag to know when we should advance to the next mode.  Initialization is key.
	// Key press handling
	switch (key) {
		case 1:		// ADV
			// Advance the current function
			currentFunction++;
			config_changed = true; // This is supposed to let the rest of the display code know to jump back to the status screen after the user is done.
			Disp_Clear();  // Clear display when changing functions
			break;
		case 2:		// Nothing
			break;
		case 3:		// MODE
			// Advance to the next mode
			modeAdv++;
			config_changed = true;
			break;
		default:
			break;
	}
	key = -1;
	//Disp_Clear();
	Disp_CursOff();
	Disp_RC(0,0);
	Disp_PutStr(P("   Manual Control   "));
	Disp_RC(1,0);
	switch (currentFunction) {
		case 0:
			Disp_PutStr(P("Fuel Auger: "));
			switch (auger_state) {
				case AUGER_ALARM:
					Disp_PutStr(P("OFF "));
					if (modeAdv) TransitionAuger(AUGER_OFF);
					break;
				default:
					Disp_PutStr(P("AUTO"));
					if (modeAdv) TransitionAuger(AUGER_ALARM);  // Alarm state is used to suppress the auger, but no alarm is raised
					break;
			}
			Disp_RC(2,0);
			Disp_PutStr(P("F: "));
			if (FuelDemand == SWITCH_ON) Disp_PutStr(P("1"));
			else Disp_PutStr(P("0"));
			Disp_PutStr(P(" M: "));
			switch (auger_state) {
				case AUGER_OFF:
				case AUGER_ALARM:
					Disp_PutStr(P("OFF"));
					break;
				case AUGER_STARTING:
				case AUGER_FORWARD:
				case AUGER_MANUAL_FORWARD:
					Disp_PutStr(P("FWD"));
					break;
				case AUGER_CURRENT_LOW:
					Disp_PutStr(P("LOW"));
					break;
				case AUGER_HIGH:
				case AUGER_REVERSE_HIGH:
					Disp_PutStr(P("HI "));
					break;
				case AUGER_REVERSE:
					Disp_PutStr(P("REV"));
					break;
				case AUGER_PULSE:
					Disp_PutStr(P("PUL"));
					break;
				default:
					Disp_PutStr(P("???"));
					break;
			}
			sprintf(buf, " I: %02u.%.1u", AugerCurrentValue / 10, AugerCurrentValue % 10);
			Disp_PutStr(buf);
			break;
		case 1:
			Disp_PutStr(P("Grate Shaker: "));
			switch (GrateGetMode()) {
				case DISABLED:
					Disp_PutStr(P("OFF "));
					if (modeAdv) {
						GrateSwitchMode(MANUAL);
					}
					break;
				case MANUAL:
					Disp_PutStr(P("ON  "));
					if (modeAdv) {
						GrateSwitchMode(AUTOMATIC);
					}
					break;
				case AUTOMATIC:
					Disp_PutStr(P("AUTO"));
					if (modeAdv) {
						GrateSwitchMode(DISABLED);
					}
					break;
				default:
					break;
			}
			break;
		case 2:
			Disp_PutStr(P("Ash Auger: "));
			switch (AshAugerGetMode()) {
				case AUTOMATIC:
					Disp_PutStr(P("AUTO"));
					if (modeAdv) AshAugerSwitchMode(MANUAL);
					break;
				case MANUAL:
					Disp_PutStr(P("ON  "));
					if (modeAdv) AshAugerSwitchMode(DISABLED);
					break;
				case DISABLED:
					Disp_PutStr(P("OFF "));
					if (modeAdv) AshAugerSwitchMode(AUTOMATIC);
					break;
				default:
					break;
			}
			break;
		default:
			// If we run out of functions, go back to the beginning
			currentFunction = 0;
			break;
	}
	//Disp_PutStr(P("          "));  // This is a hack to clear the rest of the line
	Disp_RC(3,0);
	Disp_PutStr(P("NEXT"));
	Disp_RC(3,6);
	Disp_PutStr(P("ADV"));
	Disp_RC(3,16);
	Disp_PutStr(P("MODE"));
}
