#include <NamedPipes.au3>
#include <WinAPI.au3>
#include <WindowsConstants.au3>
#include <GuiConstantsEx.au3>

; ===============================================================================================================================
; Description ...: This is the server side of the pipe demo
; Author ........: Paul Campbell (PaulIA)
; Notes .........:
; ===============================================================================================================================

; ===============================================================================================================================
; Global constants
; ===============================================================================================================================

Global Const $DEBUGGING = True
Global Const $BUFSIZE = 9
Global Const $PIPE_NAME = "\\.\pipe\Pipe"
Global Const $TIMEOUT = 5000
Global Const $WAIT_TIMEOUT = 258
Global Const $ERROR_IO_PENDING = 997
Global Const $ERROR_PIPE_CONNECTED = 535

; ===============================================================================================================================
; Global variables
; ===============================================================================================================================

Global $hEvent, $iMemo, $pOverlap, $tOverlap, $hPipe, $hReadPipe, $iState, $iToWrite

; ===============================================================================================================================
; Main
; ===============================================================================================================================

InitPipe()
MsgLoop()


; ===============================================================================================================================
; This function creates an instance of a named pipe
; ===============================================================================================================================
Func InitPipe()
	; Create an event object for the instance
	$tOverlap = DllStructCreate($tagOVERLAPPED)
	$pOverlap = DllStructGetPtr($tOverlap)
	$hEvent = _WinAPI_CreateEvent()
	If $hEvent = 0 Then
		LogError("InitPipe ..........: API_CreateEvent failed")
		Return
	EndIf
	DllStructSetData($tOverlap, "hEvent", $hEvent)

	; Create a named pipe
	$hPipe = _NamedPipes_CreateNamedPipe($PIPE_NAME, _ ; Pipe name
			2, _ ; The pipe is bi-directional
			2, _ ; Overlapped mode is enabled
			0, _ ; No security ACL flags
			1, _ ; Data is written to the pipe as a stream of messages
			1, _ ; Data is read from the pipe as a stream of messages
			0, _ ; Blocking mode is enabled
			1, _ ; Maximum number of instances
			$BUFSIZE, _ ; Output buffer size
			$BUFSIZE, _ ; Input buffer size
			$TIMEOUT, _ ; Client time out
			0) ; Default security attributes
	If $hPipe = -1 Then
		LogError("InitPipe ..........: _NamedPipes_CreateNamedPipe failed")
	Else
		; Connect pipe instance to client
		ConnectClient()
	EndIf
EndFunc   ;==>InitPipe

; ===============================================================================================================================
; This function loops waiting for a connection event or the GUI to close
; ===============================================================================================================================
Func MsgLoop()
	Local $iEvent

	Do
		$iEvent = _WinAPI_WaitForSingleObject($hEvent, 0)
		If $iEvent < 0 Then
			LogError("MsgLoop ...........: _WinAPI_WaitForSingleObject failed")
			Exit
		EndIf
		If $iEvent = $WAIT_TIMEOUT Then ContinueLoop
		Debug("MsgLoop ...........: Instance signaled")

		Switch $iState
			Case 0
				CheckConnect()
			Case 1
				ReadRequest()
			Case 2
				CheckPending()
			Case 3
;~ 				RelayOutput()
		EndSwitch
	Until GUIGetMsg() = $GUI_EVENT_CLOSE
EndFunc   ;==>MsgLoop

; ===============================================================================================================================
; Checks to see if the pending client connection has finished
; ===============================================================================================================================
Func CheckConnect()
	Local $iBytes

	; Was the operation successful?
	If Not _WinAPI_GetOverlappedResult($hPipe, $pOverlap, $iBytes, False) Then
		LogError("CheckConnect ......: Connection failed")
		ReconnectClient()
	Else
		LogMsg("CheckConnect ......: Connected")
		$iState = 1
	EndIf
EndFunc   ;==>CheckConnect

