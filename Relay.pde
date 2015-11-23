//Individual Relay Control using multiplexer
//void relayOn(int driveNum){
//  bitSet(shiftRegister, driveNum);
//  digitalWrite(latchPin, LOW);
//  shiftOut(dataPin, clockPin, MSBFIRST, shiftRegister);
//  digitalWrite(latchPin, HIGH);
//}
//
//void relayOff(int driveNum){
//  bitClear(shiftRegister, driveNum);
//  digitalWrite(latchPin, LOW);
//  shiftOut(dataPin, clockPin, MSBFIRST, shiftRegister);
//  digitalWrite(latchPin, HIGH);
//}

//FET0     Fuel Auger Relay0
//FET1     Grate Shaker Motor Relay1
//FET2     Ignition Relay2
//FET3     Starter Relay3
//FET4     Ignitor Relay4
//FET5     O2 Reset Relay5

//relay control using direct FET output
void relayOn(int driveNum){
  switch (driveNum) {
    case 1: 
      digitalWrite(FET0,HIGH);
      break;
    case 2: 
      digitalWrite(FET1,HIGH);
      break;
    case 3: 
      digitalWrite(FET2,HIGH);
      break;
    case 4: 
      digitalWrite(FET3,HIGH);
      break;
    case 5: 
      digitalWrite(FET4,HIGH);
      break;
    case 6: 
      digitalWrite(FET5,HIGH);
      break;
    case 7: 
      digitalWrite(FET6,HIGH);
      break;
    case 8: 
      digitalWrite(FET7,HIGH);
      break;  
  }     
}

void relayOff(int driveNum){
  switch (driveNum) {
    case 1: 
      digitalWrite(FET0,LOW);
      break;
    case 2: 
      digitalWrite(FET1,LOW);
      break;
    case 3: 
      digitalWrite(FET2,LOW);
      break;
    case 4: 
      digitalWrite(FET3,LOW);
      break;
    case 5: 
      digitalWrite(FET4,LOW);
      break;
    case 6: 
      digitalWrite(FET5,LOW);
      break;
    case 7: 
      digitalWrite(FET6,LOW);
      break;
    case 8: 
      digitalWrite(FET7,LOW); 
      break; 
  } 
}
