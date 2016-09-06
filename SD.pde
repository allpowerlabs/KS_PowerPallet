boolean InitSD() {
	unsigned data_log_num = EEPROMReadInt(30); //reads from EEPROM bytes 30 and 31

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
		EEPROMWriteInt(30, data_log_num);
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

void EEPROMWriteInt(int p_address, int p_value){
  byte lowByte = ((p_value >> 0) & 0xFF);
  byte highByte = ((p_value >> 8) & 0xFF);

  EEPROM.write(p_address, lowByte);
  EEPROM.write(p_address + 1, highByte);
}

unsigned int EEPROMReadInt(int p_address){
  byte lowByte = EEPROM.read(p_address);
  byte highByte = EEPROM.read(p_address + 1);

  return ((lowByte << 0) & 0xFF) + ((highByte << 8) & 0xFF00);
}

void EEPROMReadAlpha(int address, int length, char* buffer){
  for (int i=0; i < length; i++){
    buffer[i] = EEPROM.read(address+i);
    buffer[i+1] = '\0';
  }
  //return i;
}

void EEPROMWriteAlpha(int address, int length, char* buffer){
  for (int i=0; i < length; i++){
    EEPROM.write(address+i, buffer[i]);
  }
}
