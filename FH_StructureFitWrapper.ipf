#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Proper structure fit implementation for fitting a 
// Gaussian broadened FD distribution
//
// Florian Heringa 29/01/2021

//==================================================================================
// Structure to use in fitting. Order of waves is Igor defined for the first three fields,
// so the first entry is ALWAYS the model parameters and so on for xw and yw.
// strct.cst is a freely useable parameter wave for passing constants to the fitting function.

Structure fitStruct
	Wave pw  // model parameters
	Wave yw  // data to fit
	Wave xw  // x scale of data
	Wave cst // model constants
EndStructure

//==================================================================================
// Most general implementation of a structure fit function wrapper.
// This takes in all data as parameters (except the xwave, which can be generated 
// automatically for simple, linear xscale data).
//
// The above fit struct accounts for almost all possible 1D fitting implementations,
// provided the user has defined a correct fitting function (see below).

Function/WAVE StructureFitWrapper(pw, yw, cst, fitFunc, [xw, displayFit])

	// Input variables
	Wave pw, yw, xw, cst
	FUNCREF protoStructFitFunc fitFunc
	Variable displayFit
	
	// If no xwave is given, just use the scale from the original data
	if (paramisDefault(xw))
		Duplicate/O yw, xw
		xw = x
	EndIf
	
	DFREF fldr = getDataFolderDFR()
	
	// Declare fit structure
	STRUCT fitStruct str
	Duplicate/O cst, str.cst
	
	// Create special folder for fitting
	NewDataFolder/O/S root:StructureFit
	
	// Do Fit
	FuncFit/W=2/Q/N fitFunc, pw, yw /x=xw /STRC=str
	
	// Generate fitted data for displaying
	Wave fitted = genFit(pw, yw, xw, cst, fitFunc)
	
	if (!paramIsDefault(displayFit))
		Display yw
		AppendToGraph fitted
	EndIf
	
	SetDataFolder fldr
	
	return fitted
End

// Generate a wave containing the fitted function.
Function/WAVE genFit(pw, yw, xw, cst, fitFunc)

	Wave pw, yw, xw, cst
	FUNCREF protoStructFitFunc fitFunc
	
	// Declare fit structure
	STRUCT fitStruct str
	Duplicate/O pw, str.pw
	Duplicate/O yw, str.yw
	Duplicate/O xw, str.xw
	Duplicate/O cst, str.cst
	
	fitFunc(str)
	
	Duplicate/O str.yw, fitted
	
	return fitted
End

//===================================================
// Example of a fit function
//

Function SimpleQuadratic(strct) : FitFunc

	STRUCT fitStruct &strct
	// params = {coeff x^2, coeff x^1, coeff x^0}
	// constants = {}
	
	strct.yw = strct.pw[0] * strct.xw[p]^2 + strct.pw[1] * strct.xw[p] + strct.pw[2]

End

//==========================================================
// Function prototype for using the above structure fit implementation
//
// To create fit function take the function signature below and add your own code.
// The final fit function should be returned in strct.yw as:
//
// strct.yw = f(strct.xw, strct.pw, strct.cst)
//
// You can do anything before that in this function like convolutions or other multi-step
// complex operations. As long as the final wave to use as a fit is put in strct.yw in the end.
// I'd recommend using /FREE waves for intermediate steps, or expanding the structure to hold
// additional waves used in the fitting process.

Function protoStructFitFunc(strct) : FitFunc

	STRUCT fitStruct &strct
	
	//do stuff here
End