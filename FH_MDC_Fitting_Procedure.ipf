#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Functions in this procedure:

// doAll(doFit)
// --Fit all EDMs in root:EDMs
//		doFit		: 1 or 0, actually do fit, or only display

// fitAndDisplay(dataset, nEf, doFit, plotUntil)
// -- fit all EDMs in root:EDMs:'dataset'
//		dataSet  	: name of the folder inside of root:EDMs
//		nEf      	: Fermi level index of dataset (only defines where to start the fitting)
//		doFit    	: 1 or 0, actually do fit, or only display
//		plotUntil	: choose Energy value (negative, counting from Ef) for plot range

// display_fit_info(dataset, paramIndex, plotUntil)
// -- Display a graph of the chosen dataset and parameter
//		dataSet   : name of the folder inside of root:EDMs
//		paramIndex: which parameter to plot (see below for definitions), must be 0-9
//		plotUntil : choose Energy value (negative, counting from Ef) for plot range	

// fit_all_EDMs_in(folder, nEf)
// -- Fit all EDMs in the chosen folder, starting at index nEd and moving down, 
// -- seeding each successive fit with the previously found parameters
// 		folder		: name of folder inside root:EDMs
//		nEf   	 	: Fermi level index of dataset (only defines where to start the fitting) 

// fit_all_mdcs(folder, waveNam, nEf)
// -- Fit all mdcs from the chosen EDM
// 		folder		: name of folder inside root:EDMs
//		waveNam	: name of 2D wave of which to fit all horizontal MDCs
//		nEf			: Fermi level index of dataset (only defines where to start the fitting) 

// fit_single(mdc, params)
// -- Fit just a single mdc (helper function)
//		mdc			: mdc to fit, should be 1D wave with two lorentzian-like peaks
//		params		: parameter list as defined below

// get_EDCs_at_Kf()
// -- Gets all EDCs at the (visually) determined kF values

// plot_all_EDCs_at_kF()
// -- Displays all EDCs at the (visually) determined kF values
// -- can only be run after get_EDCs_at_kF() was at least executed once

// Plot_EDCs_at_kF(dataset, LorR, normed)
// -- Plot all EDCs for a chosen dataset of the left or right chosen kF value
//		dataset	: a dataset in root:EDMs that already has data in root:EDCs due to running get_EDCs_at_kF()
//		LorR		: "L" or "R", picks which peak to plot
//		normed		: plot normalised data (currently normlised to peak maximum)

// get_EDC(dataset, w, kF, LorR)
// -- Get an EDC from the chosen wave, w, in dataset that is present in root:EDMS
//		dataset	: a dataset in root:EDMs
//		w			: a wave inside the chosen dataset
// 		kF			: the chosen kF value (visually determined by finding the leading edgge)
//		LorR		: left or right peak, used in naming resulting EDCs

// The fit parameters are defined like:
// [0] background offset
// [1] background k0
// [2] background linear
// [3] background quad
// [4] left height
// [5] left width
// [6] left pos
// [7] right height
// [8] right width
// [9] right pos

Function doGraph(leftLabel, title, plotUntil)

	String leftLabel, title
	Variable plotUntil

	colourise(99, 0)
	Legend/C/N=$("legend")/F=0/B=1

	Label left "\Z18" + leftLabel;DelayUpdate

	Label bottom "\Z18Energy(\\U)";DelayUpdate
	ModifyGraph mirror=1; DelayUpdate
	ModifyGraph tick=2,fSize(left)=13,fSize(bottom)=13; DelayUpdate
	ModifyGraph fSize=16; DelayUpdate
	Textbox/C/N=title/A=MT/F=0/Z=1/X=0.00/Y=0.00/E=2 "\Z24"+title
	SetAxis bottom plotUntil,0.0
	SetAxis/A=2 left
	ModifyGraph lsize=2, width=600, height=400
End

/////////////////////////// NOT WORKING......
Function removeFDfromDataset(folder)

	String folder
	
	String df = getDataFolder(1)
	
	SetDataFolder folder

	Variable numWaves = countObjects(folder, 1)
	Variable n = 0
	String expr = "(?<=_)(\d+)(?=K)"
	String T = "1"
	
	for (n=0; n<numWaves; n++)
		String wName = GetIndexedObjName(folder, 1, n)
		Wave tmp = $(folder + ":" + wName)
		SplitString/E=(expr) wName, T
		Variable temperature = str2num(T)
		//Make/O $(nameofwave(tmp) + "_FDremoved")
		Wave tmpW = removeFD(tmp, temperature)
		Duplicate tmpW $(nameofwave(tmp) + "_FDremoved")
	EndFor	
	
	Wave FD
	Wave vFD
	
	KillWaves vFD
	
	SetDataFolder df
End

// Just uncomment the ones you want to refit/display
Function fitAll(doFit)

	Variable doFit
	
	fitAndDisplay(   "F6AN", 416, doFit, -0.2, 378)
	fitAndDisplay( "F6ANm5", 417, doFit, -0.2, 350)
	fitAndDisplay( "F6ANm8", 417, doFit, -0.2, 307)
	fitAndDisplay("F6ANm10", 417, doFit, -0.2, 270)
	fitAndDisplay("F6ANm12", 417, doFit, -0.2, 175)
	
	fitAndDisplay(   "F5bAN", 413, doFit, -0.2, 350)
	fitAndDisplay( "F5bANm5", 419, doFit, -0.2, 342)
	fitAndDisplay( "F5bANm8", 416, doFit, -0.2, 315)
	fitAndDisplay("F5bANm10", 419, doFit, -0.2, 250)
	fitAndDisplay("F5bANm12", 417, doFit, -0.2, 190)
//	
//	fitAndDisplay( "F5ANm5_22eV", 416, doFit, 17.4)
//	fitAndDisplay( "F5ANm10_22eV", 416, doFit, 17.4)
//	fitAndDisplay("F5ANm12_22eV", 416, doFit, 17.4)
//	fitAndDisplay("F5AN_22eV", 413, doFit, 17.4)

