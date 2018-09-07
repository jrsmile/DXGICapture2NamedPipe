// DXGICaptureSample.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "DXGIManager.h"
#include <windows.h>

DXGIManager g_DXGIManager;

unsigned long createRGB(int r, int g, int b)
{
	return ((r & 0xff) << 16) + ((g & 0xff) << 8) + (b & 0xff);
}

int _tmain(int argc, _TCHAR* argv[])
{
	CoInitialize(NULL);

	g_DXGIManager.SetCaptureSource(CSMonitor1);

	RECT rcDim;
	g_DXGIManager.GetOutputRect(rcDim);
	DWORD dwWidth = rcDim.right - rcDim.left;
	DWORD dwHeight = rcDim.bottom - rcDim.top;
	DWORD dwBufSize = dwWidth*dwHeight*4;

	BYTE* pBuf = new BYTE[dwBufSize];
	HRESULT hr;
	unsigned long color;

	HANDLE hPipe;
	DWORD dwWritten;
	char cPipeBuffer[8];
	
	hPipe = CreateFile(TEXT("\\\\.\\pipe\\Pipe"),
		GENERIC_READ | GENERIC_WRITE,
		0,
		NULL,
		OPEN_EXISTING,
		0,
		NULL);

	int i;
	while (true){
	i=0;
	do
	{
		hr = g_DXGIManager.GetOutputBits(pBuf, rcDim);
		i++;
	}
	while (hr == DXGI_ERROR_WAIT_TIMEOUT || i < 2);

	if( FAILED(hr) )
	{
		printf("GetOutputBits failed with hr=0x%08x\n", hr);
		return hr;
	}
	
	// printf("#start\n");
	UINT offset;
	for (int a = 1; a < 364; a = a + 4) {
		offset = a * 4;
		//	printf("#%02x%02x%02x\n", pBuf[offset + 2], pBuf[offset + 1], pBuf[offset]);
		snprintf(cPipeBuffer, sizeof cPipeBuffer,"#%02x%02x%02x\n", pBuf[offset + 2], pBuf[offset + 1], pBuf[offset]);
		WriteFile(hPipe,cPipeBuffer, sizeof cPipeBuffer + 2, &dwWritten, NULL);
	}
	//printf("#end\n");
	}
	delete[] pBuf;

	return 0;
}