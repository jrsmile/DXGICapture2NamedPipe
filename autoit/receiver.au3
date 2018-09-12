#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.14.3
	Author:         JRSmile

	Script Function:
	Retrieve Pixeldata from C++ and analyse it.

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here
#include <NamedPipes.au3>
#include <WinAPI.au3>
#include <WindowsConstants.au3>
#include <array.au3>
Local Const $PIPE_NAME = "\\.\pipe\Pipe"

$tOverlap = DllStructCreate($tagOVERLAPPED)
$pOverlap = DllStructGetPtr($tOverlap)
$hEvent = _WinAPI_CreateEvent()
If $hEvent = 0 Then
	LogError("InitPipe ..........: API_CreateEvent failed")
	Return
EndIf
DllStructSetData($tOverlap, "hEvent", $hEvent)

$hNamedPipe = _NamedPipes_CreateNamedPipe($PIPE_NAME, 0, 1, 0, 1, 1, 0, 25, 1, 8, 5000, 0)
ConsoleWrite(_ArrayToString(_NamedPipes_GetNamedPipeInfo($hNamedPipe)) & @CRLF)
Do
	Sleep(100)
	$aPipeData = _NamedPipes_PeekNamedPipe($hNamedPipe)
	ConsoleWrite(_ArrayToString($aPipeData) & @CRLF)
Until $aPipeData[0] == "DIE"