//	fitAndDisplay( "F5bANm5_22eV", 416, doFit, 17.4)
//	fitAndDisplay( "F5bANm10_22eV", 416, doFit, 17.4)
//	fitAndDisplay("F5bANm12_22eV", 416, doFit, 17.4)
//	fitAndDisplay("F5bAN_22eV", 416, doFit, 17.4)
//
//	fitAndDisplay( "F6AN", 395, doFit, 17.4)
//	fitAndDisplay( "F6ANm5", 416, doFit, 17.4)
//	fitAndDisplay("F6ANm8", 416, doFit, 17.4)
//	fitAndDisplay("F6ANm10", 416, doFit, 17.4)
//	fitAndDisplay("F6ANm12", 395, doFit, 17.4)

End

Function fitAndDisplay(dataset, nEf, doFit, plotUntil, fitUntil)

	String dataSet
	Variable nEf, doFit, plotUntil, fitUntil
	
	If (doFit)
		printf "Doing %s\r", dataset
		fit_all_EDMs_in(dataSet, nEf, fitUntil)
	EndIf
	
	Variable i
	
	For (i = 4; i < 10; i++)
		display_fit_info(dataSet, i, plotUntil)
	EndFor
End

// Dataset is the name of the folder (which already has fitted data)
// Makes and saves graphs for all datasets
Function display_fit_info(dataset, paramIndex, plotUntil)

	String dataset
	Variable paramIndex, plotUntil
	
	Make/O/T/N=(10) paramNames = {"bckg_offset", "bckgr_k0", "bckgr_lin", "bckgr_quad", "L_height", "L_width", "L_pos", "R_height", "R_width", "R_pos"}
	
	//printf "Displaying %s\r", paramNames[paramIndex]
	
	NewDataFolder/O/S root:Fitresults
	NewDataFolder/O/S root:Fitresults:Graphs
	NewDataFolder/O/S $("root:Fitresults:Graphs:" + paramNames[paramIndex])
	
	String fullPath = "root:Fitresults:" + dataset
	Variable numDataSets = CountObjects(fullPath, 4) // count all datasets
	Variable n
	
	Make/O/T/N=(numDataSets) titles
	
	For (n = 0; n< numDataSets; n++)
		String dataSetName = GetIndexedObjName(fullPath, 4, n)
		String dataPath = fullPath + ":" + dataSetName
		String paramCollPath = dataPath + ":fitParamCollection"
		// Info for legend
		titles[n] = dataSetName
		
		Make/O/N=(dimSize($paramCollPath, 1)) $dataSetName 
		Wave paramWave = $dataSetName
		SetScale/P x, dimOffset($paramCollPath, 1), dimDelta($paramCollPath, 1), waveUnits($paramCollPath, 1) paramWave
		
		Wave paramCollWave = $paramCollPath
		
		paramWave = paramCollWave[paramIndex][p]
	EndFor
	
	String windowName = "fitParam_" + paramNames[paramIndex]
	
	KillWindow/Z $(windowName)
	Display/K=1/N=$(windowName)/W=(0, 0, 600, 400) $titles[0]
	ModifyGraph lsize($titles[0])=2
	
	For (n = 1; n < numDataSets; n++) 
		AppendToGraph/W=$(windowName)/C=(65535 * (1 - n/numDataSets), (0.5) * 65535 * (n/numDataSets), 65535 * (n/numDataSets)) $titles[n]
		ModifyGraph lsize($titles[n])=2
	EndFor
	
	// Legend positions
	if (paramIndex == 6 || paramIndex == 7)
		Legend/C/N=$(windowName + "legend")/F=0/A=LB/B=1
	ElseIf (paramIndex == 5 || paramIndex == 8)
		Legend/C/N=$(windowName + "legend")/F=0/A=RT/B=1
	ElseIf (paramIndex == 4 || paramIndex == 9)
		Legend/C/N=$(windowName + "legend")/F=0/A=LT/B=1
	EndIf
	// Left axis label
	if (paramIndex == 4 || paramIndex == 7)
		Label left "\Z18counts (a.u.)";DelayUpdate
	Else
		Label left "\Z18k(A\S-1\M\Z18)";DelayUpdate
	EndIf
	Label bottom "Energy(\\U)";DelayUpdate
	ModifyGraph mirror=1; DelayUpdate
	ModifyGraph tick=2,fSize(left)=13,fSize(bottom)=13; DelayUpdate
	Textbox/C/N=$(windowName)/A=MT/F=0/Z=1/X=0.00/Y=0.00/E=2 paramNames[paramIndex]
	SetAxis bottom plotUntil,0.01
	SetAxis/A=2 left
	colourise(99, 0)
	
	//NewPath/C/Q/O imgPath "E:Natuurkunde:ARPES:Data:SOLEIL:Summary:"
	//SavePict/O/B=(5*72)/E=-5/P=imgPath as (dataset + "_" + paramNames[paramIndex] + ".png")
End

// Fits all EDMs in the chosen folder,
// The folder is assumed to be in "root:EDMS"
// and should contain only finished EDMS
// "folder" is then simply the folder name in that directory
Function fit_all_EDMs_in(folder, nEf, fitUntil)

	String folder
	Variable nEf, fitUntil
	
	// Check amount of datasets in folder
	Variable dataSets = CountObjects("root:EDMS:" + folder, 1)
	Variable n
	
	// Loop through all EDMs
	For (n = 0; n < dataSets; n++)
		String dataSetName = GetIndexedObjName("root:EDMS:" + folder, 1, n)
		//printf "Start fitting %s\r", dataSetName
		fit_all_mdcs(folder, dataSetName, nEf, fitUntil)	
	EndFor
End

