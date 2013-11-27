// KS_PowerPallet
// Library used to run APL Power Pallet
// Developed for the APL GCU/PCU: http://gekgasifier.pbworks.com/Gasifier-Control-Unit

#include <EEPROM.h>         // included with Arduino, can read/writes to non-volatile memory
#include <Servo.h>          // Arduino's native servo library
#include <PID_Beta6.h>      // http://www.arduino.cc/playground/Code/PIDLibrary, http://en.wikipedia.org/wiki/PID_controller
#include <adc.h>            // part of KSlibs, for reading analog inputs
#include <display.h>        // part of KSlibs, write to display
#include <fet.h>            // part of KSlibs, control FETs (field effect transitor) to drive motors, solenoids, etc
#include <keypad.h>         // part of KSlibs, read buttons and keypad
#include <pressure.h>       // part of KSlibs, read pressure sensors
#include <servos.h>         // part of KSlibs
#include <temp.h>           // part of KSlibs, read thermocouples
#include <timer.h>          // part of KSlibs, not implemented
#include <ui.h>             // part of KSlibs, menu
#include <util.h>           // part of KSlibs, utility functions, GCU_Setup
#include <avr/io.h>         // advanced: provides port definitions for the microcontroller (ATmega1280, http://www.atmel.com/dyn/resources/prod_documents/doc2549.PDF)   
#include <SD.h>             // SD card  
#include <avr/pgmspace.h>
#include <string.h>
#include <ModbusSlave.h>
//#include <MCP2515.h> 
//#include <SPI.h>


/*
EEPROM bytes used of 4k space:
0-10,  13-21,  33-38,  40-50,
500-999 DISPLAY_CONFIG states
1000-4000 Sensor configuration (not yet implemented)
*/

//constant definitions
#define ABSENT -500

#define CODE_VERSION "v1.21beta" 

//PROGMEM string buffer
char p_buffer[41] = ""; 
// remove excess macro parameter:
#define P(str) (strcpy_P(p_buffer, PSTR(str)))
#define putstring(x) SerialPrint_P(PSTR(x))
#define Log_p(x) Log(P(x))
#define Logln_p(x) Logln(P(x))

const prog_char co_product[] PROGMEM = "# http:\\\\AllPowerlabs.org  Power Pallet ";
const prog_char help[] PROGMEM = { 
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
  "# l: add 0.01 to lambda_setpoint\r\n"
  "# L: subtract 0.01 from lambda_setpoint\r\n"
  "# t: subtract 100 ms from Sample Period (loopPeriod1)\r\n"
  "# T: add 100 ms from Sample Period (loopPeriod1)\r\n"
  "# g: Shake grate\r\n"
  "# G: Switch Grate Shaker mode (Off/On/Pressure Ratio)\r\n"
  "# m: add 5ms to grate shake interval\r\n"
  "# M: subtract 5 ms from grate shake interval\r\n"
  "# e: Engine Governor Tuning mode\r\n"
  "# hH: Print Help Text\r\n" };

// Analog Input Mapping
#define ANA_LAMBDA ANA0
#define ANA_FUEL_SWITCH ANA1
#define ANA_ENGINE_SWITCH ANA2
#define ANA_OIL_PRESSURE ANA3
#define ANA_AUGER_CURRENT ANA4  //sense current in auger motor
#define ANA_THROTTLE_POS ANA5
#define ANA_COOLANT_TEMP ANA6
#define ANA_DIAL ABSENT
#define ANA_BATT_V ABSENT

int smoothed[8];  //array of smoothed analog signals.
int smoothed_filters[8] = {0, 0, 0, 8, 0, 0, 0, 0};  //filter values for each analog channel
int analog_inputs[] = {ANA0, ANA1, ANA2, ANA3, ANA4, ANA5, ANA6, ANA7};

// FET Mappings
#define FET_AUGER FET0
#define FET_GRATE FET1
#define FET_IGNITION FET2
#define FET_STARTER FET3
#define FET_FLARE_IGNITOR FET4
#define FET_O2_RESET FET5
#define FET_ALARM FET6
#define FET_AUGER_REV FET7
#define FET_BLOWER ABSENT

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
#define T_PYRO_IN ABSENT
#define T_PYRO_OUT ABSENT
#define T_COMB ABSENT
#define T_DRYING_GAS_OUT ABSENT
#define T_FILTER ABSENT
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

