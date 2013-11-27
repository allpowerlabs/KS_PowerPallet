// Datalogging
void LogTime(boolean header = false) {
  if (header) {
    PrintColumn(P("Time"));
  } 
  else {
    PrintColumn(millis()/100.0); 
  }
}

//void LogFlows(boolean header = false) {
//  if (flow_active) {
//    if (header) {
//      if (P_Q_AIR_ENG != ABSENT) { PrintColumn("Q_air_eng"); }
//      if (P_Q_AIR_RCT != ABSENT) { PrintColumn("Q_air_rct"); }
//      if (P_Q_GAS_ENG != ABSENT) { PrintColumn("Q_gas_eng"); }
//    } else {
//      if (P_Q_AIR_ENG != ABSENT) {
//        PrintColumn(air_eng_flow);
//      }
//      if (P_Q_AIR_RCT != ABSENT) {
//        PrintColumn(air_rct_flow);
//      }
//      if (P_Q_GAS_ENG != ABSENT) {
//        PrintColumn(gas_eng_flow);
//      }
//    }
//  }
//}

void LogPID(boolean header = false) {
  if (header) {
    PrintColumn(P("Lambda_In"));
    PrintColumn(P("Lambda_Out"));
    PrintColumn(P("Lambda_Setpoint"));
    PrintColumn(P("Lambda_P"));
    PrintColumn(P("Lambda_I"));
    PrintColumn(P("Lambda_D"));
    PrintColumn(P("Servo_Pos"));
    PrintColumn(P("Throt_Pos"));
  } 
  else {
    PrintColumn(lambda_input);
    PrintColumn(lambda_output);
    PrintColumn(lambda_setpoint);
    PrintColumn(lambda_PID.GetP_Param());
    PrintColumn(lambda_PID.GetI_Param());
    PrintColumn(lambda_PID.GetD_Param());
    PrintColumn(Servo_Mixture.read());
    PrintColumn(map(analogRead(ANA_THROTTLE_POS), 153, 870, 0, 100));  //0.75V-4.25V range on TPS output of Woodward Governor
  }
}

void LogAnalogInputs(boolean header = false) {
  if (header) {
    PrintColumn(P("ANA0"));
    PrintColumn(P("ANA1"));
    PrintColumn(P("ANA2"));
    PrintColumn(P("ANA3"));
    PrintColumn(P("ANA4"));
    PrintColumn(P("ANA5"));
    PrintColumn(P("ANA6"));
    PrintColumn(P("ANA7"));
  } 
  else {
    PrintColumnInt(analogRead(ANA0));
    PrintColumnInt(analogRead(ANA1));
    PrintColumnInt(analogRead(ANA2));
    PrintColumnInt(analogRead(ANA3));
    PrintColumnInt(analogRead(ANA4));
    PrintColumnInt(analogRead(ANA5));
    PrintColumnInt(analogRead(ANA6));
    PrintColumnInt(analogRead(ANA7));
  }
}

void LogGrate(boolean header = false) {
  if (header) {
    //PrintColumn("grateMode");
    PrintColumn(P("Grate"));
    PrintColumn(P("P_ratio_reactor"));
    PrintColumn(P("P_ratio_state_reactor"));
    PrintColumn(P("Grate_Val"));
  } 
  else {
    //PrintColumnInt(grateMode);
    PrintColumnInt(grate_motor_state);
    PrintColumn(pRatioReactor);
    PrintColumn(pRatioReactorLevel[pRatioReactorLevelName]);
    PrintColumn(grate_val);
  }
}

void LogFilter(boolean header = false) {
  if (header) {
    PrintColumn(P("P_ratio_filter"));
    PrintColumn(P("P_ratio_filter_state"));
  } 
  else {
    PrintColumn(pRatioFilter);
    //TODO: Move to enum
    if (pRatioFilterHigh) {
      PrintColumn(P("Bad"));
    } 
    else {
      PrintColumn(P("Good"));
    }
  }
}

void LogPressures(boolean header = false) {
  if (header) {
    //TODO: Handle half/full fill
#if P_REACTOR != ABSENT
    PrintColumn(P("P_reactor"));
#endif
#if P_FILTER != ABSENT
    PrintColumn(P("P_filter"));
#endif
#if P_COMB != ABSENT
    PrintColumn(P("P_comb"));
#endif
#if P_Q_AIR_ENG != ABSENT
    PrintColumn(P("P_Q_air_eng"));
#endif
#if P_Q_AIR_RCT != ABSENT
    PrintColumn(P("P_Q_air_rct"));
#endif
#if P_Q_GAS_ENG != ABSENT
    PrintColumn(P("P_Q_gas_eng"));
#endif
  } 
  else {
#if P_REACTOR != ABSENT
    PrintColumnInt(Press[P_REACTOR]);
#endif
#if P_FILTER != ABSENT
    PrintColumnInt(Press[P_FILTER]);
#endif
#if P_COMB != ABSENT
    PrintColumnInt(Press[P_COMB]);
#endif
#if P_Q_AIR_ENG != ABSENT
    PrintColumnInt(Press[P_Q_AIR_ENG]);
#endif
#if P_Q_AIR_RCT != ABSENT
    PrintColumnInt(Press[P_Q_AIR_RCT]);
#endif
#if P_Q_GAS_ENG != ABSENT
    PrintColumnInt(Press[P_Q_GAS_ENG]);
#endif
  }
}

