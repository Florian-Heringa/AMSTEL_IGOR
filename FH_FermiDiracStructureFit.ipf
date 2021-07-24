#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.



//==================================================================================
// Example Fit Function
//

Function FitFD_nobroadening(strct) : FitFunc

	STRUCT fitStruct &strct
	// params = {Ef, amplitude, background_lin, background_cst}
	// constants = {Temperature, boltzmann}

	strct.yw = strct.pw[1] / ( exp( (strct.xw - strct.pw[0]) / (strct.cst[0] * strct.cst[1]) ) + 1 ) + strct.pw[2] * strct.xw + strct.pw[3]
	// f = amplitude / (e^((E-Ef)/(kBT)) + 1) + background_lin * E + background_cst
End

Function FitFD_broadened(strct) : FitFunc

	STRUCT fitStruct &strct
	// params = {Ef, amplitude, background_lin, background_cst, sigma}
	// constants = {Temperature, boltzmann}
	
	// TODO: determine correct amount of points to get to 6 sigma
	Variable dx = deltax(strct.yw)
	Make/D/O/N=201 gaussian
	SetScale/P x, -dx*100, dx, gaussian
	
	// Get normalised gaussion to use in convolution
	Make/O gaussParams = {0, 1, 0, strct.pw[4]} // {offset, amplitude, mean, sigma}
	gaussian = gauss1D(gaussParams, x)
	Variable nrm
	nrm = sum(gaussian)
	gaussian /= nrm
	
	strct.yw = strct.pw[1] / ( exp( (strct.xw - strct.pw[0]) / (strct.cst[0] * strct.cst[1]) ) + 1 ) 
	
	Duplicate/O strct.yw beforeConv // DBG
	
	Convolve/A gaussian, strct.yw
	
	Duplicate/O strct.yw afterConv // DBG
	
	// Do offset separately to avoid offset effects in convolution
	strct.yw += strct.pw[3] + strct.pw[2] * strct.xw
End


//==================================================================================
// Specific functions, non general
//

Function findEfGuess(w)

	Wave w
	
End

//==================================================================================
// Example
//

Function ExampleQuadraticFit()

	NewDataFolder/O/S root:StructureFitTest
	
	Make/O/N=100 toFit
	SetScale/i x, -10, 10, toFit
	toFit = (3+gnoise(1)) * x^2 + (0.5 + gnoise(0.25)) * x + (3 + gnoise(1))
	
	Make/O params = {3, 0.5, 3}
	Make/O cst = {0}
	
	StructureFitWrapper(params, toFit, cst, SimpleQuadratic, displayFit = 1)
End

Function FitFD(toFit, Emin, Emax)

	Wave toFit
	Variable Emin, Emax

	NewDataFolder/O/S root:analysis:AU_nonbroadened_StructureFits
	
	// Duplicate wave so reference is kept of original wave
	Duplicate/O/RMD=(0, *)(Emin, Emax) toFit, $(nameofwave(toFit))
	Wave toFitRef = $(nameofwave(toFit))
	
	Wave integratedEDM = integrateEDM(toFitRef)
	Duplicate/O integratedEDM $(nameofwave(toFitRef) + "_integrated")
	
	// Initial values for fit
	// params = {Ef, amplitude, background_lin, background_cst, sigma}
	Wavestats/Q/Z integratedEDM
	Variable amp_init = V_max
	Extract/INDX/FREE integratedEDM, extractedWave, integratedEDM[p] < (0.5 * Amp_init)
	Variable Ef_init = IndexToScale(integratedEDM, extractedWave[0], 0)
	Variable back_lin = -V_max / 10000
	Variable back_cst = V_max / 10000
	
	// Create initial values wave for fit
	Make/O $(nameofwave(toFitRef) + "_params") = {Ef_init, amp_init, back_lin, back_cst}
	Wave params = $(nameofwave(toFitRef) + "_params")
	Duplicate/O params, $(nameofwave(toFitRef) + "_init_params")
	Wave init_params = $(nameofwave(toFitRef) + "_init_params")
	
	// Create constants wave
	// constants = {Temperature, boltzmann}
	Make/O cst = {13, 8.617 * 10^(-5)}
	
	Wave fitted = StructureFitWrapper(params, integratedEDM, cst, FitFD_nobroadening)
	
	Duplicate/O fitted, $(nameofwave(toFitRef) + "_fitted")
	
	Wave xw
	KillWaves cst, xw
End

//============================================================================================
// The following two functions are for fitting a broadened FD to an integrated EDM.

