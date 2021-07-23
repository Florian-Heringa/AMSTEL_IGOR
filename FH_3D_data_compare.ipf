#pragma rtGlobals=1
#pragma TextEncoding = "UTF-8"

Macro start_3D_sim()
	run_sim()
End

Function check_first_load()
	/////////////////////////////////////////
	Variable/G first_load = 1
	
	// Set this to 1 or remove if you want to reset the program every time it is loaded
	If(DataFolderExists("root:sim:waves"))
		first_load = 0
	EndIf
	////////////////////////////////////////
End

Function run_sim()
	
	NewDataFolder/S/O root:sim
	///////////////////////////////////////// Variables
	NewDataFolder/S/O root:sim:vars
	check_first_load()
	NVAR first_load
	// Used un generating 3D data
	Variable/G SEmode, DispMode
	Variable/G rotateSim, numBZ
	Variable/G kxbound, kybound, Emin, Emax
	Variable/G kxmin, kxmax, kymin, kymax
	Variable/G nkx, nky, nESim
	Variable/G dkx, dky, den
	// Tight Binding Parameters
	Variable/G dE, t0, t1, t2, tp
	// Self Energy Parameters
	Variable/G lambda, phononE, scattering
	Variable/G T, boltzmann = 8.617 * 10^(-5)
	// Slicing variables
	Variable/G kxsliceSim, kxSliceValSim, kysliceSim, kySliceValSim, EsliceSim, EsliceEnergySim, cutType
	Variable/G cutPointsX, cutPointsY
	// Draw mode options
	Variable/G drawMode, prevDrawMode
	
	//////////////////// Measured Data info
	Variable/G kxMinMeas, kxMaxMeas, nkxMeas
	Variable/G kyMinMeas, kyMaxMeas, nkyMeas
	Variable/G EminMeas, EmaxMeas, nEMeas
	Variable/G dkxMeas, dkyMeas, dEMeas
	Variable/G kxSliceMeas, kxSliceValMeas, kySliceMeas, kySliceValMeas, EsliceMeas, EsliceEnergyMeas
	
	//////////////// File loading info
	Variable/G toLoadNumDims
	String/G toLoadPath
	Variable/G transposeSim, transposeMeas
	
		////////////////////////////////////////
	// Set variables to default if the program is loaded for the first time
	
	if (first_load)
	
		SEmode = 2
		DispMode = 3
		rotateSim = 0
		numBZ = 1
		kxbound = pi
		kxmin = -pi
		kxmax = pi
		kybound = pi
		kymin = -pi
		kymax = pi
		Emin = -0.6
		Emax = 0.2
		nkx = 100
		nky = 100
		nESim = 125
		dkx = (2 * pi) / nkx
		dky = (2 * pi) / nkx
		den = (Emax - Emin) / nESim
		// Tight Binding Parameters
		dE = 0.43
		t0 = 0.4
		t1 = 0.09
		t2 = 0.045
		tp = 0.082
		// Self Energy Parameters
		lambda = 0.2
		phononE = 0.1
		scattering = 0.01
		T = 25
		boltzmann = 8.617 * 10^(-5)
		// Draw mode options
		drawMode = 1
		prevDrawMode = 1
	
		//////////////////// Measured Data info
		kxMinMeas = -pi
		kxMaxMeas = pi
		nkxMeas = 10
		dkxMeas = (2*pi) / nkxMeas
		kyMinMeas = -pi
		kyMaxMeas = pi
		nkyMeas = 10
		dkyMeas = (2*pi) / nkyMeas
		EminMeas = -0.1
		EmaxMeas = 0.1
		nEMeas = 10
		dEMeas = 0.2 / nEMeas
		kxSliceMeas = 0
		kxSliceValMeas = kxMinMeas
		kySliceMeas = 0
		kySliceValMeas = kyMinMeas
		EsliceMeas = 0
		EsliceEnergyMeas = EminMeas
		toLoadNumDims = 3
	EndIf
	
	///////////////////////////////////////////////////////
	
	// References to waves to display
	NewDataFolder/O/S root:sim:waves
	if (first_load)
		Make/O/N=(nkx, nky) EDMshow
		SetScale x, kxmin, kxmax, "A^-1", EDMshow
		SetScale y, kymin, kymax, "A^-1", EDMshow
		if (WaveExists(MeasDataShow) == 0)
			Duplicate EDMshow, MeasDataShow
		EndIf
	EndIf
	Wave MeasDataShow, EDMshow
	
	Make/O/N=(nESim) SelfEre, SelfEim
	SetScale x, Emin, Emax, "eV" SelfEre, SelfEim
	Make/O/N=(nESim) cut1, cut2, cut3, cut4
	SetScale x, Emin, Emax, "eV" cut1, cut2, cut3, cut4
	
	// For selecting SE from file
	NewDataFolder/O/S root:sim:SEfiles
	Make/O/N=(nESim) SelfEre_f, SelfEim_f
	SetScale x, Emin, Emax, "eV" SelfEre_f, SelfEim_f

	NewDataFolder/O/S root:sim:MeasuredData
	if (WaveExists(MeasuredData) == 0)
		Make/N=(nkx, nky, nESim) MeasuredData
		SetScale x, kxmin, kxmax, "A^-1", MeasuredData
		SetScale y, kymin, kymax, "A^-1", MeasuredData
		SetScale x, Emin, Emax, "eV" MeasuredData
	EndIf
	Wave MeasuredData
	
	////////////////////////////////////////
	if (first_load)
		gen_3D_data("init")
	Endif
	////////////////////////////////////////
	SetDataFolder root:sim
	Make/O/n=(100) tempData = x^2
	
	DoWindow/K dataSim
	Display/N=dataSim/K=1/W=(100,50,1200,650)

	NewPanel/K=1/Host=dataSim/N=buttons/W=(0.8,0,1,1)
	Showinfo
	
	// Variables for generating data
	DrawText 100,20,"Data Generation"
	// Generate data
	Button genData,pos={90,20},size={110,20},proc=gen_3D_data,title="GenerateNewData"
	// Generation Modes
	SetVariable SEmode,pos={30,45},limits={1,4,1},size={100,15},value=root:sim:vars:SEmode
	SetVariable DispMode,pos={150,45},limits={1,3,1},size={100,15},value=root:sim:vars:DispMode
	// Value ranges
	DrawText 20, 80, "k_x bounds"
	SetVariable kxbound, title=" ",pos={20,80},limits={0, 3*pi, 0.001},size={75,25},value=root:sim:vars:kxbound, proc=set_kxBounds
	DrawText 110, 80, "nkx"
	SetVariable nkx, title=" ",pos={110,80},limits={10, 500, 10},size={50,25},value=root:sim:vars:nkx
	
	DrawText 20, 120, "k_y bounds"
	SetVariable kybound, title=" ",pos={20,120},limits={0, 3*pi, 0.001},size={75,25},value=root:sim:vars:kybound, proc=set_kyBounds
	DrawText 110, 120, "nky"
	SetVariable nky, title=" ",pos={110,120},limits={10, 500, 10},size={50,25},value=root:sim:vars:nky
	
	// Options
	CheckBox/Z rotateSim, title="Rotate?", pos={190, 80}, variable=root:sim:vars:rotateSim
	DrawText 190, 120, "sim scale:"
	SetVariable numBZ, title=" ", pos={190, 120}, limits={1, 5, 0.1}, value=root:sim:vars:numBZ, proc=set_SimScale
	
	DrawText 20, 160, "E min"
	SetVariable Emin, title=" ",pos={20,160},limits={-1, 0, 0.001},size={75,25},value=root:sim:vars:Emin
	DrawText 100, 160, "E max"
	SetVariable Emax, title=" ",pos={100,160},limits={0, 1, 0.001},size={75,25},value=root:sim:vars:Emax
	DrawText 190, 160, "nE"
	SetVariable nESim, title=" ",pos={190,160},limits={10, 500, 10},size={50,25},value=root:sim:vars:nESim
	
	// Parameters
	DrawText 20, 200, "dE"
	SetVariable dE, title=" ",pos={20,200},limits={0, 1, 0.001},size={50,25},value=root:sim:vars:dE
	DrawText 70, 200, "t0"
	SetVariable t0, title=" ",pos={70,200},limits={0, 1, 0.001},size={50,25},value=root:sim:vars:t0
	DrawText 120, 200, "t1"
	SetVariable t1, title=" ",pos={120,200},limits={0, 1, 0.001},size={50,25},value=root:sim:vars:t1
	DrawText 170, 200, "t2"
	SetVariable t2, title=" ",pos={170,200},limits={0, 1, 0.001},size={50,25},value=root:sim:vars:t2
	DrawText 220, 200, "tp"
	SetVariable tp, title=" ",pos={220,200},limits={0, 1, 0.001},size={50,25},value=root:sim:vars:tp
	
	Button SetTBparams,pos={20,225},size={110,20},proc=Set_TB_params,title="Set according to t0"
	
	DrawText 10, 280, "lambda"
	SetVariable lambda, title=" ",pos={10,280},limits={0, 10, 0.001},size={50,25},value=root:sim:vars:lambda
	DrawText 60, 280, "phononE (eV)"
	SetVariable phononE, title=" ",pos={80,280},limits={0, 1, 0.01},size={50,25},value=root:sim:vars:phononE
	DrawText 140, 280, "scattering (eV)"
	SetVariable scattering, title=" ",pos={140,280},limits={0, 1, 0.001},size={50,25},value=root:sim:vars:scattering
	DrawText 220, 280, "Temp."
	SetVariable T, title=" ",pos={220,280},limits={0, 300, 1},size={50,25},value=root:sim:vars:T
