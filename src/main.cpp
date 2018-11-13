#include "client_api/athena_client.h"
#include <stdlib.h>
#include <iostream>
#include <cstdlib>
using namespace std;

int main(int argc, char** argv)
{

    wchar_t* hostip = L"192.168.1.102";
    wchar_t* port = L"8800";
    wchar_t* symbol = L"EURUSD";

//    test_api_server(hostip,port);

    float a = 1.66666;

    athena_init(&a,1,symbol,hostip,port);
    return 0;
}
