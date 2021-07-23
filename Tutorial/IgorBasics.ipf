#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Igor Basics introduction.
// Florian Heringa
// 02-04-2020

// All code in this file is supposed to be run as an instructional example. All results will be stored in "root:example".
// Make sure you understand all of the code in this file. To run type "Run_Basics()" into the command window.

// N.B.: This is NOT fully correct data analysis or preparation, but the techniques used here do give a good indication of what is necessary.

	
	// First of all you will want to set up the folder structure so your procedures are available.
	// I Would recommend taking a single folder (which is easily accessbile) and storing all procedures you
	// make and download in there.
	
	// To set his up correctly follow the following steps:
	//	1. Locate the Igor Pro user files folder, it will most likely be in
	//		~\Documents\WaveMetrics\Igor Pro 8 User Files
	//	2. Place a shortcut here to your custom procedures folder inside the "User Procedures" folder.
	//		This way Igor can find the procedures you make and you are not bound by the default file locations.
	// 3. Place the supplied "Call_macros.ipf" file in the "Igor Procedures" folder and the "HDF5-64.xop" file in the "Igor Extensions (64-bit)" folder
	//		(This may be different if you installed the 32 bit version, in which case, let me know)
	//	4. Check if this file compiles after you did this. (to compile look at the bottom of this window)
	// 5. There are some files added (see the supplied ipf files), put these in your custom igor procedures fodler.
	//    You can check these macros out already if you want, but don't take too much time on them.
	//	   We will go over them after this introduction
	
	// If anything is unclear let me know.
	
	
// Good Luck!