//	DrawText 220, 280, "tp"
//	SetVariable tp, title=" ",pos={220,280},limits={0, 1, 0.001},size={50,25},value=root:sim:vars:tp

	//////////////////////////////////////// File Loading
	
	// TODO:
	// Change transpose checkboxes to selectors to choose transpose mode
	// exactly as in Igor internal. This measn also change the load_data function
	DrawText 110, 330, "Load Waves"
	Button loadSimulatedData, pos={10, 330}, size={120, 20}, proc=load_data, title="Load Simulated Data"
	Checkbox transposeSim, title = "Transpose?", pos={10, 350}, variable=root:sim:vars:transposeSim
	Button loadMeasuredData, pos={150, 330}, size={120, 20}, proc=load_data, title="Load Measured Data"
	Checkbox transposeMeas, title = "Transpose?", pos={150, 350}, variable=root:sim:vars:transposeMeas

	///////////////////////// Slice display control
	// kx vs ky
	DrawText 80, 500, "Slice Display Control"
	DrawText 80, 520, "Simulation:"
	SetVariable set_sliceSim,    title="E_index_sim", pos={ 10, 520}, limits={0, 1000, 1}, size={130,  25} , value=root:sim:vars:EsliceSim      , proc=set_sliceIndex
	SetVariable set_sliceValSim, title="E_val_sim"  , pos={140, 520}, limits={-1000, 1000, 0.01}, size={140, 100}, value=root:sim:vars:EsliceEnergySim, proc=set_sliceVal
	DrawText 80, 560, "Measured:"
	SetVariable set_sliceMeas,    title="E_index_meas", pos={ 10, 560}, limits={0, 1000, 1}, size={130,  25}, value=root:sim:vars:EsliceMeas      , proc=set_sliceIndex
	SetVariable set_sliceValMeas, title="E_val_sim"   , pos={140, 560}, limits={-1000, 1000, 0.01}, size={140, 100}, value=root:sim:vars:EsliceEnergyMeas, proc=set_SliceVal
	
	// Cut display control
	DrawText 80, 600, "Cut display controls"
	String optionsList = "\"selfEnergies;From Cursors\""
	PopupMenu cutChoice,pos={25,600},size={120,20},proc=plot_cut,title="Type:",mode=1,popvalue="choose",value= #optionsList
	Button redrawCuts, pos={180,600}, size={90,20}, proc=redraw_cuts, title="Redraw Cuts"
	
	// Slice display control
	DrawText 80, 640, "Slice display controls"
	String optionsListMode = "\"top;horizontal;vertical;fromCursor\""
	PopupMenu cutChoiceMeas,pos={25,640},size={120,20},title="Type:",mode=1,popvalue="choose", proc=set_draw_mode, value= #optionsListMode
	Button changeMode, pos={180,640}, size={90,20}, proc=change_draw_mode, title="ChangeMode"
	Button resetCursors, pos={180,660}, size={90,20}, proc=reset_cursors, title="ResetCursors"
	
	// Testing
	//Button Test, title="RegenTestData", pos={150, 300}, size={120, 25}, proc=regen_test_data

	/////////////////////////////////////////////////////////////////// Graph Windows
	///////////////////////////////////////// Simulated Data
	Display/K=1/Host=dataSim/N=EDMsim/W=(0,0,0.39,0.6); AppendImage EDMshow
	ColorScale/W=dataSim#EDMsim/N=EDMscale/C/F=0/S=3/A=RT/B=1/E=2/X=-7.00/Y=5.00 image=EDMshow, heightPct=25, frameRGB=0
	Label/W=dataSim#EDMsim bottom, "kx (\\U)"
	Label/W=dataSim#EDMsim left, "ky (\\U)"
	ModifyImage EDMshow ctab= {*,*,BlueHot,1}
	// Cursors by default in antinodal cut mode
	Cursor/I/A=1/C=(64000,0,0)/N=1/W=dataSim#EDMsim A EDMshow kxmin, kymax // Left top
	Cursor/I/A=1/C=(64000,0,0)/N=1/W=dataSim#EDMsim B EDMshow kxmax, kymin // Bottom right
	Cursor/I/A=1/C=(0,64000,0)/N=1/W=dataSim#EDMsim C EDMshow kxmin, kymin // Bottom Left
	Cursor/I/A=1/C=(0,64000,0)/N=1/W=dataSim#EDMsim D EDMshow kxmax, kymax   // Top Right

	// Show selfEnergies or cuts
	Display/K=1/Host=dataSim/N=cutDisplaySim/W=(0, 0.6, 0.39, 1); AppendToGraph/C=(0, 0, 65535) selfEre; AppendToGraph/R selfEim
	ModifyGraph/W=dataSim#cutDisplaySim mirror(bottom)=2
	TextBox/W=dataSim#cutDisplaySim/C/N=text1/F=0/S=3/Z=1/A=MT/E=2 "SelfEnergies"
	Legend/W=dataSim#cutDisplaySim/C/N=text0/J/F=0/S=3/A=LT/E=2/X=20/Y=10 "\\s(SelfEre) SelfEre\r\\s(SelfEim) SelfEim"
	
	///////////////////////////////////////// Measured Data
	Display/K=1/Host=dataSim/N=EDMmeas/W=(0.38, 0.0, 0.78, 0.6); AppendImage MeasDataShow
	ColorScale/W=dataSim#EDMmeas/N=EDMscale/C/F=0/S=3/A=RT/B=1/E=2/X=-7.00/Y=5.00 image=MeasDataShow, heightPct=25, frameRGB=0
	Label/W=dataSim#EDMmeas bottom, "kx (\\U)"
	Label/W=dataSim#EDMmeas left, "ky (\\U)"
	ModifyImage/W=dataSim#EDMmeas MeasDataShow ctab= {*,*,BlueHot,1}
	// Cursors by default in antinodal cut mode
	Cursor/I/A=1/C=(64000,0,0)/N=1/W=dataSim#EDMmeas E MeasDataShow kxMinMeas, kyMaxMeas // Left top
	Cursor/I/A=1/C=(64000,0,0)/N=1/W=dataSim#EDMmeas F MeasDataShow kxMaxMeas, kyMinMeas // Bottom right
	Cursor/I/A=1/C=(0,64000,0)/N=1/W=dataSim#EDMmeas G MeasDataShow kxMinMeas, kyMinMeas // Bottom Left
	Cursor/I/A=1/C=(0,64000,0)/N=1/W=dataSim#EDMmeas H MeasDataShow kxMaxMeas, kyMaxMeas   // Top Right
	
	// Show selfEnergies or cuts
	Display/K=1/Host=dataSim/N=cutDisplayMeas/W=(0.39, 0.6, 0.78, 1); AppendToGraph/C=(0, 0, 65535) selfEre; AppendToGraph/R selfEim
	ModifyGraph/W=dataSim#cutDisplayMeas mirror(bottom)=2
	TextBox/W=dataSim#cutDisplayMeas/C/N=text1/F=0/S=3/Z=1/A=MT/E=2 "SelfEnergies"
	Legend/W=dataSim#cutDisplayMeas/C/N=text0/J/F=0/S=3/A=LT/E=2/X=20/Y=10 "\\s(SelfEre) SelfEre\r\\s(SelfEim) SelfEim"
	
	if (first_load)
		change_draw_mode("init")
	EndIf
End

// Set bounds for data generation
Function set_kxBounds(ctrlName,varNum,varStr,varName):SetVariableControl
	String ctrlName,varName
	Variable varNum,varStr
	String curDataFolder = GetDataFolder(1)
	
	SetDataFolder root:sim:vars
	NVAR kxmin, kxmax
	
	kxmin = -varNum
	kxmax = varNum
	
	SetDataFolder curDataFolder
End

// Set bounds for data generation
Function set_kyBounds(ctrlName,varNum,varStr,varName):SetVariableControl
	String ctrlName,varName
	Variable varNum,varStr
	String curDataFolder = GetDataFolder(1)
	
	SetDataFolder root:sim:vars
	NVAR kymin, kymax
	
	kymin = -varNum
	kymax = varNum
	
	SetDataFolder curDataFolder
End

// Reset cursors to the default corner positions
Function reset_cursors(ctrlName):buttonControl

	String ctrlName
	String curDataFolder = GetDataFolder(1)
	
	SetDataFolder root:sim:vars
	NVAR kxbound, kybound, kxMinMeas, kxMinMeas, kxMaxMeas, kyMinMeas, kyMaxMeas
	NVAR kxmin, kxmax, kymin, kymax
	
	Cursor/I/A=1/C=(64000,0,0)/N=1/W=dataSim#EDMsim A EDMshow kxmin, kymax // Left top
	Cursor/I/A=1/C=(64000,0,0)/N=1/W=dataSim#EDMsim B EDMshow kxmax, kymin // Bottom right
	Cursor/I/A=1/C=(0,64000,0)/N=1/W=dataSim#EDMsim C EDMshow kxmin, kymin // Bottom Left
	Cursor/I/A=1/C=(0,64000,0)/N=1/W=dataSim#EDMsim D EDMshow kxmax, kymax   // Top Right
	
	Cursor/I/A=1/C=(64000,0,0)/N=1/W=dataSim#EDMmeas E MeasDataShow kxMinMeas, kyMaxMeas // Left top
	Cursor/I/A=1/C=(64000,0,0)/N=1/W=dataSim#EDMmeas F MeasDataShow kxMaxMeas, kyMinMeas // Bottom right
	Cursor/I/A=1/C=(0,64000,0)/N=1/W=dataSim#EDMmeas G MeasDataShow kxMinMeas, kyMinMeas // Bottom Left
	Cursor/I/A=1/C=(0,64000,0)/N=1/W=dataSim#EDMmeas H MeasDataShow kxMaxMeas, kyMaxMeas   // Top Right
	
	SetDataFolder curDataFolder
End


// Set the number of BZs as bounds
Function set_SimScale(ctrlName,varNum,varStr,varName):SetVariableControl

	String ctrlName, varStr, varName
	Variable varNum

	String curDataFolder = GetDataFolder(1)
		
	SetDataFolder root:sim:vars
	NVAR kxbound, kybound, kxmin, kxmax, kymin, kymax
	
	kxbound = 2 * varNum * pi - pi
	kxmin = -kxbound
	kxmax = kxbound
	kybound = 2 * varNum * pi - pi
	kymin = -kybound
	kymax = kybound
	
	SetDataFolder curDataFolder

End 


