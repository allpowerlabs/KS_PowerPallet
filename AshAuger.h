#define ASH_AUGER_ONEAMP (27)

#define TIMING_TICK (62500)
#define ASH_AUGER_PERIOD_LO (25)
#define ASH_AUGER_PERIOD_HI (0)

#define ASH_AUGER_CLIMIT (346)		// 346 = 13 amps, 266 = 10 amps
#define ASH_AUGER_CHYST (27)		// 79 = 3A, 133 = 5A

#define ASH_AUGER_CLIMIT_ACCUM_UP (3)
#define ASH_AUGER_CLIMIT_ACCUM_DOWN (1)
#define ASH_AUGER_CLIMIT_ACCUM_HIGH (500)
#define ASH_AUGER_CLIMIT_ACCUM_MAX (10000)
#define ASH_AUGER_REVERSE_TIME (1250)
#define ASH_AUGER_STALL_TIME (100)
#define ASH_AUGER_FORWARD_TIME_MIN (2000)

typedef enum {
	ASH_AUGER_AUTO,
	ASH_AUGER_MANUAL,
	ASH_AUGER_DISABLED
} ashAugerMode_t;

void AshAugerSetMode(ashAugerMode_t mode);
ashAugerMode_t AshAugerGetMode();

void AshAugerSetTimer(unsigned int);

void AshAugerRun();

void DoAshAuger();

void AshAugerInit();
void AshAugerReset();
