#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// Format a graph of fits of the chosen EDM
Function GraphFitOf(OriginalEDM)

	Wave OriginalEDM
	
	String waveN = nameOfWave(OriginalEDM)
	
	String fit_wave_name = waveN + "_fit"
	String fitted_on_name = waveN + "_integrated"
	
	Wave coeffs = $(waveN + "_coeffs")
	Variable Ef = coeffs[1]
	Variable T = coeffs[0]
	
	Variable broadening = (8.617 * 10^(-5)) * (T-12)
	
	Display $(fitted_on_name)	
	AppendToGraph $(fit_wave_name)

	string list = tracenamelist("", ";", 5)
	string trace1 = stringfromlist(0, list)
	string trace2 = stringfromlist(1, list)

	Legend/C/N=text0/J "\\s("+fitted_on_name+") Integrated EDM\r\\s("+fit_wave_name+") Fit"
	ModifyGraph lsize=3
	ModifyGraph rgb($trace2)=(0,0,0)
	ModifyGraph lstyle($trace2)=3
	ModifyGraph tick=2,mirror=1
	TextBox/C/N=Title/F=0/A=MC "\\Z18Resolution: " + num2str(broadening) +" eV, Ef = " + num2str(Ef) + " ("+waveN+")"
	TextBox/C/N=Title/A=MT/X=0.00/Y=0.00/E
	Label bottom "Energy(eV)"
	Label left "Intensity (a.u.)"
	ModifyGraph lsize=2, width=600, height=400
End
	

// Do fd fit on all AU waves
Function fitAUwaves(folder, T, cutoffIndex, hnu)

	DFREF folder
	Variable T, cutoffIndex, hnu
	
	DFREF folder_ref = GetDataFolderDFR()
	
	NewDataFolder/O root:analysis:AUfits
	SetDataFolder root:analysis:AUfits
	
	Variable i = 0
	Variable numWaves = CountObjectsDFR(folder, 1)
	
	for (i=0;i<numWaves;i++)
		// Get Wave from folder and duplicate for reference
		Wave w = $(GetDataFolder(1, folder) + GetIndexedObjNameDFR(folder, 1, i))
		Duplicate/O w, $(nameOfWave(w))
		// Integrate over momentum and duplicate for reference
		Wave integratedAU = integrateEDM(w)
		Duplicate/O/RMD=(16.8, 17.2) integratedAU, $(nameOfWave(w) + "_integrated")
		Wave toFit = $(nameOfWave(w) + "_integrated")
		// Do fit and save fitted EDC
		Wave coeffs = fitSingleEDC(toFit, T, cutoffIndex, hnu)	
		Duplicate/O coeffs, $(nameOfWave(w) + "_coeffs")
		// Generate fitted wave
		Duplicate/O/RMD=(16.8, 17.2) integratedAU, $(NameOfWave(w) + "_fit")
		Wave fittedWave = $(NameOfWave(w) + "_fit") 
		fittedWave = FDfitfuncBackground(coeffs, x)
	EndFor
	
	SetDataFolder folder_ref
End

// Fit a single gold wave with FD function
Function/WAVE DoFDFitOnGoldWave(AUwave, T, cutoffIndex, hnu)

	Wave AUWave
	Variable T, cutoffIndex, hnu
	
	Wave integratedAU = integrateEDM(AUwave)
	Wave coeffs = fitSingleEDC(integratedAU, T, cutoffIndex, hnu)	
	return coeffs
End

// Integrate an EDM along the momentum direction
Function/Wave integrateEDM(edm)

	Wave edm
	DFREF folder_ref = GetDataFolderDFR()
	
	NewDataFolder/O root:analysis:integrated
	SetDataFolder root:analysis:integrated
	
	MatrixOP/O sumOfCols = sumcols(edm)^t
	Redimension/N=(dimSize(edm, 1)) sumOfCols
	SetScale/P x, dimOffset(edm, 1), dimDelta(edm, 1), sumOfCols
	
	SetDataFolder folder_ref
	
	return sumOfCols
End

Function/WAVE fitSingleEDC(EDC, T, cutoffIndex, E)

	Wave EDC
	Variable T, cutoffIndex, E
	
	DFREF folder_ref = GetDataFolderDFR()
	
	// Set up datafolders
	NewDataFolder/O root:analysis:fits
	SetDataFolder root:analysis:fits
	
	// Initial values
	
	WaveStats/Q/RMD=(16.8, 17.2) EDC
	Variable Amp = V_max
	Extract/INDX/FREE EDC, extractedWave, EDC[p] < (0.5 * Amp)
	Variable E0 = IndexToScale(EDC, extractedWave[0], 0)
	Variable bck = -V_max / 10000
	Variable bck2 = V_max
	Make/O coeff = {T, E0, Amp, bck, bck2} 
	
	// Do fit
	FuncFit/W=2/Q/N/H="00000" FDfitfuncBackground, coeff, EDC(16.8, 17.2)

	print(coeff[1])
	
	SetDataFolder folder_ref
	
	return coeff
End

// Helper function for plotting fits
Function/WAVE coeffToWave(originalWave, coeffs)

	Wave originalWave, coeffs
	
	DFREF folder_ref = GetDataFolderDFR()
	
	// Set up datafolders
	NewDataFolder/O root:analysis:fits
	SetDataFolder root:analysis:fits
	
	Duplicate/O originalWave, t
	Wave t 
	t = FDfitfuncBackground(coeffs, x)
	
	SetDataFolder folder_ref
	
	return t
End
	
// Display both original function and fit in one window
Function plotFDFit(coeffs, originalEDC)

	Wave coeffs, originalEDC
	
	DFREF folder_ref = GetDataFolderDFR()
	
	// Set up datafolders
	NewDataFolder/O root:analysis:fits
	SetDataFolder root:analysis:fits
	
	// Display fits
	Display originalEDC
	Duplicate/O originalEDC, fittedEDC
	Wave fittedEDC
	fittedEDC = FDfitfuncBackground(coeffs, x)
	AppendToGraph fittedEDC
	
	SetDataFolder folder_ref
	
End

// No resolution broadening, only interested in Ef position
Function FDfitfuncBackground(coeff, x) : FitFunc

	Wave coeff
	Variable x
	
	Variable T = coeff[0]
	Variable E0 = coeff[1]
	Variable Amp = coeff[2]
	Variable bck = coeff[3]
	Variable bck2 = coeff[4]
	Variable boltzmann = 8.617 * 10^(-5)
	
	Variable f = Amp / (exp((x-E0)/(boltzmann * T)) + 1) + bck * x + bck2

	return f
End
