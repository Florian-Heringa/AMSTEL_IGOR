#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function SetScaleForExtractedEDCs(folder)

	DFREF folder
	
	DFREF df = GetDataFolderDFR()
	SetDataFolder folder

	Variable numWavs = CountObjectsDFR(folder, 1)
	Variable n
	
	For (n=0; n<numWavs; n+=2)
		Wave scaleWav = $(GetIndexedObjNameDFR(folder, 1, n+1))
		Wave waveToScale = $(GetIndexedObjNameDFR(folder, 1, n))
		WaveStats/Q scaleWav
		
		SetScale/I x, V_min, V_max, "eV", waveToScale
	EndFor
	
	SetDataFolder df
		
End

Function FormatSymmetrizedEDCGraph(datasetLabel)

	String datasetLabel

	legend
	colourise(99, 0)
	SetAxis left 0,*
	SetAxis bottom -0.2,0.2
	ModifyGraph mirror=2
	TextBox/C/N=Title/F=0/A=MC "\Z24Symmetrized EDC at kF (" + datasetLabel + ") - Right branch"
	TextBox/C/N=Title/A=MT/X=0.00/Y=0.00/E
	ModifyGraph width={Aspect,1.6},height=350
	ModifyGraph tick=2,fSize(left)=18,fSize(bottom)=18
	ModifyGraph lsize=2, width=600, height=400
	Label bottom "Energy(eV)"
	Label left "Intensity (a.u.)"
End

// Everything in this file is completely general.
// All logic will work as long as the correct parts are changed for your specific dataset.
// These include:
// 1. The folder name of the original (not normalised) data in setupAnalysis
// 2. The list of dataset names
// 3. Most work of all, the function "get_EDCs_at_kF_from_datasets()" which handles all EDCs at Kf

Function setupAnalysis()
	
	NewDataFolder/O/S root:analysisUtility
	
	String/G nonNormedData = "root:EDMs_non_normalised"
	String/G normedData = "root:EDMs_normalised"
	String/G EDCfolder = "root:EDCs:nonsymmetrized"
	String/G EDCsymmFolder = "root:EDCs:symmetrized"
	
	NewDataFolder/O $(nonNormedData)
	NewDataFolder/O $(normedData)
	
	NewDataFolder/O root:EDCs
	NewDataFolder/O $(EDCfolder)
	NewDataFolder/O $(EDCsymmFolder)
	
	Make/O/T datasetNames = {"F5bAN", "F5bANm5", "F5bANm8", "F5bANm10", "F5bANm12", "F6AN", "F6ANm5", "F6ANm8", "F6ANm10", "F6ANm12"}
End

// Turn on or off certain parts of the anaylsis here
Function completeAnalysis()

	//setupAnalysis()
	//doNormalisation()
	get_EDCs_at_kF_from_datasets()
	doSymmetrization()

End

// First Take the Raw Data and make sure the scales are set correctly
// Ef=0, no polar (horizontal slit) or tilt (vertical slit) shifts.
// Angle to k-scale

// This data needs to be normalised first. Also, background subtraction.
// Do Background subtraction and normalisation on entire dataset
Function normalise(datasetPath, toSavePath)
	String datasetPath, toSavePath

	normaliseDataset(datasetPath, 56, 490, toSavePath)
End

//=================================================
// Do normalisation on all datasets (set by changing inFolder, outFolder and datasets/w)
Function doNormalisation()

	String df = GetDataFolder(1)
	
	SetDataFolder root:analysisUtility
	
	SVAR inFolder = nonNormedData
	SVAR outFolder = normedData
	Wave/T dataSetNames
	Variable numDatasets = dimSize(dataSetNames, 0)
	Variable n
	
	for (n = 0; n < numDataSets; n++)
		normalise(inFolder + ":" + datasetNames[n], outFolder + ":" + datasetNames[n])
	EndFor
	
	SetDataFolder df	
End


