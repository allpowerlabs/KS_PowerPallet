#define ASH_AUGER_ONEAMP (27)		// One ADC unit is ~37.6 mA

#define ASH_AUGER_CLIMIT (346)		// 346 = 13 amps, 266 = 10 amps

#define ASH_AUGER_ACCUM_RISE (3)
#define ASH_AUGER_ACCUM_FALL (1)
#define ASH_AUGER_ACCUM_STALL (500)
#define ASH_AUGER_ACCUM_FAULT (10000)
#define ASH_AUGER_REVERSE_TIME (1250)
#define ASH_AUGER_BRAKE_TIME (100)
#define ASH_AUGER_FORWARD_TIME (2000)

void AshAugerSwitchMode(int mode);
int AshAugerGetMode();

void DoAshAuger();

void AshAugerInit();
void AshAugerReset();

void AshAugerStart();
void AshAugerStop();
