// Pressure
void DoPressure() {
	Press_ReadAll();
	for (int i = 0; i<6; i++) {
		Press[i] = (Press_Data[i] - Press_Calib[i]) * ADC_UV / sensitivity[i];
	}
}

void CalibratePressureSensors() {
  int P_sum[6] = {0,0,0,0,0,0};
  int P_ave;
  byte lowbyte,highbyte;
  fprintf(&event_log, "# Calibrating Pressure Sensors: \n");
  for (int i=0; i<10; i++) {
    Press_ReadAll();
    for (int j=0; j<6; j++) {
      P_sum[j] += Press_Data[j];
    }
	fprintf(&event_log, "# P%i: %i\n", i, Press_Calib[i]);
    delay(1);
  }
  //write to EEPROM
  for (int i=0; i<6; i++) {
    P_ave = float(P_sum[i])/10.0;
	Press_Calib[i] = P_ave;
    lowbyte = ((P_ave >> 0) & 0xFF);
    highbyte = ((P_ave >> 8) & 0xFF);
    EEPROM.write(i*2, lowbyte);
    EEPROM.write(i*2+1, highbyte);
  }
}

void LoadPressureSensorCalibration() {
  int calib;
  byte lowbyte,highbyte;
  fprintf(&event_log, "# Loading Pressure Sensor Calibrations: \n");
  for (int i=0; i<6; i++) {
    byte lowByte = EEPROM.read(i*2);
    byte highByte = EEPROM.read(i*2 + 1);
    Press_Calib[i] = ((lowByte << 0) & 0xFF) + ((highByte << 8) & 0xFF00);
	fprintf(&event_log, "# P%i: %i\n", i, Press_Calib[i]);
  }
}

void Press_ReadAll() {
	ADC_SETBANK(0);
	Press_Data[0] = ADC_ReadChanSync(12);
 	ADC_SETBANK(1);
 	Press_Data[1] = ADC_ReadChanSync(12);
 	ADC_SETBANK(2);
 	Press_Data[2] = ADC_ReadChanSync(12);
 	ADC_SETBANK(3);
 	Press_Data[3] = ADC_ReadChanSync(12);
 	ADC_SETBANK(0);
	Press_Data[4] = ADC_ReadChanSync(13);
 	ADC_SETBANK(1);
 	Press_Data[5] = ADC_ReadChanSync(13);
}