Function fit_all_mdcs(folder, waveNam, nEf, fitUntil)

	String folder
	String waveNam
	Variable nEf
	Variable fitUntil
	
	Wave EDM = $("root:EDMS:" + folder + ":" + waveNam)
	
	String lastDataFolder = getDataFolder(1)
	
	// Folder Structure
	String baseFolder = "root:Fitresults:" + folder
	String fitFolder = baseFolder + ":" + waveNam
	String tempFolder = fitFolder + ":temp"
	
	NewDataFolder/O root:Fitresults
	NewDataFolder/O $(baseFolder)
	NewDataFolder/O/S $(fitFolder)
	NewDataFolder/O $(tempFolder)
	
	Duplicate/O EDM originalEDM
	
	Make/O/N=(10, nEf-fitUntil) fitParamCollection = 0
	// Holds all fit parameters
	SetScale/P y, dimOffset(EDM, 1)+fitUntil*dimDelta(EDM, 1), dimDelta(EDM, 1), "eV", fitParamCollection
	
	// Initial fit Parameters
	Make/O/N=(10) fitParams
	fitParams = 0
	
	SetDataFolder tempFolder
	Make/O/N=(dimSize(EDM, 0)) mdcToFit
	SetScale/P x, dimOffset(EDM, 0), dimDelta(EDM, 0), mdcToFit
	mdcToFit = EDM[p][nEf]
	SetDataFolder fitFolder
	
// Store all separate values in tempfolder
	SetDataFolder tempFolder
	// Left
	Duplicate/O/R=[0, scaleToIndex(EDM, 0, 0)] mdcToFit, mdcPrepL
	WaveStats/Q mdcPrepL
	Variable/G L_height     = abs(V_max - V_min)
	Variable/G L_pos        = V_maxloc
	Variable L_pos_index	 = V_maxRowLoc
	Variable halfMaxVal     = L_height/2 + V_min
		// Look for the location of the half maximum on a single side and double it
	findValue/T=(halfMaxVal*0.05)/V=(halfMaxVal) mdcPrepL
	Variable k1             = indexToScale(mdcPrepL, V_value, 0)
	Variable/G L_FWHM       = abs(2 * (k1 < L_pos ? L_pos - k1 : k1 - L_pos))
	
	// Right
	Duplicate/O/R=[scaleToIndex(EDM, 0, 0), dimSize(mdcToFit, 0)] mdcToFit, mdcPrepR
	WaveStats/Q mdcPrepR
	Variable/G R_height     = abs(V_max - V_min)
	Variable/G R_pos        = V_maxloc
	Variable R_pos_index	 = V_maxRowLoc
	halfMaxVal              = R_height/2 + V_min
		// Look for the location of the half maximum on a single side and double it
	findValue/T=(halfMaxVal*0.05)/V=(halfMaxVal)/S=(x2pnt(mdcPrepR, R_pos)) mdcPrepR
	k1                      = V_value
	Variable/G R_FWHM       = abs(2 * (k1 < R_pos_index ? R_pos_index - k1 : k1 - R_pos_index) * dimDelta(mdcToFit, 0))
	
//	if (L_FWHM<=0 && R_FWHM>=0)
//		L_FWHM=R_FWHM
//	elseif (L_FWHM>=0 && R_FWHM<=0)
//		R_FWHM=R_FWHM
//	endif
	
	fitParams[0] = V_min
	fitParams[1] = 0
	fitParams[2] = 0
	fitParams[3] = 0
	
	fitParams[4] = L_height
	fitParams[5] = L_FWHM
	fitParams[6] = L_pos
	
	fitParams[7] = R_height
	fitParams[8] = R_FWHM
	fitParams[9] = R_pos
	
	// Back to main folder	
	SetDataFolder fitFolder
	
	// Make representation of fit, used in chi^2 measurement
	Duplicate/O mdcToFit, init, lrntzns
	lrntzns = lorentzian(fitParams, x)
	
	Duplicate/O fitParams, initParams
	Duplicate/O EDM, totalFit, res
	totalFit = 0
	res = 0
 	copyScales EDM, totalFit
 	copyScales EDM, res
 	
 	Make/O/N=(dimSize(EDM, 1)) allChiSq
 	SetScale/P x, dimOffset(EDM, 1), dimDelta(EDM, 1), "eV" allChiSq
 	allChiSq = 0
	
	Variable n, err, chiSq
	Variable/G n_end = nEf
	err = 0
	
	for (n=nEf; n>=fitUntil+1; n-=1)
		// Get the mdc to fit and do fit
		mdcToFit = EDM[p][n]
		err = fit_single(mdcToFit, fitParams)
		// Reproduce fitted mdc and store chi^2
		//lrntzns = lorentzian(fitParams, x)
		//allChiSq[n] = chiSquared(mdcToFit, lrntzns)
		// If an error occured in fitting, exit loop
		if (err != 0)
			printf "Error in %s, n=%d\r", waveNam, n
			break
		EndIf
		// Store fit parameters and create reproduced fit
		fitParamCollection[][n-fitUntil-1] = fitParams[p]
		totalFit[][n] = lorentzian(fitParams, x)
		n_end = n
	EndFor
	
	res = EDM - totalFit
	res[][0, n_end] = 0
	res[][nEf, dimSize(res, 1)-1] = 0
	totalFit[][0, n_end] = 0
	totalFit[][nEf, dimSize(totalFit, 1)-1] = 0
	
	SetDataFolder lastDataFolder
	
	killDataFolder tempFolder
End

Function chiSquared(data, fit)

	Wave data, fit

	Duplicate/O data chiSqW
	CopyScales/P data chiSqW
	
	chiSqW = ((data - fit) * (data - fit)) / (fit) 
	
	Variable chiSq = sum(chiSqW)
	
	return chiSq
End

Function fit_single(mdc, params)

	Wave mdc, params
	Variable err
	
	FuncFit/W=2/N/Q/H="0111000000" lorentzian, params, mdc; err = GetRTError(1)
	
	return err
End

Function lorentzian(w, x) : FitFunc

	Wave w
	Variable x
	
	Variable func
	
	Variable pf = (1 / (2 * pi))
	
	// offsets
	func = w[0] + (x - w[1]) * w[2] + (x - w[1]) * (x - w[1]) * w[3]
	// left peak
	func += (pf * w[4] * w[5]) / ((x-w[6])*(x-w[6]) + (w[5])*(w[5])*0.25)
	// right peak
	func += (pf * w[7] * w[8]) / ((x-w[9])*(x-w[9]) + (w[8])*(w[8])*0.25)

	return func
End

