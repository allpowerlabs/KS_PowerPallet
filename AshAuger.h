#define ASH_AUGER_ONEAMP (27)		// One ADC unit is ~37.6 mA

#define ASH_AUGER_CLIMIT (346)		// 346 = 13 amps, 266 = 10 amps

#define ASH_AUGER_ACCUM_RISE (3)
#define ASH_AUGER_ACCUM_FALL (1)
#define ASH_AUGER_ACCUM_STALL (500)
#define ASH_AUGER_ACCUM_FAULT (10000)
#define ASH_AUGER_REVERSE_TIME (1250)
#define ASH_AUGER_BRAKE_TIME (100)
#define ASH_AUGER_FORWARD_TIME (2000)

#define DISABLED 0
#define AUTO 1
#define MANUAL 2

#define STANDBY 0
#define BRAKE 2
#define FORWARD 1
#define FORWARD_BRAKE 3
#define REVERSE 5
#define REVERSE_BRAKE 7

void AshAugerSwitchMode(int mode);
int AshAugerGetMode();

void DoAshAuger();

void AshAugerInit();
void AshAugerReset();

void AshAugerStart();
void AshAugerStop();
