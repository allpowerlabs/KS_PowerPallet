// Pressure

void DoPressure() {
  UpdateCalibratedPressure();
}

void CalibratePressureSensors() {
  int P_sum[6] = {0,0,0,0};
  int P_ave;
  byte lowbyte,highbyte;
  Serial.println("#Calibrating Pressure Sensors");
  for (int i=0; i<10; i++) {
    Press_ReadAll();
    for (int j=0; j<6; j++) {
      P_sum[j] += Press_Data[j];
    }
    delay(1);
  }
  //write to EEPROM
  for (int i=0; i<6; i++) {
    P_ave = float(P_sum[i])/10.0;
    lowbyte = ((P_ave >> 0) & 0xFF);
    highbyte = ((P_ave >> 8) & 0xFF);
    EEPROM.write(i*2, lowbyte);
    EEPROM.write(i*2+1, highbyte);
  }
}

void LoadPressureSensorCalibration() {
  int calib;
  byte lowbyte,highbyte;
  Serial.println("#Loading Pressure Sensor Calibrations:");
  for (int i=0; i<6; i++) {
    byte lowByte = EEPROM.read(i*2);
    byte highByte = EEPROM.read(i*2 + 1);
    Press_Calib[i] = ((lowByte << 0) & 0xFF) + ((highByte << 8) & 0xFF00);
    Serial.print("#P");
    Serial.print(i);
    Serial.print(": ");
    Serial.print(Press_Calib[i]);
    Serial.println();
  }
}

void UpdateCalibratedPressure() {
  for (int i = 0; i<6; i++) {
    Press[i] = Press_Data[i]-Press_Calib[i];
  }
}


