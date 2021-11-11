#ifndef _CLIENT_API_ATHENA_CLIENT_H_
#define _CLIENT_API_ATHENA_CLIENT_H_
#define BUFLEN 256
typedef float Real;
typedef double real64;
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
__declspec(dllexport) int __stdcall athena_test_dll();
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
 * Send the last minbar and current open
 */
__declspec(dllexport) int __stdcall accumulateMinBar(wchar_t* date, wchar_t* time, real64 open, real64 high, real64 low, real64 close, real64 tickvol);
__declspec(dllexport) int __stdcall requestAction(real64 new_open);
__declspec(dllexport) int __stdcall registerPosition(unsigned long ticket, wchar_t* time);
__declspec(dllexport) int __stdcall sendClosedPosInfo(unsigned long ticket, wchar_t* time, double profit);

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
__declspec(dllexport) int __stdcall sendAccountBalance(Real balance);
__declspec(dllexport) int __stdcall athena_finish();

/**
 * API of pair trader
 */
__declspec(dllexport) int __stdcall askSymPair(CharArray& c_arr);
__declspec(dllexport) int __stdcall sendPairHistX(Real* data, int len, int n_pts, double tick_size, double tick_val);
__declspec(dllexport) Real __stdcall sendPairHistY(Real* data, int len, int n_pts, double tick_size, double tick_val);
__declspec(dllexport) int __stdcall sendMinPair(wchar_t* timestr,double x_ask, double x_bid, double ticksize_x, double tickval_x,
                                                double y_ask, double y_bid, double ticksize_y, double tickval_y, int n_pos, int n_tp, int n_sl,
                                                double profit,
                                                double& hedge_factor);
__declspec(dllexport) int __stdcall __registerPair(long tx, long ty);
__declspec(dllexport) int __stdcall registerPairStr(CharArray& arr, bool isSend);
__declspec(dllexport) long __stdcall __getPairedTicket(long tx);
__declspec(dllexport) int __stdcall getPairedTicketStr(CharArray& arr);
__declspec(dllexport) int __stdcall sendSymbolHistory(Real* data, int len, CharArray& c_arr);
__declspec(dllexport) int __stdcall __sendPairProfit(long tx,long ty, Real profit);
__declspec(dllexport) int __stdcall sendPairProfitStr(CharArray& arr, Real profit);
__declspec(dllexport) int __stdcall reportNumPos(int num);
__declspec(dllexport) int __stdcall sendMinPairLabel(int id, int label); // 0 - buy take profit, 1 - buy stop loss, 2 - sell take profit, 3 - sell stop loss
__declspec(dllexport) int __stdcall getXYLotSizes(double& lotx, double& loty);

/**
 * API of multinode arbitrage
 */
__declspec(dllexport) int __stdcall sendAllSymOpen(Real* data, int len, CharArray& c_arr);
//////////////////////// for test purpose ////////////////////////////
__declspec(dllexport) int __stdcall test_api_server(wchar_t* hostip, wchar_t* port);

#ifdef __cplusplus
}
#endif // __cplusplus
#endif // _CLIENT_API_ATHENA_CLIENT_H_
