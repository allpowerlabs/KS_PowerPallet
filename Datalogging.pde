// Datalogging
void LogTime(boolean header = false) {
  if (header) {
    PrintColumn("Time");
  } else {
   PrintColumn(millis()/100.0); 
  }
}

void LogFlows(boolean header = false) {
  if (flow_active) {
    if (header) {
      if (P_Q_AIR_ENG != ABSENT) { PrintColumn("Q_air_eng"); }
      if (P_Q_AIR_RCT != ABSENT) { PrintColumn("Q_air_rct"); }
      if (P_Q_GAS_ENG != ABSENT) { PrintColumn("Q_gas_eng"); }
    } else {
      if (P_Q_AIR_ENG != ABSENT) {
        PrintColumn(air_eng_flow);
      }
      if (P_Q_AIR_RCT != ABSENT) {
        PrintColumn(air_rct_flow);
      }
      if (P_Q_GAS_ENG != ABSENT) {
        PrintColumn(gas_eng_flow);
      }
    }
  }
}

void LogPID(boolean header = false) {
  if (header) {
    PrintColumn("Lambda_In");
    PrintColumn("Lambda_Out");
    PrintColumn("Lambda_Setpoint");
    PrintColumn("Lambda_P");
    PrintColumn("Lambda_I");
    PrintColumn("Lambda_D");
  } else {
    PrintColumn(lambda_input);
    PrintColumn(lambda_output);
    PrintColumn(lambda_setpoint);
    PrintColumn(lambda_PID.GetP_Param());
    PrintColumn(lambda_PID.GetI_Param());
    PrintColumn(lambda_PID.GetD_Param());
  }
}

void LogAnalogInputs(boolean header = false) {
  if (header) {
    PrintColumn("ANA0");
    PrintColumn("ANA1");
    PrintColumn("ANA2");
    PrintColumn("ANA3");
    PrintColumn("ANA4");
    PrintColumn("ANA5");
    PrintColumn("ANA6");
    PrintColumn("ANA7");
  } else {
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
    PrintColumn("Grate");
    PrintColumn("P_ratio_reactor");
    PrintColumn("P_ratio_state_reactor");
    PrintColumn("Grate_Val");
  } else {
    //PrintColumnInt(grateMode);
    PrintColumnInt(grate_motor_state);
    PrintColumn(pRatioReactor);
    PrintColumn(pRatioReactorLevel[pRatioReactorLevelName]);
    PrintColumn(grate_val);
  }
}

void LogFilter(boolean header = false) {
   if (header) {
    PrintColumn("P_ratio_filter");
    PrintColumn("P_ratio_filter_state");
  } else {
    PrintColumn(pRatioFilter);
    //TODO: Move to enum
    if (pRatioFilterHigh) {
      PrintColumn("Bad");
    } else {
      PrintColumn("Good");
    }
  }
}

void LogPressures(boolean header = false) {
  if (header) {
    //TODO: Handle half/full fill
    #if P_REACTOR != ABSENT
      PrintColumn("P_reactor");
    #endif
    #if P_FILTER != ABSENT
      PrintColumn("P_filter");
    #endif
    #if P_COMB != ABSENT
      PrintColumn("P_comb");
    #endif
    #if P_Q_AIR_ENG != ABSENT
      PrintColumn("P_Q_air_eng");
    #endif
    #if P_Q_AIR_RCT != ABSENT
      PrintColumn("P_Q_air_rct");
    #endif
    #if P_Q_GAS_ENG != ABSENT
      PrintColumn("P_Q_gas_eng");
    #endif
  } else {
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
        PrintColumn("T_tred");
      #endif
      #if T_BRED != ABSENT
        PrintColumn("T_bred");
      #endif
      #if T_PYRO_IN != ABSENT
        PrintColumn("T_pyro_in");
      #endif
      #if T_PYRO_OUT != ABSENT
        PrintColumn("T_pyro_out");
      #endif
      #if T_ENG_COOLANT != ABSENT
        PrintColumn("T_eng_coolant");
      #endif 
      #if T_DRYING_GAS_OUT != ABSENT
        PrintColumn("T_drying_gas_out");
      #endif
      #if T_REACTOR_GAS_OUT != ABSENT
        PrintColumn("T_reactor_gas_out");
      #endif
      #if T_FILTER != ABSENT
        PrintColumn("T_filter");
      #endif
  } else {
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
      PrintColumn("AugerCurrent");
      PrintColumn("AugerLevel");
     }
    #if ANA_FUEL_SWITCH != ABSENT
      PrintColumn("FuelSwitchLevel");
    #endif
  } else {
     if (relay_board){ 
      PrintColumnInt(AugerCurrentValue);
      PrintColumn(AugerCurrentLevel[AugerCurrentLevelName]);
     }
    #if ANA_FUEL_SWITCH != ABSENT
      PrintColumn(FuelSwitchLevel[FuelSwitchLevelName]);
    #endif
  }
}
 
