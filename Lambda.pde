// Lambda
void InitLambda() {
  LoadLambda();
}

void DoLambda() {
  lambda_input = GetLambda();
  switch(lambda_state) {
  case LAMBDA_CLOSEDLOOP:
    lambda_PID.SetTunings(lambda_P[0], lambda_I[0], lambda_D[0]);
    lambda_PID.Compute();
    SetPremixServoAngle(lambda_output);
    if (engine_state == ENGINE_OFF) {
      TransitionLambda(LAMBDA_SEALED);
    }
    if (serial_last_input == 'o') {
      TransitionLambda(LAMBDA_STEPTEST);  //Serial input of 'o'
      serial_last_input = '\0';
    }
    if (serial_last_input == 'O') {
      TransitionLambda(LAMBDA_SPSTEPTEST); //Serial input of 'O'
      serial_last_input = '\0';
    }
    if (lambda_input < 0.52) {
      TransitionLambda(LAMBDA_NO_SIGNAL); //No Signal from Lambda Sensor
    }
    if (engine_state == ENGINE_SHUTDOWN) {
      TransitionLambda(LAMBDA_SHUTDOWN);  //
    }
    break;
  case LAMBDA_SEALED:
    if (engine_state == ENGINE_STARTING || engine_state == ENGINE_ON) {
      TransitionLambda(LAMBDA_STARTING);
    }
    //       if (engine_state == ENGINE_ON) {
    //         TransitionLambda(LAMBDA_CLOSEDLOOP);
    //       }
    if (lambda_input < 0.52) {
      TransitionLambda(LAMBDA_NO_SIGNAL);
    }
    if (serial_last_input == 'o') {
      TransitionLambda(LAMBDA_STEPTEST);
      serial_last_input = '\0';
    }
    if (serial_last_input == 'O') {
      TransitionLambda(LAMBDA_SPSTEPTEST);
      serial_last_input = '\0';
    }
    SetPremixServoAngle(0);
    break;
  case LAMBDA_STEPTEST: //used for PID tuning
    if (millis()-lambda_state_entered > 15000) { //change output every 5 seconds
      TransitionLambda(LAMBDA_STEPTEST);
    }
    if (serial_last_input == 'o') {
      TransitionLambda(LAMBDA_CLOSEDLOOP);
      serial_last_input = '\0';
    }
    SetPremixServoAngle(lambda_output);
    break;
  case LAMBDA_SPSTEPTEST:
    lambda_PID.SetTunings(lambda_P[0], lambda_I[0], lambda_D[0]);
    lambda_PID.Compute();
    SetPremixServoAngle(lambda_output);
    if (millis()-lambda_state_entered > 15000) { //change output every 5 seconds
      TransitionLambda(LAMBDA_SPSTEPTEST);
    }
    if (serial_last_input == 'o') {
      TransitionLambda(LAMBDA_CLOSEDLOOP);
      serial_last_input = '\0';
    }
    SetPremixServoAngle(lambda_output);
    break;
  case LAMBDA_NO_SIGNAL:
    if (millis() - lambda_state_entered > 1000) {
      TransitionLambda(LAMBDA_RESET);
    }
    if (lambda_input > 0.52) {
      TransitionLambda(LAMBDA_CLOSEDLOOP);
    }
    if (engine_state == ENGINE_SHUTDOWN) {
      TransitionLambda(LAMBDA_SHUTDOWN);
    }
    break;
  case LAMBDA_RESET:
    if (millis() - lambda_state_entered > 250) {
      TransitionLambda(LAMBDA_RESTART);
    }
    break;
  case LAMBDA_RESTART:
    if (millis() - lambda_state_entered > 60000) {
      if (engine_state == ENGINE_ON) {
        Log_p("No O2 Signal, Shutting down Engine at: ");
        Logln(millis() - lambda_state_entered);
        TransitionEngine(ENGINE_SHUTDOWN);
      }
      TransitionLambda(LAMBDA_SEALED);
    }
    if (lambda_input > 0.52 && millis() - lambda_state_entered > 1000) {
      if (engine_state == ENGINE_ON) {
        TransitionLambda(LAMBDA_CLOSEDLOOP);
      }  
      else {
        TransitionLambda(LAMBDA_SEALED);
      }
    }
    break;
  case LAMBDA_UNKNOWN:
    if (lambda_input > 0.52) {
      if (engine_state == ENGINE_ON) {
        TransitionLambda(LAMBDA_CLOSEDLOOP);
      }  
      else {
        TransitionLambda(LAMBDA_SEALED);
      }
    } 
    else {
      if (millis() -  lambda_state_entered > 100) {
        TransitionLambda(LAMBDA_RESTART);
      }
    }
    break;
  case LAMBDA_SHUTDOWN:
    //        if (millis()-lambda_state_entered > 2000) {
    //          SetPremixServoAngle(1);
    //        }
    SetPremixServoAngle(1);
    if (engine_state == ENGINE_OFF) {
      TransitionLambda(LAMBDA_SEALED);
    }
    break;
  case LAMBDA_STARTING:
//    if ((lambda_input > 0.52) && (lambda_input <= lambda_rich/100)) { //Check that there is a signal, and then as soon as mixture gets rich switch to closed loop
//      SetPremixServoAngle(premix_valve_center);
//      //lambda_output = premix_valve_center;  //necessary? 
//      TransitionLambda(LAMBDA_CLOSEDLOOP);
//    }
//    if (engine_state == ENGINE_OFF) {
//      TransitionLambda(LAMBDA_SEALED);
//    }
//    if (serial_last_input == 'o') {
//      TransitionLambda(LAMBDA_STEPTEST);
//      serial_last_input = '\0';
//    }
//    if (serial_last_input == 'O') {
//      TransitionLambda(LAMBDA_SPSTEPTEST);
//      serial_last_input = '\0';
//    }
//    //        if (lambda_input < 0.52) {
//    //          TransitionLambda(LAMBDA_NO_SIGNAL);
//    //        }
//    if (engine_state == ENGINE_SHUTDOWN) {
//      TransitionLambda(LAMBDA_SHUTDOWN);
//    }
    TransitionLambda(LAMBDA_CLOSEDLOOP);
    break;
  }
}

