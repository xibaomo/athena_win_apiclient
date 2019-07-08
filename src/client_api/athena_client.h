#ifndef _CLIENT_API_ATHENA_CLIENT_H_
#define _CLIENT_API_ATHENA_CLIENT_H_
#define BUFLEN 256
typedef float Real;
#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

struct CharArray {
    char a[BUFLEN];
    char b[BUFLEN];
    char c[BUFLEN];
};

typedef unsigned long ulong;
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

/**
 * API of pair trader
 */
__declspec(dllexport) int __stdcall askSymPair(CharArray& c_arr);
__declspec(dllexport) int __stdcall sendPairHistX(Real* data, int len, int n_pts);
__declspec(dllexport) Real __stdcall sendPairHistY(Real* data, int len, int n_pts);
__declspec(dllexport) int __stdcall sendMinPair(wchar_t* timestr,Real x, Real y, Real point_value, Real point_dollar, Real& hedge_factor);
__declspec(dllexport) int __stdcall __registerPair(long tx, long ty);
__declspec(dllexport) int __stdcall registerPairStr(CharArray& arr, bool isSend);
__declspec(dllexport) long __stdcall __getPairedTicket(long tx);
__declspec(dllexport) int __stdcall getPairedTicketStr(CharArray& arr);
__declspec(dllexport) int __stdcall sendSymbolHistory(Real* data, int len, CharArray& c_arr);
__declspec(dllexport) int __stdcall __sendPairProfit(long tx,long ty, Real profit);
__declspec(dllexport) int __stdcall sendPairProfitStr(CharArray& arr, Real profit);
//////////////////////// for test purpose ////////////////////////////
__declspec(dllexport) int __stdcall test_api_server(wchar_t* hostip, wchar_t* port);

#ifdef __cplusplus
}
#endif // __cplusplus
#endif // _CLIENT_API_ATHENA_CLIENT_H_
