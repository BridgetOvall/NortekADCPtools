## NortekADCPtools_BO
	- tools for quickly viewing ADCP data in the field
	
### ExploreNortek  *START HERE*
- This is an example script for using all of the tools in this toolbox
- Can be used as a single command method for viewing beam velocities and ENU velocities regardless of sampling format
- After loading a specified .mat file, this script runs all of the functions in the toolbox in the following order:
	
### GatherData
- Pulls relevant data from the loaded .mat file
- Determines the sampling format (burst/average, beams utilized, multiplexing, bottom tracking, etc) and combines everything into a simplified data structure 
	
### ViewBeamData
- Requires data structure formatted as in GatherData
- Creates a plot of beam data, adjusting for the # of beams utilized
- User can select whether to plot beam velocities, echo amplitudes, and/or correlations
- User can also set it to remove bottom tracked velocity from each beam
	
 ### FillBeams
- Requires data structure formatted as in GatherData
- Primary purpose of this function is to calculate values for beams that were turned off during data collection (by assuming zero error velocity)
- Should also be able to handle data masked over discrete portions of time/space, but this functionality has not been thoroughly tested
- User selects whether to use beam 5 for Z-matching (necessary if two side beams are turned off) or conduct a standard 3-beam solution
	
### B2Erotation *This is a work in progress, but is operable with the functionality currently included*
- Requires data structure formatted as in GatherData
- Rotates velocities from beam coordinates to Earth coordinates
- User designates weight of beam 5 in calculating vertical velocities
- User selects whether or not to remove ship velocity by subtracting bottom tracked velocity
- *future functionality: User selects whether or not to remove ship velocity by subtracting velocity from GPS
- *future functionality: User selects whether to use internal heading or GPS heading
	
### ViewUVW
- Requires data structure formatted as in GatherData with enu field as added by B2Erotation
- Creates a plot of three components of velocity in Earth coordinates as well as error velocity
	
*To add: function to view echo sounder data (and modify GatherData to pull this info)*


### -- Requirements --
- cmocean
- navigation toolbox