void TransitionLambda(int new_state) {
  //Exit
  switch (lambda_state) {
  case LAMBDA_CLOSEDLOOP:
    break;
  case LAMBDA_SEALED:
    break;
  case LAMBDA_STEPTEST:
    loopPeriod1 = loopPeriod1*4; //return to normal datalogging rate
    break;
  case LAMBDA_SPSTEPTEST:
    loopPeriod1 = loopPeriod1*4; //return to normal datalogging rate
    break;
  case LAMBDA_NO_SIGNAL:
    break;
  case LAMBDA_RESET:
    break;
  case LAMBDA_RESTART:
    break;
  case LAMBDA_UNKNOWN:
    break;
  case LAMBDA_SHUTDOWN:
    break;
  case LAMBDA_STARTING:
    break;
  }
  Log_p("Lambda switching from ");
  Log(lambda_state_name);

  //Enter
  lambda_state=new_state;
  lambda_state_entered = millis();
  switch (new_state) {
  case LAMBDA_CLOSEDLOOP:
    strcpy(lambda_state_name, P("Closed Loop"));
    lambda_PID.SetMode(AUTO);
    lambda_PID.SetSampleTime(20);
    lambda_PID.SetInputLimits(0.5,1.5);
    lambda_PID.SetOutputLimits(premix_valve_min,premix_valve_max);
    break;
  case LAMBDA_SEALED:
    strcpy(lambda_state_name, P("Sealed"));
    SetPremixServoAngle(premix_valve_closed);
    lambda_PID.SetMode(MANUAL);
    break;
  case LAMBDA_STEPTEST:
    strcpy(lambda_state_name, P("Step Test"));
    lambda_PID.SetMode(AUTO);
    lambda_output = (random(3,8)/10.0)*(lambda_PID.GetOUTMax()-lambda_PID.GetOUTMin()); //steps in random 10% increments of control output limits
    loopPeriod1 = loopPeriod1/4; //fast datalogging
    break;
  case LAMBDA_SPSTEPTEST:
    strcpy(lambda_state_name, P("Setpoint Step Test"));
    lambda_PID.SetMode(AUTO);
    lambda_setpoint = random(8,12)/10.0; //steps in random 10% increments of control output limits
    loopPeriod1 = loopPeriod1/4; //fast datalogging
    break;
  case LAMBDA_NO_SIGNAL:
    strcpy(lambda_state_name, P("O2 signal loss"));
    lambda_PID.SetMode(MANUAL);
    //lambda_output = smoothedLambda;
    break;
  case LAMBDA_RESET:
    digitalWrite(FET_O2_RESET, HIGH);
    strcpy(lambda_state_name, P("Resetting O2 Relay"));
    break;
  case LAMBDA_RESTART:
    digitalWrite(FET_O2_RESET, LOW);
    strcpy(lambda_state_name, P("Checking for O2 signal"));
    break;
  case LAMBDA_UNKNOWN:
    strcpy(lambda_state_name, P("Unknown (Checking)"));
    break;
  case LAMBDA_SHUTDOWN:
    strcpy(lambda_state_name, P("Lambda Locked (engine shutting down)"));
    lambda_PID.SetMode(MANUAL);
    break;
  case LAMBDA_STARTING:
    strcpy(lambda_state_name, P("Lambda Starting"));
    SetPremixServoAngle(premix_valve_closed);
    lambda_PID.SetMode(MANUAL);
    break;
  }
  Log_p(" to ");  
  Logln(lambda_state_name);
}

