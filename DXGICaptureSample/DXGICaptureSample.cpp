// DXGICaptureSample.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "DXGIManager.h"
#include <windows.h>

DXGIManager g_DXGIManager;

int _tmain(int argc, _TCHAR* argv[])
{
	CoInitialize(NULL);

	g_DXGIManager.SetCaptureSource(CSMonitor1);

	RECT rcDim;
	g_DXGIManager.GetOutputRect(rcDim);
	DWORD dwWidth = rcDim.right - rcDim.left;
	DWORD dwHeight = rcDim.bottom - rcDim.top;

	printf("dwWidth=%d dwHeight=%d\n", dwWidth, dwHeight);

	DWORD dwBufSize = dwWidth*dwHeight*4;

	BYTE* pBuf = new BYTE[dwBufSize];
	HRESULT hr;
	
	int i=0;
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

	UINT tmp;
	UINT offset = dwWidth * 4 * 5;
	tmp = ((pBuf[offset+ 1]) << 24) | ((pBuf[offset + 2]) << 16) | ((pBuf[offset + 3]) << 8) | ((pBuf[offset + 4]));
	printf("first pixel: %u\n",tmp);
	
	while (true) {

		i = 0;
		do
		{
			hr = g_DXGIManager.GetOutputBits(pBuf, rcDim);
			i++;
		} while (hr == DXGI_ERROR_WAIT_TIMEOUT || i < 2);

		if (FAILED(hr))
		{
			printf("GetOutputBits failed with hr=0x%08x\n", hr);
			return hr;
		}

		tmp = ((pBuf[offset + 1]) << 24) | ((pBuf[offset + 2]) << 16) | ((pBuf[offset + 3]) << 8) | ((pBuf[offset + 4]));
		printf("pixel: %u\n", tmp);
		Sleep(100);
	}

	delete[] pBuf;

	return 0;
}