// After normalisation and background subtraction, extract EDCs at kF
// This function takes a single EDC from a dataset
Function get_EDC_from_dataset(dataset, w, kF, LorR)

	String dataset, w, LorR
	Variable kF
	
	String df = GetDataFolder(1)
	SetDataFolder root:analysisUtility
	SVAR EDCfolder
	SVAR normedData
	
	String EDMpath = normedData + ":" + dataset + ":" + w
	Wave EDM = $EDMpath
	// Create new wave for integrated EDCs
	NewDataFolder/O $(EDCfolder + ":" + dataset)
	String EDCpath = EDCfolder + ":" + dataset + ":" + LorR + "_" + w 
	Make/O/N=(dimSize(EDM, 1)) $EDCpath
	Wave EDC = $EDCpath
	SetScale/P x, dimOffset(EDM, 1), dimDelta(EDM, 1), "eV" EDC
	
	Variable kFindex = scaleToIndex(EDM, kF, 0)
	// Integrate over neighbouring EDCs
	EDC = (EDM[kFindex-1][p] + EDM[kFindex][p] + EDM[kFIndex][p]) / 3
	
//	// Make normalised EDC
//	String normedEDCpath = EDCfolder + ":" + dataset + ":" + LorR + "_normed_" + w 
//	Duplicate/O/R=(*, 0) EDC $normedEDCpath
//	Wave normedEDC = $normedEDCpath
//	Wavestats/Q EDC
//	normedEDC /= V_max	
End

Function get_EDC_from_dataset_i(dataset, w, kFindex, LorR)

	String dataset, w, LorR
	Variable kFindex
	
	String df = GetDataFolder(1)
	SetDataFolder root:analysisUtility
	SVAR EDCfolder
	SVAR normedData
	
	String EDMpath = normedData + ":" + dataset + ":" + w
	Wave EDM = $EDMpath
	// Create new wave for integrated EDCs
	NewDataFolder/O $(EDCfolder + ":" + dataset)
	String EDCpath = EDCfolder + ":" + dataset + ":" + LorR + "_" + w 
	Make/O/N=(dimSize(EDM, 1)) $EDCpath
	Wave EDC = $EDCpath
	SetScale/P x, dimOffset(EDM, 1), dimDelta(EDM, 1), "eV" EDC

	// Integrate over neighbouring EDCs
	EDC = (EDM[kFindex-1][p] + EDM[kFindex][p] + EDM[kFIndex+1][p]) / 3
End