//this doesn't need to be checked that often.....
//if (millis() - lamba_updated_time > 60000 & write_lambda) {
// WriteLambda(); //values for engine on stored in flash
// write_lambda = false;
// Serial.print("Lambda PID values saved");
//}

double GetLambda() {
  return analogRead(ANA_LAMBDA)/1024.0+0.5; //0-5V = 0.5 - 1.5 L;
}

void SetPremixServoAngle(double percent) {
  Servo_Mixture.write(premix_valve_closed + percent*(premix_valve_open-premix_valve_closed));
}

void WriteLambda() {
  WriteLambda(lambda_setpoint);
}

void WriteLambda(double setpoint) {
	// We use a union to avoid float->int conversion
	union dong {
		double d;
		uint32_t l;
	} dong;
	Logln_p("Writing lambda settings to EEPROM");
	dong.d = setpoint;
	eeprom_write_dword((uint32_t *)CFG_ADDR_LAMBDA_SETPOINT, dong.l);
	dong.d = lambda_PID.GetP_Param();
	eeprom_write_dword((uint32_t *)CFG_ADDR_LAMBDA_P_GAIN, dong.l);
	dong.d = lambda_PID.GetI_Param();
	eeprom_write_dword((uint32_t *)CFG_ADDR_LAMBDA_I_GAIN, dong.l);
	
}

void LoadLambda() {
	union dong {
		double d;
		uint32_t l;
	} dong;
	Logln_p("Loading lambda settings from EEPROM");
	dong.l = eeprom_read_dword((uint32_t *)CFG_ADDR_LAMBDA_SETPOINT);
	lambda_setpoint = dong.d;
	if (!(lambda_setpoint < 1.5) || !(lambda_setpoint > 0.5)) {
		lambda_setpoint = LAMBDA_SETPOINT_DEFAULT;
		lambda_P[0] = 0.13;
		lambda_I[0] = 0.1;
	}
	dong.l = (double)eeprom_read_dword((uint32_t *)CFG_ADDR_LAMBDA_P_GAIN);
	lambda_P[0] = dong.d;
	dong.l = (double)eeprom_read_dword((uint32_t *)CFG_ADDR_LAMBDA_I_GAIN);
	lambda_I[0] = dong.d;
	lambda_PID.SetTunings(lambda_P[0], lambda_I[0],	0.0);
}