; ===============================================================================================================================
; This function reads a request message from the client
; ===============================================================================================================================
Func ReadRequest()
	Local $pBuffer, $tBuffer, $iRead, $bSuccess

	$tBuffer = DllStructCreate("char Text[" & $BUFSIZE & "]")
	$pBuffer = DllStructGetPtr($tBuffer)
	$bSuccess = _WinAPI_ReadFile($hPipe, $pBuffer, $BUFSIZE, $iRead, $pOverlap)

	If $bSuccess And ($iRead <> 0) Then
		; The read operation completed successfully
		Debug("ReadRequest .......: Read success")
	Else
		; Wait for read Buffer to complete
		If Not _WinAPI_GetOverlappedResult($hPipe, $pOverlap, $iRead, True) Then
			LogError("ReadRequest .......: _WinAPI_GetOverlappedResult failed")
			ReconnectClient()
			Return
		Else
			; Read the command from the pipe
			$bSuccess = _WinAPI_ReadFile($hPipe, $pBuffer, $BUFSIZE, $iRead, $pOverlap)
			If Not $bSuccess Or ($iRead = 0) Then
				LogError("ReadRequest .......: _WinAPI_ReadFile failed")
				ReconnectClient()
				Return
			EndIf
		EndIf
	EndIf

	; Execute the console command
		ToolTip(DllStructGetData($tBuffer, "Text") & @CRLF)
		ReconnectClient()
		Return

	; Relay console output back to the client
	$iState = 1
EndFunc   ;==>ReadRequest

; ===============================================================================================================================
; This function relays the console output back to the client
; ===============================================================================================================================
Func CheckPending()
	Local $bSuccess, $iWritten

	$bSuccess = _WinAPI_GetOverlappedResult($hPipe, $pOverlap, $iWritten, False)
	If Not $bSuccess Or ($iWritten <> $iToWrite) Then
		Debug("CheckPending ......: Write reconnecting")
		ReconnectClient()
	Else
		Debug("CheckPending ......: Write complete")
		$iState = 3
	EndIf
EndFunc   ;==>CheckPending

; ===============================================================================================================================
; This function is called to start an overlapped connection operation
; ===============================================================================================================================
Func ConnectClient()
	$iState = 0
	; Start an overlapped connection
	If _NamedPipes_ConnectNamedPipe($hPipe, $pOverlap) Then
		LogError("ConnectClient .....: ConnectNamedPipe 1 failed")
	Else
		Switch @error
			; The overlapped connection is in progress
			Case $ERROR_IO_PENDING
				Debug("ConnectClient .....: Pending")
				; Client is already connected, so signal an event
			Case $ERROR_PIPE_CONNECTED
				LogMsg("ConnectClient .....: Connected")
				$iState = 1
				If Not _WinAPI_SetEvent(DllStructGetData($tOverlap, "hEvent")) Then
					LogError("ConnectClient .....: SetEvent failed")
				EndIf
				; Error occurred during the connection event
			Case Else
				LogError("ConnectClient .....: ConnectNamedPipe 2 failed")
		EndSwitch
	EndIf
EndFunc   ;==>ConnectClient

; ===============================================================================================================================
; Dumps debug information to the screen
; ===============================================================================================================================
Func Debug($sMessage)
	If $DEBUGGING Then LogMsg($sMessage)
EndFunc   ;==>Debug

; ===============================================================================================================================
; Logs an error message to the display
; ===============================================================================================================================
Func LogError($sMessage)
	$sMessage &= " (" & _WinAPI_GetLastErrorMessage() & ")"
	ConsoleWrite($sMessage & @LF)
EndFunc   ;==>LogError

; ===============================================================================================================================
; Logs a message to the display
; ===============================================================================================================================
Func LogMsg($sMessage)
	ConsoleWrite($sMessage & @CRLF)
EndFunc   ;==>LogMsg

; ===============================================================================================================================
; This function is called when an error occurs or when the client closes its handle to the pipe
; ===============================================================================================================================
Func ReconnectClient()
	; Disconnect the pipe instance
	If Not _NamedPipes_DisconnectNamedPipe($hPipe) Then
		LogError("ReconnectClient ...: DisonnectNamedPipe failed")
		Return
	EndIf

	; Connect to a new client
	ConnectClient()
EndFunc   ;==>ReconnectClient