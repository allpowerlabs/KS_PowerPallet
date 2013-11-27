boolean InitSD() {
  pinMode(SS_PIN, OUTPUT); 
  pinMode(MOSI_PIN, OUTPUT); 
  pinMode(MISO_PIN, INPUT); 
  pinMode(SCK_PIN, OUTPUT); 

  putstring("#Initializing SD card...");
  if(!SD.begin(SS_PIN)){        // 2.004 seconds if no SD card (fail), 60msec if SD card (succeed).
    putstring("initialization failed.\r\n");
    sd_loaded = false;
  } 
  else {
    putstring("card initialized.\r\n");
    sd_loaded = true;
    int data_log_num = EEPROMReadInt(30); //reads from EEPROM bytes 30 and 31
    if (data_log_num == 32767){  //TODO: unsigned??  --> 65,535
      data_log_num = 1;
    } 
    else { 
      data_log_num++;
    }
    sprintf(sd_data_file_name, "dat%05i.csv", data_log_num); 
    sprintf(sd_log_file_name, "log%05i.txt", data_log_num); 
    putstring("#Writing data to ");
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
    if (newline) {
      dataFile.println(string_buffer);
    } 
    else {
      dataFile.print(string_buffer);
    }
    dataFile.close();
  }  
  else {
    putstring("# Error loading ");
    Serial.println(file_name);
  } 
}

//Logging Functions:

void appendTimestamp(){
  dtostrf(millis()/100, 5, 3, float_buf);
  strncat(float_buf, comma, 15);
  strncat(string_buffer, "# ", BUFFER_SIZE);
  strncat(string_buffer, float_buf, BUFFER_SIZE);
  buffer_size = strlen(string_buffer);
}  

void clearBuffer(){
  buffer_size = 0;
  string_buffer[0] = '\0';
}

void Logln(const char * str) {
  if (buffer_size == 0){
    appendTimestamp();
  }
  strncat(string_buffer, str, BUFFER_SIZE);
  Serial.print(string_buffer); Serial.println();
  if (save_datalog_to_sd && sd_loaded){
    DatalogSD(sd_log_file_name, true);  
  }
  clearBuffer();
}

void Log(const char * str) {
  if (buffer_size == 0){
    appendTimestamp();
  }
  strncat(string_buffer, str, BUFFER_SIZE);
  buffer_size = strlen(string_buffer);
}

void Logln(float str) {
  dtostrf(str, 5, 3, float_buf);
  Logln(float_buf);
}

void Log(float str) {
  dtostrf(str, 5, 3, float_buf);
  Log(float_buf);
}

void Logln(int str) {
  sprintf(float_buf, "%d", str);
  Logln(float_buf);
}

void Log(int str) {
  sprintf(float_buf, "%d", str);
  Log(float_buf);
}

void Logln(double str){
  dtostrf(str, 5, 3, float_buf);
  Logln(float_buf);
}

void Log(double str){
  dtostrf(str, 5, 3, float_buf);
  Log(float_buf);
}

void Logln(long str){
  sprintf(float_buf, "%d", str);
  Logln(float_buf);
}

void Log(long str){
  sprintf(float_buf, "%d", str);
  Log(float_buf);
}

void Logln(unsigned long str){
  sprintf(float_buf, "%d", str);
  Logln(float_buf);
}

