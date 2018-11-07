#include "athena_client.h"
#include <stdlib.h>
#include <iostream>
#include <cstdlib>
using namespace std;

int main(int argc, char** argv)
{
    int a;
    wchar_t* hostip = L"192.168.1.102";
    wchar_t* port = L"27015";

    char cp[16];
    std::wcstombs(cp,hostip,16);
    cout<<cp<<endl;
//    athena_load(1.6666,1,hostip,port);
    return 0;
}
