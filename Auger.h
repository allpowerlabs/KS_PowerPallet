// Auger.h

//Auger Switch Levels
int FuelSwitchValue = 0;
byte FuelDemand = false;
enum FuelSwitchLevels { SWITCH_OFF = false, SWITCH_ON = true} FuelSwitchLevel;
static char *FuelSwitchLevelName[] = { "Off","On"};
//int FuelSwitchLevelBoundary[2][2] = {{ 0, 200 }, {800, 1024}}; //not currently used
unsigned long fuel_state_entered;
unsigned long fuel_last_fill;
#define FUEL_SWITCH_HYSTERESIS (60000)  // Number of seconds before we allow the auger to come on again

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
int current_low_boundary; // Default/min/max 35/5/40
int current_high_boundary; // Default/min/max 100/41/135

unsigned AugerCurrentValue = 0; // current level in .1A,  ADC Count = (120 * Current) + 1350
enum AugerCurrentLevels { CURRENT_OFF = 0, CURRENT_LOW = 1, CURRENT_ON = 2, CURRENT_HIGH = 3} AugerCurrentLevel;
static char *AugerCurrentLevelName[] = { "Off", "Low", "On", "High"};
//Any changes to the following needs to be updated to update_config_var!!!   AugerCurrentLevel[AugerCurrentLevelName]
unsigned AugerCurrentLevelBoundary[4][2];  //.1A readings
