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
		condensate_level = CONDENSATE_LEVEL_HIGH;
	} else {
		condensate_level = CONDENSATE_LEVEL_NORMAL;
	}

	condensate_recirc_pressure = ADC_TO_RECIRC_PRESSURE(analogRead(ANA_CONDENSATE_PRESSURE));
	if (condensate_recirc_pressure > CONDENSATE_RECIRC_PRESSURE_HIGH) {

	} else {
	}
	if (condensate_recirc_pressure < CONDENSATE_RECIRC_PRESSURE_LOW) {

	} else {
	}

	switch (condensate_recirc_state) {
	case CONDENSATE_RECIRC_OFF:
		if ((P_reactorLevel != OFF) && T_tredLevel > COLD) {
			TransitionCondensateRecirc(CONDENSATE_RECIRC_NORMAL);
		}
		break;
	case CONDENSATE_RECIRC_NORMAL:
		if ((millis() - condensate_recirc_state_entered) > 30000) {
			if ((P_reactorLevel == OFF) || (T_tredLevel == COLD)) {
				TransitionCondensateRecirc(CONDENSATE_RECIRC_OFF);
			}
			if (condensate_level == CONDENSATE_LEVEL_HIGH) {
				TransitionCondensateRecirc(CONDENSATE_RECIRC_HIGH);
			}
		}
		// if (shutdown alarm) TransitionCondensateRecirc(CONDENSATE_RECIRC_OFF);
		break;
	case CONDENSATE_RECIRC_HIGH:
		if ((millis() - condensate_recirc_state_entered) > 30000) {
			if ((P_reactorLevel == OFF) || (T_tredLevel == COLD)) {
				TransitionCondensateRecirc(CONDENSATE_RECIRC_OFF);
			}
			if (condensate_level == CONDENSATE_LEVEL_NORMAL) {
				TransitionCondensateRecirc(CONDENSATE_RECIRC_NORMAL);
			}
		}
		// if (shutdown alarm) TransitionCondensateRecirc(CONDENSATE_RECIRC_OFF);
		break;
	}
}

void TransitionCondensateRecirc(int newState) {
	condensate_recirc_state_entered = millis();
	switch (newState) {
	case CONDENSATE_RECIRC_OFF:
		Log_p("New Concentrate Recirculation State: OFF");
		digitalWrite(FET_CONDENSATE_PUMP,LOW);
		digitalWrite(FET_CONDENSATE_FAN,LOW);
		break;
	case CONDENSATE_RECIRC_NORMAL:
		Log_p("New Concentrate Recirculation State: NORMAL");
		digitalWrite(FET_CONDENSATE_PUMP,HIGH);
		digitalWrite(FET_CONDENSATE_FAN,HIGH);
		break;
	case CONDENSATE_RECIRC_HIGH:
		Log_p("New Concentrate Recirculation State: HIGH");
		digitalWrite(FET_CONDENSATE_PUMP,HIGH);
		digitalWrite(FET_CONDENSATE_FAN,LOW);
		break;
	}
	condensate_recirc_state = newState;
}