Function get_EDCs_at_kF_from_datasets()

	String df = GetDataFolder(1)
	SetDataFolder root:analysisUtility
	
	// AN
	get_EDC_from_dataset_i("F6AN",   "F6AN_5K_normed", 331, "L")
	get_EDC_from_dataset_i("F6AN",   "F6AN_5K_normed", 457, "R")
	get_EDC_from_dataset_i("F6AN",  "F6AN_50K_normed", 327, "L")
	get_EDC_from_dataset_i("F6AN",  "F6AN_50K_normed", 467, "R")
	get_EDC_from_dataset_i("F6AN", "F6AN_100K_normed", 337, "L")
	get_EDC_from_dataset_i("F6AN", "F6AN_100K_normed", 454, "R")
	get_EDC_from_dataset_i("F6AN", "F6AN_150K_normed", 340, "L")
	get_EDC_from_dataset_i("F6AN", "F6AN_150K_normed", 451, "R")
	get_EDC_from_dataset_i("F6AN", "F6AN_300K_normed", 304, "L")
	get_EDC_from_dataset_i("F6AN", "F6AN_300K_normed", 435, "R")
	
	// ANm5
	get_EDC_from_dataset_i("F6ANm5",   "F6ANm5_5K_normed",  312, "L")
	get_EDC_from_dataset_i("F6ANm5",   "F6ANm5_5K_normed",  467, "R")
	get_EDC_from_dataset_i("F6ANm5",  "F6ANm5_50K_normed",  312, "L")
	get_EDC_from_dataset_i("F6ANm5",  "F6ANm5_50K_normed",  472, "R")
	get_EDC_from_dataset_i("F6ANm5", "F6ANm5_100K_normed",  318, "L")
	get_EDC_from_dataset_i("F6ANm5", "F6ANm5_100K_normed",  465, "R")
	get_EDC_from_dataset_i("F6ANm5", "F6ANm5_150K_normed",  316, "L")
	get_EDC_from_dataset_i("F6ANm5", "F6ANm5_150K_normed",  458, "R")
	get_EDC_from_dataset_i("F6ANm5", "F6ANm5_300K_normed",  315, "L")
	get_EDC_from_dataset_i("F6ANm5", "F6ANm5_300K_normed",  456, "R")
	
	// ANm8
	get_EDC_from_dataset_i("F6ANm8",   "F6ANm8_5K_normed",  310, "L")
	get_EDC_from_dataset_i("F6ANm8",   "F6ANm8_5K_normed",   494, "R")
	get_EDC_from_dataset_i("F6ANm8",  "F6ANm8_50K_normed",  305, "L")
	get_EDC_from_dataset_i("F6ANm8",  "F6ANm8_50K_normed",   491, "R")
	get_EDC_from_dataset_i("F6ANm8", "F6ANm8_100K_normed",  298, "L")
	get_EDC_from_dataset_i("F6ANm8", "F6ANm8_100K_normed",   486, "R")
	get_EDC_from_dataset_i("F6ANm8", "F6ANm8_150K_normed",  298, "L")
	get_EDC_from_dataset_i("F6ANm8", "F6ANm8_150K_normed",   479, "R")
	get_EDC_from_dataset_i("F6ANm8", "F6ANm8_300K_normed",  289, "L")
	get_EDC_from_dataset_i("F6ANm8", "F6ANm8_300K_normed",   487, "R")
	
	// ANm10
	get_EDC_from_dataset_i("F6ANm10",   "F6ANm10_5K_normed",  294, "L")
	get_EDC_from_dataset_i("F6ANm10",   "F6ANm10_5K_normed",   513, "R")
	get_EDC_from_dataset_i("F6ANm10",  "F6ANm10_50K_normed",  290, "L")
	get_EDC_from_dataset_i("F6ANm10",  "F6ANm10_50K_normed",   508, "R")
	get_EDC_from_dataset_i("F6ANm10", "F6ANm10_100K_normed",  284, "L")
	get_EDC_from_dataset_i("F6ANm10", "F6ANm10_100K_normed",   506, "R")
	get_EDC_from_dataset_i("F6ANm10", "F6ANm10_150K_normed",  279, "L")
	get_EDC_from_dataset_i("F6ANm10", "F6ANm10_150K_normed",   500, "R")
	get_EDC_from_dataset_i("F6ANm10", "F6ANm10_300K_normed",  248, "L")
	get_EDC_from_dataset_i("F6ANm10", "F6ANm10_300K_normed",   510, "R")
	
	// ANm12
	get_EDC_from_dataset_i("F6ANm12",   "F6ANm12_5K_normed",  264, "L")
	get_EDC_from_dataset_i("F6ANm12",   "F6ANm12_5K_normed",   538, "R")
	get_EDC_from_dataset_i("F6ANm12",  "F6ANm12_50K_normed",  263, "L")
	get_EDC_from_dataset_i("F6ANm12",  "F6ANm12_50K_normed",   537, "R")
	get_EDC_from_dataset_i("F6ANm12", "F6ANm12_100K_normed",  261, "L")
	get_EDC_from_dataset_i("F6ANm12", "F6ANm12_100K_normed",   537, "R")
	get_EDC_from_dataset_i("F6ANm12", "F6ANm12_150K_normed",  254, "L")
	get_EDC_from_dataset_i("F6ANm12", "F6ANm12_150K_normed",   528, "R")
	get_EDC_from_dataset_i("F6ANm12", "F6ANm12_300K_normed",  204, "L")
	get_EDC_from_dataset_i("F6ANm12", "F6ANm12_300K_normed",   540, "R")
	
	
	// AN
	get_EDC_from_dataset_i("F5bAN",   "F5bAN_5K_normed", 211, "L")
	get_EDC_from_dataset_i("F5bAN",   "F5bAN_5K_normed",  387, "R")
	get_EDC_from_dataset_i("F5bAN",  "F5bAN_50K_normed", 214, "L")
	get_EDC_from_dataset_i("F5bAN",  "F5bAN_50K_normed",  383, "R")
	get_EDC_from_dataset_i("F5bAN", "F5bAN_150K_normed", 228, "L")
	get_EDC_from_dataset_i("F5bAN", "F5bAN_150K_normed",  399, "R")
	get_EDC_from_dataset_i("F5bAN", "F5bAN_300K_normed", 226, "L")
	get_EDC_from_dataset_i("F5bAN", "F5bAN_300K_normed",  392, "R")
	
	// ANm5
	get_EDC_from_dataset_i("F5bANm5",   "F5bANm5_5K_normed",  207, "L")
	get_EDC_from_dataset_i("F5bANm5",   "F5bANm5_5K_normed",   385, "R")
	get_EDC_from_dataset_i("F5bANm5",  "F5bANm5_50K_normed",  207, "L")
	get_EDC_from_dataset_i("F5bANm5",  "F5bANm5_50K_normed",   377, "R")
	get_EDC_from_dataset_i("F5bANm5", "F5bANm5_150K_normed",  220, "L")
	get_EDC_from_dataset_i("F5bANm5", "F5bANm5_150K_normed",   379, "R")
	get_EDC_from_dataset_i("F5bANm5", "F5bANm5_300K_normed", 233, "L")
	get_EDC_from_dataset_i("F5bANm5", "F5bANm5_300K_normed",   392, "R")
	
	// ANm8
	get_EDC_from_dataset_i("F5bANm8",   "F5bANm8_5K_normed",  191, "L")
	get_EDC_from_dataset_i("F5bANm8",   "F5bANm8_5K_normed",   397, "R")
	get_EDC_from_dataset_i("F5bANm8",  "F5bANm8_50K_normed",  186, "L")
	get_EDC_from_dataset_i("F5bANm8",  "F5bANm8_50K_normed",   396, "R")
	get_EDC_from_dataset_i("F5bANm8", "F5bANm8_150K_normed",  195, "L")
	get_EDC_from_dataset_i("F5bANm8", "F5bANm8_150K_normed",   396, "R")
	get_EDC_from_dataset_i("F5bANm8", "F5bANm8_300K_normed",  215, "L")
	get_EDC_from_dataset_i("F5bANm8", "F5bANm8_300K_normed",   395, "R")
	
	// ANm10
	get_EDC_from_dataset_i("F5bANm10",   "F5bANm10_5K_normed",  171, "L")
	get_EDC_from_dataset_i("F5bANm10",   "F5bANm10_5K_normed",   412, "R")
	get_EDC_from_dataset_i("F5bANm10",  "F5bANm10_50K_normed",  166, "L")
	get_EDC_from_dataset_i("F5bANm10",  "F5bANm10_50K_normed",   409, "R")
	get_EDC_from_dataset_i("F5bANm10", "F5bANm10_150K_normed",  182, "L")
	get_EDC_from_dataset_i("F5bANm10", "F5bANm10_150K_normed",   408, "R")
	get_EDC_from_dataset_i("F5bANm10", "F5bANm10_300K_normed",  212, "L")
	get_EDC_from_dataset_i("F5bANm10", "F5bANm10_300K_normed",   415, "R")
	
	// ANm12
	get_EDC_from_dataset_i("F5bANm12",   "F5bANm12_5K_normed",  149, "L")
	get_EDC_from_dataset_i("F5bANm12",   "F5bANm12_5K_normed",   436, "R")
	get_EDC_from_dataset_i("F5bANm12",  "F5bANm12_50K_normed",  142, "L")
	get_EDC_from_dataset_i("F5bANm12",  "F5bANm12_50K_normed",   440, "R")
	get_EDC_from_dataset_i("F5bANm12", "F5bANm12_150K_normed",  156, "L")
	get_EDC_from_dataset_i("F5bANm12", "F5bANm12_150K_normed",   436, "R")
	get_EDC_from_dataset_i("F5bANm12", "F5bANm12_300K_normed",  190, "L")
	get_EDC_from_dataset_i("F5bANm12", "F5bANm12_300K_normed",   426, "R")


	SetDataFolder df
