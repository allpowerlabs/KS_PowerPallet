// KS_PowerPallet
// Library used to run APL Power Pallet
// Developed for the APL GCU/PCU: http://gekgasifier.pbworks.com/Gasifier-Control-Unit

#include <avr/eeprom.h>
#include <EEPROM.h>         // included with Arduino, can read/writes to non-volatile memory
#include <Servo.h>          // Arduino's native servo library
#include <PID_Beta6.h>      // http://www.arduino.cc/playground/Code/PIDLibrary, http://en.wikipedia.org/wiki/PID_controller
#include <adc.h>            // part of KSlibs, for reading analog inputs
#include <display.h>        // part of KSlibs, write to display
#include <fet.h>            // part of KSlibs, control FETs (field effect transistor) to drive motors, solenoids, etc
#include <keypad.h>         // part of KSlibs, read buttons and keypad
#include <pressure.h>       // part of KSlibs, read pressure sensors
#include <servos.h>         // part of KSlibs
#include <temp.h>           // part of KSlibs, read thermocouples
#include <timer.h>          // part of KSlibs, hardware timer functions
#include <util.h>           // part of KSlibs, utility functions, GCU_Setup
#include <intmath.h>		// part of KSlibs, integer math convenience functions
#include <vnh_bridge.h>		// part of KSlibs, VNHxxx H-bridge driver
#include <avr/io.h>         // advanced: provides port definitions for the microcontroller (ATmega1280, http://www.atmel.com/dyn/resources/prod_documents/doc2549.PDF)
#include <SD.h>             // SD card
#include <avr/pgmspace.h>
#include <string.h>
#include <ModbusSlave.h>
//#include <MCP2515.h>
//#include <SPI.h>
#include "Config.h"
#include "Modes.h"
#include "Alarm.h"
#include "AshAuger.h"		// Ash auger typedefs.
#include "Auger.h"

#define RELEASE_CYCLE RELEASE_DEVELOPMENT
#define V_MAJOR "1"
#define V_MINOR "3"
#define V_MAINT "4"
#define V_BUILD "001"
#include "Version.h"

/*
EEPROM bytes used of 4k space:
0-10,  13-21,  33-38,  40-50,
500-999 DISPLAY_CONFIG states
1000-4000 Sensor configuration (not yet implemented)
*/

//constant definitions
#define ABSENT -500

//PROGMEM string buffer
char p_buffer[41] = "";
// remove excess macro parameter:
#define P(str) (strcpy_P(p_buffer, PSTR(str)))
#define putstring(x) SerialPrint_P(PSTR(x))
#define Log_p(x) Log(P(x))
#define Logln_p(x) Logln(P(x))

const char co_product[] PROGMEM = "# http:\\\\AllPowerlabs.org  Power Pallet ";
const char help[] PROGMEM = {
  "#All Power Labs Power Pallet Serial Help:\r\n"
  "# ?: device info\r\n"
  "# #: Serial Number (follow with number if changing)\r\n"
  "# !: Rewrite specified EEPROM space (give number followed by ';')\r\n"
  "# p: add 0.02 to p\r\n"
  "# P: subtract 0.02 from p\r\n"
  "# i: add 0.02 to i\r\n"
  "# I: subtract 0.02 from i\r\n"
  "# dD: reserved for d in PID (not implemented)\r\n"
  "# c: Calibrate Pressure Sensors\r\n"
  "# s: add 10 to Servo1 calibration\r\n"
  "# S: subtract 10 from Servo1 position\r\n"
  "# l: increase lambda_setpoint\r\n"
  "# L: decrease lambda_setpoint\r\n"
  "# t: subtract 100 ms from Sample Period (loopPeriod1)\r\n"
  "# T: add 100 ms from Sample Period (loopPeriod1)\r\n"
  "# g: Shake grate\r\n"
  "# G: Switch Grate Shaker mode (Off/On/Pressure Ratio)\r\n"
  "# hH: Print Help Text\r\n" };

// Analog Input Mapping
#define ANA_LAMBDA ANA0
#define ANA_FUEL_SWITCH ANA1
#define ANA_ENGINE_SWITCH ANA2
#define ANA_CONDENSATE_LEVEL ANA3
#define ANA_AUGER_CURRENT ANA4  //sense current in auger motor
#define ANA_THROTTLE_POS ANA5
#define ANA_CONDENSATE_PRESSURE ANA6