//// w is a 1D wave having two peaks, to be fitted with two lorentzians
//Function/Wave fit_MDC(mdcToFit)
//
//	Wave mdcToFit
//	
//	// Set up data folder structure
//	String/G lastDataFolder = getDataFolder(1)
//	NewDataFolder/O/S fitInfo
//	Make/O/N=(10) fitParams
//	fitParams = 0
//	
//	// Get initial values
//	// Left
//	Duplicate/O/R=[0, dimSize(mdcToFit, 0)/2] mdcToFit, mdcPrep
//	WaveStats/Q mdcPrep
//	Variable L_height     = (V_max - V_min)
//	Variable L_pos        = V_maxloc
//	Variable halfMaxVal   = L_height/2 + V_min
//		// Look for the location of the half maximum on both sides
//	findValue/T=(halfMaxVal*0.05)/V=(halfMaxVal) mdcPrep
//	Variable k1           = V_value
//	findValue/T=(halfMaxVal*0.05)/V=(halfMaxVal)/S=(x2pnt(mdcPrep, L_pos)) mdcPrep
//	Variable k2           = V_value
//	Variable L_FWHM       = (k2 - k1) * dimDelta(mdcToFit, 0) 
//	
//	// Right
//	Duplicate/O/R=[dimSize(mdcToFit, 0)/2, dimSize(mdcToFit, 0)] mdcToFit, mdcPrep
//	WaveStats/Q mdcPrep
//	Variable R_height     = (V_max - V_min)
//	Variable R_pos        = V_maxloc
//	halfMaxVal            = R_height/2 + V_min
//		// Look for the location of the half maximum on both sides
//	findValue/T=(halfMaxVal*0.05)/V=(halfMaxVal) mdcPrep
//	k1                    = V_value
//	findValue/T=(halfMaxVal*0.05)/V=(halfMaxVal)/S=(x2pnt(mdcPrep, R_pos)) mdcPrep
//	k2                    = V_value
//	Variable R_FWHM       = (k1 - k2) * dimDelta(mdcToFit, 0) 
//	
//	if (L_FWHM<0 && R_FWHM>0)
//		L_FWHM=R_FWHM
//	elseif (L_FWHM>0 && R_FWHM<0)
//		R_FWHM=R_FWHM
//	endif
//	
//	fitParams[0] = V_min
//	fitParams[1] = 0
//	fitParams[2] = 0
//	fitParams[3] = 0
//	
//	fitParams[4] = L_height
//	fitParams[5] = L_FWHM
//	fitParams[6] = L_pos
//	
//	fitParams[7] = R_height
//	fitParams[8] = R_FWHM
//	fitParams[9] = R_pos
//	
//	// Fitting
//	Duplicate/O fitParams, initParams
//	String holdStr = "0111000000"
//	Duplicate/O mdcToFit, lrntzns, fit, res
//	CopyScales/P mdcToFit, lrntzns, fit, res
//	lrntzns = lorentzian(initParams, x)
//	
//	FuncFit/W=2/N/Q/H=holdStr lorentzian, fitParams, mdcToFit
//	
//	fit = lorentzian(fitParams, x)
//	res = mdcToFit - fit
//	
//	SetDataFolder lastDataFolder
//	
//	Return fitParams
//End

Function get_EDCs_at_Kf_F5b()

	// AN
	get_EDC("F5bAN",   "F5bAN_5K_FDremove", -0.139207, "L")
	get_EDC("F5bAN",   "F5bAN_5K_FDremove",  0.140515, "R")
	get_EDC("F5bAN",  "F5bAN_50K_FDremove", -0.142748, "L")
	get_EDC("F5bAN",  "F5bAN_50K_FDremove",  0.131663, "R")
	get_EDC("F5bAN", "F5bAN_150K_FDremove", -0.100258, "L")
	get_EDC("F5bAN", "F5bAN_150K_FDremove",  0.135204, "R")
	get_EDC("F5bAN", "F5bAN_300K_FDremove", -0.102029, "L")
	get_EDC("F5bAN", "F5bAN_300K_FDremove",   0.13343, "R")
	
	// ANm5
	get_EDC("F5bANm5",   "F5bANm5_5K_FDremove",  -0.149793, "L")
	get_EDC("F5bANm5",   "F5bANm5_5K_FDremove",   0.152933, "R")
	get_EDC("F5bANm5",  "F5bANm5_50K_FDremove",  -0.148023, "L")
	get_EDC("F5bANm5",  "F5bANm5_50K_FDremove",   0.137000, "R")
	get_EDC("F5bANm5", "F5bANm5_150K_FDremove",  -0.112616, "L")
	get_EDC("F5bANm5", "F5bANm5_150K_FDremove",   0.133459, "R")
	get_EDC("F5bANm5", "F5bANm5_300K_FDremove", -0.0931425, "L")
	get_EDC("F5bANm5", "F5bANm5_300K_FDremove",   0.138770, "R")
	
	// ANm8
	get_EDC("F5bANm8",   "F5bANm8_5K_FDremove",  -0.172770, "L")
	get_EDC("F5bANm8",   "F5bANm8_5K_FDremove",   0.170660, "R")
	get_EDC("F5bANm8",  "F5bANm8_50K_FDremove",  -0.185162, "L")
	get_EDC("F5bANm8",  "F5bANm8_50K_FDremove",   0.165349, "R")
	get_EDC("F5bANm8", "F5bANm8_150K_FDremove",  -0.153297, "L")
	get_EDC("F5bANm8", "F5bANm8_150K_FDremove",   0.156498, "R")
	get_EDC("F5bANm8", "F5bANm8_300K_FDremove",  -0.100189, "L")
	get_EDC("F5bANm8", "F5bANm8_300K_FDremove",   0.147647, "R")
	
	// ANm10
	get_EDC("F5bANm10",   "F5bANm10_5K_FDremove",  -0.204634, "L")
	get_EDC("F5bANm10",   "F5bANm10_5K_FDremove",   0.198984, "R")
	get_EDC("F5bANm10",  "F5bANm10_50K_FDremove",  -0.217026, "L")
	get_EDC("F5bANm10",  "F5bANm10_50K_FDremove",   0.197214, "R")
	get_EDC("F5bANm10", "F5bANm10_150K_FDremove",  -0.185162, "L")
	get_EDC("F5bANm10", "F5bANm10_150K_FDremove",   0.193674, "R")
	get_EDC("F5bANm10", "F5bANm10_300K_FDremove",  -0.128513, "L")
	get_EDC("F5bANm10", "F5bANm10_300K_FDremove",   0.161809, "R")
	
	// ANm12
	get_EDC("F5bANm12",   "F5bANm12_5K_FDremove",  -0.247161, "L")
	get_EDC("F5bANm12",   "F5bANm12_5K_FDremove",   0.241449, "R")
	get_EDC("F5bANm12",  "F5bANm12_50K_FDremove",  -0.263094, "L")
	get_EDC("F5bANm12",  "F5bANm12_50K_FDremove",   0.236138, "R")
	get_EDC("F5bANm12", "F5bANm12_150K_FDremove",  -0.232998, "L")
	get_EDC("F5bANm12", "F5bANm12_150K_FDremove",   0.229057, "R")
	get_EDC("F5bANm12", "F5bANm12_300K_FDremove",  -0.169267, "L")
	get_EDC("F5bANm12", "F5bANm12_300K_FDremove",   0.198961, "R")