// Sets the show waves to display the chosen slices
Function set_sliceIndex(ctrlName,varNum,varStr,varName):SetVariableControl
	
	String ctrlName, varStr, varName
	Variable varNum
	
	String curDataFolder = GetDataFolder(1)
	
	SetDataFolder root:sim:vars
	NVAR drawMode
	// Simulated Data
	NVAR kxbound, kybound, Emin, Emax
	NVAR kxmin, kxmax, kymin, kymax
	NVAR nkx, nky, nESim
	NVAR dkx, dky, den
	NVAR kxsliceSim, kxSliceValSim, kysliceSim, kySliceValSim, EsliceSim, EsliceEnergySim, cutType
	// Measured Data
	Variable/G kxMinMeas, kxMaxMeas, dkxMeas, nkxMeas
	Variable/G kyMinMeas, kyMaxMeas, dkyMeas, nkyMeas
	Variable/G EminMeas, EmaxMeas, dEMeas, nEMeas
	Variable/G dkxMeas, dkyMeas, dEMeas
	NVAR kxsliceMeas, kxSliceValMeas, kysliceMeas, kySliceValMeas, EsliceMeas, EsliceEnergyMeas

	SetDataFolder root:sim:waves
	Wave EDMShow
	Wave MeasDataShow
	
	SetDataFolder root:sim:MeasuredData
	Wave MeasuredData
	
	SetDataFolder root:sim:SpectralFunction
	Wave spectralFunction
	
	if (stringMatch(varName, "EsliceSim"))
	
		if (varNum > nESim)
			EsliceSim = nESim
		ElseIf (varNum < 0)
			EsliceSim = 0
		Endif
		
		EDMshow = spectralFunction[p][q][EsliceSim]
		
		EsliceEnergySim = IndexToScale(spectralFunction, EsliceSim, 2)
		plot_cut("from_set_slice", cutType, "")

	Elseif (stringMatch(varName, "EsliceMeas"))
	
		if (varNum > nEMeas)
			EsliceMeas = nEMeas
		ElseIf (varNum < 0)
			EsliceMeas = 0
		Endif
		
		MeasDataShow = MeasuredData[p][q][EsliceMeas]
		
		EsliceEnergyMeas = IndexToScale(MeasuredData, EsliceMeas, 2)
		plot_cut("from_set_slice", cutType, "")

	Elseif (stringMatch(varName, "kysliceSim"))
	
		if (varNum > nky)
			kySliceSim = nky
		ElseIf (varNum < 0)
			kySliceSim = 0
		Endif
		
		EDMshow = spectralFunction[p][kySliceSim][q]
		
		kySliceValSim = IndexToScale(spectralFunction, kySliceSim, 1)
		plot_cut("from_set_slice", cutType, "")

	Elseif (stringMatch(varName, "kysliceMeas"))
	
		if (varNum > nkyMeas)
			kysliceMeas = nkyMeas
		ElseIf (varNum < 0)
			kysliceMeas = 0
		Endif
		
		MeasDataShow = MeasuredData[p][kysliceMeas][q]
		
		kySliceValMeas = IndexToScale(MeasuredData, kysliceMeas, 1)
		plot_cut("from_set_slice", cutType, "")

	Elseif (stringMatch(varName, "kxsliceSim"))
	
		if (varNum > nkx)
			kxSliceSim = nkx
		ElseIf (varNum < 0)
			kxSliceSim = 0
		Endif
		
		EDMshow = spectralFunction[kxSliceSim][p][q]
		
		kxSliceValSim = IndexToScale(spectralFunction, kxSliceSim, 0)
		plot_cut("from_set_slice", cutType, "")
		
	Elseif (stringMatch(varName, "kxsliceMeas"))
	
		if (varNum > nkxMeas)
			kxsliceMeas = nkxMeas
		ElseIf (varNum < 0)
			kxsliceMeas = 0
		Endif
		
		MeasDataShow = MeasuredData[kxsliceMeas][p][q]
		
		kxSliceValMeas = IndexToScale(MeasuredData, kxsliceMeas, 0)
		plot_cut("from_set_slice", cutType, "")
		
	EndIf
	
	SetDataFolder curDataFolder
End

Function set_sliceVal(ctrlName,varNum,varStr,varName):SetVariableControl

	String ctrlName, varStr, varName
	Variable varNum
	
	String curDataFolder = GetDataFolder(1)
	
	SetDataFolder root:sim:vars
	NVAR drawMode
	// Simulated Data
	NVAR kxbound, kybound, Emin, Emax
	NVAR kxmin, kxmax, kymin, kymax
	NVAR nkx, nky, nESim
	NVAR dkx, dky, den
	NVAR kxsliceSim, kxSliceValSim, kysliceSim, kySliceValSim, EsliceSim, EsliceEnergySim, cutType
	// Measured Data
	Variable/G kxMinMeas, kxMaxMeas, dkxMeas, nkxMeas
	Variable/G kyMinMeas, kyMaxMeas, dkyMeas, nkyMeas
	Variable/G EminMeas, EmaxMeas, dEMeas, nEMeas
	Variable/G dkxMeas, dkyMeas, dEMeas
	NVAR kxsliceMeas, kxSliceValMeas, kysliceMeas, kySliceValMeas, EsliceMeas, EsliceEnergyMeas

	SetDataFolder root:sim:waves
	Wave EDMShow
	Wave MeasDataShow
	
	SetDataFolder root:sim:MeasuredData
	Wave MeasuredData
	
	SetDataFolder root:sim:SpectralFunction
	Wave spectralFunction
	
	if (stringMatch(varName, "EsliceEnergySim"))
		// Calculate index of chosen energy (with bounds checking)
		// Then set EDMshow and MeasDataShow
		// to the correct slices
		// Also update the slice index variables
		if (varNum > Emax)
			EsliceEnergySim = Emax
		ElseIf (varNum < Emin)
			EsliceEnergySim = Emin
		Endif
		
		EsliceSim = ScaleToIndex(spectralFunction, EsliceEnergySim, 2)
		EsliceEnergySim = IndexToScale(spectralFunction, EsliceSim, 2)
		
		EDMshow = spectralFunction[p][q][EsliceSim]
		
		plot_cut("from_set_slice", cutType, "")

	Elseif (stringMatch(varName, "EsliceEnergyMeas"))
	
		if (varNum > EmaxMeas)
			EsliceEnergyMeas = EmaxMeas
		ElseIf (varNum < EminMeas)
			EsliceEnergyMeas = EminMeas
		Endif
		
		EsliceMeas = ScaleToIndex(MeasuredData, EsliceEnergyMeas, 2)
		EsliceEnergyMeas = IndexToScale(MeasuredData, EsliceMeas, 2)
		
		MeasDataShow = MeasuredData[p][q][EsliceMeas]
		
		plot_cut("from_set_slice", cutType, "")
		
	Elseif (stringMatch(varName, "kySliceValSim"))
		
		if (varNum > kymax)
			kySliceValSim = kymax
		ElseIf (varNum < kymin)
			kySliceValSim = kymin
		Endif
		
		kySliceSim = ScaleToIndex(spectralFunction, kySliceValSim, 1)
		kySliceValSim = IndexToScale(spectralFunction, kySliceSim, 1)
		
		EDMshow = spectralFunction[p][kySliceSim][q]
		
		plot_cut("from_set_slice", cutType, "")

	Elseif (stringMatch(varName, "kysliceValMeas"))
	
		if (varNum > kyMaxMeas)
			kysliceValMeas = kyMaxMeas
		ElseIf (varNum < kyMinMeas)
			kysliceValMeas = kyMinMeas
		Endif
		
		kySliceMeas = ScaleToIndex(MeasuredData, kysliceValMeas, 1)
		kysliceValMeas = IndexToScale(MeasuredData, kySliceMeas, 1)
		
		MeasDataShow = MeasuredData[p][kySliceMeas][q]
		
		plot_cut("from_set_slice", cutType, "")
	
	Elseif (stringMatch(varName, "kxSliceValSim"))
	
		if (varNum > kxmax)
			kxSliceValSim = kxmax
		ElseIf (varNum < kxmin)
			kxSliceValSim = kxmin
		Endif
		
		kxSliceSim = ScaleToIndex(spectralFunction, kxSliceValSim, 0)
		kxSliceValSim = IndexToScale(spectralFunction, kxSliceSim, 0)
		
		EDMshow = spectralFunction[kxSliceSim][p][q]
		
		plot_cut("from_set_slice", cutType, "")
	
	Elseif (stringMatch(varName, "kxsliceValMeas"))
	
		if (varNum > kxMaxMeas)
			kxsliceValMeas = kxMaxMeas
		ElseIf (varNum < kxMinMeas)
			kxsliceValMeas = kxMinMeas
		Endif
		
		kxSliceMeas = ScaleToIndex(MeasuredData, kxsliceValMeas, 0)
		kxsliceValMeas = IndexToScale(MeasuredData, kxSliceMeas, 0)
		
		MeasDataShow = MeasuredData[kxSliceMeas][p][q]
		
		plot_cut("from_set_slice", cutType, "")
	
	EndIf
	
	SetDataFolder curDataFolder
End

// Just sets a global variable to the chosen draw mode
// Actual processing is done in change_draw_mode(ctrlName)
Function set_draw_mode(ctrlName, popNum, popStr) : PopupMenuControl
	
	Variable popNum
	String ctrlName, popStr
	String curDataFolder = getDataFolder(1)
	
	SetDataFolder root:sim:vars
	NVAR drawMode 
	drawMode = popNum
	
	SetDataFolder curDataFolder

End 

