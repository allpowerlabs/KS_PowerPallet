
/*
	Alarm States:
	Active - the alarm has been triggered and has not been silenced by the user
	Silenced - the alarm has been triggered, but the user has requested it to be quiet
*/

enum alarm_state {
	ALARM_ACTIVE,
	ALARM_SILENCED
};

struct alarm {
	const char * message;
	const char * message2;
	void (*reset)(void); // Pointer to a reset function, called when the user resets the alarm
	unsigned long delay; // count or time in milliseconds to wait before alarm goes off
	unsigned long shutdown; // delay after alarm activation when engine will be shutdown
	unsigned long on;  // Time when the alarm was activated
	unsigned char silenced;
	struct alarm * prev;
	struct alarm * next;
};