int smoothed[8];  //array of smoothed analog signals.
int smoothed_filters[8] = {0, 0, 0, 8, 0, 0, 0, 0};  //filter values for each analog channel
int analog_inputs[] = {ANA0, ANA1, ANA2, ANA3, ANA4, ANA5, ANA6, ANA7};

// FET Mappings
#define FET_AUGER FET0
#define FET_RUN_ENABLE FET1
#define FET_CONDENSATE_PUMP FET2
#define FET_CONDENSATE_FAN FET3
#define FET_FLARE_IGNITOR FET4
#define FET_O2_RESET FET5
#define FET_ALARM FET6
#define FET_AUGER_REV FET7

//Servo Mapping
//TODO: Use these define
#define SERVO_MIXTURE SERVO0
//#define SERVO_CALIB SERVO1
//#define SERVO_THROTTLE SERVO2

Servo Servo_Mixture;
//Servo Servo_Calib;
//Servo Servo_Throttle;

//Thermocouple Mappings
#define T_TRED 0
#define T_BRED 1
#define T_ENG_COOLANT 2
#define T_REACTOR_GAS_OUT 3
#define T_PYRO_IN 4
#define T_PYRO_OUT 5
#define T_COMB ABSENT
#define T_DRYING_GAS_OUT 6
#define T_FILTER 7
#define T_LOW_FUEL ABSENT

//Pressure Mapping
#define P_REACTOR 0
#define P_FILTER 1
#define P_COMB 2
#define P_Q_AIR_ENG 3
#define P_Q_AIR_RCT 4
#define P_Q_GAS_ENG 5

//Interrupt Mapping
// 2 - pin 21 - PD0
// 3 - pin 20 - PD1
// 4 - pin 19 - PD2
// 5 - pin 18 - PD3
//#define INT_HERTZ 5 //interrupt number (not pin number)
//#define INT_ENERGY_PULSE 4

//Control States
//TODO: Use these for auto-start/shutdown sequence (e.g. equivalent to a backup generator command)
#define CONTROL_OFF 0
#define CONTROL_START 1
#define CONTROL_ON 2

//Engine States
#define ENGINE_OFF 0
#define ENGINE_ON 1
#define ENGINE_STARTING 2
#define ENGINE_SHUTDOWN 3

//Condensate Recirculation States
#define CONDENSATE_RECIRC_OFF 0
#define CONDENSATE_RECIRC_NORMAL 1
#define CONDENSATE_RECIRC_HIGH 2

#define CONDENSATE_LEVEL_NORMAL 0
#define CONDENSATE_LEVEL_HIGH 1

//Lambda
#define LAMBDA_SIGNAL_CHECK TRUE
#define LAMBDA_SETPOINT_ADJUSTMENT (0.0025)
#define LAMBDA_SETPOINT_DEFAULT (1.05)

//Flare States
#define FLARE_OFF 0
#define FLARE_USER_SET 1
#define FLARE_LOW 2
#define FLARE_HIGH 3
#define FLARE_MAX 4

//Lambda States
#define LAMBDA_CLOSEDLOOP 0
#define LAMBDA_SEALED 1
#define LAMBDA_STEPTEST 2
#define LAMBDA_SPSTEPTEST 3
#define LAMBDA_LAMBDA_NO_SIGNAL 4
#define LAMBDA_NO_SIGNAL 5
#define LAMBDA_RESET 6
#define LAMBDA_RESTART 7
#define LAMBDA_UNKNOWN 8
#define LAMBDA_SHUTDOWN 9
#define LAMBDA_STARTING 10

//Display States
#define DISPLAY_SPLASH 0
#define DISPLAY_REACTOR 1
#define DISPLAY_LAMBDA 2
#define DISPLAY_GRATE 3
#define DISPLAY_INFO 4
#define DISPLAY_SERVO 5
#define DISPLAY_CALIBRATE_PRESSURE 6
#define DISPLAY_CONFIG 7
#define DISPLAY_RELAY 8
#define DISPLAY_ANA 9
#define DISPLAY_ALARM 999

const char menu1[] PROGMEM = "NEXT  ADV   +    -  ";
const char blank[] PROGMEM = "                    ";
const char new_engine_state[] PROGMEM = "New Engine State: ";
const char engine_shutdown[] PROGMEM = ", Engine Shutdown.";
const char new_auger_state[] PROGMEM = "New Auger State: ";
const char half_blank[] PROGMEM = "          ";
char choice[5];
char buf[22] = "";

char serial_num[11] = "#         ";
char unique_number[5] = "#";