// Sets the show waves depending on the chosen draw mode (top, horizontal, vertical and cursor)
Function change_draw_mode(ctrlName):buttonControl
	
	String ctrlName
	
	String curDataFolder = getDataFolder(1)
	
	SetDataFolder root:sim:vars
	NVAR drawMode, prevDrawMode
	// Simulated Data
	NVAR kxbound, kybound, Emin, Emax
	NVAR kxmin, kxmax, kymin, kymax
	NVAR nkx, nky, nESim
	NVAR dkx, dky, den
	NVAR kxsliceSim, kxSliceValSim, kysliceSim, kySliceValSim, EsliceSim, EsliceEnergySim, cutType
	// Measured Data
	NVAR kxMinMeas, kxMaxMeas, dkxMeas, nkxMeas
	NVAR kyMinMeas, kyMaxMeas, dkyMeas, nkyMeas
	NVAR EminMeas, EmaxMeas, dEMeas, nEMeas
	NVAR dkxMeas, dkyMeas, dEMeas
	NVAR kxsliceMeas, kxSliceValMeas, kysliceMeas, kySliceValMeas, EsliceMeas, EsliceEnergyMeas

	SetDataFolder root:sim:waves
	Wave EDMShow
	Wave MeasDataShow
	
	SetDataFolder root:sim:MeasuredData
	Wave MeasuredData
	
	SetDataFolder root:sim:SpectralFunction
	Wave spectralFunction
	
	// Change draw mode
	// Draw slices of data as images depending on choice
	// Free choice by using the first cursor pair on each image
	// 
	// Normal kx vs ky slices
	If (drawMode == 1)
		// Make sure the show waves are the right dimensions and scales
		Redimension/N=(nkx, nky) EDMShow
		SetScale/P x, kxmin, dkx, "A^-1" EDMShow
		SetScale/P y, kymin, dky, "A^-1" EDMShow
		Redimension/N=(nkxMeas, nkyMeas) MeasDataShow
		SetScale/P x, kxMinMeas, dkxMeas, "A^-1" MeasDataShow
		SetScale/P y, kyMinMeas, dkyMeas, "A^-1" MeasDataShow
		
		// Update Variables
		EsliceSim = ScaleToIndex(spectralFunction, 0, 2)
		EsliceEnergySim = IndexToScale(spectralFunction, EsliceSim, 2)
		EsliceMeas = floor(nEMeas / 2)
		EsliceEnergyMeas = IndexToScale(MeasuredData, EsliceMeas, 2)
		
		// Set Show Waves
		EDMshow = spectralFunction[p][q][EsliceSim]
		MeasDataShow = MeasuredData[p][q][EsliceMeas]
		
		// Show correct Controls
		SetVariable set_sliceSim    , title="E_index_sim" , value=root:sim:vars:EsliceSim   
		SetVariable set_sliceValSim , title="E_val_sim"   , value=root:sim:vars:EsliceEnergySim
		SetVariable set_sliceMeas   , title="E_index_meas", value=root:sim:vars:EsliceMeas      
		SetVariable set_sliceValMeas, title="E_val_meas"  , value=root:sim:vars:EsliceEnergyMeas
		
		Label/W=dataSim#EDMsim bottom, "kx (\\U)"
		Label/W=dataSim#EDMsim left, "ky (\\U)"
		Label/W=dataSim#EDMmeas bottom, "kx (\\U)"
		Label/W=dataSim#EDMmeas left, "ky (\\U)"
		
		prevDrawMode = 1
	// kx vs E slice (horizontal) So slice index is ky
	ElseIf (drawMode == 2)
	
		Redimension/N=(nkx, nESim) EDMShow
		SetScale/P x, kxmin, dkx, "A^-1" EDMShow
		SetScale/P y, Emin, den, "eV" EDMShow
		
		Redimension/N=(nkxMeas, nEMeas) MeasDataShow
		SetScale/P x, kxMinMeas, dkxMeas, "A^-1" MeasDataShow
		SetScale/P y, EMinMeas, dEMeas, "eV" MeasDataShow
		
		// Update Variables
		kySliceSim = floor(nky / 2)
		kySliceValSim = IndexToScale(spectralFunction, kySliceSim, 1)
		kySliceMeas = floor(nkyMeas / 2)
		kySliceValMeas = IndexToScale(MeasuredData, kySliceMeas, 1)
		
		// Set Show Waves
		EDMshow = spectralFunction[p][kySliceSim][q]
		MeasDataShow = MeasuredData[p][kySliceMeas][q]
		
		// Show correct controls
		SetVariable set_sliceSim    , title="ky_index_sim" , value=root:sim:vars:kySliceSim   
		SetVariable set_sliceValSim , title="ky_val_sim"   , value=root:sim:vars:kySliceValSim
		SetVariable set_sliceMeas   , title="ky_index_meas", value=root:sim:vars:kySliceMeas   
		SetVariable set_sliceValMeas, title="ky_val_meas"  , value=root:sim:vars:kySliceValMeas
		
		Label/W=dataSim#EDMsim bottom, "kx (\\U)"
		Label/W=dataSim#EDMsim left, "E (\\U)"
		Label/W=dataSim#EDMmeas bottom, "kx (\\U)"
		Label/W=dataSim#EDMmeas left, "E (\\U)"
		
		prevDrawMode = 2
	// ky vs E slice (vertical) So slice index is kx
	ElseIf (drawMode == 3)
	
		Redimension/N=(nky, nESim) EDMShow
		SetScale/P x, kymin, dky, "A^-1" EDMShow
		SetScale/P y, Emin, den, "eV" EDMShow
		
		Redimension/N=(nkyMeas, nEMeas) MeasDataShow
		SetScale/P x, kyMinMeas, dkyMeas, "A^-1" MeasDataShow
		SetScale/P y, EMinMeas, dEMeas, "eV" MeasDataShow
		
		// Update Variables
		kxSliceSim = floor(nkx / 2)
		kxSliceValSim = IndexToScale(spectralFunction, kxSliceSim, 0)
		kxSliceMeas = floor(nkxMeas / 2)
		kxSliceValMeas = IndexToScale(MeasuredData, kxSliceMeas, 0)
		
		EDMshow = spectralFunction[kxSliceSim][p][q]
		MeasDataShow = MeasuredData[kxSliceMeas][p][q]

		// Show correct controls
		SetVariable set_sliceSim    , title="kx_index_sim" , value=root:sim:vars:kxSliceSim   
		SetVariable set_sliceValSim , title="kx_val_sim"   , value=root:sim:vars:kxSliceValSim
		SetVariable set_sliceMeas   , title="kx_index_meas", value=root:sim:vars:kxSliceMeas   
		SetVariable set_sliceValMeas, title="kx_val_meas"  , value=root:sim:vars:kxSliceValMeas
		
		Label/W=dataSim#EDMsim left  , "E (\\U)"
		Label/W=dataSim#EDMsim bottom, "ky (\\U)"
		Label/W=dataSim#EDMmeas left  , "E (\\U)"
		Label/W=dataSim#EDMmeas bottom, "ky (\\U)"
		
		prevDrawMode = 3
	ElseIf (drawMode == 4)
		// Set slice to draw from cursor AB for sim data and EF for meas Data
		SetDataFolder root:sim:vars
		Variable/G posAx = pcsr(A, "dataSim#EDMsim"), posBx = pcsr(B, "dataSim#EDMsim")
		Variable/G posAy = qcsr(A, "dataSim#EDMsim"), posBy = qcsr(B, "dataSim#EDMsim")
		Variable/G posEx = pcsr(E, "dataSim#EDMmeas"), posFx = pcsr(F, "dataSim#EDMmeas")
		Variable/G posEy = qcsr(E, "dataSim#EDMmeas"), posFy = qcsr(F, "dataSim#EDMmeas")
		SetDataFolder root:sim:waves
		Variable m_AB = (posAy - posBy)/(posAx - posBx)
		Variable m_EF = (posEy - posFy)/(posEx - posFx)
		Variable pStart_AB = posAx < posBx ? posAx : posBx
		Variable qStart_AB = posAx < posBx ? posAy : posBy
		Variable pStart_EF = posEx < posFx ? posEx : posFx
		Variable qStart_EF = posEx < posFx ? posEy : posFy
		Variable dHorAB = abs(m_AB) < 1 ? abs(posAx - posBx) : abs(posAy - posBy)
		Variable dHorEF = abs(m_EF) < 1 ? abs(posEx - posFx) : abs(posEy - posFy)
		Variable n, m
		Variable dVertAB, dVertEF
		
		// Set correct dimensions of show waves
		switch(prevDrawMode)
			case 1: 
				dVertAB = dimSize(spectralFunction, 2)
				dVertEF = dimSize(MeasuredData, 2)
				break
			case 2: 
				dVertAB = dimSize(spectralFunction, 1)
				dVertEF = dimSize(MeasuredData, 1)
				break
			case 3: 
				dVertAB = dimSize(spectralFunction, 0)
				dVertEF = dimSize(MeasuredData, 0)
				break
		endSwitch
		
		Make/O/N=(dHorAB, dVertAB) tmpAB
		Make/O/N=(dHorEF, dVertEF) tmpEF
		
		//////////////////////// AB
		if (abs(m_AB) < 1)
			switch(prevDrawMode)
				case 1: 
					tmpAB = spectralFunction[pStart_AB + p][qStart_AB + floor(m_AB * p)][q]
					break
				case 2: 
					tmpAB = spectralFunction[pStart_AB + p][q][qStart_AB + floor(m_AB * p)]
					break
				case 3: 
					tmpAB = spectralFunction[q][pStart_AB + p][qStart_AB + floor(m_AB * p)]
					break
			endSwitch
		ElseIf (m_AB <= -1)
			switch(prevDrawMode)
				case 1: 
					tmpAB = spectralFunction[pStart_AB - floor(1/m_AB * p)][qStart_AB - p][q]
					break
				case 2: 
					tmpAB = spectralFunction[pStart_AB - floor(1/m_AB * p)][q][qStart_AB - p]
					break
				case 3: 
					tmpAB = spectralFunction[q][pStart_AB - floor(1/m_AB * p)][qStart_AB - p]
					break
			endSwitch
		ElseIf (m_AB >= 1)
			switch(prevDrawMode)
				case 1: 
					tmpAB = spectralFunction[pStart_AB + floor(1/m_AB * p)][qStart_AB + p][q]
					break
				case 2: 
					tmpAB = spectralFunction[pStart_AB + floor(1/m_AB * p)][q][qStart_AB + p]
					break
				case 3: 
					tmpAB = spectralFunction[q][pStart_AB + floor(1/m_AB * p)][qStart_AB + p]
					break
			endSwitch
		EndIf
		
		
		//////////////////////////////////// EF
		if (abs(m_EF) < 1)
			switch(prevDrawMode)
				case 1: 
					tmpEF = MeasuredData[pStart_EF + p][qStart_EF + floor(m_EF * p)][q]
					break
				case 2: 
					tmpEF = MeasuredData[pStart_EF + p][q][qStart_EF + floor(m_EF * p)]
					break
				case 3: 
					tmpEF = MeasuredData[q][pStart_EF + p][qStart_EF + floor(m_EF * p)]
					break
			endSwitch
		ElseIf (m_EF <= -1)
			switch(prevDrawMode)
				case 1: 
					tmpEF = MeasuredData[pStart_EF - floor(1/m_EF * p)][qStart_EF - p][q]
					break
				case 2: 
					tmpEF = MeasuredData[pStart_EF - floor(1/m_EF * p)][q][qStart_EF - p]
					break
				case 3: 
					tmpEF = MeasuredData[q][pStart_EF - floor(1/m_AB * p)][qStart_EF - p]
					break
			endSwitch
		ElseIf (m_EF >= 1)
			switch(prevDrawMode)
				case 1: 
					tmpEF = MeasuredData[pStart_EF + floor(1/m_EF * p)][qStart_EF + p][q]
					break
				case 2: 
					tmpEF = MeasuredData[pStart_EF + floor(1/m_EF * p)][q][qStart_EF + p]
					break
				case 3: 
					tmpEF = MeasuredData[q][pStart_EF + floor(1/m_EF * p)][qStart_EF + p]
					break
			endSwitch
		EndIf
		
		
		switch(prevDrawMode)
			case 1:
				SetScale/P y, dimOffset(spectralFunction, 2), dimDelta(spectralFunction, 2), "meV" tmpAB
				SetScale/P y, dimOffset(MeasuredData, 2), dimDelta(MeasuredData, 2), "meV" tmpEF
				Label/W=dataSim#EDMsim left  , "E (\\U)"
				Label/W=dataSim#EDMsim bottom, "kx (\\U)"
				Label/W=dataSim#EDMmeas left  , "E (\\U)"
				Label/W=dataSim#EDMmeas bottom, "kx (\\U)"
				break
			case 1:
				SetScale/P y, dimOffset(spectralFunction, 1), dimDelta(spectralFunction, 1), tmpAB
				SetScale/P y, dimOffset(MeasuredData, 1), dimDelta(MeasuredData, 1), tmpEF
				break
			case 1:
				SetScale/P y, dimOffset(spectralFunction, 0), dimDelta(spectralFunction, 0), tmpAB
				SetScale/P y, dimOffset(MeasuredData, 0), dimDelta(MeasuredData, 0), tmpEF
				break
		EndSwitch

		Duplicate/O tmpAB EDMshow
		Duplicate/O tmpEF MeasDataShow	

	EndIf
	
	SetDataFolder curDataFolder

