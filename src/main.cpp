#include "client_api/athena_client.h"
#include <stdlib.h>
#include <iostream>
#include <cstdlib>
using namespace std;

int main(int argc, char** argv)
{

    wchar_t* hostip = L"73.92.253.8";
    wchar_t* port = L"8888";
    wchar_t* symbol = L"EURUSD";

//    test_api_server(hostip,port);

    athena_init(symbol,hostip,port);

    Real p[500];
    for (int i=0;i<500;i++)
        p[i] = 1.0;
    sendHistoryTicks(p,500,L"buy");

    float pc = 1.666;
    int action = classifyATick(pc,L"buy");

    printf("action %d\n",action);
    return 0;
}