//Testing States
#define TESTING_OFF 0
#define TESTING_FUEL_AUGER 1
#define TESTING_RUN_ENABLE 2
#define TESTING_CONDENSATE_PUMP 3
#define TESTING_CONDENSATE_FAN 4
#define TESTING_FLARE_IGNITOR 5
#define TESTING_O2_RESET 6
#define TESTING_ALARM 7
#define TESTING_FUEL_REV 8
#define TESTING_ANA_LAMBDA 9
#define TESTING_ANA_ENGINE_SWITCH 10
#define TESTING_ANA_FUEL_SWITCH 11
#define TESTING_ANA_CONDENSATE_PRESSURE 12
#define TESTING_SERVO 13     //used in Display to defeat any other writes to servo.  Must be last testing state!!!


#define BUFFER_SIZE 128
int buffer_size = 0;
char string_buffer[BUFFER_SIZE] = "";
char comma[]=", ";
char float_buf[15] = "";

//Test Variables
int testing_state = TESTING_OFF;
unsigned long testing_state_entered = 0;
int analog_input[] = {ANA0, ANA1, ANA2, ANA3, ANA4, ANA5, ANA6, ANA7};

//const char testing_state_0[] PROGMEM = "Off";
const char testing_state_1[] PROGMEM = "FET0 Feed Auger Fwd";
const char testing_state_2[] PROGMEM = "FET1 Run Enable";
const char testing_state_3[] PROGMEM = "FET2 Condensate Pump";
const char testing_state_4[] PROGMEM = "FET3 Condensate Fan";
const char testing_state_5[] PROGMEM = "FET4 Flare";
const char testing_state_6[] PROGMEM = "FET5 O2 Reset";
const char testing_state_7[] PROGMEM = "FET6 Alarm";
const char testing_state_8[] PROGMEM = "FET7 Feed Auger Rev";

const char testing_state_9[] PROGMEM =  "Lambda";
const char testing_state_10[] PROGMEM = "Feed Switch";
const char testing_state_11[] PROGMEM = "Eng Switch";
const char testing_state_12[] PROGMEM = "Condensate Level";
const char testing_state_13[] PROGMEM = "Feed Auger Current";
const char testing_state_14[] PROGMEM = "Throttle Pos";
const char testing_state_15[] PROGMEM = "Condensate Pressure";
const char testing_state_16[] PROGMEM = "Ash Auger Current";

const char * const TestingStateName[] PROGMEM = {testing_state_1, testing_state_2, testing_state_3, testing_state_4, testing_state_5, testing_state_6, testing_state_7, testing_state_8, testing_state_9, testing_state_10, testing_state_11, testing_state_12, testing_state_13, testing_state_14, testing_state_15, testing_state_16};

// Datalogging variables
int lineCount = 0;

const char config_0[] PROGMEM = "Reset Defaults?";
const char config_1[] PROGMEM = "Engine Type    ";
const char config_2[] PROGMEM = "RESERVED        ";
const char config_3[] PROGMEM = "Auger Rev (.1s)";
const char config_4[] PROGMEM = "Auger Low (.1A)";
const char config_5[] PROGMEM = "Auger High(.1A)";
const char config_6[] PROGMEM = "RESERVED        ";
const char config_7[] PROGMEM = "Datalog SD card";
const char config_8[] PROGMEM = "Pratio Accum#  ";
const char config_9[] PROGMEM = "High Coolant T ";
const char config_10[] PROGMEM = "Display Per .1s";
const char config_11[] PROGMEM = "Trst low temp? ";
const char config_12[] PROGMEM = "Trst High Temp ";
const char config_13[] PROGMEM = "Tred High Temp ";
const char config_14[] PROGMEM = "Pfilter Accum# ";
const char config_15[] PROGMEM = "Grate Max Inter";
const char config_16[] PROGMEM = "Grate Min Inter";
const char config_17[] PROGMEM = "Grate Shake .1s";
const char config_18[] PROGMEM = "Servo Start Pos";
const char config_19[] PROGMEM = "Lambda Rich    ";
const char config_20[] PROGMEM = "Modbus Enabled?";  //Set to Modbus baud of zero and remove this configuration?
const char config_21[] PROGMEM = "Modbus Baud    ";  //0:2400, 1:4800, 2:9600, 3:19200, 4:38400, 5:57600, 6:115200
const char config_22[] PROGMEM = "Modbus Parity  ";  //0:None, 1:Odd, 2:Even
const char config_23[] PROGMEM = "Modbus Address ";  //1-127
const char config_24[] PROGMEM = "RESERVED       ";
const char config_25[] PROGMEM = "Pratio Low     ";
const char config_26[] PROGMEM = "Trst Warn Temp ";
const char config_27[] PROGMEM = "Pratio High    ";
const char config_28[] PROGMEM = "Ash Aug Low (A)";
const char config_29[] PROGMEM = "Ash Aug High(A)";
const char config_30[] PROGMEM = "Ash Aug Max (A)";
const char config_31[] PROGMEM = "Ash Aug Period ";
const char config_32[] PROGMEM = "Grate Rev Time ";
const char config_33[] PROGMEM = "Grate Power    ";
const char config_34[] PROGMEM = "Fuel Sw Delay  ";

