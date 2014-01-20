=== Change Log ===
2014-01-20 v1.3
  * Added ash auger logic and user control.  Ash auger uses FET 5, previously 
    the O2 reset FET, so no more O2 reset
  * Renamed Ttred and Tbred to Trst and Tred, respectively
  * Fixed a bug with fuel auger relay on entering test mode
  * Removed ignition on PCU start, and lean-out on shutdown when in grid-tie 
    mode
  * Fixed missing values for Reduction Temp High in alarm arrays
  * Fixed PCU Commanded Shutdown latching error in grid-tie mode
  * Modified flare ignitor logic to avoid lighting until reactor is >COLD (50C)
  * Added this lovely README file!