void LogPulseEnergy(boolean header = false) {
  if (header) {
    PrintColumn("Power");
    PrintColumn("Energy");
  } else {
    PrintColumnInt(CalculatePulsePower());
    PrintColumnInt(CalculatePulseEnergy());
  }
}

void LogHertz(boolean header = false) {
  if (header) {
    PrintColumn("Hz");
  } else {
    PrintColumnInt(CalculatePeriodHertz());
  }
}

void LogCounterHertz(boolean header = false) {
  if (header) {
    PrintColumn("Blower PWM");
  } else {
    PrintColumnInt(counter_hertz);
  }
}


void LogEngine(boolean header=false) {
  if (header) {
    PrintColumn("Engine");
  } else {
    if (engine_state == ENGINE_OFF) {
      PrintColumn("Off");
    }
    if (engine_state == ENGINE_ON) {
      PrintColumn("On");
    }
    if (engine_state == ENGINE_STARTING) {
      PrintColumn("Starting");
    }
  }
}

void LogBatteryVoltage(boolean header=false) {
    if (header) {
      PrintColumn("battery_voltage");
    } else {
      PrintColumn(battery_voltage);
    }
}
void LogOilPressure(boolean header=false){
  if (header){
    PrintColumn("OilPressureLevel");
    if (engine_type == 1){ //20k
      PrintColumn("OilPressurePSI");
    } else {
      PrintColumn("OilPressureValue");
    }
  } else {
      PrintColumn(EngineOilPressureLevel[EngineOilPressureName]);
      PrintColumn(EngineOilPressureValue);
    }
}
void LogReactor(boolean header=false) {
    if (header) {
      PrintColumn("P_reactorLevel");
      PrintColumn("T_tredLevel");
      PrintColumn("T_bredLevel");
    } else {
      PrintColumn(P_reactorLevel[P_reactorLevelName]);
      PrintColumn(T_tredLevel[TempLevelName]);
      PrintColumn(T_bredLevel[TempLevelName]);
    }
}

void DoTests() { //space to log testing of variables.  Normally not logged
  Serial.print("#");
//  Serial.print("current: ");
//  Serial.print(AugerCurrentValue);
//  Serial.print(" Auger Current Level: ");
//  Serial.print(AugerCurrentLevel[AugerCurrentLevelName]);
//  Serial.print(" current_low_boundary: "); 
//  Serial.println(current_low_boundary); 
//  Serial.print(" current_high_boundary: ");
//  Serial.println(current_high_boundary);
  
}

void PrintColumn(String str) {
  data_buffer += str;
  data_buffer += ", ";
//  Serial.print(str);
//  Serial.print(", ");  
}

void PrintColumn(float str) {
  dtostrf(str, 5, 3, float_buf);
  data_buffer += float_buf;
  data_buffer += ", ";
//  Serial.print(str);
//  Serial.print(", ");  
}

void PrintColumnInt(int str) {
  data_buffer += str;
  data_buffer += ", ";
//  Serial.print(str);
//  Serial.print(", ");
}

void DoDatalogging() {
  data_buffer = "";
  boolean header = false;
  //Serial.begin(57600); //reset serial?
  Serial.begin(115200);
  if (lineCount == 0) {
    header = true;
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
  //LogFlows(header);
  //LogHertz(header);
  //LogCounterHertz(header);
  //LogGovernor(header);
  //LogPulseEnergy(header);
  //LogBatteryVoltage(header);
  Serial.println(data_buffer);
//  if (save_to_sd = 0) {
//    DoDatalogSD(data_buffer);
//  }
//  DoTests();
  lineCount++;
}


