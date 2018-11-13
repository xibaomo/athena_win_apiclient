#ifndef _CLIENT_API_ATHENA_CLIENT_H_
#define _CLIENT_API_ATHENA_CLIENT_H_
typedef float Real;
#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

/**
 * Initialize athena engine
 * Send history data with given length, FX symbol to api server
 */

__declspec(dllexport) int __stdcall athena_init(Real* data, int len, wchar_t* symbol, wchar_t* hostip, wchar_t* port);

__declspec(dllexport) int __stdcall test_api_server(wchar_t* hostip, wchar_t* port);

#ifdef __cplusplus
}
#endif // __cplusplus
#endif // _CLIENT_API_ATHENA_CLIENT_H_
