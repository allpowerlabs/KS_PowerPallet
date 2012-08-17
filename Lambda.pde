// Lambda
void InitLambda() {
  LoadLambda();
}

void DoLambda() {
    lambda_input = GetLambda();
    switch(lambda_state) {
      case LAMBDA_CLOSEDLOOP:
        //don't reset changed PID values
//        if (display_state != DISPLAY_LAMBDA) {
//          if (lambda_input < lambda_setpoint - 0.1) {
//            lambda_PID.SetTunings(lambda_P[0]*1.5, lambda_I[0], lambda_D[0]);
//          } else {
//            lambda_PID.SetTunings(lambda_P[0], lambda_I[0], lambda_D[0]);
//          }
//        }
        lambda_PID.SetTunings(lambda_P[0], lambda_I[0], lambda_D[0]);
        lambda_PID.Compute();
        SetPremixServoAngle(lambda_output);
        if (engine_state == ENGINE_OFF) {
          TransitionLambda(LAMBDA_SEALED);
        }
        if (serial_last_input == 'o') {
          TransitionLambda(LAMBDA_STEPTEST);
          serial_last_input = '\0';
        }
        if (serial_last_input == 'O') {
          TransitionLambda(LAMBDA_SPSTEPTEST);
          serial_last_input = '\0';
        }
        if (lambda_input < 0.52) {
          TransitionLambda(LAMBDA_NO_SIGNAL);
        }
        break;
      case LAMBDA_SEALED:
        if (engine_state == ENGINE_STARTING) {
          TransitionLambda(LAMBDA_CLOSEDLOOP);
        }
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
        break;
      case LAMBDA_RESET:
        if (millis() - lambda_state_entered > 250) {
          TransitionLambda(LAMBDA_RESTART);
        }
        break;
      case LAMBDA_RESTART:
        if (millis() - lambda_state_entered > 60000) {
          if (engine_state == ENGINE_ON){
            Serial.print("# No O2 Signal, Shutting down Engine at: ");
            Serial.println(millis() - lambda_state_entered);
            TransitionEngine(ENGINE_SHUTDOWN);
          }
          TransitionLambda(LAMBDA_SEALED);
        }
        if (lambda_input > 0.52 && millis() - lambda_state_entered > 1000) {
          if (engine_state == ENGINE_ON){
            TransitionLambda(LAMBDA_CLOSEDLOOP);
          }  else {
            TransitionLambda(LAMBDA_SEALED);
          }
        }
        break;
      case LAMBDA_UNKNOWN:
        if (lambda_input > 0.52) {
          if (engine_state == ENGINE_ON){
            TransitionLambda(LAMBDA_CLOSEDLOOP);
          }  else {
            TransitionLambda(LAMBDA_SEALED);
          }
        } else {
          if (millis() -  lambda_state_entered > 10){
            TransitionLambda(LAMBDA_RESTART);
          }
        }
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
   }
  Serial.print("# Lambda switching from ");
  Serial.print(lambda_state_name);
  
  //Enter
  lambda_state=new_state;
  lambda_state_entered = millis();
  switch (new_state) {
    case LAMBDA_CLOSEDLOOP:
      lambda_state_name = "Closed Loop";
      lambda_setpoint = lambda_setpoint_mode[0];
      if (engine_state == ENGINE_STARTING){
        lambda_output = premix_valve_center;
      }
      lambda_PID.SetMode(AUTO);
      lambda_PID.SetSampleTime(20);
      lambda_PID.SetInputLimits(0.5,1.5);
      lambda_PID.SetOutputLimits(premix_valve_min,premix_valve_max);
      break;
    case LAMBDA_SEALED:
      lambda_state_name = "Sealed";
      SetPremixServoAngle(premix_valve_closed);
      lambda_PID.SetMode(MANUAL);
      break;
    case LAMBDA_STEPTEST:
      lambda_state_name = "Step Test";
      lambda_PID.SetMode(AUTO);
      lambda_output = (random(3,8)/10.0)*(lambda_PID.GetOUTMax()-lambda_PID.GetOUTMin()); //steps in random 10% increments of control output limits
      loopPeriod1 = loopPeriod1/4; //fast datalogging
      break;
    case LAMBDA_SPSTEPTEST:
      lambda_state_name = "Setpoint Step Test";
      lambda_PID.SetMode(AUTO);
      lambda_setpoint = random(8,12)/10.0; //steps in random 10% increments of control output limits
      loopPeriod1 = loopPeriod1/4; //fast datalogging
      break;
    case LAMBDA_NO_SIGNAL:
      lambda_state_name = "O2 signal loss";
      lambda_PID.SetMode(MANUAL);
      //lambda_output = smoothedLambda;
      break;
    case LAMBDA_RESET:
      digitalWrite(FET_O2_RESET, HIGH);
      lambda_state_name = "Resetting O2 Relay";
      break;
    case LAMBDA_RESTART:
      digitalWrite(FET_O2_RESET, LOW);
      lambda_state_name = "Checking for O2 signal";
      break;
    case LAMBDA_UNKNOWN:
       lambda_state_name = "Lambda state unknown, checking for O2 signal";
       break;
    }
  Serial.print(" to ");  
  Serial.println(lambda_state_name);
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
  int val,p,i;
  p = constrain(lambda_PID.GetP_Param()*100,0,255);
  i = constrain(lambda_PID.GetI_Param()*10,0,255);
  lambda_setpoint_mode[0] = setpoint;
  val = constrain(128+(setpoint-1.0)*100,0,255);
  EEPROM.write(12,128); //check point
  EEPROM.write(13, val);
  EEPROM.write(14, p);
  EEPROM.write(15, i);
  Serial.println("#Writing lambda settings to EEPROM");
}

void LoadLambda() {
  byte check;
  double val,p,i;
  check = EEPROM.read(12); 
  val = 1.0+(EEPROM.read(13)-128)*0.01;
  p = EEPROM.read(14)*0.01;
  i = EEPROM.read(15)*0.1;
  if (check == 128 && val >= 0.5 && val <= 1.5) { //check to see if lambda has been set
    Serial.println("#Loading lambda from EEPROM");
    lambda_setpoint = val;
    lambda_PID.SetTunings(p,i,0);
    lambda_P[0] = p;
    lambda_I[0] = i;
  } else {
    Serial.println("#Saving default lambda setpoint to EEPROM");
    val = lambda_setpoint_mode[0];
    WriteLambda(val);
  }
  lambda_setpoint = val;
  lambda_setpoint_mode[0] = val;
}