Function Run_Basics()

	NewDataFolder/O root:example
	//or use
	NewDataFolder/O/S $("root:example")
	// The /O flag makes sure no errors are given when the folder already exists.
	// The /S flag automatically changes the current datafolder to the new datafolder. This is important to realise:
	// EVERYTHING YOU EXECUTE IS DONE IN THE CURRENT DATAFOLDER.
	
	// To make a new wave use
	Make/N=100/O w
	// This wave is named "w" and has 100 points. The /O flag will overwrite an already existing wave named "w"
	
	// Next we fill the wave with half a parabola
	w = x^2
	// in Igor we can use advanced wave assignment syntax as shown above.
	// The symbols "x, y, z, t" refer to scaled wave values while "p, q, r, s" refer to indexed wave values.
	// Definitely take a look at the "Waveform Arithmetic and Assignment" help article.
	
	// Take a look at the wave "w". This does look like half a parabola, but only integer values are used on the x-axis.
	// This is the default behaviour when creating a new wave. To create a scaled wave use the following commands:
	Make/N=100/O w2
	SetScale/I x, -5, 5, "x", w2
	// To make parabola use the same syntax as before, but look at the results with the new scaling
	w2 = x^2
	// Absolutely take a look at the help page of "SetScale" (right click -> "" Help for SetScale") as this is one of the more prevalent functions you will use.
	

	//=============================================================================================
	
	// To start off, a few simple exercises that will get you aqcuainted with Igor
	
	// A bit of information about the supplied dataset:
	// The data is exactly as it came out of the DIAMOND ARPES measurements. So the scales are not correct.
	// As you know the Fermi level should be around where the band stops, which we define to be 0.
	// ----- Make a guess of what the Fermi Energy is for the supplied measurements, is it consistent?
	
	// Also the horizontal scale is still in angles as this is what the machine measures. 
	// To convert this into a momentum scale we will need some additional information like the Photon energy.
	// Then use the formula 0.5123 * sqrt(Ep) * cos(theta) to get the correct k-scale.
	// For this to work the 0 angle position should be exactly at the middle of the band.
	// ----- Can you think of why this is?
	
	// You can write new procedure files for everything you want to do, but it is more useful to
	// make a single .ipf file per subject and then just call the functions in the command window.
	// Also, if you want to use your functions in other procedures, make sure you add them to the "Call_macros.ipf" file.
	
	
	
	// Ef = 17.6245
	
	// DO EXERCISE 1-4 BELOW FOR A SINGLE SPECTRUM ONLY
	
	
	
	
	
	//========= 1. Write a procedure that puts the Fermi Energy at the correct position (Ef=0).
	// You will need to change the scale on a 2D wave y axis.
	// First "Duplicate" one of the waves into a new folder so you don't accidentally overwrite the raw data.
	// Do this by either selecting the wave in the Data Browser and pressing "ctrl+D" or by using the "Duplicate" function as follows:
	
	NewDataFolder/O root:Analysis
	NewDataFolder/O/S root:Analysis:F6ANm12
	Duplicate/O root:RawData:F6ANm12:F6ANm12_50K, root:Analysis:F6ANm12:F6ANm12_50K
	
	//To get a wave reference in a script you can use the full path:
	Wave toAnalyse = root:Analysis:F6ANm12:F6ANm12_50K
	Duplicate/O toAnalyse, justToShowThatItWorks
	// Or you can use a direct reference to the name if you are in the correct datafolder already
	Wave toAnalyse2 = F6ANm12_50K
	Duplicate/O toAnalyse, ThisAlsoWorks
	// If you are not in the correct datafolder use the following command
	SetDataFolder root:Analysis:F6ANm12
	
	
	
	//======== 2. Get MDCs (momentum distribution curves, horizontal traces in the supplied dataset) at Ef for the test spectrum of the previous exercise.
	
	// To do this make a new wave with the correct length, you might use "DimSize(w)" here.
	// Set the newly created wave to the correct scaling. Extract the MDC at Ef, you might want to use "ScaleToIndex()" here.
	
	// Use the MDC to determine the amount the spectrum should be shifted to be centered.
	
		
		
	//======== 3. Change the angle scale to k-scale as described above.
	// You will need to shift the horizontal scale and rescale it.
	
	// It can be useful here to use an auxiliary function (defined below)
	// Try to figure out how to make use of them here. If you add this file to "call_macros.ipf" you will be able to use the 
	// functions defined below in all other procedure files you create.
	
	
	
	//======== 4. Determine an approximate location for kF (the Fermi wavevector, where the band crosses the Fermi level).
	//            Extract EDCs (Energy Distribution Curves) at kF for both branches of the dispersion.
	
	
	
	//======== 5. Write a procedure that does all of this automatically for the entire dataset.
	//				 This sounds daunting, but it's basically just combining the previous exercises together.
	//				 Try to separate everything into functions. Have afunction for setting Ef- and k-scales
	//				 If you want you can try to determine the amount of shift automatically, but it is probably much easier
	//				 to do this manually and just hardcoding the numbers in your program.
	//				 For finding the numbers you can use the "AlternateLineProfile" procedure that is supplied. Just put the file in the correct folder
	//				 and add it to "Call_macros". Then you can access it by opening an image (double click on the image of the spectrum in the Data Browser)
	//				 and go to "Image -> Alternate Line Profile" in the top menu bar. While the Alternate Line Profile tool is open press "ctrl+I" and place
	//				 the cursors on the image to determine the location of the peaks.
	
	// You can use the following functions to loop over datafolder contents
	String folder = "root:RawData:F6AN"
	Variable numberOfWaves = CountObjects(folder, 1)
	Variable n
	for (n = 0; n<numberOfWaves;n++)
		Wave tmp = $(folder + ":" + GetIndexedObjName(folder, 1, n))
		print nameOfWave(tmp)
	EndFor
End

Function degrees_to_rad(angle)
	
	Variable angle
	
	return angle * (pi / 180)
	
End

Function angle_to_k(angle, Ep)
	
	// You must always declare all input variables
	Variable angle, Ep
	
	// Trig functions all work in rad
	return 0.5123 * sqrt(Ep) * sin(degrees_to_rad(angle))
End