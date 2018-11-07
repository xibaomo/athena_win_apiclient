#ifndef _ATHENA_CLIENT_API_H_
#define _ATHENA_CLIENT_API_H_
#include <string>

struct MqlStr {
int len;
char* str;
};
extern "C" {
__declspec(dllexport) int athena_load(float price,int code,wchar_t* hostip, wchar_t* port);
}
#endif // _ATHENA_CLIENT_API_H_
