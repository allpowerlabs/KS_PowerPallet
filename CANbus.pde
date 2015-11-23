///*
//http://arduino.cc/forum/index.php/topic,8730.0.html# 
//http://tucrrc.utulsa.edu/Publications/Arduino/arduino.html
//
//*/
//
////If possible, filter for: 65203 address - .05 L/hour trip fuel rate
//
//#define CS_PIN    72  
//#define INT_PIN   73
//String CAN_buffer = "";
//
//// Create CAN object with pins as defined
//MCP2515 CAN(CS_PIN, INT_PIN);
//
//void initCANbusMCP2515(){
//  Serial.print("Initializing CANbus...");
//  pinMode(CS_PIN,OUTPUT); 
//
//  // Set up SPI Communication
//  // dataMode can be SPI_MODE0 or SPI_MODE3 only for MCP2515
//  SPI.setClockDivider(SPI_CLOCK_DIV2);
//  SPI.setDataMode(SPI_MODE0);
//  SPI.setBitOrder(MSBFIRST);
//  SPI.begin();
//  
//  // Initialise MCP2515 CAN controller at the specified speed and clock frequency
//  // In this case 125kbps with a 16MHz oscillator
//  // (Note:  This is the oscillator attached to the MCP2515, not the Arduino oscillaltor)
//  int baudRate=CAN.Init(125,16);
//  if(baudRate>0) {
//    Logln("MCP2515 Init OK");
//    Serial.print("Baud Rate (kbps): ");
//    Logln(baudRate,DEC);
//  } else {
//    Logln("MCP2515 Init Failed");
//  }
//}
//
//void LogCANbus (){
//  byte i=0;
//  Frame message;
//  message.id = 0;
//  String CAN_buffer = "";
//  
//  if(CAN.Interrupt()) {
//    byte interruptFlags = CAN.Read(CANINTF); // determine which interrupt flags have been set
//    if(interruptFlags & RX0IF) {
//      message = CAN.ReadBuffer(RXB0);  // read from RX buffer 0
//    }
//    if(interruptFlags & RX1IF) {
//      message = CAN.ReadBuffer(RXB1);  // read from RX buffer 1 (this is poor code as clearly if two messages are received then the second will overwrite the first) 
//    }
//    if(interruptFlags & TX0IF) { // TX buffer 0 sent
//    }
//    if(interruptFlags & TX1IF) {  // TX buffer 1 sent
//    }
//    if(interruptFlags & TX2IF) {  // TX buffer 2 sent
//    }
//    if(interruptFlags & ERRIF) {  // error handling code
//    }
//    if(interruptFlags & MERRF) {
//      // error handling code
//      // if TXBnCTRL.TXERR set then transmission error
//      // if message is lost TXBnCTRL.MLOA will be set
//    }
//  }
//  
//  if(message.id>0) {
//    // Print message
//    Serial.print("#ID: ");
//    CAN_buffer += "ID: "
//    Logln(message.id,HEX);
//    CAN_buffer += message.id
//    Serial.print("Extended: ");
//    CAN_buffer += " Extended: "
//    if(message.ide) {
//      Logln("Yes");
//    } else {
//      Logln("No");
//    }
//    Serial.print("DLC: ");
//    Logln(message.dlc,DEC);
//    for(i=0;i<message.dlc;i++) {
//      Serial.print(message.data[i],HEX);
//      Serial.print(" ");
//    }
//    Logln();
//
//    // Send out a return message for each one received
//    // Simply increment message id and data bytes to show proper transmission
//    // Note:  Please see explanation at top of sketch.  You might want to comment this out!
////    message.id++;
////    for(i=0;i<message.dlc;i++) {
////      message.data[i]++;
////    }
////    CAN.LoadBuffer(TXB0, message);
////    CAN.SendBuffer(TXB0);
//  }
//}
//
//
////---------
//
///**MCP2515 CONFIG state: Enables mask configuration etc.*/
//const byte MCP2515_CONFIG =0x80;
///**MCP2515 LISTEN_ONLY state: Receives messages but does not send any*/
//const byte MCP2515_LISTEN =0x60;
///**MCP2515 LOOP state: Enables sending/receiving of messages without using the CAN BUS*/
//const byte MCP2515_LOOP   =0x40;
///**MCP2515 SLEEP state: Reduces power consumption*/
//const byte MCP2515_SLEEP  =0x20;
///**MCP2515 NORMAL state: Participates as a regular node in the CAN network*/
//const byte MCP2515_NORMAL =0x00;
//
///**File name of log file*/
//char fileName[]     = "DATA00.txt";
///**Column headers for logged data*/
//char header[]       = "Msg#,Time Diff, ID,DLC, Data";
///**File objet used to access the SD card*/
//File dataFile;
//
///**Object to interact with the MCP2515 directly*/
//MCP2515 CAN(CS_PIN, INT_PIN);
///** CAN message frame exposed by the MCP2515 RX0 buffer*/
//Frame message0;
///** CAN message frame exposed by the MCP2515 RX1 buffer*/
//Frame message1;
//
//int counter = 0;
//int msgCount =0;
//unsigned long timeLastMessageReceived = 0;
//unsigned long timeDifference =0;
//
//boolean KEEPGOING = true;
//
//String tmpMessage;
//
//boolean DEBUG = true;
//
//boolean initCAN(void)
//{
//  Logln("initCan:entry");  
//  boolean setupSuccess = false;
//  pinMode(CS_PIN,OUTPUT);      
//  
//  // Initialize MCP2515 CAN controller at the specified speed and clock frequency. 
//  // Entering 0 as the first argument  to CAN.init request automatic CAN bus speed detection
//  // In this case 500 kbps
//  int baudRate=CAN.Init(250,16);
//  //Pause for a second
//  delay(1000);
//  if(baudRate>0) 
//  { 
//    //Print current progress
//    Logln("initiCAN: MCP2515 Init OK ...");
//    Serial.print("initCAN: Baud Rate (kbps): ");
//    Logln(baudRate,DEC);
//    delay(1000);
//    
//    //Print CAN bus status
//    if(DEBUG ==true)
//    {
//      Serial.print("initCAN Inital CAN Status: ");
//      displayCanStatus();
//      Logln(" ");
//    }
//    
//    setCanStatus();        
//    setupSuccess = true;
//  } 
//  else 
//  {
//    Logln("MCP2515 Init Failed ...");
//  }   
//  return setupSuccess;
//}
//
///**Modifies several registers that determine which methods will be processed by the receive buffers*/
//void setCanStatus()
//{
//  Logln("setCANStatus:entry");
//  /*
//    // MCP2515 SPI Commands
//        #define CAN_RESET	0xC0
//        #define CAN_READ	0x03
//        #define CAN_WRITE	0x02
//        #define CAN_RTS	   	0x80
//        #define CAN_STATUS	0xA0
//        #define CAN_BIT_MODIFY  0x05
//        #define CAN_RX_STATUS   0xB0
//        #define CAN_READ_BUFFER 0x90
//        #define CAN_LOAD_BUFFER 0X40
//        
//        // Register Bit Masks
//        
//        // CANSTAT
//        #define MODE_CONFIG	0x80
//        #define MODE_LISTEN	0x60
//        #define MODE_LOOPBACK	0x40
//        #define MODE_SLEEP	0x20
//        #define MODE_NORMAL	0x00
//        
//        // CANINTF
//        #define RX0IF		0x01
//        #define RX1IF		0x02
//        #define TX0IF		0x04
//        #define TX1IF		0x08
//        #define TX2IF		0x10
//        #define ERRIF		0x20
//        #define WAKIF		0x40
//        #define MERRF		0x80
//        
//        // Configuration Registers
//        #define CANSTAT	   	0x0E
//        #define CANCTRL	   	0x0F
//        #define BFPCTRL	   	0x0C
//        #define TEC		0x1C
//        #define REC		0x1D
//        #define CNF3		0x28
//        #define CNF2		0x29
//        #define CNF1		0x2A
//        #define CANINTE	   	0x2B
//        #define CANINTF	   	0x2C
//        #define EFLG		0x2D
//        #define TXRTSCTRL	0x0D
//            
//        // RX Buffer 0
//        #define RXB0CTRL	0x60
//        #define RXB0SIDH	0x61
//        #define RXB0SIDL	0x62
//        #define RXB0EID8	0x63
//        #define RXB0EID0	0x64
//        #define RXB0DLC	   	0x65
//        #define RXB0D0	    	0x66
//        #define RXB0D1	    	0x67
//        #define RXB0D2	    	0x68
//        #define RXB0D3	    	0x69
//        #define RXB0D4	    	0x6A
//        #define RXB0D5	    	0x6B
//        #define RXB0D6	    	0x6C
//        #define RXB0D7	    	0x6D
//        
//        // RX Buffer 1
//        #define RXB1CTRL	0x70
//        #define RXB1SIDH	0x71
//        #define RXB1SIDL	0x72
//        #define RXB1EID8	0x73
//        #define RXB1EID0	0x74
//        #define RXB1DLC	   	0x75
//        #define RXB1D0	    	0x76
//        #define RXB1D1	    	0x77
//        #define RXB1D2	    	0x78
//        #define RXB1D3	    	0x79
//        #define RXB1D4	    	0x7A
//        #define RXB1D5	    	0x7B
//        #define RXB1D6	    	0x7C
//        #define RXB1D7	    	0x7D            
//    */
//    
//   //set configuraton mode  
//   int modeset = CAN.Mode(MCP2515_CONFIG);
//   if(DEBUG ==true)
//   {
//     Logln("Changing MCP2515 Registers");
//     Serial.print("Mode set: ");
//     Logln(modeset);
//   }
//    
//
//    //Enable reception of all messages in buffer 0. 
//    byte value= B01100100;
//    CAN.Write(RXB0CTRL, value);
//    if(DEBUG==true)
//    {
//      Serial.print("RXB0CTRL: ");
//      Logln( CAN.Read(RXB0CTRL),BIN);
//    }           
//    
//    //enable reception of all messages in buffer 1
//    value = B01100000;
//    CAN.Write(RXB1CTRL, value);
//    if(DEBUG ==true)
//    {
//      Serial.print("RXB1CTRL: ");
//      Logln( CAN.Read(RXB1CTRL),BIN);
//    }
//    
//    //Set the interrupt enable flags    
//    value = B00000011;
//    byte mask = B11111111;
//    CAN.BitModify(CANINTE,mask, value);
//   
//    //Reset all interrupt flags
//    value = B00000000;
//    CAN.BitModify(CANINTF, mask, value); 
//    
//    //finally set mode to listen only mode
//    modeset = CAN.Mode(MCP2515_LISTEN);
//    if(DEBUG == true)
//    {
//      Serial.print("Mode set: ");
//      Logln(modeset);
//    }
//}
//
//  
///**Initialize SPI communication*/  
//void initSPI(void){
//  Logln("initSPI:entry");
//  SPI.setClockDivider(SPI_CLOCK_DIV2); // dataMode can be SPI_MODE0 or SPI_MODE3 only for MCP2515
//  SPI.setDataMode(SPI_MODE0);
//  SPI.setBitOrder(MSBFIRST);
//  SPI.begin();
//}
//
//
//void displayCanStatus(void){    
//    Logln("displayCANStatus:entry");
//   //Display CAN Status bits
//   /*
//    bit 7 - CANINTF.TX2IF
//    bit 6 - TXB2CNTRL.TXREQ
//    bit 5 - CANINTF.TX1IF
//    bit 4 - TXB1CNTRL.TXREQ
//    bit 3 - CANINTF.TX0IF
//    bit 2 - TXB0CNTRL.TXREQ
//    bit 1 - CANINTF.RX1IF
//    bit 0 - CANINTF.RX0IF         
//   */
//   Serial.print("CAN Status: ");  Logln(CAN.Status(), BIN);
//    
//    //DISPLAY RX status bits  
//    /*
//  bit 7 - CANINTF.RX1IF
//  bit 6 - CANINTF.RX0IF
//  bit 5 -
//  bit 4 - RXBnSIDL.EIDE
//  bit 3 - RXBnDLC.RTR
//  bit 2 | 1 | 0 | Filter Match
//  ------|---|---|-------------
//	0 | 0 | 0 | RXF0
//	0 | 0 | 1 | RXF1
//	0 | 1 | 0 | RXF2
//	0 | 1 | 1 | RXF3
//	1 | 0 | 0 | RXF4
//	1 | 0 | 1 | RXF5
//	1 | 1 | 0 | RXF0 (rollover to RXB1)
//	1 | 1 | 1 | RXF1 (rollover to RXB1)
//  */
//   Serial.print("RX Status: ");   Logln(CAN.RXStatus(), BIN);
//   
//   byte helper = CAN.Read(CANCTRL);  
//   Serial.print("CANTRL: ");    Logln(helper, BIN);
//   
//   helper = CAN.Read(CANSTAT);
//   Serial.print("CANSTAT: ");   Logln(helper, BIN);
//   
//   Logln();
//   helper = CAN.Read(RXB0CTRL);   
//   Serial.print("RXB0CTRL: ");  Logln(helper,BIN);
//   
//   helper= CAN.Read(RXB0SIDL);
//   Serial.print("RFX0SIDL: ");  Logln(helper,BIN);
//   
//   helper= CAN.Read(RXB0EID8);
//   Serial.print("RXB0EID8: ");  Logln(helper,BIN);
//   
//   helper= CAN.Read(RXB0EID0);
//   Serial.print("RXB0EID0: ");  Logln(helper,BIN);
//   Logln();
//   
//   helper = CAN.Read(RXB1CTRL);
//   Serial.print("RXB1CTRL: ");  Logln(helper,BIN);
//     
//   helper= CAN.Read(RXB1SIDL);
//   Serial.print("RXB1SIDL: ");  Logln(helper,BIN);
//   
//   helper= CAN.Read(RXB1EID8);
//   Serial.print("RXB1EID8: ");  Logln(helper,BIN);
//   
//   helper= CAN.Read(RXB1EID0);
//   Serial.print("RXB1EID0: ");  Logln(helper,BIN);
//   Logln();
//      
//   helper = CAN.Read(BFPCTRL);
//   Serial.print("BFPCTRL: ");   Logln(helper,BIN);
//   
//   helper = CAN.Read(CANINTE);
//   Serial.print("CANINTE: ");   Logln(helper,BIN);
//   
//   helper = CAN.Read(CANINTF);
//   Serial.print("CANINTF: ");   Logln(helper,BIN);
//}
//
///**Initializes all components that will be used during the continuous loop*/
//void setup()
//{
//  boolean setupSuccess = true;
//  Serial.begin(9600);
//  Logln("Setup");
//  
//  
//  //spi
//  initSPI();
//  
//  //sd
//  setupSuccess = initSD();
//  
//  //can
//  setupSuccess &= initCAN(); 
// 
//   //
//  
//  if ( setupSuccess == true)
//  {
//    if(DEBUG== true)
//    {
//      displayCanStatus();
//    }    
//    Logln("Beginning to log");
//  }
//   
//  
//}
//
///**Determines the delta time between the last two messages*/
//unsigned long getTimeDifference()
//{
//  //Serial.print("getTime Difference(): ");
//  unsigned long current_time = millis();
//  unsigned long result = current_time - timeLastMessageReceived;
//  if( DEBUG == true )
//  {
//    tmpMessage = String("getTimeDifference(): ");
//    tmpMessage += current_time;
//    tmpMessage += " - ";
//    tmpMessage += timeLastMessageReceived;
//    tmpMessage +=  "=";
//    tmpMessage += result;
//   // Logln( tmpMessage );
//  }  
//  return ( result );
//}
///**Determines whether a set amount of time (wait_time) has expired since a given start_time*/
//boolean hasTimeElapsed( unsigned long start_time, unsigned long wait_time)
//{
//  boolean ret_value = false;
//  unsigned long now = millis();
//  if( now < start_time + wait_time)
//  { 
//    ret_value = false;
//  }
//  else
//  {
//    ret_value = true;
//  }
//  return ret_value;
//}
//
///**Main loop continuously reading CAN messages and writing text representaions to the SD card. Each time a interupt is generated 
//the nessage is extracted and forearded to ``processMessage''
//*/
//void loop()
//{
//   //Find the next available file name to prevent overwriting previously recorded sessions.
//  Serial.print("Checking file name: ");
//  Logln(fileName); 
//  boolean fileExists = SD.exists( fileName );
//  //If the file exists change the name until a new one is created
//  if( fileExists == true )
//  {
//    for (uint8_t i = 0; i < 100; i++) 
//    {
//      fileName[4] = i/10 + '0';
//      fileName[5] = i%10 + '0';
//      Serial.print("Checking file name: ");
//      Logln(fileName);
//      fileExists = SD.exists( fileName );
//      if(fileExists == false )
//      {
//        break;
//      }
//    }
//   }
//   else
//   {
//     //file does not exist yet -> create it
//   }
//    //Open file and get ready to enter data
//  dataFile = SD.open(fileName, FILE_WRITE);
//  //Write the header line
//  dataFile.println(header);
//  dataFile.flush();
//  //Begin the loop to capture CAN messgages
//  byte mask;
//  const byte INTERRUPT_RESET = B00000000;
//  while( KEEPGOING ==true )
//  {
//    //time since last message has been received
//    timeDifference = getTimeDifference();
//    if( DEBUG == true)
//    {
//      tmpMessage = String("loop:timeDifference = ");
//      tmpMessage.concat( timeDifference );
//      Logln( tmpMessage );
//    }
//    /*After a inital message has been received, the program will shutdown afte 10 sec of idle time*/
//    if( ((timeLastMessageReceived!=0)) && ( timeDifference > 10000))
//    {
//      if( DEBUG == true)
//      {
//        tmpMessage = String("Shutting down after idle period\n timeDifferenc = ");
//        tmpMessage.concat( timeDifference );
//        tmpMessage.concat(", timeLastMessageReceived= ");
//        tmpMessage.concat( timeLastMessageReceived );
//        Logln( tmpMessage);
//      }      
//      //Close file
//      dataFile.close();      
//      KEEPGOING = false;
//    }
//    else
//    {
//      //continue
//    }
//   
//    byte interruptFlags = CAN.Read(CANINTF);
//    if( DEBUG == true)
//    {
//      Logln(interruptFlags,BIN);
//      Logln("Done printing interrupt flags");
//      Logln("Waiting for interrrupt");
//    }
//    //Wait a maximum of 10 seconds for the next message
//    unsigned long start_wait_time = millis();
//    while(  (KEEPGOING==true) && (! CAN.Interrupt()) && ( ! hasTimeElapsed(start_wait_time, 10000 )) )
//    {
//      ;
//    }
//    
//    // This implementation utilizes the MCP2515 INT pin to flag received messages
//    if(CAN.Interrupt()) 
//    {      
//      
//      //Message in RX buffer 0
//      if(interruptFlags & RX0IF) 
//      {
//       // Logln("Message on RX Buffer 0");
//        if(DEBUG == true )
//        {	
//          Logln("Message on RX Buffer 0");
//          interruptFlags = CAN.Read(CANINTF);
//          Logln(interruptFlags,BIN);
//        }
//        //Retrieve the new message
//	message0 = CAN.ReadBuffer(RXB0);
//        //Process the message
//        processMessage( message0);
//        //Reset the CANITF flag
//        mask = RX0IF;
//        CAN.BitModify(CANINTF,mask, INTERRUPT_RESET);       
//      }
//      if(interruptFlags & RX1IF) 
//      {
//        //Logln("Message on RX Buffer 1");
//        if(DEBUG == true)
//        {
//         Logln("Message on RX Buffer 1");
//         interruptFlags = CAN.Read(CANINTF);
//         Logln(interruptFlags,BIN);
//        }
//        //Retrieve the new message
//	message1 = CAN.ReadBuffer(RXB1);
//        //Process the message
//        processMessage( message1 );
//        //Reset the CANITF flag
//	mask = RX1IF;
//        CAN.BitModify(CANINTF,mask, INTERRUPT_RESET);
//      }
//      if(interruptFlags & TX0IF) 
//      {
//        // Logln("Sent on TX Buffer 0");
//	// TX buffer 0 sent
//        mask = TX0IF;
//        CAN.BitModify(CANINTF,mask, INTERRUPT_RESET);
//      }
//      if(interruptFlags & TX1IF) 
//      {
//        //Logln("Sent on TX Buffer 1");
//	// TX buffer 1 sent
//        mask = TX1IF;
//        CAN.BitModify(CANINTF,mask, INTERRUPT_RESET);
//      }
//      if(interruptFlags & TX2IF) 
//      {
//        //Logln("Sent on TX Buffer 2");
//	// TX buffer 2 sent
//        mask = TX2IF;
//        CAN.BitModify(CANINTF,mask, INTERRUPT_RESET);
//      }
//      if(interruptFlags & ERRIF) 
//      {
//        //Logln("Error encountered");
//	// error handling code
//        mask = ERRIF;
//        CAN.BitModify(CANINTF,mask, INTERRUPT_RESET);
//      }
//      if(interruptFlags & MERRF) 
//      {
//        //Logln("Error encountered 2");
//        mask = MERRF;
//        CAN.BitModify(CANINTF,mask, INTERRUPT_RESET);
//	// error handling code
//	// if TXBnCTRL.TXERR set then transmission error
//	// if message is lost TXBnCTRL.MLOA will be set
//      }
//    }
//  }  // end while loop 
//  Logln("Program complete!");
//  Logln("Waiting for reset......");
//  while( true )
//  {
//    //do nothing
//    ;
//  }
//}
//
///**Extracts the components from received messsage and writes them to file. This method has a considerable performance impact 
//and is for illustration purposes only. Speedup can be achieved by ensuring the maximum amount of data (e.g. 512 byte ) is written each time ``print'' is called. 
//*/
//void processMessage( Frame& message )
//{
//    //current time 
//    timeLastMessageReceived = millis();
//    if(DEBUG == true)
//    {
//      Serial.print("Assigning= ");
//      Logln(timeLastMessageReceived);
//    }   
//   
//    if(message.id>0) 
//    { 
//      if(DEBUG == true)
//      {      
//        Logln(message.id,HEX);
//      }
//      dataFile.print(msgCount++, DEC);
//      dataFile.print(",");
//      dataFile.print(getTimeDifference(),DEC);
//      dataFile.print(",");
//      dataFile.print(message.id,HEX);
//      dataFile.print(",");
//      dataFile.print(message.dlc,DEC);  
//      dataFile.print(",");        
//      for(int i=0;i<message.dlc;i++) 
//      {	
//        dataFile.print(message.data[i],HEX);
//        dataFile.print(" ");
//      }
//      
//      dataFile.println();     
//      //flush for illustration purpose only
//      dataFile.flush();
//  }
//}  
//
//
//
//
//