End


// So many lines of code..... OLD version with wrongly determined kF
//Function get_EDCs_at_kF_from_datasets()
//
//	String df = GetDataFolder(1)
//	SetDataFolder root:analysisUtility
//	
//	// AN
//	get_EDC_from_dataset("F6AN",   "F6AN_5K_normed", -0.105498, "L")
//	get_EDC_from_dataset("F6AN",   "F6AN_5K_normed",  0.102284, "R")
//	get_EDC_from_dataset("F6AN",  "F6AN_50K_normed", -0.0967679, "L")
//	get_EDC_from_dataset("F6AN",  "F6AN_50K_normed",  0.100538, "R")
//	get_EDC_from_dataset("F6AN", "F6AN_100K_normed", -0.0880375, "L")
//	get_EDC_from_dataset("F6AN", "F6AN_100K_normed",  0.0830769, "R")
//	get_EDC_from_dataset("F6AN", "F6AN_150K_normed", -0.0897836, "L")
//	get_EDC_from_dataset("F6AN", "F6AN_150K_normed",  0.0760927, "R")
//	get_EDC_from_dataset("F6AN", "F6AN_300K_normed", -0.14042, "L")
//	get_EDC_from_dataset("F6AN", "F6AN_300K_normed",  0.0481556, "R")
//	
//	// ANm5
//	get_EDC_from_dataset("F6ANm5",   "F6ANm5_5K_normed",  -0.096814, "L")
//	get_EDC_from_dataset("F6ANm5",   "F6ANm5_5K_normed",   0.12563, "R")
//	get_EDC_from_dataset("F6ANm5",  "F6ANm5_50K_normed",  -0.0968144, "L")
//	get_EDC_from_dataset("F6ANm5",  "F6ANm5_50K_normed",   0.129133, "R")
//	get_EDC_from_dataset("F6ANm5", "F6ANm5_100K_normed",  -0.0898083, "L")
//	get_EDC_from_dataset("F6ANm5", "F6ANm5_100K_normed",   0.122127, "R")
//	get_EDC_from_dataset("F6ANm5", "F6ANm5_150K_normed",  -0.0950629, "L")
//	get_EDC_from_dataset("F6ANm5", "F6ANm5_150K_normed",   0.118624, "R")
//	get_EDC_from_dataset("F6ANm5", "F6ANm5_300K_normed",  -0.119584, "L")
//	get_EDC_from_dataset("F6ANm5", "F6ANm5_300K_normed",   0.115121, "R")
//	
//	// ANm8
//	get_EDC_from_dataset("F6ANm8",   "F6ANm8_5K_normed",  -0.151933, "L")
//	get_EDC_from_dataset("F6ANm8",   "F6ANm8_5K_normed",   0.149765, "R")
//	get_EDC_from_dataset("F6ANm8",  "F6ANm8_50K_normed",  -0.153677, "L")
//	get_EDC_from_dataset("F6ANm8",  "F6ANm8_50K_normed",   0.148021, "R")
//	get_EDC_from_dataset("F6ANm8", "F6ANm8_100K_normed",  -0.158909, "L")
//	get_EDC_from_dataset("F6ANm8", "F6ANm8_100K_normed",   0.137557, "R")
//	get_EDC_from_dataset("F6ANm8", "F6ANm8_150K_normed",  -0.158909, "L")
//	get_EDC_from_dataset("F6ANm8", "F6ANm8_150K_normed",   0.128838, "R")
//	get_EDC_from_dataset("F6ANm8", "F6ANm8_300K_normed",  -0.185067, "L")
//	get_EDC_from_dataset("F6ANm8", "F6ANm8_300K_normed",   0.139301, "R")
//	
//	// ANm10
//	get_EDC_from_dataset("F6ANm10",   "F6ANm10_5K_normed",  -0.178558, "L")
//	get_EDC_from_dataset("F6ANm10",   "F6ANm10_5K_normed",   0.184346, "R")
//	get_EDC_from_dataset("F6ANm10",  "F6ANm10_50K_normed",  -0.180303, "L")
//	get_EDC_from_dataset("F6ANm10",  "F6ANm10_50K_normed",   0.186091, "R")
//	get_EDC_from_dataset("F6ANm10", "F6ANm10_100K_normed",  -0.192516, "L")
//	get_EDC_from_dataset("F6ANm10", "F6ANm10_100K_normed",   0.179112, "R")
//	get_EDC_from_dataset("F6ANm10", "F6ANm10_150K_normed",  -0.206474, "L")
//	get_EDC_from_dataset("F6ANm10", "F6ANm10_150K_normed",   0.165154, "R")
//	get_EDC_from_dataset("F6ANm10", "F6ANm10_300K_normed",  -0.248348, "L")
//	get_EDC_from_dataset("F6ANm10", "F6ANm10_300K_normed",   0.177367, "R")
//	
//	// ANm12
//	get_EDC_from_dataset("F6ANm12",   "F6ANm12_5K_normed",  -0.225178, "L")
//	get_EDC_from_dataset("F6ANm12",   "F6ANm12_5K_normed",   0.223009, "R")
//	get_EDC_from_dataset("F6ANm12",  "F6ANm12_50K_normed",  -0.235641, "L")
//	get_EDC_from_dataset("F6ANm12",  "F6ANm12_50K_normed",   0.228241, "R")
//	get_EDC_from_dataset("F6ANm12", "F6ANm12_100K_normed",  -0.240873, "L")
//	get_EDC_from_dataset("F6ANm12", "F6ANm12_100K_normed",   0.223009, "R")
//	get_EDC_from_dataset("F6ANm12", "F6ANm12_150K_normed",  -0.251336, "L")
//	get_EDC_from_dataset("F6ANm12", "F6ANm12_150K_normed",   0.207314, "R")
//	get_EDC_from_dataset("F6ANm12", "F6ANm12_300K_normed",  -0.319349, "L")
//	get_EDC_from_dataset("F6ANm12", "F6ANm12_300K_normed",   0.228241, "R")
//	
//	
//	// AN
//	get_EDC_from_dataset("F5bAN",   "F5bAN_5K_normed", -0.139207, "L")
//	get_EDC_from_dataset("F5bAN",   "F5bAN_5K_normed",  0.140515, "R")
//	get_EDC_from_dataset("F5bAN",  "F5bAN_50K_normed", -0.142748, "L")
//	get_EDC_from_dataset("F5bAN",  "F5bAN_50K_normed",  0.131663, "R")
//	get_EDC_from_dataset("F5bAN", "F5bAN_150K_normed", -0.100258, "L")
//	get_EDC_from_dataset("F5bAN", "F5bAN_150K_normed",  0.135204, "R")
//	get_EDC_from_dataset("F5bAN", "F5bAN_300K_normed", -0.102029, "L")
//	get_EDC_from_dataset("F5bAN", "F5bAN_300K_normed",   0.13343, "R")
//	
//	// ANm5
//	get_EDC_from_dataset("F5bANm5",   "F5bANm5_5K_normed",  -0.149793, "L")
//	get_EDC_from_dataset("F5bANm5",   "F5bANm5_5K_normed",   0.152933, "R")
//	get_EDC_from_dataset("F5bANm5",  "F5bANm5_50K_normed",  -0.148023, "L")
//	get_EDC_from_dataset("F5bANm5",  "F5bANm5_50K_normed",   0.137000, "R")
//	get_EDC_from_dataset("F5bANm5", "F5bANm5_150K_normed",  -0.112616, "L")
//	get_EDC_from_dataset("F5bANm5", "F5bANm5_150K_normed",   0.133459, "R")
//	get_EDC_from_dataset("F5bANm5", "F5bANm5_300K_normed", -0.0931425, "L")
//	get_EDC_from_dataset("F5bANm5", "F5bANm5_300K_normed",   0.138770, "R")
//	
//	// ANm8
//	get_EDC_from_dataset("F5bANm8",   "F5bANm8_5K_normed",  -0.172770, "L")
//	get_EDC_from_dataset("F5bANm8",   "F5bANm8_5K_normed",   0.170660, "R")
//	get_EDC_from_dataset("F5bANm8",  "F5bANm8_50K_normed",  -0.185162, "L")
//	get_EDC_from_dataset("F5bANm8",  "F5bANm8_50K_normed",   0.165349, "R")
//	get_EDC_from_dataset("F5bANm8", "F5bANm8_150K_normed",  -0.153297, "L")
//	get_EDC_from_dataset("F5bANm8", "F5bANm8_150K_normed",   0.156498, "R")
//	get_EDC_from_dataset("F5bANm8", "F5bANm8_300K_normed",  -0.100189, "L")
//	get_EDC_from_dataset("F5bANm8", "F5bANm8_300K_normed",   0.147647, "R")
//	
//	// ANm10
//	get_EDC_from_dataset("F5bANm10",   "F5bANm10_5K_normed",  -0.204634, "L")
//	get_EDC_from_dataset("F5bANm10",   "F5bANm10_5K_normed",   0.198984, "R")
//	get_EDC_from_dataset("F5bANm10",  "F5bANm10_50K_normed",  -0.217026, "L")
//	get_EDC_from_dataset("F5bANm10",  "F5bANm10_50K_normed",   0.197214, "R")
//	get_EDC_from_dataset("F5bANm10", "F5bANm10_150K_normed",  -0.185162, "L")
//	get_EDC_from_dataset("F5bANm10", "F5bANm10_150K_normed",   0.193674, "R")
//	get_EDC_from_dataset("F5bANm10", "F5bANm10_300K_normed",  -0.128513, "L")
//	get_EDC_from_dataset("F5bANm10", "F5bANm10_300K_normed",   0.161809, "R")
//	
//	// ANm12
//	get_EDC_from_dataset("F5bANm12",   "F5bANm12_5K_normed",  -0.247161, "L")
//	get_EDC_from_dataset("F5bANm12",   "F5bANm12_5K_normed",   0.241449, "R")
//	get_EDC_from_dataset("F5bANm12",  "F5bANm12_50K_normed",  -0.263094, "L")
//	get_EDC_from_dataset("F5bANm12",  "F5bANm12_50K_normed",   0.236138, "R")
//	get_EDC_from_dataset("F5bANm12", "F5bANm12_150K_normed",  -0.232998, "L")
//	get_EDC_from_dataset("F5bANm12", "F5bANm12_150K_normed",   0.229057, "R")
//	get_EDC_from_dataset("F5bANm12", "F5bANm12_300K_normed",  -0.169267, "L")
//	get_EDC_from_dataset("F5bANm12", "F5bANm12_300K_normed",   0.198961, "R")
//
//
//	SetDataFolder df
//End


