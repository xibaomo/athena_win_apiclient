#ifndef _CLIENT_API_ATHENA_CLIENT_H_
#define _CLIENT_API_ATHENA_CLIENT_H_
typedef float Real;
#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

/**
 * Initialize athena client
 * Send FX symbol to api server
 */
__declspec(dllexport) int __stdcall athena_init(wchar_t* symbol, wchar_t* hostip, wchar_t* port);

/**
 * Send history data to api server
 */
__declspec(dllexport) int __stdcall sendHistoryTicks(Real* data, int len, wchar_t* pos_type);

__declspec(dllexport) int __stdcall sendHistoryMinBars(Real* data, int len, int n_pts);

__declspec(dllexport) wchar_t* __stdcall sendInitTime(wchar_t* timeString);

/**
 * Classify a tick
 */
__declspec(dllexport) int __stdcall classifyATick(Real price, wchar_t* position_type);
__declspec(dllexport) int __stdcall classifyAMinBar(Real open, Real high, Real low, Real close, Real tickvol,wchar_t* timeString);

/**
 * Send total profit of the current positions
 */
__declspec(dllexport) int __stdcall sendCurrentProfit(Real profit);

/**
 * Send profit of a position just closed
 */
__declspec(dllexport) int __stdcall sendPositionProfit(Real profit);

/**
 * Finalize athena client
 * Ask api server to exit
 */
__declspec(dllexport) int __stdcall athena_finish();

__declspec(dllexport) const wchar_t* __stdcall askSymPair(int* lrlen);
__declspec(dllexport) int __stdcall sendPairHistX(Real* data, int len, int n_pts);
__declspec(dllexport) int __stdcall sendPairHistY(Real* data, int len, int n_pts);
__declspec(dllexport) int __stdcall sendMinPair(Real x, Real y);

//////////////////////// for test purpose ////////////////////////////
__declspec(dllexport) int __stdcall test_api_server(wchar_t* hostip, wchar_t* port);

#ifdef __cplusplus
}
#endif // __cplusplus
#endif // _CLIENT_API_ATHENA_CLIENT_H_