End

// Load a wave into root:sim:MeasuredData:MeasuredData
Function load_data(ctrlName):buttonControl

	String ctrlName
	
	String CurDataFolder = GetDataFolder(1)
	
	SetDataFolder root:sim:vars
	SVAR toLoadPath
	NVAR transposeSim, transposeMeas
	//////////////////// Measured Data info
	NVAR kxMinMeas, kxMaxMeas, dkxMeas, nkxMeas
	NVAR kyMinMeas, kyMaxMeas, dkyMeas, nkyMeas
	NVAR EminMeas, EmaxMeas, dEMeas, nEMeas
	NVAR toLoadNumDims
	NVAR EsliceMeas, EsliceEnergyMeas
	//////////////////// Simulated Data info
	NVAR kxBound, kyBound, dkx, dky, nkx, nky
	NVAR kxmin, kxmax, kymin, kymax
	NVAR Emin, Emax, den, nESim
	NVAR EsliceSim, EsliceEnergySim
	
	SetDataFolder root:sim:waves
	Wave EDMshow
	Wave MeasDataShow
	
	SetDataFolder root:sim:SpectralFunction
	Wave spectralFunction
	
	SetDataFolder root:sim:MeasuredData
	Wave MeasuredData
	
	String path
	String message = "Path to data:"
	
	Prompt path, "Enter path to data: "
	DoPrompt message, path
	
	if (stringMatch(path, ""))
		path = "root:FSMAP1:new_wave"
	EndIf
	
	toLoadPath = path
	
	NewDataFolder/O/S root:sim:load_data
	
	if (waveExists($toLoadPath))
		Duplicate/O $toLoadPath toLoad
		WaveStats/Q/P/RMD=[0, *][0, *][0, *][0, *] toLoad
		toLoadNumDims = (V_startRow == 0 ? 1 : 0) + (V_startCol == 0 ? 1 : 0) + (V_startLayer == 0 ? 1 : 0)
		
		// 2D data simply gets displayed
		if (toLoadNumDims == 2)
			
			if (stringMatch(ctrlName, "loadSimulatedData"))
				Duplicate/O toLoad spectralFunction
				Duplicate/O toLoad EDMshow
				
				SetVariable EsliceSim, disable=1
				SetVariable EsliceEnergySim, disable=1
				
				// In case of 2D measured data, the kx variable is used for the k axis
				// If simulated data is loaded it is only valid for data symmetric
				// around 0 with min(kx) = - max(kx)
				kxmin = dimOffset(toLoad, 0)
				dkx = dimDelta(toLoad, 0)
				nkx = dimSize(toLoad, 0)
				kxmax = kxmin + nkx * dkx
				
				Emin = dimOffset(toLoad, 1)
				dEn = dimDelta(toLoad, 1)
				nESim = dimSize(toLoad, 1)
				EmaxMeas = EminMeas + dEMeas * nEMeas
			ElseIf (stringMatch(ctrlName, "loadMeasuredData"))
				Duplicate/O toLoad MeasuredData
				Duplicate/O toLoad MeasDataShow
				
				SetVariable EsliceMeas, disable=1
				SetVariable EsliceEnergyMeas, disable=1
				
				// In case of 2D measured data, the kx variable is used for the k axis
				kxMinMeas = dimOffset(toLoad, 0)
				dkxMeas = dimDelta(toLoad, 0)
				nkxMeas = dimSize(toLoad, 0)
				kxMaxMeas = kxMinMeas + dkxMeas * nkxMeas
				
				EminMeas = dimOffset(toLoad, 1)
				dEMeas = dimDelta(toLoad, 1)
				nEMeas = dimSize(toLoad, 1)
				EmaxMeas = EminMeas + dEMeas * nEMeas
			EndIf
			
		// 3D data gets plotted at the fermi level (if applicable)
		ElseIf (toLoadNumDims == 3)

			if (stringMatch(ctrlName, "loadSimulatedData"))
			
				if (transposeSim)
					// To Handle real ARPES data, we need to do some transposes and scaling
					MatrixOp/O tmp = transposeVol(toLoad, 1) 
					SetScale/P x, dimOffset(toLoad, 0), dimDelta(toLoad, 0), tmp
					SetScale/P y, dimOffset(toLoad, 2), dimDelta(toLoad, 2), tmp
					SetScale/P z, dimOffset(toLoad, 1), dimDelta(toLoad, 1), tmp
					Duplicate/O tmp toLoad
				
					killwaves tmp
				EndIf
			
				SetDataFolder root:sim:SpectralFunction
				Duplicate/O toLoad spectralFunction
			
				SetVariable EsliceSim, disable=0
				SetVariable EsliceEnergySim, disable=2
				
				EsliceSim = ScaleToIndex(toLoad, 0, 2)
				EsliceEnergySim = IndexToScale(toLoad, EsliceSim, 2)
				
				kxmin = dimOffset(toLoad, 0)
				dkx = dimDelta(toLoad, 0)
				nkx = dimSize(toLoad, 0)
				kxmax = kxmin + nkx * dkx
				
				kymin = dimOffset(toLoad, 1)
				dky = dimDelta(toLoad, 1)
				nky = dimSize(toLoad, 1)
				kymax = kymin + nky * dky
				
				Emin = dimOffset(toLoad, 2)
				den = dimDelta(toLoad, 2)
				nESim = dimSize(toLoad, 2)
				
				SetDataFolder root:sim:waves
			
				Make/O/N=(dimSize(toLoad, 0), dimSize(toLoad, 1)) EDMshow
				EDMshow = toLoad[p][q][EsliceMeas]
				SetScale/P x, kxmin, dkx, "A^-1", EDMshow
				SetScale/P y, kymin, dky, "A^-1", EDMshow
				
				SetVariable EsliceSim, disable=0
				SetVariable EsliceEnergySim, disable=2
				
			ElseIf (stringMatch(ctrlName, "loadMeasuredData"))
			
				if (transposeMeas)
					// To Handle real ARPES data, we need to do some transposes and scaling
					MatrixOp/O tmp = transposeVol(toLoad, 1) 
					SetScale/P x, dimOffset(toLoad, 0), dimDelta(toLoad, 0), tmp
					SetScale/P y, dimOffset(toLoad, 2), dimDelta(toLoad, 2), tmp
					SetScale/P z, dimOffset(toLoad, 1), dimDelta(toLoad, 1), tmp
					Duplicate/O tmp toLoad
				
					killwaves tmp
				EndIf
				
				SetDataFolder root:sim:MeasuredData
				Duplicate/O toLoad MeasuredData
			
				SetVariable EsliceMeas, disable=0
				SetVariable EsliceEnergyMeas, disable=2
				
				EsliceMeas = ScaleToIndex(toLoad, 0, 2)
				EsliceEnergyMeas = IndexToScale(toLoad, EsliceMeas, 2)
				
				kxMinMeas = dimOffset(toLoad, 0)
				dkxMeas = dimDelta(toLoad, 0)
				nkxMeas = dimSize(toLoad, 0)
				kxMaxMeas = kxMinMeas + dkxMeas * nkxMeas
				
				kyMinMeas = dimOffset(toLoad, 1)
				dkyMeas = dimDelta(toLoad, 1)
				nkyMeas = dimSize(toLoad, 1)
				kyMaxMeas = kyMinMeas + dkyMeas * nkyMeas
				
				EminMeas = dimOffset(toLoad, 2)
				dEMeas = dimDelta(toLoad, 2)
				nEMeas = dimSize(toLoad, 2)
				EmaxMeas = EminMeas + dEMeas * nEMeas
				
				SetDataFolder root:sim:waves
				
				Make/O/N=(dimSize(toLoad, 0), dimSize(toLoad, 1)) MeasDataShow
				MeasDataShow = toLoad[p][q][EsliceMeas]
				SetScale/P x, kxMinMeas, dkxMeas, "A^-1", MeasDataShow
				SetScale/P y, kyMinMeas, dkyMeas, "A^-1", MeasDataShow
			EndIf
		EndIf
	Else
		print "Error: invalid path entered"
	EndIf
	
	
	
	SetDataFolder curDataFolder