//==========================================================
// Symmetrize an entire EDM 30-04-2020


Function/Wave symmEDM(EDM)

	Wave EDM
	
	String df = GetDataFolder(1)
	
	NewDataFolder/O/S root:SymmEDM
	
	Variable zeroIndex = ScaleToIndex(EDM, 0, 1)
	Variable NewLength = 2 * zeroIndex + 1
	
	Make/O/N=(DimSize(EDM, 0), NewLength) bottomPart
	SetScale/P x, dimOffset(EDM, 0), dimDelta(EDM, 0), bottomPart
	SetScale/P y, dimOffset(EDM, 1), dimDelta(EDM, 1), bottomPart
	bottomPart = 0
	bottomPart[0,dimSize(EDM, 0)-1][0,dimSize(EDM, 1)-1] = EDM[p][q]
	
	// Reverse one EDM in the y scale
	Duplicate/O bottomPart, topPart
	Variable yMin = DimOffset(bottomPart, 1)
	Variable yMax = DimOffset(bottomPart, 1) + DimSize(bottomPart, 1) * DimDelta(bottomPart, 1)
	SetScale/I y, yMax, yMin, topPart
	
	// Create a window around Ef to display
	Duplicate/O bottomPart, tWave
	tWave = 0
	tWave = bottomPart[p][q] + topPart[p][DimSize(topPart, 1)-q-1]
	Duplicate/O/R=[0, Dimsize(EDM, 0)][2*scaleToIndex(EDM, 0, 1)-dimSize(EDM, 1), dimSize(EDM, 1)-1] tWave, symmWave
	SetDataFolder df
	
	return symmWave