const char plus_minus[] PROGMEM = "+    -  ";
const char no_yes[] PROGMEM = "NO  YES ";
const char ten_twenty_k[] PROGMEM = "10k 20k ";
const char plus_minus_five[] PROGMEM = "+5  -5  ";
const char reserved[] PROGMEM = "Reserved";

//Configuration Variables
#define CONFIG_COUNT 35
int config_var;
byte config_changed = false;

// Configurables - Label, choices, min, max, def
configurable Config[] = {
	{config_0, no_yes, 0, 254, 0},				// Reset values to default
	{config_1, reserved, 0, 254, 0},			// RESERVED - Engine type
	{config_2, reserved, 0, 254, 1},			// RESERVED - Relay board
	{config_3, plus_minus, 0, 254, 5},			// Auger Reverse Time
	{config_4, plus_minus, 0, 40, 35},			// Auger Low Current
	{config_5, plus_minus, 41, 135, 100},		// Auger High Current
	{config_6, reserved, 1, 10, 6},				// RESERVED - Oil Low Pressure
	{config_7, no_yes, 0, 254, 1},				// Data Log to SD Card
	{config_8, reserved, 0, 15, 10},			// RESERVED - Pratio Accum Max
	{config_9, plus_minus, 10, 254, 98},		// Coolant High Temperature
	{config_10, reserved, 0, 199, 10},			// RESERVED - Display Changes Per Second
	{config_11, plus_minus_five, 0, 254, 135},	// T_RST Low Temperature
	{config_12, plus_minus_five, 0, 254, 210},	// T_RST High Temperature
	{config_13, plus_minus_five, 20, 254, 195},	// T_RED High Temperature
	{config_14, reserved, 0, 254, 50},			// RESERVED - P_Filter High
	{config_15, plus_minus_five, 2, 254, 60},	// Grate Max Interval
	{config_16, plus_minus_five, 0, 254, 12},	// Grate Min Interval
	{config_17, plus_minus, 1, 254, 20},		// Grate Shake Time
	{config_18, plus_minus, 0, 90, 30},			// Servo Start Position
	{config_19, reserved, 0, 150, 140},			// Lambda Rich
	{config_20, no_yes, 0, 1, 0},				// Modbus Enable
	{config_21, plus_minus, 0, 6, 3},			// Modbus Baud
	{config_22, plus_minus, 0, 3, 0},			// Modbus Parity
	{config_23, plus_minus, 0, 127, 1},			// Modbus Address
	{config_24, reserved, 0, 254, 0},			// RESERVED - Grid-Tie Enable
	{config_25, plus_minus, 0, 100, 30},		// Pratio Low
	{config_26, plus_minus_five, 0, 254, 150},	// T_RST Warn Temperature
	{config_27, reserved, 0, 100, 60},			// P_ratio High
	{config_28, plus_minus, 0, 254, 50},		// Ash Auger Low Current
	{config_29, plus_minus, 30, 254, 130},		// Ash Auger High Current
	{config_30, plus_minus, 50, 254, 150},		// Ash Auger Limit Current
	{config_31, plus_minus_five, 0, 254, 40},	// Ash Auger Period
	{config_32, reserved, 1, 254, 30},			// Grate Reverse Time
	{config_33, reserved, 1, 100, 100},			// Grate % Duty Cycle
	{config_34, plus_minus, 1, 60, 30},			// Fuel Switch Delay
	{0, 0, 0, 0, 0}								// NULL terminator
};