End

// Draws cuts again, used for updating cuts after moving cursors
Function redraw_cuts(ctrlName):buttonControl
	String ctrlName
	String curDataFolder = GetDataFolder(1)
	
	NewDataFolder/O/S root:sim:temp
	ControlInfo/W=dataSim#buttons cutChoice
	plot_cut("redraw", V_Value, "redraw")
	
	SetDataFolder curDataFolder
end

// Get position of the cursors from the simulated EDM graph and set the cut1 and cut2
// waves
Function SetTraceFromCursors()

	Variable simOrMeas

	String curDataFolder = GetDataFolder(1)
	
	SetDataFolder root:sim:vars
	
	// Sim
	Variable/G posAx = pcsr(A, "dataSim#EDMsim"), posBx = pcsr(B, "dataSim#EDMsim"), posCx = pcsr(C, "dataSim#EDMsim"), posDx = pcsr(D, "dataSim#EDMsim")
	Variable/G posAy = qcsr(A, "dataSim#EDMsim"), posBy = qcsr(B, "dataSim#EDMsim"), posCy = qcsr(C, "dataSim#EDMsim"), posDy = qcsr(D, "dataSim#EDMsim")
	// Meas
	Variable/G posEx = pcsr(E, "dataSim#EDMmeas"), posFx = pcsr(F, "dataSim#EDMmeas"), posGx = pcsr(G, "dataSim#EDMmeas"), posHx = pcsr(H, "dataSim#EDMmeas")
	Variable/G posEy = qcsr(E, "dataSim#EDMmeas"), posFy = qcsr(F, "dataSim#EDMmeas"), posGy = qcsr(G, "dataSim#EDMmeas"), posHy = qcsr(H, "dataSim#EDMmeas")
	
	SetDataFolder root:sim:waves
	Wave cut1, cut2
	Wave cut3, cut4
	Wave EDMshow, MeasDataShow
	
	// Sim
	Variable m_trace1 = (posAy - posBy)/(posAx - posBx)
	Variable m_trace2 = (posCy - posDy)/(posCx - posDx)
	// Meas
	Variable m_trace3 = (posEy - posFy)/(posEx - posFx)
	Variable m_trace4 = (posGy - posHy)/(posGx - posHx)
	
	// Sim
	Variable pStart_trace1 = posAx < posBx ? posAx : posBx
	Variable qStart_trace1 = posAx < posBx ? posAy : posBy
	Variable pStart_trace2 = posCx < posDx ? posCx : posDx
	Variable qStart_trace2 = posCx < posDx ? posCy : posDy
	// Meas
	Variable pStart_trace3 = posEx < posFx ? posEx : posFx
	Variable qStart_trace3 = posEx < posFx ? posEy : posFy
	Variable pStart_trace4 = posGx < posHx ? posGx : posHx
	Variable qStart_trace4 = posGx < posHx ? posGy : posHy
	
	// Sim
	Variable numPoints_trace1 = abs(m_trace1) < 1 ? abs(posAx - posBx) : abs(posAy - posBy)
	Variable numPoints_trace2 = abs(m_trace2) < 1 ? abs(posCx - posDx) : abs(posCy - posDy)
	// Sim
	Variable numPoints_trace3 = abs(m_trace3) < 1 ? abs(posEx - posFx) : abs(posEy - posFy)
	Variable numPoints_trace4 = abs(m_trace4) < 1 ? abs(posGx - posHx) : abs(posGy - posHy)
	
	Variable n
	
	// AB cut (sim)
	Redimension/N=(numPoints_trace1) cut1
	cut1 = 0
	/////////////////////////////////// DEBUG
	duplicate/O EDMshow edmtmp
	edmTmp = 0
	/////////////////////////////////////////
	
	for (n = 0; n <= numPoints_trace1; n++)
		if (abs(m_trace1) < 1)
			cut1[n] = EDMshow[pStart_trace1 + n][qStart_trace1 + floor(m_trace1 * n)]
			edmtmp[pStart_trace1 + n][qStart_trace1 + floor(m_trace1 * n)] = 1
		ElseIf (m_trace1 <= -1)
			cut1[n] = EDMshow[pStart_trace1 - floor(1/m_trace1 * n)][qStart_trace1 - n]
			edmtmp[pStart_trace1 - floor(1/m_trace1 * n)][qStart_trace1 - n] = 1
		ElseIf (m_trace1 >= 1)
			cut1[n] = EDMshow[pStart_trace1 + floor(1/m_trace1 * n)][qStart_trace1 + n]
			edmtmp[pStart_trace1 + floor(1/m_trace1 * n)][qStart_trace1 + n] = 1
		EndIf
	EndFor

	SetScale/P x, 0, abs(((indexToScale(EDMshow, posAy, 1) - IndexToScale(EDMshow, posBy, 1))/(IndexToScale(EDMshow, posAx, 0) - IndexToScale(EDMshow, posBx, 0))) / numPoints_trace1), "A^-1", cut1
	
	// CD cut (sim)
	Redimension/N=(numPoints_trace2) cut2
	cut2 = 0
	
	for (n = 0; n <= numPoints_trace2; n++)
		if (abs(m_trace2) < 1)
			cut2[n] = EDMshow[pStart_trace2 + n][qStart_trace2 + floor(m_trace2 * n)]
			edmtmp[pStart_trace2 + n][qStart_trace2 + floor(m_trace2 * n)] =  1
		ElseIf (m_trace2 <= -1)
			cut2[n] = EDMshow[pStart_trace2 - floor(1/m_trace2 * n)][qStart_trace2 - n]
			edmtmp[pStart_trace2 - floor(1/m_trace2 * n)][qStart_trace2 - n] =  1
		ElseIf (m_trace2 >= 1)
			cut2[n] = EDMshow[pStart_trace2 + floor(1/m_trace2 * n)][qStart_trace2 + n]
			edmtmp[pStart_trace2 + floor(1/m_trace2 * n)][qStart_trace2 + n] =  1
		EndIf
	EndFor	

	SetScale/P x, 0, abs(((indexToScale(EDMshow, posCy, 1) - IndexToScale(EDMshow, posDy, 1))/(IndexToScale(EDMshow, posCx, 0) - IndexToScale(EDMshow, posDx, 0))) / numPoints_trace2), "A^-1", cut2
	
	// EF cut (meas)
	Redimension/N=(numPoints_trace3) cut3
	cut3 = 0
	
	for (n = 0; n <= numPoints_trace3; n++)
		if (abs(m_trace3) < 1)
			cut3[n] = MeasDataShow[pStart_trace3 + n][qStart_trace3 + floor(m_trace3 * n)]
			//edmtmp[pStart_trace2 + n][qStart_trace2 + floor(m_trace2 * n)] =  1
		ElseIf (m_trace3 <= -1)
			cut3[n] = MeasDataShow[pStart_trace3 - floor(1/m_trace3 * n)][qStart_trace3 - n]
			//edmtmp[pStart_trace2 - floor(1/m_trace2 * n)][qStart_trace2 - n] =  1
		ElseIf (m_trace3 >= 1)
			cut3[n] = MeasDataShow[pStart_trace3 + floor(1/m_trace3 * n)][qStart_trace3 + n]
			//edmtmp[pStart_trace3 + floor(1/m_trace3 * n)][qStart_trace3 + n] =  1
		EndIf
	EndFor	

	SetScale/P x, 0, abs(((indexToScale(MeasDataShow, posEy, 1) - IndexToScale(MeasDataShow, posFy, 1))/(IndexToScale(MeasDataShow, posEx, 0) - IndexToScale(MeasDataShow, posFx, 0))) / numPoints_trace3), "A^-1", cut3
	
	// GH cut (meas)
	Redimension/N=(numPoints_trace4) cut4
	cut4 = 0
	
	for (n = 0; n <= numPoints_trace4; n++)
		if (abs(m_trace4) < 1)
			cut4[n] = MeasDataShow[pStart_trace4 + n][qStart_trace4 + floor(m_trace4 * n)]
			//edmtmp[pStart_trace2 + n][qStart_trace2 + floor(m_trace2 * n)] =  1
		ElseIf (m_trace4 <= -1)
			cut4[n] = MeasDataShow[pStart_trace4 - floor(1/m_trace4 * n)][qStart_trace4 - n]
			//edmtmp[pStart_trace2 - floor(1/m_trace2 * n)][qStart_trace2 - n] =  1
		ElseIf (m_trace4 >= 1)
			cut4[n] = MeasDataShow[pStart_trace4 + floor(1/m_trace4 * n)][qStart_trace4 + n]
			//edmtmp[pStart_trace3 + floor(1/m_trace3 * n)][qStart_trace3 + n] =  1
		EndIf
	EndFor	

	SetScale/P x, 0, abs(((indexToScale(MeasDataShow, posGy, 1) - IndexToScale(MeasDataShow, posHy, 1))/(IndexToScale(MeasDataShow, posGx, 0) - IndexToScale(MeasDataShow, posHx, 0))) / numPoints_trace4), "A^-1", cut4
	
	SetDataFolder curDataFolder
	/////////////////////////////////// DEBUG
	//RemoveImage/Z/W=dataSim#EDM edmtmp
	//AppendImage/W=dataSim#EDM edmtmp
	/////////////////////////////////////////
