//void InitSD() {
//  pinMode(SCK_PIN,OUTPUT);
//  pinMode(SS_PIN,OUTPUT);
//  sd_card.init();               //Initialize the SD card and configure the I/O pins.
//  sd_volume.init(card);         //Initialize a volume on the SD card.
//  sd_root.openRoot(volume);     //Open the root directory in the volume. 
//}
//
//void DoDatalogSD() {
//    sd_file.open(sd_root, sd_name, O_CREAT | O_APPEND | O_WRITE);    //Open or create the file 'name' in 'root' for writing to the end of the file.
//    sprintf(sd_contents, "Millis: %d    ", millis());    //Copy the letters 'Millis: ' followed by the integer value of the millis() function into the 'contents' array.
//    sd_file.print(sd_contents);    //Write the 'contents' array to the end of the file.
//    sd_file.close();            //Close the file.
//}

//void checkSDconfig(){
//  char c;
//  String SD_config_entry;
//  
//  SD.begin(); //SD.begin(SCK_PIN)??
//  if (SD.exist("config.txt")){
//    config = SD.open("config.txt");
//    while (c!=-1) {
//    	c = config.read();  
//      while(string.length() < 15){  //each configurations array is 14 characters long  
//        SD_config_entry += c;
//      }
//    config.close();
//    }
//}