void Log(unsigned long str){
  sprintf(float_buf, "%d", str);
  Log(float_buf);
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

//unsigned int uniqueNumber(){
//  if (EEPROM.read(35) == 255){ 
//    for (int y=0; y<=1; y++){
//      byte uniqueByte;
//      for (int x=0; x<8; x++){
//        bitWrite(uniqueByte, x, bitRead(analogRead(ANA0),0));
//      }
//      EEPROM.write(35+y, uniqueByte);
//    }
//  }
//  return EEPROMReadInt(35);
//}

//void testSD() {
//  switch(sd_card.type()) {
//  case SD_CARD_TYPE_SD1:
//    putstring("SD1\n");
//    break;
//  case SD_CARD_TYPE_SD2:
//    putstring("SD2\n");
//    break;
//  case SD_CARD_TYPE_SDHC:
//    putstring("SDHC\n");
//    break;
//  default:
//    putstring("Unknown\n");
//  }
//  if (!sd_volume.init(sd_card)) {
//    putstring("Could not find FAT16/FAT32 partition.\nMake sure you've formatted the card\n");
//    return;
//  }
//  uint32_t volumesize;
//  putstring("\nVolume type is FAT");
//  Serial.println(sd_volume.fatType(), DEC);
//  Serial.println();
//
//  volumesize = sd_volume.blocksPerCluster();    // clusters are collections of blocks
//  volumesize *= sd_volume.clusterCount();       // we'll have a lot of clusters
//  volumesize *= 512;                            // SD card blocks are always 512 bytes
//  putstring("Volume size (bytes): ");
//  Serial.println(volumesize);
//  putstring("Volume size (Kbytes): ");
//  volumesize /= 1024;
//  Serial.println(volumesize);
//  putstring("Volume size (Mbytes): ");
//  volumesize /= 1024;
//  Serial.println(volumesize);
//  putstring("\nFiles found on the card (name, date and size in bytes): \n");
//  sd_root.openRoot(sd_volume);
//  sd_root.ls(LS_R | LS_DATE | LS_SIZE);  // list all files in the card with date and size
//
//  // print the type of card
//  putstring("#Card type: ");
//  switch(sd_card.type()) {
//  case SD_CARD_TYPE_SD1:
//    putstring("SD1\n");
//    break;
//  case SD_CARD_TYPE_SD2:
//    putstring("SD2\n");
//    break;
//  case SD_CARD_TYPE_SDHC:
//    putstring("SDHC\n");
//    break;
//  default:
//    putstring("Unknown\n");
//  }
//
//  if (!sd_volume.init(sd_card)) {
//    putstring("# Could not find FAT16/FAT32 partition.  Make sure you've formatted the card\n");
//    return;
//  }
//}

//String readSDline(char file_name[13], int line_num = 0){ //pass a filename in the root directory
//  char c;
//  String SD_line = "";
//  //  SD.begin(SS_PIN);
//  int line_count = 0;
//  File file = SD.open(file_name);
//  while((c=file.read())>0 && line_count <= line_num){
//    if (c == '\n'){
//      line_count++;
//    }
//    if (line_count == line_num && c != '\n'){
//      SD_line += c;
//    }
//  }
//  file.close();
//  return SD_line;
//}

//String readSDline(File file, int line_num = 0){ //pass an open file
//  char c;
//  String SD_line = "";
//  int line_count = 0;
//  while((c=file.read())>0 && line_count <= line_num){
//    if (c == '\n'){
//      line_count++;
//    }
//    if (line_count == line_num && c != '\n'){
//      SD_line += c;
//    }
//  }
//  return SD_line;
//}

//void readJSON(String line){
//  //{key:value, key2:[0,1,2,3],{nested_object_key:nested_object_value}}  //allow nested objects??
//  while (open_bracket > close_bracket){
//    ...
//    if (character == "{"){
//      open_bracket++
//    }
//    if (character == "}"){
//      close_bracket++
//    }
//    ...
//  }


//void checkSDconfig(){
//  int line = 0;  
//  if (SD.exists("config.ini")){
//    File config = SD.open("config.ini");
//    config_count = config.size() / sizeof(config_entry);
//    String SD_config_entry[config_count];
//    while (line <= config_count){
//      SD_config_entry[line] = readSDline(config, line);
//      putstring("# ");
//      Serial.println(SD_config_entry[line]);
//      line++;
//    }
//  } else {
//    Serial.println("# config.ini doesn't exist on SD card");
//  }
//}

//config_entry Config2Struct(String config_line){
//  string name
//  config_entry config;
//  name = config_line.substring(0,7);
//  name.toCharArray(config.name, 8)
//  //config.name = name.toArray();
//  config.sensor_num = int(config_line.charAt(9));
//  config.flag = int(config_line.charAt(11));
//  config.show = int(config_line.charAt(13));
//  return config;
//}

//void ConfigSD2Array(char file_name[12] = "config.ini", int line_num = 0){  //loads all configurations saved on SD card to sensor_config array
//  char c;
//  char entry[];
//  //char sensor_config[][][3];
//  int line_count = 0;
//  if(SD.begin() != 0){
//    putstring("Problem loading SD card");
//    break;
//  }
//  file = SD.open(file_name)
//  while((c = file.read())>0){
//    if (c == '\n'){
//      sensor_config[line_count][index] = entry;
//      entry = "";
//      line_count++;
//      index = 0;
//    } else {
//      if (c == ','){
//        sensor_config[line_count][index] = entry;
//        entry = "";
//        index++;
//      } else {
//        entry += c;
//      }
//    }
//  }
//  file.close();
//}