End

// callback function for popupmenu to plot the correct 1D cut
Function plot_cut(ctrlName, popNum, popStr) : PopupMenuControl

	// TODO :
	// Update to work with scaling depending on slice display mode
	// Ex.: In top slice mode use custom ticks distance from center
	// Ex.: In side mode use projection on momentum axis (default),
	//      also set a checkbox to choose k or E projection next to cut display controls
	
	String ctrlName, popStr
	Variable popNum
	String curDataFolder = GetDataFolder(1)
	
	if (stringmatch(ctrlName, "") || popNum == 0)
		Return 0
	EndIf
	
	// Bookkeeping
	SetDataFolder root:sim:vars
	// Used in generating 3D data
	NVAR SEmode, DispMode
	NVAR kxbound, kybound, Emin, Emax
	NVAR kxmin, kxmax, kymin, kymax
	NVAR nkx, nky, nESim
	NVAR dkx, dky, den
	NVAR cutPointsX, cutPointsY, EsliceSim
	NVAR cutType
	cutType = popNum
	SetDataFolder root:sim:waves
	Wave cut1, cut2, cut3, cut4, selfEre, selfEim
	SetDataFolder root:sim:SpectralFunction
	Wave spectralFunction
	
	//dataSim#EDMsim
	
	RemoveFromGraph/Z/W=dataSim#cutDisplaySim cut1, cut2
	RemoveFromGraph/Z/W=dataSim#cutDisplayMeas cut3, cut4
	RemoveFromGraph/Z/W=dataSim#cutDisplaySim selfEre, selfEim
	RemoveFromGraph/Z/W=dataSim#cutDisplayMeas selfEre, selfEim
	
	// Self energies
	// STILL ASSUMES CONSTANT SELF ENERGY AS FUNCTION OF K
	if (popNum == 1)
		AppendToGraph/W=dataSim#cutDisplaySim/C=(0, 0, 65535) selfEre
		AppendToGraph/W=dataSim#cutDisplaySim selfEim
		TextBox/W=dataSim#cutDisplaySim/C/N=text1/F=0/S=3/Z=1/A=MT/E=2 "SelfEnergies"
		ModifyGraph/W=dataSim#cutDisplaySim mirror(left)=2,mirror(bottom)=2
//	// Antinodal
//	// There are 4 antinodal cuts, left = cut1, top = cut2 etc. (CW)
//	Elseif (popNum == 2)
//		cutPointsX = dimSize(spectralFunction, 0)
//		cutPointsY = dimSize(spectralFunction, 1)
//		regenerate_show_waves()
//		cut1 = spectralFunction[0][q][EsliceSim]
//		cut2 = spectralFunction[p][0][EsliceSim]
//		cut3 = spectralFunction[cutPointsX][q][EsliceSim]
//		cut4 = spectralFunction[p][cutPointsY][EsliceSim]
//		AppendToGraph/W=dataSim#cutDisplaySim/C=(0, 0, 65535) cut1
//		AppendToGraph/W=dataSim#cutDisplaySim/C=(0, 65535, 0) cut2
//		AppendToGraph/W=dataSim#cutDisplaySim/C=(65535, 0, 65535) cut3
//		AppendToGraph/W=dataSim#cutDisplaySim/C=(0, 65535, 65535) cut4
//		ModifyGraph/W=dataSim#cutDisplaySim lStyle(cut1)=3, lStyle(cut2)=11, lStyle(cut3)=7, lStyle(cut4)=8
//		TextBox/W=dataSim#cutDisplaySim/C/N=text1/F=0/S=3/Z=1/A=MT/E=2 "Antinodal"
//		ModifyGraph/W=dataSim#cutDisplaySim mirror(left)=2,mirror(bottom)=2
//	Elseif (popNum == 3)
//		cutPointsX = max(nkx, nky)
//		cutPointsY = max(nkx, nky)
//		regenerate_show_waves()
//		Variable n, dx, dy
//		for (n=0; n<cutPointsX; n++)
//		// TODO: FIX THIS
//			cut1 = 0//spectralFunction[][][EsliceSim]
//		EndFor
//		AppendToGraph/W=dataSim#cutDisplaySim/C=(0, 0, 65535) cut1
//		AppendToGraph/W=dataSim#cutDisplaySim cut2
//		TextBox/W=dataSim#cutDisplaySim/C/N=text1/F=0/S=3/Z=1/A=MT/E=2 "Nodal"
//		ModifyGraph/W=dataSim#cutDisplaySim mirror(left)=2,mirror(bottom)=2
	// From Cursor
	ElseIf (popNum == 2)
		SetTraceFromCursors()
		// Simulated Data
		AppendToGraph/W=dataSim#cutDisplaySim/C=(64000, 0, 0)/B cut1;DelayUpdate
		AppendToGraph/W=dataSim#cutDisplaySim/C=(0, 64000, 0)/T=cut2 cut2;DelayUpdate
		ModifyGraph/W=dataSim#cutDisplaySim tick=2,axOffset=-1,freePos=0;DelayUpdate
		ModifyGraph/W=dataSim#cutDisplaySim tick(cut2)=2,axOffset(cut2)=-1,freePos(cut2)=0;DelayUpdate
		Label/W=dataSim#cutDisplaySim bottom "k (\\U)";DelayUpdate
		Label/W=dataSim#cutDisplaySim cut2 "k (\\U)";DelayUpdate
		
		ModifyGraph/W=dataSim#cutDisplaySim lStyle(cut1)=0, lStyle(cut2)=4;DelayUpdate
		ModifyGraph/W=dataSim#cutDisplaySim mirror(left)=2;DelayUpdate
		
		TextBox/W=dataSim#cutDisplaySim/C/N=text1/F=0/S=3/Z=1/A=MT/E=2 "FromCursors";DelayUpdate
		Legend/W=dataSim#cutDisplaySim/C/N=text0/J/F=0/S=3/A=LT/E=2/X=15/Y=15 "\\s(cut1) AB\r\\s(cut2) CD";DelayUpdate
		ModifyGraph/W=dataSim#cutDisplaySim mirror(left)=2
		
		// Measured Data
		AppendToGraph/W=dataSim#cutDisplayMeas/C=(64000, 0, 0)/B cut3;DelayUpdate
		AppendToGraph/W=dataSim#cutDisplayMeas/C=(0, 64000, 0)/T=cut4 cut4;DelayUpdate
		ModifyGraph/W=dataSim#cutDisplayMeas tick=2,axOffset=-1,freePos=0;DelayUpdate
		ModifyGraph/W=dataSim#cutDisplayMeas tick(cut4)=2,axOffset(cut4)=-1,freePos(cut4)=0;DelayUpdate
		Label/W=dataSim#cutDisplayMeas bottom "k (\\U)";DelayUpdate
		Label/W=dataSim#cutDisplayMeas cut4 "k (\\U)";DelayUpdate
		
		ModifyGraph/W=dataSim#cutDisplayMeas lStyle(cut3)=0, lStyle(cut4)=4;DelayUpdate
		ModifyGraph/W=dataSim#cutDisplayMeas mirror(left)=2;DelayUpdate
		
		TextBox/W=dataSim#cutDisplayMeas/C/N=text1/F=0/S=3/Z=1/A=MT/E=2 "FromCursors";DelayUpdate
		Legend/W=dataSim#cutDisplayMeas/C/N=text0/J/F=0/S=3/A=LT/E=2/X=15/Y=15 "\\s(cut3) EF\r\\s(cut4) GH";DelayUpdate
		ModifyGraph/W=dataSim#cutDisplayMeas mirror(left)=2
	EndIf
	
	SetDataFolder curDataFolder

End


// Get the fermi level index of the wave
// It is assumed the wave is a 3d spectral function representation of ARPES data
// with the energy scale on the third axis
Function GetFermiLevelIndex(inWave)

	Wave inWave
	Variable ind = ScaleToIndex(inWave, 0, 2)
	
	return ind
End


// Checks if scaling has changed on any of the display waves wrt the data
// and regenerates them (empty waves after regen)
Function regenerate_show_waves()
	
	String curDataFolder = GetDataFolder(1)
	
	// Get global variable references
	SetDataFolder root:sim:vars
	
	// Ranges of three dimensions
	NVAR kxbound, kybound, Emin, Emax
	NVAR kxmin, kxmax, kymin, kymax
	// Amount of points (resolution)
	NVAR nkx, nky, nESim, dkx, dky, den
	// Used for scaling cuts
	NVAR cutPointsX, cutPointsY, cutType
	
	// Get global wave references
	SetDataFolder root:sim:waves
	
	Wave cut1, cut2, cut3, cut4
	if (cutPointsY != dimSize(cut1, 0) || cutPointsY != dimSize(cut3, 0) || cutPointsX != dimSize(cut2, 0) || cutPointsX != dimSize(cut4, 0))
		if (cutType == 2)
			Make/O/N=(cutPointsX) cut1, cut3
			Make/O/N=(cutPointsX) cut2, cut4
			SetScale x, kymin, kymax, "A^-1", cut1, cut3
			SetScale x, kxmin, kxmax, "A^-1", cut2, cut4
		ElseIf (cutType == 3)
			Make/O/N=(cutPointsX) cut1
			Make/O/N=(cutPointsY) cut2
			SetScale x -sqrt(kymin^2 + kxmin^2), sqrt(kymax^2 + kxmax^2), "A^-1", cut1, cut2
		EndIf
	Endif	
	
	// EDM wave
	Wave EDMshow
	if (nkx != dimSize(edmShow, 0) || nky != dimSize(edmShow, 1) || kxmin != dimOffset(edmShow, 0) || kymin != dimOffset(edmShow, 1))
		Make/O/N=(nkx, nky) EDMshow
		SetScale x, kxmin, kxmax, "A^-1", EDMshow
		SetScale y, kymin, kymax, "A^-1", EDMshow
		print "Wave regenerated"
	Endif
	
	// Self energies
	Wave SelfEre, SelfEim
	if (nESim != dimSize(SelfEre, 0) || Emin != dimOffset(SelfEre, 0) || den != dimDelta(SelfEre, 0))
		Make /O/N=(nESim) SelfEre, SelfEim
		SetScale x, Emin, Emax, "eV", SelfEre, SelfEim
		print "Wave regenerated"
	Endif
	
	SetDataFolder curDataFolder
