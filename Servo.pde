// Servo
// TO DO: move to hardware timer based output, improve or remove the deadband code, code should be implemented for all 3 servos
void InitServos() {
  #ifdef SERVO_MIXTURE != ABSENT
    Servo_Mixture.attach(SERVO_MIXTURE); //the def links to the equivalent Arduino pin
  #endif
  #ifdef SERVO_CALIB != ABSENT
    Servo_Calib.attach(SERVO_CALIB);
  #endif
  #ifdef SERVO_THROTTLE !=
    Servo_Throttle.attach(SERVO_THROTTLE);
  #endif
}

void PulseServo(int servo_pin,double angle) {
  digitalWrite(servo_pin,HIGH);
  delayMicroseconds(1520+angle*6);
  digitalWrite(servo_pin,LOW);
}

void LoadServo() {
  servo_min = EEPROM.read(23);
  if (servo_min != 255) {  //if EEPROM in default value, then default to 133
    premix_valve_open = int(servo_min);
  }
  servo_max = EEPROM.read(22);
  if (servo_max != 255) { //if EEPROM in default value, then default to 68
    premix_valve_closed = int(servo_max);
  } 
}

void WriteServo(){
  if (servo_min != premix_valve_closed) {
    EEPROM.write(22,premix_valve_closed);
    servo_min = premix_valve_closed;
    Serial.println("#Writing Servo Min position setting to EEPROM");
  }
  if (servo_max != premix_valve_open){
    EEPROM.write(23,premix_valve_open);
    servo_max = premix_valve_open;
    Serial.println("#Writing Servo Max position setting to EEPROM");
  }
}

// code for driving servos w/ dead band
//void DoServos() {
//  if (servo_alt == 1) { // pulse every other time through the loop
//    if (abs(servo0_pos - servo0_db) > 3) {
//      servo0_db = servo0_pos;
//    }
//    if (abs(servo1_pos - servo1_db) > 3) {
//      servo1_db = servo1_pos;
//    }
//    if (abs(servo2_pos - servo2_db) > 3) {
//      servo2_db = servo2_pos;
//    }
//    PulseServo(SERVO0,servo0_db);
//    PulseServo(SERVO1,servo1_db);
//    PulseServo(SERVO2,servo2_db);
//    servo_alt = 0; 
//  }
//  servo_alt++;
//}