End

Function plot_all_EDCs_at_kF_F5b()

	Variable normed = 1

	Plot_EDCs_at_kF("F5bAN", "L", normed)
	Plot_EDCs_at_kF("F5bAN", "R", normed)
	Plot_EDCs_at_kF("F5bANm5", "L", normed)
	Plot_EDCs_at_kF("F5bANm5", "R", normed)
	Plot_EDCs_at_kF("F5bANm8", "L", normed)
	Plot_EDCs_at_kF("F5bANm8", "R", normed)
	Plot_EDCs_at_kF("F5bANm10", "L", normed)
	Plot_EDCs_at_kF("F5bANm10", "R", normed)
	Plot_EDCs_at_kF("F5bANm12", "L", normed)
	Plot_EDCs_at_kF("F5bANm12", "R", normed)
End

Function get_EDCs_at_Kf_F6()

	// AN
	get_EDC("F6AN",   "F6AN_5K_FDremove", -0.105498, "L")
	get_EDC("F6AN",   "F6AN_5K_FDremove",  0.102284, "R")
	get_EDC("F6AN",  "F6AN_50K_FDremove", -0.0967679, "L")
	get_EDC("F6AN",  "F6AN_50K_FDremove",  0.100538, "R")
	get_EDC("F6AN", "F6AN_100K_FDremove", -0.0880375, "L")
	get_EDC("F6AN", "F6AN_100K_FDremove",  0.0830769, "R")
	get_EDC("F6AN", "F6AN_150K_FDremove", -0.0897836, "L")
	get_EDC("F6AN", "F6AN_150K_FDremove",  0.0760927, "R")
	get_EDC("F6AN", "F6AN_300K_FDremove", -0.14042, "L")
	get_EDC("F6AN", "F6AN_300K_FDremove",  0.0481556, "R")
	
	// ANm5
	get_EDC("F6ANm5",   "F6ANm5_5K_FDremove",  -0.096814, "L")
	get_EDC("F6ANm5",   "F6ANm5_5K_FDremove",   0.12563, "R")
	get_EDC("F6ANm5",  "F6ANm5_50K_FDremove",  -0.0968144, "L")
	get_EDC("F6ANm5",  "F6ANm5_50K_FDremove",   0.129133, "R")
	get_EDC("F6ANm5", "F6ANm5_100K_FDremove",  -0.0898083, "L")
	get_EDC("F6ANm5", "F6ANm5_100K_FDremove",   0.122127, "R")
	get_EDC("F6ANm5", "F6ANm5_150K_FDremove",  -0.0950629, "L")
	get_EDC("F6ANm5", "F6ANm5_150K_FDremove",   0.118624, "R")
	get_EDC("F6ANm5", "F6ANm5_300K_FDremove",  -0.119584, "L")
	get_EDC("F6ANm5", "F6ANm5_300K_FDremove",   0.115121, "R")
	
	// ANm8
	get_EDC("F6ANm8",   "F6ANm8_5K_FDremove",  -0.151933, "L")
	get_EDC("F6ANm8",   "F6ANm8_5K_FDremove",   0.149765, "R")
	get_EDC("F6ANm8",  "F6ANm8_50K_FDremove",  -0.153677, "L")
	get_EDC("F6ANm8",  "F6ANm8_50K_FDremove",   0.148021, "R")
	get_EDC("F6ANm8", "F6ANm8_100K_FDremove",  -0.158909, "L")
	get_EDC("F6ANm8", "F6ANm8_100K_FDremove",   0.137557, "R")
	get_EDC("F6ANm8", "F6ANm8_150K_FDremove",  -0.158909, "L")
	get_EDC("F6ANm8", "F6ANm8_150K_FDremove",   0.128838, "R")
	get_EDC("F6ANm8", "F6ANm8_300K_FDremove",  -0.185067, "L")
	get_EDC("F6ANm8", "F6ANm8_300K_FDremove",   0.139301, "R")
	
	// ANm10
	get_EDC("F6ANm10",   "F6ANm10_5K_FDremove",  -0.178558, "L")
	get_EDC("F6ANm10",   "F6ANm10_5K_FDremove",   0.184346, "R")
	get_EDC("F6ANm10",  "F6ANm10_50K_FDremove",  -0.180303, "L")
	get_EDC("F6ANm10",  "F6ANm10_50K_FDremove",   0.186091, "R")
	get_EDC("F6ANm10", "F6ANm10_100K_FDremove",  -0.192516, "L")
	get_EDC("F6ANm10", "F6ANm10_100K_FDremove",   0.179112, "R")
	get_EDC("F6ANm10", "F6ANm10_150K_FDremove",  -0.206474, "L")
	get_EDC("F6ANm10", "F6ANm10_150K_FDremove",   0.165154, "R")
	get_EDC("F6ANm10", "F6ANm10_300K_FDremove",  -0.248348, "L")
	get_EDC("F6ANm10", "F6ANm10_300K_FDremove",   0.177367, "R")
	
	// ANm12
	get_EDC("F6ANm12",   "F6ANm12_5K_FDremove",  -0.225178, "L")
	get_EDC("F6ANm12",   "F6ANm12_5K_FDremove",   0.223009, "R")
	get_EDC("F6ANm12",  "F6ANm12_50K_FDremove",  -0.235641, "L")
	get_EDC("F6ANm12",  "F6ANm12_50K_FDremove",   0.228241, "R")
	get_EDC("F6ANm12", "F6ANm12_100K_FDremove",  -0.240873, "L")
	get_EDC("F6ANm12", "F6ANm12_100K_FDremove",   0.223009, "R")
	get_EDC("F6ANm12", "F6ANm12_150K_FDremove",  -0.251336, "L")
	get_EDC("F6ANm12", "F6ANm12_150K_FDremove",   0.207314, "R")
	get_EDC("F6ANm12", "F6ANm12_300K_FDremove",  -0.319349, "L")
	get_EDC("F6ANm12", "F6ANm12_300K_FDremove",   0.228241, "R")
