// Datalogging
int log_putchar(char c, FILE * stream) {
	if (buffer_size == BUFFER_SIZE - 1) return -1;
	string_buffer[buffer_size++] = c;
	string_buffer[buffer_size] = 0;
	return 0;
}

void LogTime(boolean header = false) {
  if (header) {
	fprintf(&data_log, "Time, ");
  }
  else {
	fprintf(&data_log, "%06lu, ", millis()/1000);
  }
}

void LogAnalogInputs(boolean header = false) {
	unsigned j;
  if (header) {
	for(j=54; j<62; j++) {
		fprintf(&data_log, "ANA%u, ", j);
	}
  }
  else {

	for(j=54; j<62; j++) {
		fprintf(&data_log, "%4u, ", analogRead(j));
	}
  }
}

void LogPressures(boolean header = false) {
	unsigned j;
  if (header) {
	for(j=0; j<NPRESS; j++) {
		fprintf(&data_log, "P%i, ", j);
	}
  }
  else {

	for(j=0; j<NPRESS; j++) {
		fprintf(&data_log, "%4i, ", Press[j]);
	}
  }
}

void LogTemps(boolean header = false) {
	unsigned j;
	if (header) {
		for(j=0; j<NTEMP; j++) {
			fprintf(&data_log, "T%u, ", j);
		}
	}
	else {
		for(j=0; j<NTEMP; j++) {
			fprintf(&data_log, "%4u, ", Temp_Data[j]);
		}
	}
}

void DoDatalogging() {
	boolean header = false;
	// Clear the string buffer
	buffer_size = 0;
	string_buffer[0] = (char) 0;
	if (lineCount == 0) {
		header = true;
	}
	LogTime(header);
	LogTemps(header);
	LogPressures(header);
	LogAnalogInputs(header);
	// Add a newline
	log_putchar('\n', &data_log);
	// Output to serial
	Serial.print(string_buffer);
	// Output to SD card
	if (sd_loaded){
		DatalogSD(sd_data_file_name, true);
	}
	lineCount++;
}