void LogTemps(boolean header = false) {
  if (header) {
#if T_TRED != ABSENT
    PrintColumn(P("T_tred"));
#endif
#if T_BRED != ABSENT
    PrintColumn(P("T_bred"));
#endif
#if T_PYRO_IN != ABSENT
    PrintColumn(P("T_pyro_in"));
#endif
#if T_PYRO_OUT != ABSENT
    PrintColumn(P("T_pyro_out"));
#endif
#if T_ENG_COOLANT != ABSENT
    PrintColumn(P("T_eng_coolant"));
#endif 
#if T_DRYING_GAS_OUT != ABSENT
    PrintColumn(P("T_drying_gas_out"));
#endif
#if T_REACTOR_GAS_OUT != ABSENT
    PrintColumn(P("T_reactor_gas_out"));
#endif
#if T_FILTER != ABSENT
    PrintColumn(P("T_filter"));
#endif
  } 
  else {
#if T_TRED != ABSENT
    PrintColumnInt(Temp_Data[T_TRED]);
#endif
#if T_BRED != ABSENT
    PrintColumnInt(Temp_Data[T_BRED]);
#endif
#if T_PYRO_IN != ABSENT
    PrintColumnInt(Temp_Data[T_PYRO_IN]);
#endif
#if T_PYRO_OUT != ABSENT
    PrintColumnInt(Temp_Data[T_PYRO_OUT]);
#endif
#if T_ENG_COOLANT != ABSENT
    PrintColumnInt(Temp_Data[T_ENG_COOLANT]);
#endif 
#if T_DRYING_GAS_OUT != ABSENT
    PrintColumnInt(Temp_Data[T_DRYING_GAS_OUT]);
#endif
#if T_REACTOR_GAS_OUT != ABSENT
    PrintColumnInt(Temp_Data[T_REACTOR_GAS_OUT]);
#endif
#if T_FILTER != ABSENT
    PrintColumnInt(Temp_Data[T_FILTER]);
#endif
  }
} 

void LogAuger(boolean header = false) {
  if (header) {
    if (relay_board){ 
      PrintColumn(P("AugerCurrent"));
      PrintColumn(P("AugerLevel"));
    }
#if ANA_FUEL_SWITCH != ABSENT
    PrintColumn(P("FuelSwitchLevel"));
#endif
  } 
  else {
    if (relay_board){ 
      PrintColumnInt(AugerCurrentValue);
      PrintColumn(AugerCurrentLevel[AugerCurrentLevelName]);
    }
#if ANA_FUEL_SWITCH != ABSENT
    PrintColumn(FuelSwitchLevel[FuelSwitchLevelName]);
#endif
  }
}

//void LogPulseEnergy(boolean header = false) {
//  if (header) {
//    PrintColumn("Power");
//    PrintColumn("Energy");
//  } else {
//    PrintColumnInt(CalculatePulsePower());
//    PrintColumnInt(CalculatePulseEnergy());
//  }
//}

//void LogHertz(boolean header = false) {
//  if (header) {
//    PrintColumn("Hz");
//  } else {
//    PrintColumnInt(CalculatePeriodHertz());
//  }
//}

//void LogCounterHertz(boolean header = false) {
//  if (header) {
//    PrintColumn("Blower PWM");
//  } else {
//    PrintColumnInt(counter_hertz);
//  }
//}

void LogEngine(boolean header=false) {
  if (header) {
    PrintColumn(P("Engine"));
  } 
  else {
    switch(engine_state){
    case ENGINE_OFF:
      PrintColumn(P("Off")); 
      break;
    case ENGINE_ON:
      PrintColumn(P("On"));
      break;
    case ENGINE_STARTING:
      PrintColumn(P("Starting"));
      break;
    case ENGINE_GOV_TUNING:
      PrintColumn(P("Govenor Tuning"));
      break;
    case ENGINE_SHUTDOWN:
      PrintColumn(P("Shutdown"));
      break;
    default:
      PrintColumnInt(engine_state);
      break;
    }
  }
}

//void LogBatteryVoltage(boolean header=false) {
//    if (header) {
//      PrintColumn("battery_voltage");
//    } else {
//      PrintColumn(battery_voltage);
//    }
//}

void LogOilPressure(boolean header=false){
  if (header){
    PrintColumn(P("OilPressureLevel"));
    if (engine_type == 1){ //20k
      PrintColumn(P("OilPressurePSI"));
    } 
    else {
      PrintColumn(P("OilPressureValue"));
    }
  } 
  else {
    PrintColumn(EngineOilPressureLevel[EngineOilPressureName]);
    PrintColumn(EngineOilPressureValue);
  }
}