//Don't forget to add the following to update_config_var in Display!  The first Configuration, Reset Defaults, is skipped, so these start at 1, not 0.
//int engine_type = getConfig(1);
//int relay_board = getConfig(2);
int aug_rev_time = getConfig(3)*100;
//int current_low_boundary = getConfig(4);
//int current_high_boundary = getConfig(5);
int low_oil_psi = getConfig(6);
int save_datalog_to_sd = getConfig(7);
//int pratio_max = getConfig(8)*5;
int high_coolant_temp = getConfig(9);
//int display_per = getConfig(10);
int tred_low_temp = getConfig(11)*5;
int ttred_high = getConfig(12)*5;
int tbred_high = getConfig(13)*5;
//int pfilter_alarm = getConfig(14);
//int grate_max_interval = getConfig(15)*5;  //longest total interval in seconds
//int grate_min_interval = getConfig(16)*5;
//int grate_on_interval = getConfig(17);
int servo_start = getConfig(18);
//int lambda_rich = getConfig(19);
int use_modbus = getConfig(20);
int m_baud = getConfig(21);
int m_parity = getConfig(22);
int m_address = getConfig(23);
int grid_tie = getConfig(24);
int pratio_low_boundary = getConfig(25);
int ttred_warn = getConfig(26)*5;
//int pratio_high_boundary = getConfig(27);

// Reactor pressure ratio
float pRatioReactor;
enum pRatioReactorLevels { PR_HIGH = 0, PR_CORRECT = 1, PR_LOW = 2} pRatioReactorLevel;
static char *pRatioReactorLevelName[] = { "High", "Correct", "Low" };
float pratio_low = pratio_low_boundary/100.0;
float pratio_high = 0.6; // 	pratio_high_boundary/100.0;
float pRatioReactorLevelBoundary[3][2] = { { pratio_high, 1.0 }, { pratio_low, pratio_high }, {0.0, pratio_low} };

// Filter pressure ratio
float pRatioFilter;
boolean pRatioFilterHigh;
int filter_pratio_accumulator;

// Condensate Recirculation
int condensate_recirc_state;
unsigned long condensate_recirc_state_entered;
int condensate_level;
int condensate_recirc_pressure;
#define CONDENSATE_RECIRC_PRESSURE_LOW (15)
#define CONDENSATE_RECIRC_PRESSURE_HIGH (80)
#define ADC_TO_RECIRC_PRESSURE(p) (p)

// Temperature Levels
#define TEMP_LEVEL_COUNT 5
enum TempLevels { COLD = 0,COOL = 1,WARM = 2 ,HOT = 3, EXCESSIVE = 4} TempLevel;
TempLevels T_tredLevel;
static char *TempLevelName[] = { "Cold", "Cool", "Warm", "Hot ", "TooHot" };
int T_tredLevelBoundary[TEMP_LEVEL_COUNT][2] = { { 0, 40 }, {50, 80}, {300,790}, {800,950}, {1000,1250} };

TempLevels T_bredLevel;
int T_bredLevelBoundary[TEMP_LEVEL_COUNT][2] = { { 0, 40 }, {50, 80}, {300,740}, {750,900}, {950,1250} };

//Pressure Levels
#define P_REACTOR_LEVEL_COUNT 4
enum P_reactorLevels { OFF = 0, LITE = 1, MEDIUM = 2 , EXTREME = 3} P_reactorLevel;
static char *P_reactorLevelName[] = { "Off", "Low", "Medium", "High"};
int P_reactorLevelBoundary[4][2] = { { -100, 4000 }, {-500, -200}, {-2000,-750}, {-4000,-2000} };

// Loop variables - 0 is longest, 3 is most frequent, place code at different levels in loop() to execute more or less frequently
//TO DO: move loops to hardware timer and interrupt based control, figure out interrupt prioritization

int loopPeriod1 = 1000;
unsigned long nextTime1;
int loopPeriod2 = 100;
unsigned long nextTime2;

//Control
int control_state = CONTROL_OFF;
unsigned long control_state_entered;

////Flare
int flare_state = FLARE_USER_SET;
boolean ignitor_on;
//int blower_dial = 0;
//double blower_setpoint;
//double blower_input;
//double blower_output;
//double blower_value;
//double blower_P[1] = {2}; //Adjust P_Param to get more aggressive or conservative control, change sign if moving in the wrong direction
//double blower_I[1] = {.2}; //Make I_Param about the same as your manual response time (in Seconds)/4
//double blower_D[1] = {0.0}; //Unless you know what it's for, don't use D
//PID blower_PID(&blower_input, &blower_output, &blower_setpoint,blower_P[0],blower_I[0],blower_D[0]);

//Engine
int engine_state = ENGINE_OFF;
unsigned long engine_state_entered;