End

Function symmAllFromFolder(folder)

	String folder
	
	String df = GetDataFolder(1)
	
	NewDataFolder/O/S root:EDMs_Symmetrized
	
	Variable numDatasets = CountObjects(folder, 4)
	Variable m, n
	
	For (n=0; n< numDatasets; n++)
	
		String folderName = GetIndexedObjName(folder, 4, n)
		String folderToCheck = folder + ":" + folderName
		String folderToStore = "root:EDMs_Symmetrized:" + folderName
		NewDataFolder/O $(folderToStore)
		Variable numWaves = CountObjects(folderToCheck, 1)
		
		For (m=0; m<numWaves; m++)
			String wName = GetIndexedObjName(folderToCheck, 1, m)
			Wave toSymm = $(folderToCheck + ":" + wName)
			
			Wave symmWave = symmEDM(toSymm)
			Duplicate/O symmWave, $(folderToStore + ":" + wName)
		EndFor
	
	EndFor

End	


//==========================================================
// Symmetrize the EDCs

// Florian Heringa -- 06-04-2020

Function/Wave SymmetrizeWave(w)

	Wave w

	String df = GetDataFolder(1)	
	NewDataFolder/O/S root:symm

	Variable zeroIndex = scaleToIndex(w, 0, 0)
	Variable newLength = 2 * zeroIndex
	
	Duplicate/O w, leftSide
	Redimension/N=(newLength) leftSide
	
	Duplicate/O w, rightSide
	Redimension/N=(newLength) rightSide
	Reverse/DIM=-1 rightSide
	
	leftSide += rightSide
	
	SetDataFolder df
	
	return leftSide
