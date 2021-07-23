#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


// To use this function make sure that all data is inside separate folders inside the "root:RawData" folder
Function set_scale_for_all(laser_Ef, He_Ef)

	Variable laser_Ef, He_Ef
	
	newDataFolder/O root:ProcessedData
	setDatafolder root:RawData
	
	// Count all datafolders in "root:RawData"
	Variable numFolders = CountObjectsDFR(root:RawData, 4)
	Variable n
	
	For (n=0; n<numFolders; n+=1)
		String dfName = GetIndexedObjNameDFR(root:RawData, 4, n)
		DFREF currentFolder = $(dfName)
		Variable numWaves = CountObjectsDFR(currentFolder, 1)
		Variable m
		
		For (m=0; m<numWaves; m+=1)
			String wName = GetIndexedObjNameDFR(currentFolder, 1, m)
			Wave w = $(GetDataFolder(-1, currentFolder) + wName)
			Variable scaleStart = dimOffset(w, 1)
			
//			String newDfName = replacestring(")", replacestring("(", dfName, "_"), "_")
			String newDFName = "root:ProcessedData:'" + dfName + "'"
			NewDataFolder/O $(newDFName)
			
			Duplicate/O w, $(newDFName + ":" + NameOfWave(w))
			Wave toScale = $(newDFName + ":" + NameOfWave(w))
			
			// In this case we have He lamp data
			Variable maxRangeX
			If (scaleStart > 10)
				SetScale/P y, DimOffset(w, 1) - He_Ef, DimDelta(w, 1), "eV", toScale
				maxRangeX = DimOffset(w, 0) + DimDelta(w, 0) * DimSize(w, 0)
				SetScale/I x, angleToK(dimOffset(w, 0), He_Ef), angleToK(maxRangeX, He_Ef), "A^-1", toScale
			Else
			 	SetScale/P y, DimOffset(w, 1) - laser_Ef, DimDelta(w, 1), "eV", toScale
				maxRangeX = DimOffset(w, 0) + DimDelta(w, 0) * DimSize(w, 0)
				SetScale/I x, angleToK(dimOffset(w, 0), laser_Ef), angleToK(maxRangeX, laser_Ef), "A^-1", toScale 
			EndIf
		EndFor
	EndFor	
	
	SetDataFolder root:
End