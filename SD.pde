////void InitSD() {
////  pinMode(SCK_PIN,OUTPUT);
////  pinMode(SS_PIN,OUTPUT);
////  sd_card.init();               //Initialize the SD card and configure the I/O pins.
////  sd_volume.init(card);         //Initialize a volume on the SD card.
////  sd_root.openRoot(volume);     //Open the root directory in the volume. 
////}
//
//void DoDatalogSD(String data) {
//    sd_file.open("data_log.txt", O_APPEND); //sd_file.open(sd_root, sd_name, O_CREAT | O_APPEND | O_WRITE);    //Open or create the file 'name' in 'root' for writing to the end of the file.
//    sd_file.print(data);    //Write the 'contents' array to the end of the file.
//    sd_file.close();            //Close the file.
//}
//
//void checkSDconfig(){
//  char c;
//  String SD_config_entry;  
//  SD.begin();      //SD.begin(SCK_PIN)??
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
//
//typedef struct{
//  char name[8];
//  int sensor_num;
//  int flag;
//  int show;
//} config_entry;
//
//config_entry config[config_num];
//
//String readSDline(char file_name, int line_num){
//  char c;
//  String SD_line = "";
//  SD.begin();
//  int line_count = 0;
//  file = SD.open(file_name)
//  while((c=file.read())>0 && line_count<=line_num){
//    if (c == '/n'){
//      line_count++;
//    }
//    if (line_count == line_num && c != '\n'){
//      SD_line += c;
//    }
//  }
//  file.close();
//  return SD_line;
//}
//
//void ConfigSD2Array(char file_name[], int line_num){  //loads all configurations saved on SD card to sensor_config array
//  char c;
//  char entry[];
//  //char sensor_config[][][3];
//  int line_count = 0;
//  if(SD.begin() != 0){
//    Serial.print("Problem loading SD card");
//    break;
//  }
//  file = SD.open(file_name)
//  while((c = file.read())>0){
//    if (c == '/n'){
//      line_count++;
//      index = 0;
//    } else {
//      if (c == ','){
//        //sensor_config[line_count][index] = entry;
//        sensor
//        entry = "";
//        index++;
//      } else {
//        entry += c;
//      }
//    }
//  }
//  file.close();
//}  
//    
