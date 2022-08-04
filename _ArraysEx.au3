; #INDEX# =======================================================================================================================
; Title ..........: _ArraysEx
; AutoIt Version .: 3.3.10 +
; Language .......: English
; Description ....: Custom array functions to simplify some common usages.
; Author .........: Sam Coates (inpho)
; ===============================================================================================================================

#AutoIt3Wrapper_Au3Check_Parameters=-d -w- 1 -w 2 -w 3 -w 4 -w 5 -w 6

; #INCLUDES# ====================================================================================================================
#include-once
#include <Array.au3>
#include <_StringsEx.au3>

; #CURRENT# =====================================================================================================================
; _ArraysEx_ArraysConcat:					Concatenates arrays of multiple dimensions
; _ArraysEx_ArrayFindEmptyRows:				Returns an array of indexes corresponding to empty rows in an array
; _ArraysEx_ArrayFindAllCols:				Searches an array in all columns (_ArrayFindAll only searches one column)
; _ArraysEx_ArrayGen:						Generates an array populated with random values
; _ArraysEx_Array1DToND:					Converts a 1D array to ND with column count dependant on delimiters
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name ...........: _ArraysEx_ArraysConcat
; Description ....: Concatenates a 1D array of arrays into a single array. Sub-arrays can be 1D, ND or a mix of both.
; Syntax .........: _ArraysEx_ArraysConcat($aArray[, $iStartRow = 1])
; Parameters .....: $aArray             - An array of arrays.
;                   $iStartRow          - [optional] Integer. The row to start from. Default is 1.
; Return values ..: Success:			- A 1D/ND array of values.
;					Failure:			- 0 and @error flag as follows:
;										1 - $aArray is not an array
;										2 - $aArray is a 2D array
; Remarks.........: $aArray must be zero-based. All sub-arrays can be either 1-based or zero-based; use $iStartRow to define the
;					row of sub-arrays to start extracting from.
; Author .........: Sam Coates (inpho)
; ===============================================================================================================================
Func _ArraysEx_ArraysConcat($aArray, $iStartRow = 1)

	;; if source array is not an array
	If IsArray($aArray) = 0 Then Return (SetError(1, 0, 0))
	;; if source array is not 1D
	If UBound($aArray, 2) <> 0 Then Return (SetError(2, 0, 0))

	Local $i, $ii = $iStartRow, $iii = 0, $iTotalRows = 0, $iArrayReturnColumns = 1
	Local $aArraySource, $aArrayReturn

	;; loop through the main array counting the rows. If any sub-array is 2D, then the return array is 2D
	For $i = 0 To UBound($aArray) - 1
		$iTotalRows += UBound($aArray[$i]) - $iStartRow
		If UBound($aArray[$i], 2) > 0 Then $iArrayReturnColumns = 2
	Next

	; create the array of the new size
	If $iArrayReturnColumns = 1 Then
		Local $aArrayReturn[$iTotalRows + 1]
	Else
		Local $aArrayReturn[$iTotalRows + 1][2]
	EndIf

	;; source array is first array
	$aArraySource = $aArray[0]

	For $i = 1 To UBound($aArrayReturn) - 1
		If $ii > UBound($aArray[$iii]) - 1 Then     ;; if current element is bigger than the size of current source array
			$iii += 1     ;; increment sub-array counter
			$aArraySource = $aArray[$iii]     ;; switch to next array
			$ii = $iStartRow     ;; and start from the beginning of it
		EndIf

		;; if return array is 1D, then it's quick and easy
		If $iArrayReturnColumns = 1 Then
			$aArrayReturn[$i] = $aArraySource[$ii]     ;; assign the elements
		Else
			;; if return array is 2D but the source array is 1D
			If UBound($aArraySource, 2) = 0 Then
				$aArrayReturn[$i][0] = $aArraySource[$ii]     ;; assign the elements
			Else
				;; if return array is 2D and source array is 2D
				For $j = 0 To UBound($aArrayReturn, 2) - 1
					$aArrayReturn[$i][$j] = $aArraySource[$ii][$j]     ;; assign the elements in a loop
				Next
			EndIf
		EndIf

		$ii += 1     ;; add 1 to current element

	Next

	;; add count in [0] or [0][0] depending on return array type
	If $iArrayReturnColumns = 1 Then
		$aArrayReturn[0] = UBound($aArrayReturn) - 1
	Else
		$aArrayReturn[0][0] = UBound($aArrayReturn) - 1
	EndIf

	Return ($aArrayReturn) ;; return the array