End

Function plot_all_EDCs_at_kF_F6()

	Variable normed = 1

	Plot_EDCs_at_kF("F6AN", "L", normed)
	Plot_EDCs_at_kF("F6AN", "R", normed)
	Plot_EDCs_at_kF("F6ANm5", "L", normed)
	Plot_EDCs_at_kF("F6ANm5", "R", normed)
	Plot_EDCs_at_kF("F6ANm8", "L", normed)
	Plot_EDCs_at_kF("F6ANm8", "R", normed)
	Plot_EDCs_at_kF("F6ANm10", "L", normed)
	Plot_EDCs_at_kF("F6ANm10", "R", normed)
	Plot_EDCs_at_kF("F6ANm12", "L", normed)
	Plot_EDCs_at_kF("F6ANm12", "R", normed)
End


Function get_EDCs_at_Kf()
	// B3A1_38K
	get_EDC("B3A1_38K", "s3b_38K_33", -0.232, "L")
	get_EDC("B3A1_38K", "s3b_38K_33",  0.192, "R")
	get_EDC("B3A1_38K", "s3b_38K_35", -0.181, "L")
	get_EDC("B3A1_38K", "s3b_38K_35",  0.158, "R")
	get_EDC("B3A1_38K", "s3b_38K_37", -0.138, "L")
	get_EDC("B3A1_38K", "s3b_38K_37",  0.126, "R")
	get_EDC("B3A1_38K", "s3b_38K_39", -0.104, "L")
	get_EDC("B3A1_38K", "s3b_38K_39",  0.102, "R")
	// B3A1_60K
	get_EDC("B3A1_60K", "s3b_60K_33", -0.246, "L")
	get_EDC("B3A1_60K", "s3b_60K_33",  0.165, "R")
	get_EDC("B3A1_60K", "s3b_60K_35", -0.201, "L")
	get_EDC("B3A1_60K", "s3b_60K_35",  0.136, "R")
	get_EDC("B3A1_60K", "s3b_60K_37", -0.136, "L")
	get_EDC("B3A1_60K", "s3b_60K_37",  0.128, "R")
	get_EDC("B3A1_60K", "s3b_60K_39", -0.114, "L")
	get_EDC("B3A1_60K", "s3b_60K_39",  0.085, "R")
	get_EDC("B3A1_60K", "s3b_60K_41", -0.102, "L")
	get_EDC("B3A1_60K", "s3b_60K_41",  0.061, "R")
	// B3A1_150K
	get_EDC("B3A1_150K", "s3b_150K_33", -0.244, "L")
	get_EDC("B3A1_150K", "s3b_150K_33",  0.165, "R")
	get_EDC("B3A1_150K", "s3b_150K_35", -0.187, "L")
	get_EDC("B3A1_150K", "s3b_150K_35",  0.119, "R")
	get_EDC("B3A1_150K", "s3b_150K_37", -0.140, "L")
	get_EDC("B3A1_150K", "s3b_150K_37",  0.108, "R")
	get_EDC("B3A1_150K", "s3b_150K_39", -0.102, "L")
	get_EDC("B3A1_150K", "s3b_150K_39",  0.091, "R")
	get_EDC("B3A1_150K", "s3b_150K_41", -0.083, "L")
	get_EDC("B3A1_150K", "s3b_150K_41",  0.075, "R")
	// B3A1_300K
	get_EDC("B3A1_300K", "s3b_300K_33", -0.181, "L")
	get_EDC("B3A1_300K", "s3b_300K_33",  0.189, "R")
	get_EDC("B3A1_300K", "s3b_300K_35", -0.147, "L")
	get_EDC("B3A1_300K", "s3b_300K_35",  0.148, "R")
	get_EDC("B3A1_300K", "s3b_300K_37", -0.113, "L")
	get_EDC("B3A1_300K", "s3b_300K_37",  0.127, "R")
	get_EDC("B3A1_300K", "s3b_300K_39", -0.084, "L")
	get_EDC("B3A1_300K", "s3b_300K_39",  0.110, "R")
	get_EDC("B3A1_300K", "s3b_300K_41", -0.069, "L")
	get_EDC("B3A1_300K", "s3b_300K_41",  0.100, "R")
	
	//
	//
	
	// B3A3_38K
	get_EDC("B3A3_38K", "B3A3_S10x014", -0.270, "L")
	get_EDC("B3A3_38K", "B3A3_S10x014",  0.222, "R")
	get_EDC("B3A3_38K", "B3A3_S10x015", -0.220, "L")
	get_EDC("B3A3_38K", "B3A3_S10x015",  0.162, "R")
	get_EDC("B3A3_38K", "B3A3_S10x016", -0.177, "L")
	get_EDC("B3A3_38K", "B3A3_S10x016",  0.114, "R")
	get_EDC("B3A3_38K", "B3A3_S10x017", -0.161, "L")
	get_EDC("B3A3_38K", "B3A3_S10x017",  0.092, "R")
	// B3A3_60K
	get_EDC("B3A3_60K", "B3A3_S10x019", -0.261, "L")
	get_EDC("B3A3_60K", "B3A3_S10x019",  0.199, "R")
	get_EDC("B3A3_60K", "B3A3_S10x021", -0.220, "L")
	get_EDC("B3A3_60K", "B3A3_S10x021",  0.158, "R")
	get_EDC("B3A3_60K", "B3A3_S10x022", -0.170, "L")
	get_EDC("B3A3_60K", "B3A3_S10x022",  0.118, "R")
	get_EDC("B3A3_60K", "B3A3_S10x023", -0.132, "L")
	get_EDC("B3A3_60K", "B3A3_S10x023",  0.077, "R")
	get_EDC("B3A3_60K", "B3A3_S10x024", -0.103, "L")
	get_EDC("B3A3_60K", "B3A3_S10x024",  0.041, "R")
	// B3A3_150K
	get_EDC("B3A3_150K", "B3A3_S10x027", -0.240, "L")
	get_EDC("B3A3_150K", "B3A3_S10x027",  0.217, "R")
	get_EDC("B3A3_150K", "B3A3_S10x028", -0.188, "L")
	get_EDC("B3A3_150K", "B3A3_S10x028",  0.177, "R")
	get_EDC("B3A3_150K", "B3A3_S10x029", -0.150, "L")
	get_EDC("B3A3_150K", "B3A3_S10x029",  0.134, "R")
	// B3A3_300K
	get_EDC("B3A3_300K", "B3A3_S10x033", -0.194, "L")
	get_EDC("B3A3_300K", "B3A3_S10x033",  0.239, "R")
	get_EDC("B3A3_300K", "B3A3_S10x034", -0.145, "L")
	get_EDC("B3A3_300K", "B3A3_S10x034",  0.209, "R")
	get_EDC("B3A3_300K", "B3A3_S10x035", -0.103, "L")
	get_EDC("B3A3_300K", "B3A3_S10x035",  0.179, "R")
	get_EDC("B3A3_300K", "B3A3_S10x036", -0.078, "L")
	get_EDC("B3A3_300K", "B3A3_S10x036",  0.110, "R")
	
	//
	//
	
	// LaB1A8_38K
	get_EDC("LaB1A8_38K", "LaPbB1A8_S4b_003", -0.162, "L")
	get_EDC("LaB1A8_38K", "LaPbB1A8_S4b_003",  0.170, "R")
	get_EDC("LaB1A8_38K", "LaPbB1A8_S4b_004", -0.220, "L")
	get_EDC("LaB1A8_38K", "LaPbB1A8_S4b_004",  0.205, "R")
	get_EDC("LaB1A8_38K", "LaPbB1A8_S4b_005", -0.132, "L")
	get_EDC("LaB1A8_38K", "LaPbB1A8_S4b_005",  0.134, "R")
	get_EDC("LaB1A8_38K", "LaPbB1A8_S4b_006", -0.101, "L")
	get_EDC("LaB1A8_38K", "LaPbB1A8_S4b_006",  0.105, "R")
	get_EDC("LaB1A8_38K", "LaPbB1A8_S4b_007", -0.079, "L")
	get_EDC("LaB1A8_38K", "LaPbB1A8_S4b_007",  0.079, "R")
	// LaB1A8_60K
	get_EDC("LaB1A8_60K", "LaPbB1A8_S4b_010", -0.235, "L")
	get_EDC("LaB1A8_60K", "LaPbB1A8_S4b_010",  0.190, "R")
	get_EDC("LaB1A8_60K", "LaPbB1A8_S4b_011", -0.183, "L")
	get_EDC("LaB1A8_60K", "LaPbB1A8_S4b_011",  0.155, "R")
	get_EDC("LaB1A8_60K", "LaPbB1A8_S4b_012", -0.140, "L")
	get_EDC("LaB1A8_60K", "LaPbB1A8_S4b_012",  0.123, "R")
	get_EDC("LaB1A8_60K", "LaPbB1A8_S4b_013", -0.113, "L")
	get_EDC("LaB1A8_60K", "LaPbB1A8_S4b_013",  0.094, "R")
	get_EDC("LaB1A8_60K", "LaPbB1A8_S4b_014", -0.090, "L")
	get_EDC("LaB1A8_60K", "LaPbB1A8_S4b_014",  0.068, "R")
	// LaB1A8_150K
	get_EDC("LaB1A8_150K", "LaPbB1A8_S4b_016", -0.241, "L")
	get_EDC("LaB1A8_150K", "LaPbB1A8_S4b_016",  0.179, "R")
	get_EDC("LaB1A8_150K", "LaPbB1A8_S4b_017", -0.194, "L")
	get_EDC("LaB1A8_150K", "LaPbB1A8_S4b_017",  0.146, "R")
	get_EDC("LaB1A8_150K", "LaPbB1A8_S4b_018", -0.149, "L")
	get_EDC("LaB1A8_150K", "LaPbB1A8_S4b_018",  0.113, "R")
	get_EDC("LaB1A8_150K", "LaPbB1A8_S4b_019", -0.119, "L")
	get_EDC("LaB1A8_150K", "LaPbB1A8_S4b_019",  0.082, "R")
	get_EDC("LaB1A8_150K", "LaPbB1A8_S4b_020", -0.096, "L")
	get_EDC("LaB1A8_150K", "LaPbB1A8_S4b_020",  0.056, "R")
	// LaB1A8_300K
	get_EDC("LaB1A8_300K", "LaPbB1A8_S4b_023", -0.199, "L")
	get_EDC("LaB1A8_300K", "LaPbB1A8_S4b_023",  0.181, "R")
	get_EDC("LaB1A8_300K", "LaPbB1A8_S4b_025", -0.172, "L")
	get_EDC("LaB1A8_300K", "LaPbB1A8_S4b_025",  0.160, "R")
	get_EDC("LaB1A8_300K", "LaPbB1A8_S4b_026", -0.127, "L")
	get_EDC("LaB1A8_300K", "LaPbB1A8_S4b_026",  0.134, "R")
	get_EDC("LaB1A8_300K", "LaPbB1A8_S4b_027", -0.114, "L")
	get_EDC("LaB1A8_300K", "LaPbB1A8_S4b_027",  0.100, "R")
	get_EDC("LaB1A8_300K", "LaPbB1A8_S4b_028", -0.095, "L")
	get_EDC("LaB1A8_300K", "LaPbB1A8_S4b_028",  0.090, "R")
