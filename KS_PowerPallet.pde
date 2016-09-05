// KS_PowerPallet
// Library used to run APL Power Pallet
// Developed for the APL GCU/PCU: http://gekgasifier.pbworks.com/Gasifier-Control-Unit

#include <avr/eeprom.h>
#include <EEPROM.h>         // included with Arduino, can read/writes to non-volatile memory
#include <adc.h>            // part of KSlibs, for reading analog inputs
#include <display.h>        // part of KSlibs, write to display
#include <keypad.h>         // part of KSlibs, read buttons and keypad
#include <pressure.h>       // part of KSlibs, read pressure sensors
#include <temp.h>           // part of KSlibs, read thermocouples
#include <timer.h>          // part of KSlibs, hardware timer functions
#include <util.h>           // part of KSlibs, utility functions, GCU_Setup
#include <avr/io.h>         // advanced: provides port definitions for the microcontroller (ATmega1280, http://www.atmel.com/dyn/resources/prod_documents/doc2549.PDF)
#include <SD.h>             // SD card
#include <avr/pgmspace.h>
#include <string.h>
#include <stdio.h>

#define RELEASE_CYCLE RELEASE_PRODUCTION
#define V_MAJOR "6"
#define V_MINOR "6"
#define V_MAINT "6"
#define V_BUILD "300"
#include "Version.h"

/*
EEPROM bytes used of 4k space:
0-10,  13-21,  33-38,  40-50,
500-999 DISPLAY_CONFIG states
1000-4000 Sensor configuration (not yet implemented)
*/

//PROGMEM string buffer
char p_buffer[41] = "";
// remove excess macro parameter:
#define P(str) (strcpy_P(p_buffer, PSTR(str)))
#define putstring(x) SerialPrint_P(PSTR(x))
#define Log_p(x) Log(P(x))
#define Logln_p(x) Logln(P(x))

int smoothed[8];  //array of smoothed analog signals.
int smoothed_filters[8] = {0, 0, 0, 8, 0, 0, 0, 0};  //filter values for each analog channel
int analog_inputs[] = {ANA0, ANA1, ANA2, ANA3, ANA4, ANA5, ANA6, ANA7};

char serial_num[11] = "#         ";
char unique_number[5] = "#";

#define BUFFER_SIZE 256
int buffer_size = 0;
char string_buffer[BUFFER_SIZE] = "";
char comma[]=", ";
char float_buf[15] = "";

int analog_input[] = {ANA0, ANA1, ANA2, ANA3, ANA4, ANA5, ANA6, ANA7};

// Datalogging variables
int lineCount = 0;

// Loop variables - 0 is longest, 3 is most frequent, place code at different levels in loop() to execute more or less frequently
//TO DO: move loops to hardware timer and interrupt based control, figure out interrupt prioritization

int loopPeriod1 = 1000;
unsigned long nextTime1;
int loopPeriod2 = 100;
unsigned long nextTime2;

//Display
//Display States
#define DISPLAY_SPLASH -1
#define DISPLAY_PRESS 0
#define DISPLAY_TEMP0 1
#define DISPLAY_TEMP1 2
#define DISPLAY_ANA 3
unsigned display_state;
unsigned long display_state_entered;
char buf[21];

// Pressure variables
int Press_Calib[6];
int Press[6]; //values corrected for sensor offset (calibration)

//Serial
char serial_last_input = '\0'; // \0 is the ABSENT character
char serial_buffer[20];

// SD Card
boolean sd_loaded;

//Sd2Card sd_card;
//SdVolume sd_volume;
//SdFile sd_root;
//SdFile sd_file;
char sd_data_file_name[] = "No SD Card  ";  //Create an array that contains the name of our datalog file, updated upon reboot
char sd_log_file_name[] = "No SD Card  ";
//char sd_in_char=0;
//int sd_index=0;

timer_s control_timer;

FILE data_log;

void setup() {
  GCU_Setup(V3,FULLFILL,P777722);
  DDRJ |= 0x80;
  PORTJ |= 0x80;

  // timer initialization
  nextTime1 = millis() + loopPeriod1;
  nextTime2 = millis() + loopPeriod2;

  LoadPressureSensorCalibration();

  Serial.begin(115200);

 //Library initializations
  Disp_Init();
  Kpd_Init();
  ADC_Init();
  Temp_Init();
  Press_Init();
  timer_init();  // Initialize timer system

  Disp_Reset();
  Kpd_Reset();
  ADC_Reset();
  Temp_Reset();
  Press_Reset();

  if(EEPROM.read(35) != 255){
    EEPROMReadAlpha(35, 4, unique_number);
  }
  if(EEPROM.read(40) != 255){
    EEPROMReadAlpha(40, 10, serial_num);
  }

	fdev_setup_stream(&data_log, log_putchar, NULL, _FDEV_SETUP_WRITE);

  InitSD();
  DoDatalogging();

  TransitionDisplay(DISPLAY_SPLASH);

}

void loop() {
	Temp_ReadAll();  // reads into array Temp_Data[], in deg C
	Press_ReadAll(); // reads into array Press_Data[], in hPa
	// the above two Readalls take peak 2.9msec, avg 2.2msec
	DoKeyInput();
	if (millis() >= nextTime2) {
	nextTime2 += loopPeriod2;
	DoDisplay();
	DoHeartBeat(); // blink heartbeat LED
		if (millis() >= nextTime1) {
			nextTime1 += loopPeriod1;
			DoDatalogging(); // No SD card: 27msec peak, 22msec normal. With SD card: 325msec at first, 288msec normal
		}
	}
}

