#define ASH_AUGER_ONEAMP (27)		// One ADC unit is ~37.6 mA

#define ASH_AUGER_CLIMIT (346)		// 346 = 13 amps, 266 = 10 amps

#define ASH_AUGER_POWER_GAIN (3)

#define ASH_AUGER_ACCUM_RISE (3)
#define ASH_AUGER_ACCUM_FALL (1)
#define ASH_AUGER_ACCUM_STALL (500)
#define ASH_AUGER_ACCUM_FAULT (5000)
#define ASH_AUGER_REVERSE_TIME (1000)
#define ASH_AUGER_BRAKE_TIME (10)
#define ASH_AUGER_FORWARD_TIME (2000)

void AshAugerSwitchMode(int mode);
int AshAugerGetMode();

void DoAshAuger();

void AshAugerInit();
void AshAugerReset();

void AshAugerStart();
void AshAugerStop();
