
int disp_putchar(char c, FILE * stream) {
	if (buffer_size == BUFFER_SIZE - 1) return -1;
	string_buffer[buffer_size++] = c;
	string_buffer[buffer_size] = 0;
	return 0;
}

void DoDisplay() {
	unsigned j;
	switch (display_state) {
		case DISPLAY_SPLASH:
			Disp_CursOff();
			//Row 0
			Disp_RC(0,0);
			Disp_PutStr(PSTR("    Datalogging    "));
			//Row 1
			Disp_RC(1,0);
			Disp_PutStr(PSTR("www.allpowerlabs.org"));
			//Row 2
			Disp_RC(2,(20-strlen(CODE_VERSION))/2);
			sprintf(buf, "%s", CODE_VERSION);
			Disp_PutStr(buf);
			//Row 3
			Disp_RC(3,0);
			//Transition out after delay
			if (millis()-display_state_entered>2000) {
				TransitionDisplay(DISPLAY_PRESS);
			}
			break;
		case DISPLAY_PRESS:
			Disp_CursOff();
			for (j=0; j<4; j++) {
				Disp_RC(j, 0);
				sprintf(buf, "P%-2i %5i", j, MPXV7007_TO_DECI_INH2O(Press[j]));
				Disp_PutStr(buf);
			}
			for (j=0; j<2; j++) {
				Disp_RC(j, 10);
				sprintf(buf, "P%-2i %5i", j+4, MPXV7025_TO_DECI_INH2O(Press[j+4]));
				Disp_PutStr(buf);
			}
			Disp_RC(3, 11);
			sprintf(buf, "%9lu", millis()/1000);
			Disp_PutStr(buf);
			break;
		case DISPLAY_TEMP0:
			Disp_CursOff();
			for (j=0; j<4; j++) {
				if (j < NTEMP) {
					Disp_RC(j, 0);
					sprintf(buf, "T%-2u %5u", j, Temp_Data[j]);
					Disp_PutStr(buf);
				}
				if ((j+4) < NTEMP) {
					Disp_RC(j, 11);
					sprintf(buf, "T%-2u %5u", j+4, Temp_Data[j+4]);
					Disp_PutStr(buf);
				}
			}
			break;
		case DISPLAY_TEMP1:
			Disp_CursOff();
			for (j=0; j<4; j++) {
				if ((j+8) < NTEMP) {
					Disp_RC(j, 0);
					sprintf(buf, "T%-2u %5u", j+8, Temp_Data[j+8]);
					Disp_PutStr(buf);
				}
				if ((j+12) < NTEMP) {
					Disp_RC(j, 11);
					sprintf(buf, "T%-2u %5u", j+12, Temp_Data[j+12]);
					Disp_PutStr(buf);
				}
			}
			break;
		default:
			TransitionDisplay(0);
			break;
	}
}

void TransitionDisplay(int new_state) {
  //Enter
  display_state_entered = millis();
  display_state=new_state;
  Disp_Clear(); // Clear display between menus
}

void DoKeyInput() {
	int key;
	key = Kpd_GetKeyAsync();
	switch (key) {
		case 0:
			TransitionDisplay(++display_state);
			break;
		default:
			break;
	}
	key = -1; //key caught
}

void DoHeartBeat() {
  PORTJ ^= 0x80;    // toggle the heartbeat LED
}