End

Function doSymmetrization()

	String df = GetDataFolder(1)
	SetDataFolder root:analysisUtility
	
	SVAR EDCFolder
	SVAR EDCsymmFolder
	Wave/T dataSetNames
	
	SetDataFolder EDCfolder
	
	Variable numFolders = countObjects("", 4)
	Variable n
	
	// Loop over all datafolders
	for (n=0;n<numFolders;n++)
	
		String folderName = GetIndexedObjName("", 4, n)
		SetDataFolder EDCfolder + ":" + folderName
		Variable numWaves = countObjects("", 1)
		Variable m
		
		// Loop over all waves in the datafolder
		for (m=0;m<numWaves;m++)
			String wName = GetIndexedObjName("", 1, m)
			Wave symm = SymmetrizeWave($(wName))
			NewDataFolder/O $(EDCsymmFolder + ":" + folderName)
			Duplicate/O symm, $(EDCsymmFolder + ":" + folderName + ":" + wName)
		EndFor
	
		SetDataFolder EDCfolder
		
	EndFor
	
	SetDataFolder df

End

// Fitting multivariate polynomial to find peak positions

Function FindPeakOfEDC(EDC)

	Wave EDC
	
	String df = GetDataFolder(1)
	NewDataFolder/S/O root:PeakFind
	
	Variable EFindex = scaletoIndex(EDC, 0, 0)
	
	Duplicate/O/R=[0, EFindex] EDC, toFit
	
	// Do Fit
	CurveFit/Q poly 10, toFit /D
	String fitName = "fit_toFit"
	
	Wave fittedWave = $(fitName)
	
	// Back to where to store the fit
	SetDataFolder "root:'Symm EDC at kF'"
	NewDataFolder/S/O EDC_curvefit
	Duplicate/O fittedWave, $("fit" + nameOfWave(EDC))
	
	SetDataFolder df
