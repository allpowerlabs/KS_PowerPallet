void InitModbusSlave(){  //include in Setup() loop
    for (int i = 0; i < MB_REGS; ++i) { regs[i]=0; }  //preset all registers to zero
    
    regs[MB_CONFIG1] = engine_type;
    regs[MB_CONFIG2] = relay_board;
    regs[MB_CONFIG3] = aug_rev_time;
    regs[MB_CONFIG4] = current_low_boundary;
    regs[MB_CONFIG5] = current_high_boundary;
    regs[MB_CONFIG6] = low_oil_psi;
    regs[MB_CONFIG7] = save_datalog_to_sd;
    regs[MB_CONFIG8] = pratio_max;
    regs[MB_CONFIG9] = high_coolant_temp;
    regs[MB_CONFIG10] = display_per;
    regs[MB_CONFIG11] = tred_low_temp;
    regs[MB_CONFIG12] = ttred_high;
    regs[MB_CONFIG13] = tbred_high;
    regs[MB_CONFIG14] = pfilter_alarm;
    regs[MB_CONFIG15] = grate_max_interval;
    regs[MB_CONFIG16] = grate_min_interval;
    regs[MB_CONFIG17] = grate_on_interval;
    regs[MB_CONFIG18] = servo_start;
    regs[MB_CONFIG19] = lambda_rich;
    regs[MB_CONFIG20] = use_modbus;
    regs[MB_CONFIG21] = m_baud;
    regs[MB_CONFIG22] = m_parity;
    regs[MB_CONFIG23] = m_address;
    
    init_mb_slave(baud_rates[m_baud], parity[m_parity], 16);  //baud, parity, tx_en_pin
    Serial.print("# Modbus Baud Rate:"); Serial.print(baud_rates[m_baud]); Serial.print(" Parity: "); Serial.print(m_parity);
    Serial.print(" Address: "); Serial.print(m_address); Serial.print(" Number of Registers: "); Serial.println(MB_REGS);

}


void DoModbus() {
    start_mb_slave(m_address, regs, MB_REGS);
    
    if (written.num_regs) {
   // Log_p("Modbus recieved Register update:");Logln(written.num_regs);
   // Log_p("Lastwrite.start_addr"); Logln(written.start_addr);    
    
      for(int i = written.start_addr; i < (written.start_addr + written.num_regs); i++){
        Log_p("i = "); Log(i); Log_p(" "); Logln(regs[i]);
        switch (i) {
        case MB_ENGINE_STATE:
          TransitionEngine(regs[MB_ENGINE_STATE]);
          break;
        case MB_AUGER_STATE:
          TransitionAuger(regs[MB_AUGER_STATE]);
          break;
        case MB_GRATE_STATE:
          grateMode = regs[MB_GRATE_STATE];
          break;
        case MB_FLARE_STATE:
          flare_state = regs[MB_FLARE_STATE]; //???
          break;
        case  MB_BLOWER_STATE:  
          break;
        case MB_LAMBDA_OUT:
          lambda_output = regs[MB_LAMBDA_OUT]/100.0;
          break;
        case MB_LAMBDA_SETPOINT:
          lambda_setpoint = regs[MB_LAMBDA_SETPOINT]/1000.0;	
          break;
        case MB_LAMBDA_P:
        case MB_LAMBDA_I:
        case MB_LAMBDA_D:  //the following catches all three:
          lambda_P[0] = regs[MB_LAMBDA_P]/100.0;
          lambda_I[0] = regs[MB_LAMBDA_I]/100.0;
          lambda_PID.SetTunings(lambda_P[0],lambda_I[0],0);
          WriteLambda();
          break;
        default:  //catch all configs
          if((i >= MB_CONFIG1) && (i < MB_CONFIG1+CONFIG_COUNT-1)){
            saveConfig(i-MB_CONFIG1+1,regs[i]);
            update_config_var(i);
              }
              break;
          }
        }
        written.num_regs=0;
    }
    
    regs[MB_ALARMS] = getAlarmBin();                
    regs[MB_FUELSWITCHLEVEL] = getFuelSwitch();
    regs[MB_P_RATIO_FILTER_STATE] = -500;  //int(pRatioFilterHigh);  
    regs[MB_P_RATIO_STATE_REACTOR] = (int)pRatioReactorLevel;	 //pRatioReactorLevel[pRatioReactorLevelName] 
    regs[MB_P_REACTORLEVEL] = (int)pRatioReactorLevel;	 //pRatioReactorLevel[pRatioReactorLevelName]        
    regs[MB_T_BREDLEVEL] = (int)T_bredLevel;//T_bredLevel[TempLevelName]	          
    regs[MB_T_TREDLEVEL] = (int)T_tredLevel;//T_tredLevel[TempLevelName]           
    regs[MB_LAMBDA_P] = int(100*lambda_PID.GetP_Param());	 
    regs[MB_LAMBDA_I] = int(100*lambda_PID.GetI_Param());	 
    //regs[MB_LAMBDA_D] = int(100*lambda_PID.GetD_Param());	 //Not used	             
    regs[MB_LAMBDA_SETPOINT] = int(1000*lambda_setpoint);	     
    regs[MB_P_COMB] = (int)Press[P_COMB]; 
    regs[MB_P_FILTER] = (int)Press[P_FILTER];
    //regs[MB_P_Q_AIR_ENG] = (int)Press[P_Q_AIR_ENG]; //ABSENT;
    //regs[MB_P_Q_AIR_RCT] = (int)Press[P_Q_AIR_RCT];   //(ABSENT?)
    //regs[MB_P_Q_GAS_ENG] = (int)Press[P_Q_GAS_ENG];  //(ABSENT?)
    regs[MB_P_REACTOR] = (int)Press[P_REACTOR];
    regs[MB_AUGER_STATE] = auger_state;
    //regs[MB_BLOWER_STATE] = ABSENT; //(NOT SURE IF THIS CAN BE COMBINED WITH FLARE)
    regs[MB_ENGINE_STATE] = engine_state;
    regs[MB_FLARE_STATE] = flare_state;
    regs[MB_GRATE_STATE] = grateMode;  //grate_motor_state;
    regs[MB_T_BRED] = (int)Temp_Data[T_BRED];
    //regs[MB_T_COMB] = (int)Temp_Data[T_COMB]; //ABSENT;
    //regs[MB_T_DRYING_GAS_OUT] = (int)Temp_Data[T_COMB]; //ABSENT;
    regs[MB_T_ENG_COOLANT] = (int)Temp_Data[T_ENG_COOLANT];
    //regs[MB_T_LOW_FUEL] = (int)Temp_Data[T_LOW_FUEL]; //ABSENT;
    //regs[MB_T_PYRO_IN] = Temp_Data[T_PYRO_IN]; //ABSENT;
    //regs[MB_T_PYRO_OUT] = Temp_Data[T_PYRO_OUT]; //ABSENT;
    //regs[MB_T_REACTOR_GAS_OUT] = (int)Temp_Data[T_REACTOR_GAS_OUT];  //(ABSENT?)
    regs[MB_T_TRED] = (int)Temp_Data[T_TRED];
    regs[MB_GRATE_VAL] = grate_val;	
    regs[MB_LAMBDA_IN] = int(100*lambda_input);
    regs[MB_LAMBDA_OUT] = int(100*lambda_output);
    regs[MB_P_RATIO_FILTER] = int(pRatioFilter*100);	
    regs[MB_P_RATIO_REACTOR] = int(pRatioReactor*100);
}


int getFuelSwitch(){
  if (FuelDemand){
    return 1;
  }
  else {
    return 0;
  }
}

