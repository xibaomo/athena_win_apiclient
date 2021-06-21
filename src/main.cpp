#include "client_api/athena_client.h"
#include <stdlib.h>
#include <iostream>
#include <cstdlib>
#define N 2000*5
using namespace std;

int main(int argc, char** argv)
{

    wchar_t* hostip = L"192.168.1.103";
    wchar_t* port = L"8888";
    wchar_t* symbol = L"EURUSD";

//    test_api_server(hostip,port);

    athena_init(symbol,hostip,port);


    Real* data = new Real[N];
    for (int i=0; i < N; i++) {
        data[i] = i*1e-3;
    }

   // sendPairHistX(data,2000,5);

    delete[] data;
    return 0;
}