End

// Testing function
Function regen_test_data(ctrlName):buttonControl
	
	String ctrlName

	String curDataFolder = GetDataFolder(1)
	SetDataFolder root:sim
	Wave tempData
	
	tempData = eNoise(x) * x * x
	
	SetDataFolder curDataFolder
End

// Set parameters of the tight-binding band according to
// "Measuring the Gap in ARPES experiments" - A.A. Kordyuk
Function Set_TB_params(ctrlName):buttonControl

	String ctrlName

	String curDataFolder = GetDataFolder(1)
	SetDataFolder root:sim:vars
	NVAR t0, t1, t2, tp, dE
	
	t1 = 0.23 * t0
	t2 = 0.11 * t0
	tp = 0.21 * t0
	dE = 1.08 * t0

	SetDataFolder curDataFolder
End

Function gen_3D_data(ctrlName):buttonControl

	String ctrlName

	String curDataFolder = GetDataFolder(1)
	
	// Get wave reference for correct slice assignment
	SetDataFolder root:sim:waves
	Wave EDMshow
	Wave SelfEre, SelfEim
	SetDataFolder root:sim:SEfiles
	Wave SelfEre_f, SelfEim_f
	
	SetDataFolder root:sim:vars
	// Choices for self-energy and dispersion
	// SE: 1 - SEre = cst, SEim = 0
	// SE: 2 - Debye phonon
	// SE: 3 - Marginal Fermi Liquid
	// SE: 4 - from file
	//
	// Disp: 1 - linear band
	// Disp: 2 - Parabolic band
	// Disp: 3 - tight binding band (BSCO)
	NVAR SEmode, DispMode, cutType
	NVAR rotateSim
	// Ranges of three dimensions
	NVAR kxbound, kybound, Emin, Emax
	NVAR kxmin, kxmax, kymin, kymax
	if (Emin > 0)
		Emin = 0
	EndIf
	// Amount of points (resolution)
	NVAR nkx, nky, nESim, dkx, dky, den
	// Tight Binding Parameters
	NVAR dE, t0, t1, t2, tp
	// Self energy Parameters
	NVAR lambda, phononE, scattering
	// FermiDirac Parameters
	NVAR boltzmann, T
	// Slicing params
	NVAR kxsliceSim, kysliceSim, EsliceSim, EsliceEnergySim
	
	NewDataFolder/S/O root:sim:SpectralFunction
	
	// Self-energy
	Make/O/N=(nkx, nky, nESim) SEre
	SetScale x, kxmin, kxmax, "A^-1", SEre
	SetScale y, kymin, kymax, "A^-1", SEre
	SetScale z, Emin, Emax, "eV", SEre
	Make/O/N=(nkx, nky, nESim) SEim
	SetScale x, kxmin, kxmax, "A^-1", SEim
	SetScale y, kymin, kymax, "A^-1", SEim
	SetScale z, Emin, Emax, "eV", SEim
	
	if (SEmode==1)
		SEre = 0
		SEim = 0.001
	Elseif (SEmode==2)
		Make/FREE/O/N=(nkx, nky, nESim) f1, f2, f3
		SetScale x, kxmin, kxmax, "A^-1", f1, f2, f3
		SetScale y, kymin, kymax,"A^-1", f1, f2, f3
		SetScale z, Emin, Emax, "eV", f1, f2, f3
		f1 = (z) / (phononE)
		f2 = f1^3 * ln( abs(1 - ( 1 / f1 )^2 ) )
		f3 = ln( abs( (1 + f1) / (1 - f1) ) )
		SEre = -lambda * ((phononE) / 3) * (f1 + f2 + f3)
		SEim = ( (lambda * pi)/3 ) * ( (z >= phononE) * z^3 / (phononE)^2 + (z < phononE) * phononE ) + scattering 
	Elseif (SEmode==3)
		// Lambda plays the role here of g^2 * N(0)^2 and the phonon Energy is interpreted as w_c
		// See article for exact expressions: Phenomenology of the Normal State of Cu-0 High-Temperature Superconductors
		
		SEre = -lambda * (z) * ln(max(abs(z), boltzmann*T)/phononE)
		SEim =  lambda * (pi/2) * max(abs(z), boltzmann*T)
	Elseif (SEmode==4)
		// Check num dimensions of input wave (must be 1d or 3d), assumed both are the same, also scaling
		// Should be in form (kx, ky, E)
		NewDataFolder/O/S SEloadTemp
		Variable SEdims
		Duplicate/O SelfEre_f re
		Duplicate/O SelfEim_f im
		WaveStats/Q/P/RMD=[0, *][0, *][0, *][0, *] re
		SEdims = (V_startRow == 0 ? 1 : 0) + (V_startCol == 0 ? 1 : 0) + (V_startLayer == 0 ? 1 : 0)
	
		if (SEdims == 1)
			nESim = dimSize(SelfEre_f, 0)
			Emin = dimOffset(SelfEre_f, 0)
			den = dimDelta(SelfEre_f, 0)
			Emax = Emin + nESim * den
			Redimension/N=(nkx, nky, nESim) SEre
			SetScale/P z, Emin, den, SEre 
			Redimension/N=(nkx, nky, nESim) SEim
			SetScale/P z, Emin, den, SEim
			Variable n
			for(n=0; n<nESim; n++)
				SEre[][][n] = SelfEre_f[r]
				SEim[][][n] = SelfEim_f[r]
			EndFor
		ElseIf (SEdims == 3)
			nESim = dimSize(SelfEre_f, 2)
			Emin = dimOffset(SelfEre_f, 2)
			den = dimDelta(SelfEre_f, 2)
			Emax = Emin + nESim * den
			
			nkx = dimSize(selfEre_f, 0)
			kxmin = dimOffset(selfEre_f, 0)
			dkx = dimDelta(selfEre_f, 0)
			kxmax = kxmin + nkx * dkx
			
			nky = dimSize(selfEre_f, 1)
			kymin = dimOffset(selfEre_f, 1)
			dky = dimDelta(selfEre_f, 1)
			kymax = kymin + nky * dky

			Duplicate/O selfEre_f SEre
			Duplicate/O selfEim_f SEim
		EndIf
		
		SetDataFolder root:sim:SpectralFunction
	EndIf
	
	// Dispersion
	Make/O/N=(nkx, nky, nESim) dispersion
	SetScale x, kxmin, kxmax, "A^-1", dispersion
	SetScale y, kymin, kymax, "A^-1", dispersion
	SetScale z, Emin, Emax, "eV", dispersion
	dkx = dimDelta(dispersion, 0)
	dky = dimDelta(dispersion, 1)
	den = dimDelta(dispersion, 2)
	if (DispMode==1)
		dispersion = t0 * (abs(x) + abs(y))
	Elseif (DispMode==2)
		dispersion = t0 * (x^2 + y^2) 
	Elseif (DispMode==3)
	
		if (rotateSim == 1)
			dispersion = dE - 2 * t0 * ( Cos(2*(sqrt(2)*(x-y))/pi) + Cos(2*(sqrt(2)*(x+y))/pi) ) + 4 * t1 * ( Cos(2*(sqrt(2)*(x-y))/pi) * Cos(2*(sqrt(2)*(x+y))/pi) ) - 2 * t2 * ( Cos(4*(sqrt(2)*(x-y))/pi) + Cos(4*(sqrt(2)*(x+y))/pi) ) - tp * (Cos(2*(sqrt(2)*(x-y))/pi) - Cos(2*(sqrt(2)*(x+y))/pi)) / 4
		Else			
			dispersion = dE - 2 * t0 * ( Cos(2*x/pi) + Cos(2*y/pi) ) + 4 * t1 * ( Cos(2*x/pi) * Cos(2*y/pi) ) - 2 * t2 * ( Cos(4*x/pi) + Cos(4*y/pi) ) - tp * (Cos(2*x/pi) - Cos(2*y/pi)) / 4
		EndIf
		
		//dispersion = dE - 2 * t0 * ( Cos(2*x/kxbound) + Cos(2*y/kybound) ) + 4 * t1 * ( Cos(2*x/kxbound) * Cos(2*y/kybound) ) - 2 * t2 * ( Cos(4*x/kxbound) + Cos(4*y/kybound) ) - tp * (Cos(2*x/kxbound) - Cos(2*y/kybound) ) / 4
	   //dispersion = dE - 2 * t0 * ( Cos(2*x) + Cos(2*y) ) + 4 * t1 * ( Cos(2*x) * Cos(2*y) ) - 2 * t2 * ( Cos(4*x) + Cos(4*y) ) + tp * (Cos(2*x) - Cos(2*y) ) / 4
	EndIf

	Make/O/N=(nkx, nky, nESim) spectralFunction
	SetScale x, kxmin, kxmax, "A^-1", spectralFunction
	SetScale y, kymin, kymax, "A^-1", spectralFunction
	SetScale z, Emin, Emax, "eV", spectralFunction
	
	Make/O/N=(nESim) fdWave
	SetScale x, Emin, Emax, "eV", fdWave
	fdWave = 1 / (exp((x)/(boltzmann * T)) + 1)
	
	spectralFunction = (fdWave[r]/pi) * (SEim[p][q][r])/( (z - dispersion[p][q] - SEre[p][q][r])^2 + (SEim[p][q][r])^2 )
	
	Regenerate_show_waves()
	if (stringmatch(ctrlname, "init") == 0)
		change_draw_mode("from_gen_data")
	EndIf
	SelfEre = SEre[0][0][p]
	SelfEim = SEim[0][0][p]
	// Return to previous Data Folder
	SetDataFolder curDataFolder
End
