#ifndef _ATHENA_CLIENT_API_H_
#define _ATHENA_CLIENT_API_H_
#include <string>
typedef int Status;

extern "C" {
__declspec(dllexport) int athena_load(float price,int code);
}
#endif // _ATHENA_CLIENT_API_H_
