void DoFilter() {
	pRatioFilter = (float)Press[P_REACTOR]/(float)Press[P_FILTER];
	pRatioFilterHigh = (pRatioFilter < 0.3);

	if (pRatioFilterHigh  && Press[P_REACTOR] < -200) {
		filter_pratio_accumulator++;
	} else {
		filter_pratio_accumulator -= 5;
	}
	filter_pratio_accumulator = max(0,filter_pratio_accumulator); // don't let it go below 0
	filter_pratio_accumulator = min(filter_pratio_accumulator,20); //keep value below 20
}

void DoCondensateRecirc() {
	if (analogRead(ANA_CONDENSATE_LEVEL) > 515) {
		condensate_level = CONDENSATE_LEVEL_NORMAL;
	} else {
		condensate_level = CONDENSATE_LEVEL_HIGH;
	}

	condensate_recirc_pressure = ADC_TO_RECIRC_PRESSURE(analogRead(ANA_CONDENSATE_PRESSURE));

	switch (condensate_recirc_state) {
	case CONDENSATE_RECIRC_OFF:
		if (
			(P_reactorLevel != OFF) &&
			(T_tredLevel > COLD) &&
			(getAlarmShutdownTime(&ALARM_CONDENSATE_RECIRCULATION_PRESSURE_HIGH) > 0 ) &&
			(getAlarmShutdownTime(&ALARM_CONDENSATE_RECIRCULATION_PRESSURE_LOW) > 0 ) &&
			(getAlarmShutdownTime(&ALARM_CONDENSATE_RECIRCULATION_LEVEL_HIGH) > 0)
		) {
			TransitionCondensateRecirc(CONDENSATE_RECIRC_NORMAL);
		}
		break;
	case CONDENSATE_RECIRC_NORMAL:
		removeAlarm(&ALARM_CONDENSATE_RECIRCULATION_LEVEL_HIGH);

		if ((millis() - condensate_recirc_state_entered) > 30000) {
			if ((P_reactorLevel == OFF) || (T_tredLevel == COLD)) {
				TransitionCondensateRecirc(CONDENSATE_RECIRC_OFF);
			}
			if (condensate_level == CONDENSATE_LEVEL_HIGH) {
				TransitionCondensateRecirc(CONDENSATE_RECIRC_HIGH);
			}
		}

		if (condensate_recirc_pressure > CONDENSATE_RECIRC_PRESSURE_HIGH) {
			setAlarm(&ALARM_CONDENSATE_RECIRCULATION_PRESSURE_HIGH);
		} else {
			removeAlarm(&ALARM_CONDENSATE_RECIRCULATION_PRESSURE_HIGH);
		}

		if (condensate_recirc_pressure < CONDENSATE_RECIRC_PRESSURE_LOW) {
			setAlarm(&ALARM_CONDENSATE_RECIRCULATION_PRESSURE_LOW);
		} else {
			removeAlarm(&ALARM_CONDENSATE_RECIRCULATION_PRESSURE_LOW);
		}

		if (
			(getAlarmShutdownTime(&ALARM_CONDENSATE_RECIRCULATION_PRESSURE_HIGH) <= 0) ||
			(getAlarmShutdownTime(&ALARM_CONDENSATE_RECIRCULATION_PRESSURE_LOW) <= 0)
		) {
			TransitionCondensateRecirc(CONDENSATE_RECIRC_OFF);
			//EngineShutdown();
		}
		break;
	case CONDENSATE_RECIRC_HIGH:
		if ((millis() - condensate_recirc_state_entered) > ALARM_CONDENSATE_RECIRCULATION_LEVEL_HIGH.delay) {
			setAlarm(&ALARM_CONDENSATE_RECIRCULATION_LEVEL_HIGH);
		}

		if ((millis() - condensate_recirc_state_entered) > 30000) {
			if ((P_reactorLevel == OFF) || (T_tredLevel == COLD)) {
				TransitionCondensateRecirc(CONDENSATE_RECIRC_OFF);
			}
			if (condensate_level == CONDENSATE_LEVEL_NORMAL) {
				TransitionCondensateRecirc(CONDENSATE_RECIRC_NORMAL);
			}
		}

		if (condensate_recirc_pressure > CONDENSATE_RECIRC_PRESSURE_HIGH) {
			setAlarm(&ALARM_CONDENSATE_RECIRCULATION_PRESSURE_HIGH);
		} else {
			removeAlarm(&ALARM_CONDENSATE_RECIRCULATION_PRESSURE_HIGH);
		}

		if (condensate_recirc_pressure < CONDENSATE_RECIRC_PRESSURE_LOW) {
			setAlarm(&ALARM_CONDENSATE_RECIRCULATION_PRESSURE_LOW);
		} else {
			removeAlarm(&ALARM_CONDENSATE_RECIRCULATION_PRESSURE_LOW);
		}

		if (
			(getAlarmShutdownTime(&ALARM_CONDENSATE_RECIRCULATION_PRESSURE_HIGH) <= 0) ||
			(getAlarmShutdownTime(&ALARM_CONDENSATE_RECIRCULATION_PRESSURE_LOW) <= 0) ||
			(getAlarmShutdownTime(&ALARM_CONDENSATE_RECIRCULATION_LEVEL_HIGH) <= 0)
		) {
			TransitionCondensateRecirc(CONDENSATE_RECIRC_OFF);
			//EngineShutdown();
		}
		break;
	}
}

void TransitionCondensateRecirc(int newState) {
	condensate_recirc_state_entered = millis();
	switch (newState) {
	case CONDENSATE_RECIRC_OFF:
		Logln_p("New Concentrate Recirculation State: OFF");
		digitalWrite(FET_CONDENSATE_PUMP,LOW);
		digitalWrite(FET_CONDENSATE_FAN,LOW);
		break;
	case CONDENSATE_RECIRC_NORMAL:
		Logln_p("New Concentrate Recirculation State: NORMAL");
		digitalWrite(FET_CONDENSATE_PUMP,HIGH);
		digitalWrite(FET_CONDENSATE_FAN,HIGH);
		break;
	case CONDENSATE_RECIRC_HIGH:
		Logln_p("New Concentrate Recirculation State: HIGH");
		digitalWrite(FET_CONDENSATE_PUMP,HIGH);
		digitalWrite(FET_CONDENSATE_FAN,LOW);
		break;
	}
	condensate_recirc_state = newState;
}
