boolean InitSD() {
	pinMode(SS_PIN, OUTPUT);
	pinMode(MOSI_PIN, OUTPUT);
	pinMode(MISO_PIN, INPUT);
	pinMode(SCK_PIN, OUTPUT);

	SerialPrint_P(PSTR("# Initializing SD card..."));
	if(!SD.begin(SS_PIN)){        // 2.004 seconds if no SD card (fail), 60msec if SD card (succeed).
		SerialPrint_P(PSTR("initialization failed.\n"));
		sd_loaded = false;
	}
	else {
		SerialPrint_P(PSTR("card initialized.\n"));
		sd_loaded = true;
		data_log_num++;
		sprintf_P(sd_data_file_name, PSTR("dat%05i.csv"), data_log_num);
		//sprintf_P(sd_log_file_name, PSTR("log%05i.txt"), data_log_num);

		dataFile = SD.open(sd_data_file_name, FILE_WRITE);  //if file doesn't exist it will be created

		SerialPrint_P(PSTR("# Writing data to "));
		Serial.println(sd_data_file_name);
		eeprom_write_word((uint16_t *)(30), data_log_num);
	}
return sd_loaded;
}

void DatalogSD(boolean newline) {    //file_name should be 8.3 format names
  if (dataFile) {
	dataFile.print(string_buffer);
	dataFile.flush();
  }
  else {
	SerialPrint_P(PSTR("# Error loading "));
	Serial.println(sd_data_file_name);
	sd_loaded = false;
  }
}


void EEPROMReadAlpha(int address, int length, char* buffer){
  for (int i=0; i < length; i++){
    buffer[i] = eeprom_read_byte((uint8_t *)(address+i));
    buffer[i+1] = '\0';
  }
  //return i;
}

void EEPROMWriteAlpha(int address, int length, char* buffer){
  for (int i=0; i < length; i++){
    eeprom_write_byte((uint8_t *)(address+i), buffer[i]);
  }
}
