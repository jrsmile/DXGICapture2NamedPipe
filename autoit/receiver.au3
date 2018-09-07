#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.3
 Author:         JRSmile

 Script Function:
	Retrieve Pixeldata from C++ and analyse it.

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here
#include <NamedPipes.au3>
#include <array.au3>
_NamedPipes_WaitNamedPipe ("\\.\pipe\Pipe", 0 )
$hNamedPipe = FileOpen("\\.\pipe\Pipe", 0)
_ArrayDisplay(_NamedPipes_GetNamedPipeHandleState ( $hNamedPipe ))
_ArrayDisplay(_NamedPipes_GetNamedPipeInfo ( $hNamedPipe ))