// Grate Shaking States
#define GRATE_SHAKE_OFF 0
#define GRATE_SHAKE_ON 1
#define GRATE_SHAKE_PRATIO 2

// Grate Motor States
#define GRATE_MOTOR_OFF 0
#define GRATE_MOTOR_LOW 1
#define GRATE_MOTOR_HIGH 2
#define GRATE_PRATIO_THRESHOLD 180 //number of seconds until we use high shaking mode

// Grate Shaking
#define GRATE_SHAKE_CROSS 5000
#define GRATE_SHAKE_INIT 32000

//Control States
//TODO: Use these for auto-start/shutdown sequence (e.g. equivalent to a backup generator command)
#define CONTROL_OFF 0
#define CONTROL_START 1
#define CONTROL_ON 2

//Engine States
#define ENGINE_OFF 0
#define ENGINE_ON 1
#define ENGINE_STARTING 2
#define ENGINE_GOV_TUNING 3
#define ENGINE_SHUTDOWN 4

//Lambda
#define LAMBDA_SIGNAL_CHECK TRUE

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
#define DISPLAY_ENGINE 2
#define DISPLAY_TEST 3
#define DISPLAY_LAMBDA 4
#define DISPLAY_GRATE 5
#define DISPLAY_INFO 6
#define DISPLAY_TESTING 7
#define DISPLAY_SERVO 8
#define DISPLAY_CALIBRATE_PRESSURE 9
#define DISPLAY_CONFIG 10
#define DISPLAY_SD 11
#define DISPLAY_RELAY 12
#define DISPLAY_ANA 13

const prog_char menu1[] PROGMEM = "NEXT  ADV   +    -  ";
const prog_char blank[] PROGMEM = "                    ";
const prog_char new_engine_state[] PROGMEM = "New Engine State: ";
const prog_char engine_shutdown[] PROGMEM = ", Engine Shutdown.";
const prog_char new_auger_state[] PROGMEM = "New Auger State: ";
const prog_char half_blank[] PROGMEM = "          ";
char choice[5];
char buf[22] = "";

char serial_num[11] = "#         ";
char unique_number[5] = "#";

//Testing States
#define TESTING_OFF 0
#define TESTING_FUEL_AUGER 1
#define TESTING_GRATE 2
#define TESTING_ENGINE_IGNITION 3
#define TESTING_STARTER 4
#define TESTING_FLARE_IGNITOR 5
#define TESTING_O2_RESET 6
#define TESTING_ALARM 7
#define TESTING_FUEL_REV 8
#define TESTING_ANA_LAMBDA 9
#define TESTING_ANA_ENGINE_SWITCH 10
#define TESTING_ANA_FUEL_SWITCH 11
#define TESTING_ANA_OIL_PRESSURE 12
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

//prog_char testing_state_0[] PROGMEM = "Off";
prog_char testing_state_1[] PROGMEM = "FET0 Auger Fwd";
prog_char testing_state_2[] PROGMEM = "FET1 Grate";
prog_char testing_state_3[] PROGMEM = "FET2 Engine/Governor";
prog_char testing_state_4[] PROGMEM = "FET3 Starter";
prog_char testing_state_5[] PROGMEM = "FET4 Flare";
prog_char testing_state_6[] PROGMEM = "FET5 O2 Reset";
prog_char testing_state_7[] PROGMEM = "FET6 Alarm";
prog_char testing_state_8[] PROGMEM = "FET7 Auger Rev";

prog_char testing_state_9[] PROGMEM =  "ANA_Lambda";
prog_char testing_state_10[] PROGMEM = "ANA_Fuel_Switch";
prog_char testing_state_11[] PROGMEM = "ANA_Eng_Switch";
prog_char testing_state_12[] PROGMEM = "ANA_Oil";
prog_char testing_state_13[] PROGMEM = "ANA_Auger_current";
prog_char testing_state_14[] PROGMEM = "ANA_Throttle_Pos";
prog_char testing_state_15[] PROGMEM = "ANA_Coolant_Temp";
prog_char testing_state_16[] PROGMEM = "Unused"; 

PROGMEM const char *TestingStateName[] = {testing_state_1, testing_state_2, testing_state_3, testing_state_4, testing_state_5, testing_state_6, testing_state_7, testing_state_8, testing_state_9, testing_state_10, testing_state_11, testing_state_12, testing_state_13, testing_state_14, testing_state_15, testing_state_16};