End

Function plot_all_EDCs_at_kF()

	Variable normed = 0

	Plot_EDCs_at_kF("B3A1_38K", "L", normed)
	Plot_EDCs_at_kF("B3A1_38K", "R", normed)
	Plot_EDCs_at_kF("B3A1_60K", "L", normed)
	Plot_EDCs_at_kF("B3A1_60K", "R", normed)
	Plot_EDCs_at_kF("B3A1_150K", "L", normed)
	Plot_EDCs_at_kF("B3A1_150K", "R", normed)
	Plot_EDCs_at_kF("B3A1_300K", "L", normed)
	Plot_EDCs_at_kF("B3A1_300K", "R", normed)
	
	Plot_EDCs_at_kF("B3A3_38K", "L", normed)
	Plot_EDCs_at_kF("B3A3_38K", "R", normed)
	Plot_EDCs_at_kF("B3A3_60K", "L", normed)
	Plot_EDCs_at_kF("B3A3_60K", "R", normed)
	Plot_EDCs_at_kF("B3A3_150K", "L", normed)
	Plot_EDCs_at_kF("B3A3_150K", "R", normed)
	Plot_EDCs_at_kF("B3A3_300K", "L", normed)
	Plot_EDCs_at_kF("B3A3_300K", "R", normed)
	
	Plot_EDCs_at_kF("LaB1A8_38K", "L", normed)
	Plot_EDCs_at_kF("LaB1A8_38K", "R", normed)
	Plot_EDCs_at_kF("LaB1A8_60K", "L", normed)
	Plot_EDCs_at_kF("LaB1A8_60K", "R", normed)
	Plot_EDCs_at_kF("LaB1A8_150K", "L", normed)
	Plot_EDCs_at_kF("LaB1A8_150K", "R", normed)
	Plot_EDCs_at_kF("LaB1A8_300K", "L", normed)
	Plot_EDCs_at_kF("LaB1A8_300K", "R", normed)