Function FitBroadenedFD(toFit, Emin, Emax)

	Wave toFit
	Variable Emin, Emax

	NewDataFolder/O/S root:analysis:AU_broadened_StructureFits
	
	// Duplicate wave so reference is kept of original wave
	Duplicate/O/RMD=(0, *)(Emin, Emax) toFit, $(nameofwave(toFit))
	Wave toFitRef = $(nameofwave(toFit))
	
	Wave integratedEDM = integrateEDM(toFitRef)
	Duplicate/O integratedEDM $(nameofwave(toFitRef) + "_integrated")
	
	// Pad wave with 100 points before and after to minimise convolution influence at edges
	Make/O/N=(dimSize(integratedEDM, 0) + 200) $(nameofwave(toFitRef) + "_padded") = 0
	Wave paddedToFit = $(nameofwave(toFitRef) + "_padded")
	SetScale/P x, dimOffset(integratedEDM, 0) - 100 * dimDelta(integratedEDM, 0), dimdelta(integratedEDM, 0), paddedToFit
	paddedToFit[0, 99] = integratedEDM[0]
	paddedToFit[100, 100 + dimSize(integratedEDM, 0) - 1] = integratedEDM[p-100]
	paddedToFit[100 + dimSize(integratedEDM, 0) - 1, *] = integratedEDM[dimSize(integratedEDM, 0) - 1]

	// Initial values for fit
	// params = {Ef, amplitude, background_lin, background_cst, 2 * var}
	Wavestats/Q/Z paddedToFit
	Variable amp_init = V_max
	Extract/INDX/FREE paddedToFit, extractedWave, paddedToFit[p] < (0.5 * Amp_init)
	Variable Ef_init = IndexToScale(paddedToFit, extractedWave[0], 0)
	Variable back_lin = -V_max / 10
	Variable back_cst = 0
	Variable sigma = 0.01
	
	// Create initial values wave for fit
	Make/O $(nameofwave(toFitRef) + "_params") = {Ef_init, amp_init, back_lin, back_cst, sigma}
	Wave params = $(nameofwave(toFitRef) + "_params")
	Duplicate/O params, $(nameofwave(toFitRef) + "_init_params")
	Wave init_params = $(nameofwave(toFitRef) + "_init_params")
	
	// Create constants wave
	// constants = {Temperature, boltzmann}
	Make/O cst = {13, 8.617 * 10^(-5)}
	
	Wave fitted = StructureFitWrapper(params, paddedToFit, cst, FitFD_broadened)
	
	Duplicate/O fitted, $(nameofwave(toFitRef) + "_fitted")
	Wave fittedWave = $(nameofwave(toFitRef) + "_fitted")
	
	Wave xw
	KillWaves cst, xw
	
	display paddedToFit
	appendToGraph fittedWave
	
	string list = tracenamelist("", ";", 5)
	string trace1 = stringfromlist(0, list)
	string trace2 = stringfromlist(1, list)
	
	Variable Ef = params[0]
	Variable FWHM = 1.66511 * params[4] // multiply by 2 ln(2) to recover FWHM
	String waveN = nameOfWave(toFitRef)

	Legend/C/N=text0/J "\\s("+nameOfWaVE(paddedToFit)+") Integrated EDM\r\\s("+NameOfWave(fittedWave)+") Fit"
	ModifyGraph lsize=3
	ModifyGraph rgb($trace2)=(0,0,0)
	ModifyGraph lstyle($trace2)=3
	ModifyGraph tick=2,mirror=1
	TextBox/C/N=Title/F=0/A=MC "\\Z18Resolution: " + num2str(FWHM*1000) +" meV, Ef = " + num2str(Ef) + " ("+waveN+")"
	TextBox/C/N=Title/A=MT/X=0.00/Y=0.00/E
	Label bottom "Energy(eV)"
	Label left "Intensity (a.u.)"
	ModifyGraph lsize=2, width=450, height=300
	SetAxis bottom Emin, Emax
End
	
// FIT broadened FD for every wave in folder
Function FitFD_for_folder(folder)

	DFREF folder

	Variable Emin = 16.8
	Variable Emax = 17

	
	DFREF folder_ref = GetDataFolderDFR()
	
	SetDataFolder folder
	
	Variable i = 0
	Variable numWaves = CountObjectsDFR(folder, 1)
	
	for (i=0;i<numWaves;i++)
		Wave w = $(GetDataFolder(1, folder) + GetIndexedObjNameDFR(folder, 1, i))
		FitBroadenedFD(w, Emin, Emax)
	EndFor
	
	SetDataFolder folder_ref