// Datalogging variables
int lineCount = 0;

//Configuration Variables
#define CONFIG_COUNT 28  
int config_var;
byte config_changed = false;

prog_char config_0[] PROGMEM = "Reset Defaults?";
prog_char config_1[] PROGMEM = "Engine Type    "; 
prog_char config_2[] PROGMEM = "Relay Board    "; 
prog_char config_3[] PROGMEM = "Auger Rev (.1s)"; 
prog_char config_4[] PROGMEM = "Auger Low (.1A)"; 
prog_char config_5[] PROGMEM = "Auger High(.1A)"; 
prog_char config_6[] PROGMEM = "Low Oil (PSI)  "; 
prog_char config_7[] PROGMEM = "Datalog SD card"; 
prog_char config_8[] PROGMEM = "Pratio Accum#  "; 
prog_char config_9[] PROGMEM = "High Coolant T "; 
prog_char config_10[] PROGMEM = "Display Per .1s"; 
prog_char config_11[] PROGMEM = "Ttred low temp?"; 
prog_char config_12[] PROGMEM = "Ttred High Temp"; 
prog_char config_13[] PROGMEM = "Tbred High Temp";
prog_char config_14[] PROGMEM = "Pfilter Accum# "; 
prog_char config_15[] PROGMEM = "Grate Max Inter"; 
prog_char config_16[] PROGMEM = "Grate Min Inter"; 
prog_char config_17[] PROGMEM = "Grate On Interv";
prog_char config_18[] PROGMEM = "Servo Start Pos";
prog_char config_19[] PROGMEM = "Lambda Rich    ";
prog_char config_20[] PROGMEM = "Modbus Enabled?";  //Set to Modbus baud of zero and remove this configuration?
prog_char config_21[] PROGMEM = "Modbus Baud    ";  //0:2400, 1:4800, 2:9600, 3:19200, 4:38400, 5:57600, 6:115200 
prog_char config_22[] PROGMEM = "Modbus Parity  ";  //0:None, 1:Odd, 2:Even
prog_char config_23[] PROGMEM = "Modbus Address ";  //1-127
prog_char config_24[] PROGMEM = "Grid tie?      "; 
prog_char config_25[] PROGMEM = "Pratio Low     ";
prog_char config_26[] PROGMEM = "Ttred Warn Temp";
prog_char config_27[] PROGMEM = "Pratio High    ";

PROGMEM const char *Configuration[CONFIG_COUNT] = {config_0, config_1, config_2, config_3, config_4, config_5, config_6, config_7, config_8, config_9, config_10, config_11, config_12, config_13, config_14, config_15, config_16, config_17, config_18, config_19, config_20, config_21, config_22, config_23, config_24, config_25, config_26, config_27};

prog_char plus_minus[] PROGMEM = "+    -  ";
prog_char no_yes[] PROGMEM = "NO  YES ";
prog_char ten_twenty_k[] PROGMEM = "10k 20k ";
prog_char plus_minus_five[] PROGMEM = "+5  -5  ";


PROGMEM const char *Config_Choices[CONFIG_COUNT] = {
no_yes, 
ten_twenty_k,
no_yes,
plus_minus, 
plus_minus, 
plus_minus, 
plus_minus, 
no_yes, 
plus_minus_five, 
plus_minus, 
plus_minus, 
plus_minus_five, 
plus_minus_five, 
plus_minus_five,
plus_minus, 
plus_minus_five, 
plus_minus_five, 
plus_minus,
plus_minus,
plus_minus,
no_yes,
plus_minus,
plus_minus,
plus_minus,
no_yes,
plus_minus,
plus_minus_five,
plus_minus
}; 

//                              0    1    2    3    4   5    6   7    8    9    10   11   12   13   14   15   16   17   18  19   20  21  22  23   24  25   26   27
int defaults[CONFIG_COUNT]   = {0,   0,   1,   10,  35, 100, 6,  1,   10,  98,  10,  130, 210, 195, 50,  60,  12,  3,   30, 140, 0,  3,  0,  1,   0,  30,  150, 60};  //default values to be saved to EEPROM for the following getConfig variables
int config_min[CONFIG_COUNT] = {0,   0,   0,   0,   5,  41,  1,  0,   0,   10,  0,   0,   0,   20,  0,   0,   0,   0,   0,  0,   0,  0,  0,  1,   0,  0,   0,   0};  //minimum values allowed 
int config_max[CONFIG_COUNT] = {254, 254, 254, 254, 40, 135, 10, 254, 15, 254, 199, 254, 254, 254, 254, 254, 254, 254, 90, 150, 1,  6,  3,  127, 254, 100, 254, 254}; //maximum values allowed  