EndFunc   ;==>_ArraysEx_ArraysConcat

; #FUNCTION# ====================================================================================================================
; Name ...........:	_ArraysEx_ArrayFindEmptyRows
; Description ....:	Searches for empty rows in ND arrays. Returns an array of indexes (similar to _ArrayFindAll) ready to feed
;					straight into _ArrayDelete.
; Syntax .........:	_ArraysEx_ArrayFindEmptyRows(Const Byref $aArray[, $iStartRow = 0[, $iEndRow = 0]])
; Parameters .....:	$aArray             - Array. The array to search for empty rows.
;                 	$iStartRow          - [optional] Integer. The index to start searching from.
;				  	$iEndRow			- [optional] Integer. The index to stop searching at.
; Return values ..:	Success:			- An array of indexes.
;				  	Failure				- Empty string and @error flag as follows:
;										1 - $aArray is not an array
;										2 - $aArray contains one row
;										3 - $iStartRow is out of bounds
;										4 - No results (unable to find any blank rows)
; Author .........:	Sam Coates (inpho)
; ===============================================================================================================================
Func _ArraysEx_ArrayFindEmptyRows(ByRef Const $aArray, $iStartRow = 0, $iEndRow = 0)

	If Not IsArray($aArray) Then Return (SetError(-1, 0, "")) ;; Array isn't an array
	If UBound($aArray) < 2 Then Return (SetError(-2, 0, "")) ;; Array only contains one row

	Local $i, $ii
	Local $sResults = ""
	Local $aReturn
	Local $iArrayRows

	If $iEndRow <> 0 Then
		$iArrayRows = $iEndRow ;; hold the number of rows
	Else
		$iArrayRows = UBound($aArray) - 1 ;; hold the number of rows
	EndIf

	If $iStartRow > $iArrayRows Then Return (SetError(-3, 0, "")) ;; Check if StartRow isn't out of bounds

	Local $iArrayColumns = UBound($aArray, 2) ;; hold the number of columns
	If @error = 2 Then $iArrayColumns = 1 ;; if error, then 1d array

	If $iArrayColumns = 1 Then ;; if 1d array

		For $i = $iStartRow To $iArrayRows ;; loop through rows
			If $aArray[$i] = "" Then $sResults &= $i & ";" ;; if its blank, save the index
		Next

	ElseIf $iArrayColumns > 1 Then ;; if 2d array

		For $i = $iStartRow To $iArrayRows ;; loop through rows
			For $ii = 0 To $iArrayColumns - 1 ;; loop through columns
				If $aArray[$i][$ii] <> "" Then ExitLoop ;; if a non-blank is found in any cell on a row, skip to next row
				If $ii = $iArrayColumns - 1 Then $sResults &= $i & ";" ;; if we reach the end of the columns and still havent found a non-blank, save the index
			Next
		Next

	EndIf

	If $sResults <> "" Then ;; if we made changes
		$sResults = StringTrimRight($sResults, 1) ;; strip the final semi-colon
	Else ;; if we made no changes
		Return (SetError(-4, 0, "")) ;; No results
	EndIf

	$aReturn = StringSplit($sResults, ";") ;; split the final string

	Return ($aReturn) ;; return it

EndFunc   ;==>_ArraysEx_ArrayFindEmptyRows

; #FUNCTION# ====================================================================================================================
; Name ...........: _ArraysEx_ArrayFindAllCols
; Description ....: Returns an array of indexes (similar to _ArrayFindAll) but searches all rows and columns.
; Syntax .........: _ArraysEx_ArrayFindAllCols(Const Byref $aArray, $vValue[, $iStart = 0[, $iEnd = 0[, $iCase = 0[, $iCompare = 0]]]])
; Parameters .....: $aArray             - Array. The array to search
;					$vValue				- Value. What to search the array for
;					$iStart				- [optional] Integer. What row to start searching from
;					$iEnd				- [optional] Integer. What row to stop searching at
;					$iCase				- [optional] Integer. If set to 1, search is case sensitive
;					$iCompare			- [optional] Integer. Comparison type as per _ArrayFindAll() and _ArraySearch()
; Return values ..:	Success:			- An array of indexes
;				  	Failure				- Sets the @error flag to non-zero (see _ArraySearch() description for @error)
; Remarks.........:	The values of $iCompare cannot be combined together
; Author .........:	Sam Coates (inpho)
; ===============================================================================================================================
Func _ArraysEx_ArrayFindAllCols($aArray, $vValue, $iStart = 0, $iEnd = 0, $iCase = 0, $iCompare = 0)

	Local $i, $iCols = UBound($aArray, 2)
	Local $aSearch, $aArrayReturn[1] = ["DEL"]

	For $i = 0 To $iCols - 1
		$aSearch = _ArrayFindAll($aArray, $vValue, $iStart, $iEnd, $iCase, $iCompare, $i)
		If @error Then
			ContinueLoop
		Else
			_ArrayConcatenate($aArrayReturn, $aSearch)
		EndIf
	Next

	If UBound($aArrayReturn) = 1 Then Return (SetError(-1, 0, 0))
	_ArrayDelete($aArrayReturn, 0)
	$aArrayReturn = _ArrayUnique($aArrayReturn, 0, 0, 0, 0)

	Return ($aArrayReturn)

