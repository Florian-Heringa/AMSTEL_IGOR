#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


Function setAngleOffsetAndScale(w, polarOffset, energy)

	Wave w
	Variable polarOffset, energy
	
	NewDataFolder/O/S root:angleAndScale
	
	Duplicate/O w, $(nameOfWave(w) + "_scaled")
	Wave scaledW = $(nameOfWave(w) + "_scaled")
	
	SetScale/P x, angleToK(dimOffset(w, 0) + polarOffset, energy), angleToK(dimDelta(w, 0), energy), "A^-1", scaledW
	
End

Function angleToK(angle, energy)
	
	Variable angle, energy
	
	print 0.512 * sqrt(energy) * sin(angle*(pi/180))
End

Function KtoAngle(k, energy)

	Variable k, energy
	
	print asin(k/(0.512*sqrt(energy))) * (180/pi)
End


Function convert_between_energy_ranges(from, to, angle)
	
	variable from, to, angle
	
	print asin( (sqrt(from)/sqrt(to)) * sin(angle) )
End