//Don't forget to add the following to update_config_var in Display!  The first Configuration, Reset Defaults, is skipped, so these start at 1, not 0. 
int engine_type = getConfig(1);  
int relay_board = getConfig(2);
int aug_rev_time = getConfig(3)*100;
int current_low_boundary = getConfig(4);  
int current_high_boundary = getConfig(5);
int low_oil_psi = getConfig(6);
int save_datalog_to_sd = getConfig(7);
int pratio_max = getConfig(8)*5;
int high_coolant_temp = getConfig(9);
int display_per = getConfig(10);
int tred_low_temp = getConfig(11)*5;
int ttred_high = getConfig(12)*5;
int tbred_high = getConfig(13)*5;
int pfilter_alarm = getConfig(14);
int grate_max_interval = getConfig(15)*5;  //longest total interval in seconds
int grate_min_interval = getConfig(16)*5;
int grate_on_interval = getConfig(17);
int servo_start = getConfig(18);
int lambda_rich = getConfig(19);
int use_modbus = getConfig(20);
int m_baud = getConfig(21);
int m_parity = getConfig(22);
int m_address = getConfig(23);
int grid_tie = getConfig(24);
int pratio_low_boundary = getConfig(25);
int ttred_warn = getConfig(26)*5;
int pratio_high_boundary = getConfig(27);

// Grate turning variables
int grateMode = GRATE_SHAKE_PRATIO; //set default starting state
int grate_motor_state; //changed to indicate state (for datalogging, etc)
int grate_val = GRATE_SHAKE_INIT; //variable that is changed and checked
int grate_pratio_accumulator = 0; // accumulate high pratio to trigger stronger shaking past threshhold
//define these in init, how much to remove from grate_val each cycle [1 second] (slope)
int m_grate_bad; 
int m_grate_good;
int m_grate_on;

// Reactor pressure ratio
float pRatioReactor;
enum pRatioReactorLevels { PR_HIGH = 0, PR_CORRECT = 1, PR_LOW = 2} pRatioReactorLevel;
static char *pRatioReactorLevelName[] = { "High", "Correct", "Low" };
float pratio_low = pratio_low_boundary/100.0;
float pratio_high = pratio_high_boundary/100.0;
float pRatioReactorLevelBoundary[3][2] = { { pratio_high, 1.0 }, { pratio_low, pratio_high }, {0.0, pratio_low} };

// Filter pressure ratio
float pRatioFilter;
boolean pRatioFilterHigh;
int filter_pratio_accumulator;

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

//Auger Switch Levels
#if ANA_FUEL_SWITCH != ABSENT
int FuelSwitchValue = 0;
byte FuelDemand = false;
enum FuelSwitchLevels { SWITCH_OFF = false, SWITCH_ON = true} FuelSwitchLevel;
static char *FuelSwitchLevelName[] = { "Off","On"};
//int FuelSwitchLevelBoundary[2][2] = {{ 0, 200 }, {800, 1024}}; //not currently used
unsigned long fuel_state_entered;
#endif

//Auger states
#define AUGER_OFF 0
#define AUGER_STARTING 1
#define AUGER_FORWARD 2
#define AUGER_HIGH 3
#define AUGER_REVERSE 4
#define AUGER_REVERSE_HIGH 5
#define AUGER_CURRENT_LOW 6
#define AUGER_ALARM 7
#define AUGER_PULSE 8
#define AUGER_MANUAL_FORWARD 9

int auger_state = 0;
int auger_rev_count = 0;
unsigned long auger_current_low = 0;
unsigned long auger_state_entered;
unsigned long auger_direction_entered;
unsigned long auger_pulse_entered;
unsigned long auger_pulse_time = 500;
int auger_pulse_state = 0;

//Auger Current Levels
int AugerCurrentValue = 0; // current level in .1A,  ADC Count = (120 * Current) + 1350
enum AugerCurrentLevels { CURRENT_OFF = 0, CURRENT_LOW = 1, CURRENT_ON = 2, CURRENT_HIGH = 3} AugerCurrentLevel;  
static char *AugerCurrentLevelName[] = { "Off", "Low", "On", "High"};
//Any changes to the following needs to be updated to update_config_var!!!   AugerCurrentLevel[AugerCurrentLevelName]
int AugerCurrentLevelBoundary[4][2] = { { -140, 10}, { 10, current_low_boundary}, {current_low_boundary+10, current_high_boundary-10}, {current_high_boundary, 750} };  //.1A readings

