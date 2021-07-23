#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Recipe:
//
// 1. Have all data loaded using the Load_many_SLS_separate(start, fin) and Load_many_SLS(start, fin) functions
// 2. Use the AUfit(AUWave, T, cutoffI, hnu) function to get the offset for Ef
// 3. Correct all EDMs with corresponding AU waves using Function ProcessEDM(EDM, EfWave, hnu, sampleString)


Function ProcessAUWave(AUWave, T, cutoffI, hnu)
	
	Wave AUwave
	Variable T, cutoffI, hnu
	
	Wave w = AUfit(AUWave, T, cutoffI, hnu)
	SmoothAUWave(w)
End


// Smooth a gold wave fit to be used in Ef offsets
Function SmoothAUWave(AUwave)
	
	Wave AUwave
	
	String smoothWave = nameOfWave(AUwave) + "_smooth"
	Duplicate/O AUwave, $(smoothWave)
	Wave smoothW = $(smoothWave)
	
	Smooth/B=5 6, smoothW
	Smooth/B=5 10, smoothW
	Smooth/B=40 20, smoothW
End 

// Fit non broadened FD to Au calibration wave
Function/Wave AUfit(AUWave, T, cutoffI, hnu)

	Wave AUWave
	Variable T, cutoffI, hnu
	
	DFREF dfr = GetDataFolderDFR()
	
	Variable n, err
	Variable E0 = hnu - 5 // Assume work function of ~5
	
	NewDataFolder/O/S root:processing
	
	WaveStats/Q/RMD=[*][cutoffI, *] AUwave
	Variable Amp = V_max
	
	Make/O coeff = {T, E0, Amp} // Initial values for Temperature, Ef position and resolution
	Make/O/N=(DimSize(AUwave, 0)) EfPos
	SetScale/P x, DimOffset(AUwave, 0), DimDelta(AUwave, 0), "deg", Efpos
	
	For (n=0; n<dimSize(AUwave, 0); n++)
		coeff = {T, E0, Amp}
		FuncFit/W=2/Q/N/H="10" FDfitfunc, coeff, AUwave[n][cutoffI, *]
		EfPos[n] = coeff[1]
	EndFor
	
	String df = GetWavesDataFolder(AUwave, 1)
	String EfWavePath = df + nameOfWave(AUwave) + "_Ef"
	
	Duplicate/O Efpos, $(EfWavePath)
	Wave w = $(EfWavePath)
	
	SetDataFolder dfr
	
	Return w
End

// No resolution broadening, only interested in Ef position
Function FDfitfunc(coeff, x) : FitFunc

	Wave coeff
	Variable x
	
	Variable T = coeff[0]
	Variable E0 = coeff[1]
	Variable Amp = coeff[2]
	Variable boltzmann = 8.617 * 10^(-5)
	
	Variable f = Amp / (exp((x-E0)/(boltzmann * T)) + 1)

	return f
End

// Example: ProcessEDM(root:RawData:'H5_B3A1(S4)':'AN->N 250K':'SLS_602-608 AN', root:RawData:GoldWaves:a_unsure_Ef_smooth, 100, "H5_B3A1_S4")
Function ProcessEDM(EDM, EfWave, hnu, sampleString)

	Wave EDM, EfWave
	String sampleString
	Variable hnu
	
	String prevdf = GetDataFolder(1)
	
	String dfName = GetWavesDataFolder(EDM, 0)
	NewDataFolder/O root:ScaledData
	NewDataFolder/O $("root:ScaledData:" + sampleString)
	NewDataFolder/O/S $("root:ScaledData:" + sampleString + ":" + dfName)
	
	// Set Ef
	Wave EfCorrectedEDM = setEf(EfWave, EDM)
	// Set k scale
	Variable maxRangeX = DimOffset(EfCorrectedEDM, 0) + DimDelta(EfCorrectedEDM, 0) * DimSize(EfCorrectedEDM, 0)
	SetScale/I x, angleToK(dimOffset(EfCorrectedEDM, 0), hnu), angleToK(maxRangeX, hnu), "A^-1", EfCorrectedEDM
	
	Duplicate/O EfCorrectedEDM, $(NameOfWave(EDM))
	
	SetDataFolder prevdf
End

// Takes an Ef calibration wave as found by fitting an FD distribution to a gold EDM
// This corrects the measured EDM for detector inhomogenities
//
// Returns the corrected wave for further processing
Function/WAVE setEf(EfWave, waveToSet)

	Wave EfWave, waveToSet
	
	String df = GetDataFolder(1)
	NewDataFolder/O/S root:processing
	Duplicate/O waveToSet, corrected
	Duplicate/O waveToSet, original
	
	WaveStats/Q EfWave
	SetScale/P y, DimOffset(waveToSet, 1) - V_avg, DimDelta(waveToSet, 1), "eV", corrected
	SetScale/P y, DimOffset(waveToSet, 1) - V_avg, DimDelta(waveToSet, 1), "eV", original
	
	Duplicate/O EfWave, offsets
	offsets -= v_avg
	SetScale/I x, DimOffset(waveToSet, 0), DimSize(waveToSet, 0) * DimDelta(waveToSet, 0) + DimOffset(waveToSet, 0), offsets
	
	
	Variable n, err
	
	For (n=0; n<dimSize(waveToSet, 0); n++)
		// Extract wave from total EDM and ensure it is 1D
		Duplicate/O/RMD=[n][*] waveToSet, tmpWave
		Redimension/N=(DimSize(waveToSet, 1), 0, 0, 0) tmpWave 
		// Account for mismatched wave dimensions
		Variable i = scaleToIndex(offsets, indexToScale(waveToSet, n, 0), 0)
		// Correct Ef offset
		SetScale/P x, DimOffset(corrected, 1) - offsets[i], DimDelta(corrected, 1), "eV", tmpWave

		corrected[n][] = tmpWave(y); err = GetRTError(1)
	EndFor

	//KillWaves tmpWave, offsets
	SetDataFolder df
	
	return corrected
