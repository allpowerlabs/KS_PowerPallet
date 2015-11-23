
typedef void (*reset_f)(int);

typedef struct alarm_s {
	const char * message;
	reset_f reset;
	unsigned silent:1;
	alarm_s * next;
} alarm_s;