End

// dataset is the name of the folder inside of "root:EDCs:atKF"
// LorR is either the string "L" or "R" which denotes which peak to plot
// normed is either 0 or 1 and determines if normalised data is plotted
Function Plot_EDCs_at_kF(dataset, LorR, normed)

	String dataset, LorR
	Variable normed
	
	String fullPath = "root:EDCs:atKF:" + dataset 
	
	Variable numEDCs = countObjects(fullPath, 1)
	Variable n, c
	c = 0
	
	killWindow/Z EDCs
	Display/N=EDCs
	
	For (n = 0; n < numEDCs; n++)
	
		String EDCname = GetIndexedObjName(fullPath, 1, n)
		Wave EDC = $(fullPath + ":" + EDCname)
		
		// Plot left or right
		if (stringMatch(EDCname[0], LorR))
			// Select normed data
			if (normed)
				If (stringMatch(EDCname[2, 7], "normed"))
					AppendToGraph/W=EDCs/C=((pi) * 65535 * (1 - c/numEDCs), (pi) * 65535 * (c/numEDCs), (exp(1)) * 65535 * (c/numEDCs)) EDC
					ModifyGraph/W=EDCs lsize($(EDCname))=1//, lStyle($(EDCname))=mod(n, 4)
					c += 1
				Else
					continue
				EndIf
			Else
				If (stringMatch(EDCname[2, 7], "normed"))
					continue
				Else
					AppendToGraph/W=EDCs/C=((exp(1)) * 65535 * (1 - c/numEDCs), (pi) * 65535 * (c/numEDCs), (pi) * 65535 * (c/numEDCs)) EDC
					ModifyGraph/W=EDCs lsize($(EDCname))=1//, lStyle($(EDCname))=mod(n, 4)
					c += 1
				EndIf
			EndIf
		EndIf
	EndFor
	Label/W=EDCs left "Counts(a.u.)"
	Label/W=EDCs bottom "Energy(\\U)"
	Legend/W=EDCs/A=LT
	ModifyGraph/W=EDCs tick=2,mirror=1
	TextBox/C/N=title/F=0/S=3/A=MT/X=0.00/Y=0.00/E ("EDCs for " + dataSet + "_" + LorR)
	SetAxis bottom -0.4,*
	
	NewPath/C/Q/O imgPath "E:Natuurkunde:ARPES:DIAMOND:EDCs:"
	SavePict/O/B=(5*72)/E=-5/P=imgPath as (dataset + "_" + LorR + SelectString(normed, "", "normed") + ".png")
End

Function get_EDC(dataset, w, kF, LorR)

	String dataset, w, LorR
	Variable kF
	
	// Get all necessary info and make folder
	NewDataFolder/O $("root:EDCs:atKF")
	NewDataFolder/O $("root:EDCs:atKF:" + dataset)
	String EDMpath = "root:EDMS:" + dataset + ":" + w
	Wave EDM = $EDMpath
	// Create new wave for integrated EDCs
	String EDCpath = "root:EDCs:atKF:" + dataset + ":" + LorR + "_" + w 
	Make/O/N=(dimSize(EDM, 1)) $EDCpath
	Wave EDC = $EDCpath
	SetScale/P x, dimOffset(EDM, 1), dimDelta(EDM, 1), "eV" EDC
	
	Variable kFindex = scaleToIndex(EDM, kF, 0)
	// Integrate over neighbouring EDCs
	EDC = (EDM[kFindex-1][p] + EDM[kFindex][p] + EDM[kFIndex][p]) / 3
	
	// Make normalised EDC
	String normedEDCpath = "root:EDCs:atKF:" + dataset + ":" + LorR + "_normed_" + w 
	Duplicate/O/R=(*, 0.001) EDC $normedEDCpath
	Wave normedEDC = $normedEDCpath
	Wavestats/Q EDC
	normedEDC /= V_max	
End