End

// Data browser wrapper for setting Ef
Function setEfWrapper(EfWave, waveToSet)
	
	Wave EfWave, waveToSet
	
	Wave w = setEf(EfWave, waveToSet)
	Duplicate/O w, waveToSet	
End

Function SetEfForFolder(folder, EfWave)
	
	String folder
	Wave EfWave
	
	DFREF df = GetDataFolderDFR()
	SetDataFolder folder
		
	Variable n
	Variable numWaves = CountObjects(folder, 1)
	
	For (n=0; n<numWaves; n++)
		Wave w = $(GetIndexedObjName(folder, 1, n))
		setEfWrapper(EfWave, w)
	EndFor
	
	SetDataFolder df

End

// Load SLS data (all files separately)
Function Load_many_SLS_separate(start, fin)

	Variable start, fin
	Variable n = 0

	for (n=start; n<=fin; n++)
		Load_many_SLS(n, n)
	EndFor
End


// Load SLS data (added from start to fin)
function Load_many_SLS(start, fin)

	Variable start, fin
	Variable n
	String loadname
	String base = "B3A1_s4_h5"
	Variable err

	//start = 69
	//fin = 69

	For(n=start;n<=fin;n+=1)
		String numStr =""
		sprintf numStr, "%04d", n
		//SetDatafolder root:
		loadname = "E:Natuurkunde:ARPES:SLS:RawData:" + base + ":" + base + "_" + numStr + ".h5"
		 
		String new = LoadSIStemHDF5_Easy(loadname)
		
		Wave edm = $new
		
		if(n==start)
			String fname = "SLS_"+num2str(start)+"_"+num2str(fin)
			
			Duplicate/o edm, $fname
			
			wave basefile = $fname
			
			//duplicate/o basefile, original
		else		
			basefile[][]+=edm[p][q]
			Killwaves/Z edm
		endif
		
	endfor
	
	Matrixtranspose basefile; err = GetRTError(1)
End

// Set k-scale on EDM
Function EDMkScale(w, hnu)

	Variable hnu
	Wave w
	
	Variable maxRangeX = DimOffset(w, 0) + DimDelta(w, 0) * DimSize(w, 0)
	SetScale/I x, angleToK(dimOffset(w, 0), hnu), angleToK(maxRangeX, hnu), "A^-1", w 
End

Function SetkScaleOnFolder(folder, hnu)

	DFREF folder
	Variable hnu
	
	SetDataFolder folder	
	
	Variable numWaves = countObjectsDFR(folder, 1)
	Variable n
	
	For (n=0; n<numWaves; n++)
		Wave w = $(GetIndexedObjNameDFR(folder, 1, n))
		EDMkScale(w, hnu)
	EndFor
	
End

Function FormatEDMPlot()
	
	SetAxis left 94.8,95.6;DelayUpdate
	SetAxis bottom -0.5,0.5;DelayUpdate
	ModifyGraph manTick(left)={0,0.2,0,1},manMinor(left)={3,0},manTick(bottom)={0,0.25,0,2},manMinor(bottom)={1,0};DelayUpdate
	ModifyGraph width=125, height=250
End

// Set scales correctly on EDM, simple version assuming constant Ef offset
Function PrepEDM(w, Ef, hnu)

	Variable Ef, hnu
	Wave w
	
	Variable maxRangeX = DimOffset(w, 0) + DimDelta(w, 0) * DimSize(w, 0)
	SetScale/I x, angleToK(dimOffset(w, 0), hnu), angleToK(maxRangeX, hnu), "A^-1", w 
	
	SetScale/P y, DimOffset(w, 1) - Ef, DimDelta(w, 1), "eV", w
End

// Replaces the map by a transposed and scale corrected version
Function PrepMap(transpose, w, Ef, hnu)

	Variable transpose, Ef, hnu
	Wave w
	
	Duplicate w, tmp
	
	if (transpose == 1)
		MatrixOP/O w = transposeVol(tmp, 5)
		SetScale/P x, dimOffset(tmp, 1), dimDelta(tmp, 1), "deg", w
		SetScale/P y, dimOffset(tmp, 0), dimDelta(tmp, 0), "eV", w
		SetScale/P z, dimOffset(tmp, 1), dimDelta(tmp, 1), "deg", w
	EndIf
	
	KillWaves tmp
	
	// Set degree scales
	Variable maxRangeX = DimOffset(w, 0) + DimDelta(w, 0) * DimSize(w, 0)
	SetScale/I x, angleToK(dimOffset(w, 0), hnu), angleToK(maxRangeX, hnu), "A^-1", w
	Variable maxRangeY = DimOffset(w, 2) + DimDelta(w, 2) * DimSize(w, 2)
	SetScale/I z, angleToK(dimOffset(w, 2), hnu), angleToK(maxRangeX, hnu), "A^-1", w
	
	// Set Energy Scale
	SetScale/P y, DimOffset(w, 1) - Ef, DimDelta(w, 1), "eV", w
	
End

// Conversion function between detector angle and k-scale
Function angleToK(angle, energy)
	
	Variable angle, energy
	
	return 0.512 * sqrt(energy) * sin(angle*(pi/180))
End
	
	
		