void LogReactor(boolean header=false) {
  if (header) {
    PrintColumn(P("P_reactorLevel"));
    PrintColumn(P("T_tredLevel"));
    PrintColumn(P("T_bredLevel"));
  } 
  else {
    PrintColumn(P_reactorLevel[P_reactorLevelName]);
    PrintColumn(T_tredLevel[TempLevelName]);
    PrintColumn(T_bredLevel[TempLevelName]);
  }
}

//void DoTests() { //space to log testing of variables.  Normally not logged
//  Log_p("#");
//  //smooth(int data, int smoothed, int filterval)
//
//  Log_p("Smoothed Signal: ");
//  Serial.print(smoothed[getAnaArray(ANA_OIL_PRESSURE)]);
//  Log_p(" Smoothed PSI: ");
//  Logln(getPSI(smoothed[getAnaArray(ANA_OIL_PRESSURE)])); 
//}


void PrintColumn(const char * str) {
  if (buffer_size + strlen(str) + 2 < BUFFER_SIZE){
    strncat(string_buffer, str, BUFFER_SIZE);
    strncat(string_buffer, comma, BUFFER_SIZE); //add comma
    buffer_size = strlen(string_buffer);  //add on size of comma
  }  
  else {
    Serial.print(string_buffer);
    if (save_datalog_to_sd && sd_loaded){
      DatalogSD(sd_data_file_name, false);  //write to SD but don't put line ending
    }
    strcpy(string_buffer, str);
    strncat(string_buffer, comma, BUFFER_SIZE);
    buffer_size = strlen(string_buffer);
  }
}

void PrintColumn(float str) {
  dtostrf(str, 5, 3, float_buf);
  if (buffer_size + strlen(float_buf) + 2 < BUFFER_SIZE){
    strncat(string_buffer, float_buf, BUFFER_SIZE);
    strncat(string_buffer, comma, BUFFER_SIZE); //add comma
    buffer_size = strlen(string_buffer);
  }  
  else {
    Serial.print(string_buffer);
    if (save_datalog_to_sd && sd_loaded){
      DatalogSD(sd_data_file_name, false);  //write to SD but don't put line ending
    }
    strcpy(string_buffer, float_buf);
    strncat(string_buffer, comma, BUFFER_SIZE);
    buffer_size = strlen(string_buffer);
  }
}

void PrintColumnInt(int str) {
  sprintf(float_buf, "%d, ", str);
  if (buffer_size + strlen(float_buf) < BUFFER_SIZE){
    strncat(string_buffer, float_buf, BUFFER_SIZE);
    buffer_size = strlen(string_buffer);
  }  
  else {
    Serial.print(string_buffer);
    if (save_datalog_to_sd && sd_loaded){
      DatalogSD(sd_data_file_name, false);  //write to SD but don't put line ending
    }
    strcpy(string_buffer, float_buf);
    buffer_size = strlen(string_buffer);
  }
}

void DoDatalogging() {
  Serial.begin(115200); // Can glitch logging, but seems to be required due to MODBus code baud rate change(?) - investigate further.
  if (buffer_size > 0){
    Logln_p("..."); //for debugging purposes...remove if no longer needed
  }
  boolean header = false;
  if (lineCount == 0) {
    header = true;
    clearBuffer(); //guarantee no extra chars in buffer first time through
  }

  if(lineCount == 1 && serial_num[0] != '#'){
//    sprintf_P(string_buffer, P("#APL Serial:#%s PCU#%u Version:%s"), serial_num, unique_number, CODE_VERSION);// This line, with sprintf_P produces a bare "ent" in serial and log
    sprintf(string_buffer, "#APL Serial:%s\r\n#PCU UID:%5s\r\n#Version:%s", serial_num, unique_number, CODE_VERSION);//sprintf is trustworthy, worth eating a small amount of RAM
    Serial.println(string_buffer);
    if (save_datalog_to_sd && sd_loaded){
      DatalogSD(sd_data_file_name, true);
    }
    clearBuffer();
  }
  LogTime(header);
  LogTemps(header);
  LogPressures(header);
  LogAnalogInputs(header);
  LogGrate(header);
  LogFilter(header);
  LogPID(header);
  LogReactor(header);
  LogEngine(header);
  //LogEnergy(header);
  LogAuger(header);
  LogOilPressure(header);
  //LogFlows(header);
  //LogHertz(header);
  //LogCounterHertz(header);
  //LogGovernor(header);
  //LogPulseEnergy(header);
  //LogBatteryVoltage(header);
  Serial.println(string_buffer);
  if (save_datalog_to_sd && sd_loaded){
    DatalogSD(sd_data_file_name, true);
  }
  //  DoTests();
  clearBuffer();
  lineCount++;
}