End

// Go through a folder of fits and find the maximum position
Function FindPeaksOfFits(folder)

	DFref folder
	
	String df = GetDataFolder(1)
	
	SetDataFolder folder
	
	Variable numWaves = countObjects("", 1)
	Variable i
	
	for(i = 0;i < numWaves; i++)
		String wName = GetIndexedObjName(":", 1, i)	
		Wave toCheck = $(wName)
		
		WaveStats	/Q toCheck
		
		NewDataFolder/O/S root:'Symm EDC at kF':MaxLocation
		//Make/N=1 $(wName + "_x_max") = V_maxloc
		//Make/N=1 $(wName + "_y_max") = V_max
		SetDataFolder folder
	endfor						
	
	SetDataFolder df
END

// Plot All Fits, folder is the folder containing the original EDCs
Function PlotFits(EDCfolder)

	DFref EDCfolder
	
	String df = GetDataFolder(1)
	
	SetDataFolder EDCfolder
	DFref curveFitFolder = root:'Symm EDC at kF':EDC_curvefit:
	DFref LocationFolder = root:'Symm EDC at kF':MaxLocation:
	
	Variable numWaves = countObjects("", 1)
	Variable i
	
	for(i = 0;i < numWaves; i++)
		SetDataFolder EDCfolder
		String wName = GetIndexedObjName(":", 1, i)	
		Wave toPlot = $(wName)
		
		// Original EDC
		Display toPlot/TN=EDC
		
		// Fit
		SetDataFolder curveFitFolder
		Wave EDCFit = $("fit" + wName)
		AppendToGraph/Q EDCFit/TN=fit
		
		// Max Position
		SetDataFolder LocationFolder
		Wave xPos = $("fit" + wName + "_x_max")
		Wave yPos = $("fit" + wName + "_y_max")
		AppendToGraph/Q yPos/TN=maxLoc vs xPos 
		
		// Formatting
		ModifyGraph lsize(EDC)=2,rgb(EDC)=(8738,8738,8738),mode(fit)=2,lsize(fit)=2,mode(maxLoc)=2,lsize(maxLoc)=5,rgb(maxLoc)=(0,65535,0)
		SetAxis bottom *,0
		Legend/X=0.00/Y=0.00/A=LB
		Label bottom "E-E\\BF\\M(\\U)a"
	endfor						
	
	SetDataFolder df
END
	