EndFunc   ;==>_ArraysEx_ArrayFindAllCols

; #FUNCTION# ====================================================================================================================
; Name ...........: _ArraysEx_ArrayGen
; Description ....: Generates an array populated with random characters.
; Syntax .........: _ArraysEx_ArrayGen([$iLength = 10[, $iType = 1[, $iRows = 50[, $iCols = 1]]]])
; Parameters .....: $iLength			- [optional] Integer. Length of each random string. Default is 10.
;					$iType				- [optional] Integer. Refer to _StringRandom. Default is 1.
;					$iRows				- [optional] Integer. The amount of rows in the returned array. Default is 50.
;					$iCols				- [optional] Integer. The amount of rows in the returned array. Default is 1.
; Return values ..: Success:			- An array of strings.
;					Failure:			- None
; Author .........:	Sam Coates (inpho)
; ===============================================================================================================================
Func _ArraysEx_ArrayGen($iLength = 10, $iType = 1, $iRows = 50, $iCols = 1)

	If $iCols > 1 Then

		Local $aArray[$iRows][$iCols]

		For $i = 0 To $iRows - 1
			For $ii = 0 To $iCols - 1
				$aArray[$i][$ii] = _StringsEx_StringRandom($iLength, $iType)
			Next
		Next

	Else

		Local $aArray[$iRows]
		For $i = 0 To $iRows - 1
			$aArray[$i] = _StringsEx_StringRandom($iLength, $iType)
		Next

	EndIf

	Return ($aArray)

EndFunc   ;==>_ArraysEx_ArrayGen

; #FUNCTION# ====================================================================================================================
; Name ...........: _ArraysEx_Array1DToND
; Description ....: Converts a 1D array to a 2D array. Number of columns is dependent on delimiters in the original array.
; Syntax .........: _ArraysEx_Array1DToND(Byref $aArray[, $iColumns = Default[, $sDelimiter = "|"]])
; Parameters .....: $aArray				- Array. The array you want to convert to 2D.
;					$iColumns			- [optional] Integer. Default automatically determines the amount of columns needed.
;					$sDelimiter			- [optional] String. The delimiter used for splitting the strings.
; Return values ..: Success:			- A 2D array
;					Failure:			- None.
; Author .........:	Sam Coates (inpho)
; ===============================================================================================================================
Func _ArraysEx_Array1DToND(ByRef $aArray, $iColumns = Default, $sDelimiter = "|")

	Local $iSize = UBound($aArray), $iTotal = 1
	Local $aArrayStringSplit[$iSize]

	If $iColumns = Default Then
		$iColumns = 1
		For $i = 1 To UBound($aArray) - 1
			$aArrayStringSplit[$i] = StringSplit($aArray[$i], $sDelimiter, 1)
			If Not @error Then
				If $iColumns < ($aArrayStringSplit[$i])[0] Then $iColumns = ($aArrayStringSplit[$i])[0]
			EndIf
		Next
	EndIf

	Local $aArray2D[$iSize][$iColumns]

	For $ii = 0 To $iColumns - 1
		For $i = 1 To UBound($aArray) - 1
			$aArray2D[$iTotal][$ii] = ($aArrayStringSplit[$i])[$ii + 1]
			$iTotal += 1
		Next
		$iTotal = 1
	Next

	$aArray2D[0][0] = UBound($aArray2D) - 1

	Return ($aArray2D)

EndFunc   ;==>_ArraysEx_Array1DToND