//oil pressure
int EngineOilPressureValue;
enum EngineOilPressureLevels { OIL_P_LOW = 0, OIL_P_NORMAL = 1, OIL_P_HIGH = 2} EngineOilPressureLevel;  
static char *EngineOilPressureName[] = { "Low", "Normal", "High"};
//int EngineOilPressureLevelBoundary[2][2] = { { 0, low_oil_psi}, {600, 1024} };  
unsigned long oil_pressure_state = 0;


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
unsigned long engine_end_cranking;
int engine_crank_period = 10000; //length of time to crank engine before stopping (milliseconds)
double battery_voltage;

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
double premix_valve_center = servo_start/100; //initial value when entering closed loop operation (percent open)
double lambda_setpoint;
double lambda_input;
double lambda_output;
double lambda_value;
double lambda_setpoint_mode[1] = {1.05};
double lambda_P[1] = {0.13}; //Adjust P_Param to get more aggressive or conservative control, change sign if moving in the wrong direction
double lambda_I[1] = {1.0}; //Make I_Param about the same as your manual response time (in Seconds)/4 
double lambda_D[1] = {0.0}; //Unless you know what it's for, don't use D
PID lambda_PID(&lambda_input, &lambda_output, &lambda_setpoint,lambda_P[0],lambda_I[0],lambda_D[0]);
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

// Alarm
boolean alarm = false;
int pressureRatioAccumulator = 0;  

#define ALARM_NUM 16
unsigned long alarm_on[ALARM_NUM] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
unsigned long alarm_start[ALARM_NUM] = {240000, 480000, pratio_max, pfilter_alarm, 230, 0, 0, 0, 30000, 60000, 10, 0, 0, 3000, 15000};  //count or time in milliseconds when alarm goes off
unsigned long shutdown[ALARM_NUM] = {360000, 600000, 0, 0, 0, 0, 60000, 0, 0, 180000, 0, 0, 3000, 7000, 15000};  //time when engine will be shutdown
int alarm_count = 0;
int alarm_queue[ALARM_NUM] = {};
int alarm_shown = 0;

#define ALARM_AUGER_ON_LONG 0  
#define ALARM_AUGER_OFF_LONG 1
#define ALARM_BAD_REACTOR 2
#define ALARM_BAD_FILTER 3
#define ALARM_LOW_FUEL_REACTOR 4
#define ALARM_LOW_TRED 5
#define ALARM_HIGH_BRED 6
#define ALARM_BAD_OIL_PRESSURE 7
#define ALARM_O2_NO_SIG 8
#define ALARM_AUGER_LOW_CURRENT 9
#define ALARM_BOUND_AUGER 10
#define ALARM_HIGH_PCOMB 11
#define ALARM_HIGH_COOLANT_TEMP 12
#define ALARM_TRED_LOW 13 
#define ALARM_TTRED_HIGH 14
#define ALARM_TBRED_HIGH 15

prog_char alarm_1[] PROGMEM = "Auger on too long   ";
prog_char alarm_2[] PROGMEM = "Auger off too long  ";
prog_char alarm_3[] PROGMEM = "Bad Reactor P_ratio ";
prog_char alarm_4[] PROGMEM = "Bad Filter P_ratio  ";
prog_char alarm_5[] PROGMEM = "Reactor Fuel Low    ";
prog_char alarm_6[] PROGMEM = "tred low for engine ";
prog_char alarm_7[] PROGMEM = "bred high for engine";
prog_char alarm_8[] PROGMEM = "Check Oil Pressure  ";
prog_char alarm_9[] PROGMEM  = "No O2 Sensor Signal ";
prog_char alarm_10[] PROGMEM = "Auger Low Current   ";
prog_char alarm_11[] PROGMEM = "FuelSwitch/Auger Jam";
prog_char alarm_12[] PROGMEM = "High P_comb         ";
prog_char alarm_13[] PROGMEM = "High Coolant Temp   ";
prog_char alarm_14[] PROGMEM = "Reduction Temp Low  ";
prog_char alarm_15[] PROGMEM = "Reduction Temp High ";
//prog_char alarm_16[] PROGMEM = "Reduction Temp High ";