//Display
int display_state = DISPLAY_SPLASH;
unsigned long display_state_entered;
unsigned long transition_entered;
//String transition_message;
int item_count,cur_item;

//Keypad
int key = -1;


byte servo_min,servo_max;
double premix_valve_open = 95;
double premix_valve_closed = 5;


double premix_valve_max = 1.0;  //minimum of range for closed loop operation (percent open)
double premix_valve_min = 0.00; //maximum of range for closed loop operation (percent open)
double premix_valve_center = (double) servo_start/100; //initial value when entering closed loop operation (percent open)
double lambda_setpoint = LAMBDA_SETPOINT_DEFAULT;
double lambda_input;
double lambda_output;
double lambda_value;
double lambda_P[1] = {0.13}; //Adjust P_Param to get more aggressive or conservative control, change sign if moving in the wrong direction
double lambda_I[1] = {1.0}; //Make I_Param about the same as your manual response time (in Seconds)/4
double lambda_D[1] = {0.0}; //Unless you know what it's for, don't use D
PID lambda_PID(&lambda_input, &lambda_output, &lambda_setpoint, lambda_P[0], lambda_I[0], lambda_D[0]);
unsigned long lamba_updated_time;
boolean write_lambda = false;
char lambda_state_name[40] = "Unknown";
int lambda_state = LAMBDA_SEALED;
unsigned long lambda_state_entered;
float smooth_filter_Lambda = .75;
int smoothedLambda;

// Pressure variables
int Press_Calib[6];
int Press[6]; //values corrected for sensor offset (calibration)

//// Flow variables
//float CfA0_air_rct = 0.6555;
//float CfA0_air_eng = 0.6555;
//float CfA0_gas_eng = 4.13698;
//double air_eng_flow;
//double air_rct_flow;
//double gas_eng_flow;
//boolean flow_active; // are any flowmeters hooked up?

//Servos
//int servo_alt = 0; //used to pulse every other time through loop (~20 ms)

//Servo0
//float servo0_pos = 0;
//float servo0_db = 0; // used to deadband the servo movement

////Servo1
//float servo1_pos;
//float servo1_db = 0; // used to deadband the servo movement
//
////Servo2
//float servo2_pos;
//float servo2_db = 0; // used to deadband the servo movement


//Serial
char serial_last_input = '\0'; // \0 is the ABSENT character
char serial_buffer[20];

////Relay Muliplexer  Still to be implemented
//byte shiftRegister = 0;  //Holder for all 8 relay states (8 bits, initialized to B00000000, all relays off)
//int dataPin = 50;  //To SRIN on Relay Board, Bottom Right Pin on Relay Board when XR IN at top.
//int latchPin = 51; //To RCK on Relay Board, Second Pin from Bottom on Right hand side
//int clockPin = 52; //To SRCLK on Relay Board, Second Pin from Bottom on Left hand side
//

int pressureRatioAccumulator = 0;

// Alarms
unsigned char annoying; // State of the annunciator

const char alarm_0[] PROGMEM = "Auger on too long   ";
const char alarm_1[] PROGMEM = "Auger off too long  ";
const char alarm_2[] PROGMEM = "Bad Reactor P_ratio ";
const char alarm_3[] PROGMEM = "Bad Filter P_ratio  ";
const char alarm_4[] PROGMEM = "Reactor Fuel Low    ";
const char alarm_5[] PROGMEM = "Trst low for engine ";
const char alarm_6[] PROGMEM = "Tred high for engine";
const char alarm_7[] PROGMEM = "RESERVED            ";
const char alarm_8[] PROGMEM = "No O2 Sensor Signal ";
const char alarm_9[] PROGMEM = "Auger Low Current   ";
const char alarm_10[] PROGMEM = "FuelSwitch/Auger Jam";
const char alarm_11[] PROGMEM = "High P_comb         ";
const char alarm_12[] PROGMEM = "High Coolant Temp   ";
const char alarm_13[] PROGMEM = "Reduction Temp Low  ";
const char alarm_14[] PROGMEM = "Restriction Temp High ";
const char alarm_15[] PROGMEM = "Reduction Temp High ";
const char alarm_16[] PROGMEM = "Grate Motor Fault   ";
const char alarm_17[] PROGMEM = "Ash Auger Stuck     ";
const char alarm_18[] PROGMEM = "Ash Auger Fault     ";