End

//=======================================================================
// Fit every EDC in an EDM with broadened FD function
// NOT WORKING 

Function/WAVE FitBroadenedFD_per_EDC(toFit, Emin, Emax, T, Ef_init_guess)

	Wave toFit // EDM
	Variable Emin, Emax, T, Ef_init_guess
	
	NewDataFolder/O root:analysis
	NewDataFolder/O/S root:analysis:AU_fits
	
	Duplicate/O/RMD=()(Emin, Emax) toFit, $(nameofWave(toFit))
	wave toFitRef = $(nameofWave(toFit))
	SetScale/P x, dimOffset(toFit, 0), dimDelta(toFit, 0), toFitRef
	
	Variable numEDCs = dimSize(toFitRef, 0)
	
	// Set up variables to use in loop
	Variable amp_init, Ef_init, back_lin, back_cst, broadening
	Make/O/N=5 params
	Make/FREE/N=2 cst = {T, 8.617 * 10^(-5)}
	
	// Container wave for holding fit parameters
	Make/O/N=(dimSize(toFit, 0), 5) $(nameOfWave(toFit) + "_params")
	Wave res = $(nameOfWave(toFit) + "_params")
	SetScale/P x, dimOffset(toFit, 0), dimDelta(toFit, 0), res
	
	// Container wave for holding fitted values
	Duplicate/O toFitRef, $(nameofwave(toFitRef) + "_fitted")
	Wave fitted = $(nameofwave(toFitRef) + "_fitted")
	
	Variable i
	for (i = 0; i < numEDCs-4; i++)
	
		Make/FREE/N=(dimSize(toFitRef, 1)) EDCtoFit
		SetScale/P x, dimOffset(toFitRef, 1), dimDelta(toFitRef, 1), EDCtoFit
		
		EDCtoFit = toFitRef[i][p] + toFitRef[i+1][p] + toFitRef[i+2][p] + toFitRef[i+3][p] + toFitRef[i+4][p]
		
		// Initial Values
		WaveStats/Q/Z EDCtoFit
		amp_init = V_avg
		//Extract/INDX/FREE EDCtoFit, extr, EDCtoFit[p] < (0.5 * Amp_init)
		Ef_init = Ef_init_guess//IndexToScale(EDCtoFit, extr[0], 0)
		back_lin = -V_max / 10
		back_cst = 0
		broadening = 0.01
		
		params = {Ef_init, amp_init, back_lin, back_cst, broadening}
		
		Wave f = StructureFitWrapper(params, EDCtoFit, cst, FitFD_broadened)
		
		fitted[i][] = f[q]
		res[i][] = params[q]
	
	EndFor
	
	Wave integratedFit = integrateEDM(fitted)
	Duplicate/O integratedFit, $(nameOfWave(toFit) + "_integratedfit")
	Wave intedm = $(nameOfWave(toFit) + "_integratedfit")
	
	// Display results
	Duplicate/O/RMD=[][0] res, Ef_pos
	Redimension/N=-1 Ef_pos
	Display Ef_pos
	AppendImage fitted
	
	Wave integrated_original = integrateEDM(toFitRef)
	Duplicate/O integrated_original, $(nameOfWave(toFit) + "_integratedoriginal")
	Display integratedFit
	AppendToGraph integrated_original
	
End

// Preapre an EDM by integrating each point for +- integration?steps/2 around it
// returns an EDM of size dimSize(EDM) - integration_steps/2
Function prep_k_integrated_EDM(EDM, integration_steps)

	Wave EDM
	Variable integration_steps // Should be an odd integer
	
	Variable dI = floor(integration_steps / 2)
	
	NewDataFolder/O/S root:analysis:k_integrated_EDM
	
	Make/O/N=(dimSize(EDM, 0) - dI, dimSize(EDM, 1)) EDM_container
	Wave EDM_container
	SetScale/P x, dI * dimDelta(EDM, 0) + dimOffset(EDM, 0), dimDelta(EDM, 0), EDM_container
	SetScale/P y, dimOffset(EDM, 1), dimDelta(EDM, 1), EDM_container
	
	Variable i
	// Loop in range [integration_steps, dimsize(EDM) - integration_steps]
	For (i=dI; i < dimSize(EDM_container, 0) - dI; i++)
		
		Duplicate/FREE/RMD=[i-dI, i+dI][] EDM, EDM_int
		EDM_container[i-dI][] = integrateEDM(EDM_int)[q]
	
	EndFor
End