PROGMEM const char *display_alarm[]  = {alarm_1, alarm_2, alarm_3, alarm_4, alarm_5, alarm_6, alarm_7, alarm_8, alarm_9, alarm_10, alarm_11, alarm_12, alarm_13, alarm_14, alarm_15, alarm_15};

//line 2 on display.  If shutdown[] is greater than zero, countdown will be added to last 3 spaces.
prog_char alarm2_1[] PROGMEM = "Check Fuel          ";
prog_char alarm2_2[] PROGMEM = "Bridging?           ";
prog_char alarm2_3[] PROGMEM = "Reactor Fuel Issue  ";
prog_char alarm2_4[] PROGMEM = "Check Filter        ";
prog_char alarm2_5[] PROGMEM = "Check Auger/Fuel    ";  //Not implemented!!
prog_char alarm2_6[] PROGMEM = "Increase Load       ";
prog_char alarm2_7[] PROGMEM = "Low Fuel in Reactor?";
//prog_char alarm2_8[] PROGMEM = "                    ";
//prog_char alarm2_9[] PROGMEM = "                    ";
//prog_char alarm2_10[] PROGMEM = "Check Fuel          ";
prog_char alarm2_11[] PROGMEM = "Check Fuel & Switch ";
prog_char alarm2_12[] PROGMEM = "Check Air Intake    ";
//prog_char alarm2_13[] PROGMEM = "                    ";
//prog_char alarm2_14[] PROGMEM = "                    ";
prog_char alarm2_15[] PROGMEM = "Reduce Load         ";
//prog_char alarm2_16[] PROGMEM = "Reduce Load         ";

PROGMEM const char *display_alarm2[] = {alarm2_1, alarm2_2, alarm2_3, alarm2_4, alarm2_5, alarm2_6, alarm2_7, blank, blank, alarm2_1, alarm2_11, alarm2_12, blank, blank, alarm2_15, alarm2_15};

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
  if (engine_type == 0) {
    shutdown[ALARM_AUGER_OFF_LONG] = shutdown[ALARM_AUGER_OFF_LONG] * 2;
    alarm_start[ALARM_AUGER_ON_LONG] = alarm_start[ALARM_AUGER_ON_LONG] * 2;
  }
  
  Serial.begin(115200);
  
 //Library initializations                    
  Disp_Init();
  Kpd_Init();
  UI_Init();
  ADC_Init();
  Temp_Init();
  Press_Init();
  Fet_Init();
  Servo_Init();
  Timer_Init();

  Disp_Reset();
  Kpd_Reset();
  UI_Reset();
  ADC_Reset();
  Temp_Reset();
  Press_Reset();
  Fet_Reset();
  Servo_Reset();
  Timer_Reset();
  
  if(EEPROM.read(35) != 255){
    EEPROMReadAlpha(35, 4, unique_number);
  }
  if(EEPROM.read(40) != 255){
    EEPROMReadAlpha(40, 10, serial_num);
  }
  
  //unique_number = uniqueNumber();
  InitSD();
  DoDatalogging();
  InitLambda();
  InitServos();
  InitGrate();  
  if (use_modbus == 1){
    InitModbusSlave();
  }

 
  TransitionEngine(ENGINE_ON); //default to engine on. if PCU resets, don't shut a running engine off. in the ENGINE_ON state, should detect and transition out of engine on.
  TransitionLambda(LAMBDA_UNKNOWN);
  TransitionAuger(AUGER_OFF);
  TransitionDisplay(DISPLAY_SPLASH);
 
}

void loop() {
  if (testing_state == TESTING_OFF) {
    Temp_ReadAll();  // reads into array Temp_Data[], in deg C
    Press_ReadAll(); // reads into array Press_Data[], in hPa
    // the above two Readalls take peak 2.9msec, avg 2.2msec
    DoPressure();
    DoSerialIn();
    DoLambda();
    DoControlInputs();
    DoOilPressure();
    DoEngine();
    DoFlare();
    DoReactor();
    DoAuger();
    if (use_modbus == 1){
      DoModbus();
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
        DoGrate();
        DoFilter();
        DoDatalogging(); // No SD card: 27msec peak, 22msec normal. With SD card: 325msec at first, 288msec normal
        DoAlarmUpdate();
        DoAlarm();
      }
    }
  }
}

