void DoFlare() {
	switch (flare_state) {
	case FLARE_OFF:
		break;
	case FLARE_USER_SET:
		if (
			P_reactorLevel > OFF &&
			//T_tredLevel > COLD &&
			engine_state == ENGINE_OFF
		) {
			ignitor_on = true;
			digitalWrite(FET_FLARE_IGNITOR,HIGH);
		} else {
			ignitor_on = false;
			digitalWrite(FET_FLARE_IGNITOR,LOW);
		}
		break;
	}
// #if FET_BLOWER != ABSENT
    // blower_dial = analogRead(ANA_BLOWER_DIAL);
    // analogWrite(FET_BLOWER,blower_dial/4);
// #endif
}

void DoReactor() {
  //TODO:Refactor
  //Define reactor condition levels
  for(int i = 0; i < TEMP_LEVEL_COUNT; i++) {
    if (Temp_Data[T_TRED] > T_tredLevelBoundary[i][0] && Temp_Data[T_TRED] < T_tredLevelBoundary[i][1]) {
      T_tredLevel = (TempLevels) i;
    }
  }
  for(int i = 0; i < TEMP_LEVEL_COUNT; i++) {
    if (Temp_Data[T_BRED] > T_bredLevelBoundary[i][0] && Temp_Data[T_BRED] < T_bredLevelBoundary[i][1]) {
      T_bredLevel = (TempLevels) i;
    }
  }
	for(int i = 0; i < P_REACTOR_LEVEL_COUNT; i++) {
		if (Press[P_REACTOR] > P_reactorLevelBoundary[i][0] && Press[P_REACTOR] < P_reactorLevelBoundary[i][1]) {
			P_reactorLevel = (P_reactorLevels) i;
    }
	
	// P_ratio calculations - moved from Grate.pde
	pRatioReactor = (float)Press[P_COMB]/(float)Press[P_REACTOR];
	if (pRatioReactor > pRatioReactorLevelBoundary[PR_LOW][0] && pRatioReactor < pRatioReactorLevelBoundary[PR_LOW][1]) {
		pRatioReactorLevel = PR_LOW;
	}
	if (pRatioReactor > pRatioReactorLevelBoundary[PR_CORRECT][0] && pRatioReactor < pRatioReactorLevelBoundary[PR_CORRECT][1]) {
		pRatioReactorLevel = PR_CORRECT;
	}
	if (pRatioReactor > pRatioReactorLevelBoundary[PR_HIGH][0] && pRatioReactor < pRatioReactorLevelBoundary[PR_HIGH][1]) {
		pRatioReactorLevel = PR_HIGH;
	}
}
//  switch (reactor_state) {
//    case REACTOR_OFF:
//      break;
//    case REACTOR_IGNITING:
//      break;
//    case REACTOR_WARMING:
//      break;
//    case REACTOR_COOLING:
//      break;
//    case REACTOR_WARM:
//      break;
//  }
}
  