//line 2 on display.  If shutdown[] is greater than zero, countdown will be added to last 3 spaces.
const char alarm2_0[] PROGMEM = "Check Fuel          ";
const char alarm2_1[] PROGMEM = "Bridging?           ";
const char alarm2_2[] PROGMEM = "Reactor Fuel Issue  ";
const char alarm2_3[] PROGMEM = "Check Filter        ";
const char alarm2_4[] PROGMEM = "Check Auger/Fuel    ";  //Not implemented!!
const char alarm2_5[] PROGMEM = "Increase Load       ";
const char alarm2_6[] PROGMEM = "Low Fuel in Reactor?";
const char alarm2_9[] PROGMEM = "Check Fuel          ";
const char alarm2_10[] PROGMEM = "Check Fuel & Switch ";
const char alarm2_11[] PROGMEM = "Check Air Intake    ";
const char alarm2_14[] PROGMEM = "Reduce Load         ";
const char alarm2_15[] PROGMEM = "Reduce Load         ";

const char message_filter_condesate[] PROGMEM = "Filter Condensate   ";
const char message_pump_low[] PROGMEM = "Pump Pressure Low   ";
const char message_pump_high[] PROGMEM = "Pump Pressure High  ";
const char message_level_high[] PROGMEM = "Level High          ";
const char message_level_low[] PROGMEM = "Level Low           ";

struct alarm ALARM_AUGER_ON_LONG = {
	alarm_0, // message line 1
	alarm2_0, // message line 2
	AugerReset, // reset function (or NULL)
	240000, // Warning delay time
	360000, // Shutdown delay time
	0, 0, 0, 0 // On time, Silenced, Prev Alarm, Next Alarm (initialize these to 0)
};
struct alarm ALARM_AUGER_OFF_LONG = {
	alarm_1,
	alarm2_1,
	AugerReset,
	480000,
	600000,
	0, 0, 0, 0
};
struct alarm ALARM_BAD_REACTOR = {
	alarm_2,
	alarm2_2,
	NULL,
	10,
	0,
	0, 0, 0, 0
};
struct alarm ALARM_LOW_FUEL_REACTOR = {
	alarm_4,
	alarm2_4,
	NULL,
	230,
	0,
	0, 0, 0, 0
};
struct alarm ALARM_LOW_TRED = {
	alarm_5,
	alarm2_5,
	NULL,
	120000,
	0,
	0, 0, 0, 0
};
struct alarm ALARM_HIGH_BRED = {
	alarm_6,
	alarm2_6,
	NULL,
	0,
	60000,
	0, 0, 0, 0
};
struct alarm ALARM_O2_NO_SIG = {
	alarm_8,
	NULL,
	NULL,
	30000,
	0,
	0, 0, 0, 0
};
struct alarm ALARM_AUGER_LOW_CURRENT = {
	alarm_9,
	alarm2_9,
	AugerReset,
	60000,
	180000,
	0, 0, 0, 0
};
struct alarm ALARM_BOUND_AUGER = {
	alarm_10,
	alarm2_10,
	AugerReset,
	10,
	20,
	0, 0, 0, 0
};
struct alarm ALARM_HIGH_COOLANT_TEMP = {
	alarm_12,
	NULL,
	NULL,
	0,
	3000,
	0, 0, 0, 0
};
struct alarm ALARM_HIGH_PCOMB = {
	alarm_11,
	alarm2_11,
	NULL,
	0,
	0,
	0, 0, 0, 0
};
struct alarm ALARM_TRED_LOW = {
	alarm_13,
	NULL,
	NULL,
	0,
	180000,
	0, 0, 0, 0
};
struct alarm ALARM_TTRED_HIGH = {
	alarm_14,
	alarm2_14,
	NULL,
	15000,
	15000,
	0, 0, 0, 0
};
struct alarm ALARM_TBRED_HIGH = {
	alarm_15,
	alarm2_15,
	NULL,
	0,
	60000,
	0, 0, 0, 0
};
struct alarm ALARM_GRATE_FAULT = {
	alarm_16,
	NULL,
	GrateReset,
	0,
	0,
	0, 0, 0, 0
};
struct alarm ALARM_ASHAUGER_STUCK = {
	alarm_17,
	NULL,
	AshAugerReset,
	0,
	0,
	0, 0, 0, 0
};
struct alarm ALARM_ASHAUGER_FAULT = {
	alarm_18,
	NULL,
	AshAugerReset,
	0,
	0,
	0, 0, 0, 0
};
struct alarm ALARM_CONDENSATE_RECIRCULATION_PRESSURE_LOW = {
	message_filter_condesate,
	message_pump_low,
	NULL,
	10000,
	60000,
	0, 0, 0, 0
};
struct alarm ALARM_CONDENSATE_RECIRCULATION_PRESSURE_HIGH = {
	message_filter_condesate,
	message_pump_high,
	NULL,
	10000,
	60000,
	0, 0, 0, 0
};
struct alarm ALARM_CONDENSATE_RECIRCULATION_LEVEL_HIGH = {
	message_filter_condesate,
	message_level_high,
	NULL,
	60000,
	300000,
	0, 0, 0, 0
};

