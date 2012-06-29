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
    case 2: 
      digitalWrite(FET1,HIGH);
    case 3: 
      digitalWrite(FET2,HIGH);
    case 4: 
      digitalWrite(FET3,HIGH);
    case 5: 
      digitalWrite(FET4,HIGH);
    case 6: 
      digitalWrite(FET5,HIGH);
    case 7: 
      digitalWrite(FET6,HIGH);
    case 8: 
      digitalWrite(FET7,HIGH);  
  }     
}

void relayOff(int driveNum){
  switch (driveNum) {
    case 1: 
      digitalWrite(FET0,LOW);
    case 2: 
      digitalWrite(FET1,LOW);
    case 3: 
      digitalWrite(FET2,LOW);
    case 4: 
      digitalWrite(FET3,LOW);
    case 5: 
      digitalWrite(FET4,LOW);
    case 6: 
      digitalWrite(FET5,LOW);
    case 7: 
      digitalWrite(FET6,LOW);
    case 8: 
      digitalWrite(FET7,LOW);  
  } 
}
