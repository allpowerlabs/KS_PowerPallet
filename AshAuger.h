
#define TIMING_TICK (62500)
#define ASH_AUGER_PERIOD_LO (25)
#define ASH_AUGER_PERIOD_HI (0)

#define ASH_AUGER_CLIMIT (266)		// 346 = 13 amps, 266 = 10 amps
#define ASH_AUGER_CHYST (27)		// 79 = 3A, 133 = 5A

#define ASH_AUGER_CLIMIT_ACCUM_UP (10)
#define ASH_AUGER_CLIMIT_ACCUM_DOWN (1)
#define ASH_AUGER_CLIMIT_ACCUM_HIGH (1000)
#define ASH_AUGER_CLIMIT_ACCUM_MAX (10000)
#define ASH_AUGER_REVERSE_TIME (2000)
#define ASH_AUGER_STALL_TIME (500)


typedef enum {
	ASH_AUGER_AUTO,
	ASH_AUGER_MANUAL,
	ASH_AUGER_DISABLED
} ashAugerMode_t;

void AshAugerSetMode(ashAugerMode_t mode);
ashAugerMode_t AshAugerGetMode();

void AshAugerRun();

void DoAshAuger();