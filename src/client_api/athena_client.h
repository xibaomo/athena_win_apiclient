#ifndef _CLIENT_API_ATHENA_CLIENT_H_
#define _CLIENT_API_ATHENA_CLIENT_H_
#define BUFLEN 256
#include <stdint.h>
#include "basics/types.h"
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
__declspec(dllexport) int __stdcall sendHistoryTicks(real64* data, int len, wchar_t* pos_type);

__declspec(dllexport) int __stdcall athena_send_history_minbars(wchar_t* time_strs, real64* data, int len, int n_pts);

__declspec(dllexport) wchar_t* __stdcall sendInitTime(wchar_t* timeString);

/**
 * Classify a tick
 */
__declspec(dllexport) int __stdcall classifyATick(real64 price, wchar_t* position_type);
__declspec(dllexport) int __stdcall classifyAMinBar(real64 open, real64 high, real64 low, real64 close, real64 tickvol,wchar_t* timeString);

/**
 * Send the last minbar and current open
 */
__declspec(dllexport) int __stdcall athena_accumulate_minbar(wchar_t* time_str, real64 open, real64 high, real64 low, real64 close, real64 tickvol);
__declspec(dllexport) int __stdcall athena_request_action(wchar_t* time_str, real64 new_open);
__declspec(dllexport) int __stdcall athena_request_action_rtn(wchar_t* time_str, real64 new_open, real64* rtn);
__declspec(dllexport) int __stdcall athena_register_position(mt5ulong ticket, wchar_t* time, double ask, double bid);
__declspec(dllexport) int __stdcall athena_send_closed_position_info(mt5ulong ticket, wchar_t* time, double price, double profit);
__declspec(dllexport) int __stdcall athena_update_position(mt5ulong ticket, double profit);

/**
 * Send total profit of the current positions
 */
__declspec(dllexport) int __stdcall sendCurrentProfit(real64 profit);

/**
 * Send profit of a position just closed
 */
__declspec(dllexport) int __stdcall sendPositionProfit(real64 profit);

/**
 * Finalize athena client
 * Ask api server to exit
 */
__declspec(dllexport) int __stdcall sendAccountBalance(real64 balance);
__declspec(dllexport) int __stdcall athena_finish();

/**
 * API of pair trader
 */
__declspec(dllexport) int __stdcall askSymPair(CharArray& c_arr);
__declspec(dllexport) int __stdcall sendPairHistX(real64* data, int len, int n_pts, double tick_size, double tick_val);
__declspec(dllexport) real64 __stdcall sendPairHistY(real64* data, int len, int n_pts, double tick_size, double tick_val);
__declspec(dllexport) int __stdcall sendMinPair(wchar_t* timestr,double x_ask, double x_bid, double ticksize_x, double tickval_x,
                                                double y_ask, double y_bid, double ticksize_y, double tickval_y, int n_pos, int n_tp, int n_sl,
                                                double profit,
                                                double& hedge_factor);
__declspec(dllexport) int __stdcall __registerPair(long tx, long ty);
__declspec(dllexport) int __stdcall registerPairStr(CharArray& arr, bool isSend);
__declspec(dllexport) long __stdcall __getPairedTicket(long tx);
__declspec(dllexport) int __stdcall getPairedTicketStr(CharArray& arr);
__declspec(dllexport) int __stdcall sendSymbolHistory(real64* data, int len, CharArray& c_arr);
__declspec(dllexport) int __stdcall __sendPairProfit(long tx,long ty, real64 profit);
__declspec(dllexport) int __stdcall sendPairProfitStr(CharArray& arr, real64 profit);
__declspec(dllexport) int __stdcall reportNumPos(int num);
__declspec(dllexport) int __stdcall sendMinPairLabel(int id, int label); // 0 - buy take profit, 1 - buy stop loss, 2 - sell take profit, 3 - sell stop loss
__declspec(dllexport) int __stdcall getXYLotSizes(double& lotx, double& loty);

/**
 * API of multinode arbitrage
 */
__declspec(dllexport) int __stdcall sendAllSymOpen(real64* data, int len, CharArray& c_arr);


/**
 * API for graph loop
 */
__declspec(dllexport) int __stdcall request_all_syms(CharArray& arr, int& nsyms);

//////////////////////// for test purpose ////////////////////////////
__declspec(dllexport) int __stdcall test_api_server(wchar_t* hostip, wchar_t* port);

#ifdef __cplusplus
}
#endif // __cplusplus
#endif // _CLIENT_API_ATHENA_CLIENT_H_
