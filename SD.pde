boolean InitSD() {
	unsigned data_log_num = eeprom_read_word((uint16_t *)(30)); //reads from EEPROM bytes 30 and 31

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
		sprintf(sd_data_file_name, "dat%05i.csv", data_log_num);
		sprintf(sd_log_file_name, "log%05i.txt", data_log_num);
		SerialPrint_P(PSTR("# Writing data to "));
		Serial.println(sd_data_file_name);
		eeprom_write_word((uint16_t *)(30), data_log_num);
	}
return sd_loaded;
}

void DatalogSD(char file_name[13], boolean newline) {    //file_name should be 8.3 format names
  //SD.begin(SS_PIN);
  File dataFile = SD.open(file_name, FILE_WRITE);  //if file doesn't exist it will be created
                                                   //if file exists, it will be appended to, even though no seek is performed?
  if (dataFile) {
	dataFile.print(string_buffer);
    dataFile.close();
  }
  else {
	SerialPrint_P(PSTR("# Error loading "));
   Serial.println(file_name);
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
