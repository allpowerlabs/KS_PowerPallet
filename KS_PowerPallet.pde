// KS_PowerPallet
// Library used to run APL Power Pallet
// Developed for the APL GCU/PCU: http://gekgasifier.pbworks.com/Gasifier-Control-Unit

#include <avr/eeprom.h>
#include <EEPROM.h>         // included with Arduino, can read/writes to non-volatile memory
#include <adc.h>            // part of KSlibs, for reading analog inputs
#include <display.h>        // part of KSlibs, write to display
#include <keypad.h>         // part of KSlibs, read buttons and keypad
//#include <pressure.h>       // part of KSlibs, read pressure sensors
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

int smoothed[8];  //array of smoothed analog signals.
int smoothed_filters[8] = {0, 0, 0, 8, 0, 0, 0, 0};  //filter values for each analog channel
int analog_inputs[] = {ANA0, ANA1, ANA2, ANA3, ANA4, ANA5, ANA6, ANA7};
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
#define NPRESS (6)
// rough offset in counts
#define OFFSET (-512l)
// result in Pa
#define ADC_UV (4888) // ADC resolution in microvolts
// fine offset in Pa
long Press_Data[NPRESS];
long Press_Calib[NPRESS];
long Press[NPRESS]; //values corrected for sensor offset (calibration)
// uV / Pa
long sensitivity[] = {286, 286, 1000, 1000, 100, 100};

// SD Card
boolean sd_loaded;

char sd_data_file_name[] = "No SD Card  ";  //Create an array that contains the name of our datalog file, updated upon reboot
char sd_log_file_name[] = "No SD Card  ";


#define BUFFER_SIZE 256
int buffer_size = 0;
char string_buffer[BUFFER_SIZE] = "";

FILE data_log;
FILE event_log;
FILE display;

void setup() {
	GCU_Setup(V3,FULLFILL,P777722);
	DDRJ |= 0x80;
	PORTJ |= 0x80;

	// timer initialization
	nextTime1 = millis() + loopPeriod1;
	nextTime2 = millis() + loopPeriod2;

	// Start the logging functions early on
	fdev_setup_stream(&data_log, log_putchar, NULL, _FDEV_SETUP_WRITE);
	fdev_setup_stream(&event_log, log_putchar, NULL, _FDEV_SETUP_WRITE);
	Serial.begin(115200);
	InitSD();

	//Library initializations
	Disp_Init();
	Kpd_Init();
	Disp_Reset();
	Kpd_Reset();
	fdev_setup_stream(&display, disp_putchar, NULL, _FDEV_SETUP_WRITE);
	TransitionDisplay(0);

	ADC_Init();
	ADC_Reset();

	Temp_Init();

	LoadPressureSensorCalibration();
}

void loop() {
	Temp_ReadAll();  // reads into array Temp_Data[], in deg C
	// the above two Readalls take peak 2.9msec, avg 2.2msec
	DoPressure();
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
	switch (Serial.read()) {
		case 'c':
			CalibratePressureSensors();
			break;
		default:
			break;
	}
}