//modbus
long baud_rates[] = {2400, 4800, 9600, 19200, 38400, 57600, 115200};
char parity[] = {'n', 'o', 'e'};

// SD Card
boolean sd_loaded;

//int config_count = 20; //number of configurations in config.txt
//
//typedef struct{
//  char name[8];
//  int sensor_num;
//  int flag;
//  int show;
//} config_entry;
////config_entry config[config_num];  //use config_entry struct

//Sd2Card sd_card;
//SdVolume sd_volume;
//SdFile sd_root;
//SdFile sd_file;
char sd_data_file_name[] = "No SD Card  ";  //Create an array that contains the name of our datalog file, updated upon reboot
char sd_log_file_name[] = "No SD Card  ";
//char sd_in_char=0;
//int sd_index=0;

timer_s control_timer;

void setup() {
  GCU_Setup(V3,FULLFILL,P777722);
  DDRJ |= 0x80;
  PORTJ |= 0x80;

  //set all FET pins to output
  pinMode(FET0,OUTPUT);
  pinMode(FET1,OUTPUT);
  pinMode(FET2,OUTPUT);
  pinMode(FET3,OUTPUT);
  pinMode(FET4,OUTPUT);
  pinMode(FET5,OUTPUT);
  pinMode(FET6,OUTPUT);
  pinMode(FET7,OUTPUT);

  // timer initialization
  nextTime1 = millis() + loopPeriod1;
  nextTime2 = millis() + loopPeriod2;

  LoadPressureSensorCalibration();
  LoadServo();

  Serial.begin(115200);

 //Library initializations
  Disp_Init();
  Kpd_Init();
  ADC_Init();
  Temp_Init();
  Press_Init();
  Fet_Init();
  Servo_Init();
  pwm_init(); // Initialize hardware PWM channels
  timer_init();  // Initialize timer system

  Disp_Reset();
  Kpd_Reset();
  ADC_Reset();
  Temp_Reset();
  Press_Reset();
  Fet_Reset();
  Servo_Reset();

  if(EEPROM.read(35) != 255){
    EEPROMReadAlpha(35, 4, unique_number);
  }
  if(EEPROM.read(40) != 255){
    EEPROMReadAlpha(40, 10, serial_num);
  }

  InitSD();
  DoDatalogging();
  InitLambda();
  InitServos();
  GrateInit();
  AugerInit();
  AshAugerInit();
  if (use_modbus == 1){
    InitModbusSlave();
  }

  TransitionLambda(LAMBDA_UNKNOWN);
  TransitionAuger(AUGER_OFF);
  TransitionDisplay(DISPLAY_SPLASH);

  timer_set(&control_timer, 0);
  timer_start(&control_timer);

}

void loop() {
	if (testing_state == TESTING_OFF) {
		Temp_ReadAll();  // reads into array Temp_Data[], in deg C
		Press_ReadAll(); // reads into array Press_Data[], in hPa
		// the above two Readalls take peak 2.9msec, avg 2.2msec
		if (!timer_read(&control_timer)) {
			DoPressure();
			DoSerialIn();
			DoLambda();
			DoControlInputs();
			DoEngine();
			DoFlare();
			DoReactor();
			DoAuger();
			DoGrate();
			DoAshAuger();	// New!
			DoCondensateRecirc();
			if (use_modbus == 1){
			  DoModbus();
			}
			timer_set(&control_timer, 100);
		}
	}
  DoKeyInput();
  DoHeartBeat(); // blink heartbeat LED
  if (millis() >= nextTime2) {
    nextTime2 += loopPeriod2;
    DoDisplay();
    if (millis() >= nextTime1) {
      nextTime1 += loopPeriod1;
      if (testing_state == TESTING_OFF) {
        DoFilter();
        DoDatalogging(); // No SD card: 27msec peak, 22msec normal. With SD card: 325msec at first, 288msec normal
        DoAlarmUpdate();
        DoAlarm();
      }
    }
  }
}

