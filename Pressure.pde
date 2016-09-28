// Pressure
void DoPressure() {
	Press_ReadAll();
	for (int i = 0; i<NPRESS; i++) {
		Press[i] = (Press_Data[i] - Press_Calib[i]);
	}
}

void CalibratePressureSensors() {
	int P_sum[NPRESS] = {0,0,0,0,0,0};
	fprintf(&event_log, "# Calibrating Pressure Sensors: \n");
	// Take 10 pressure samples
	for (int i=0; i<NSAMPLES; i++) {
		Press_ReadAll();
		// Add the current sample set
		for (int j=0; j<NPRESS; j++) {
			P_sum[j] += Press_Data[j];
		}
		delay(1);
	}
	//write to EEPROM
	for (int i=0; i<NPRESS; i++) {
		Press_Calib[i] = P_sum[i] / NSAMPLES;
		eeprom_write_word((uint16_t *)(i * 2), Press_Calib[i]);
		fprintf(&event_log, "# P%i: %i\n", i, Press_Calib[i]);
	}
}

void LoadPressureSensorCalibration() {
  int calib;
  fprintf(&event_log, "# Loading Pressure Sensor Calibrations: \n");
  for (int i=0; i<NPRESS; i++) {
    Press_Calib[i] = eeprom_read_word((uint16_t *)(i * 2));
	fprintf(&event_log, "# P%i: %i\n", i, Press_Calib[i]);
  }
}

void Press_ReadAll() {
	ADC_SETBANK(0);
	Press_Data[0] = ADC_ReadChanSync(12);
	Press_Data[4] = ADC_ReadChanSync(13);
 	ADC_SETBANK(1);
 	Press_Data[1] = ADC_ReadChanSync(12);
	Press_Data[5] = ADC_ReadChanSync(13);
 	ADC_SETBANK(2);
 	Press_Data[2] = ADC_ReadChanSync(12);
 	ADC_SETBANK(3);
 	Press_Data[3] = ADC_ReadChanSync(12);
}
