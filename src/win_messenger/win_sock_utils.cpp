#include "win_sock_utils.h"
#define WIN32_LEAN_AND_MEAN
#include "basics/utils.h"
#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <stdlib.h>
#include <cstdlib>
#include <stdio.h>

#define DEFAULT_BUFLEN 512
using namespace std;

long connectAddr(const string& serverIP, const string& port)
{
    WSADATA wsaData;
    SOCKET ConnectSocket = INVALID_SOCKET;
    struct addrinfo *result=NULL,
                         *ptr = NULL,
                          hints;

    char recvbuf[DEFAULT_BUFLEN];
    int iResult;

    // Initialize winsock
    iResult = WSAStartup(MAKEWORD(2,2),&wsaData);
    if (iResult !=0)
    {
        printf("WSAStartup failed with error: %d\n",iResult);
        return -1;
    }
    ZeroMemory(&hints,sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;

    //Resolve the server address and port
    iResult = getaddrinfo(serverIP.c_str(),port.c_str(),&hints,&result);
    if (iResult!=0)
    {
        printf("getaddrinfo failed with error: %d\n",iResult);
        WSACleanup();
        return -1;
    }

    // Attempt to connect to an address until one succeeds
    for (ptr=result; ptr != NULL; ptr=ptr->ai_next)
    {
        //create a socket for connecting to server
        ConnectSocket = socket(ptr->ai_family,ptr->ai_socktype,
                               ptr->ai_protocol);
        if (ConnectSocket == INVALID_SOCKET)
        {
            printf("socket failed with error: %d\n",WSAGetLastError());
            WSACleanup();
            return -1;
        }

        // Connect to server
        iResult = connect(ConnectSocket,ptr->ai_addr,(int)ptr->ai_addrlen);
        if (iResult  == SOCKET_ERROR)
        {
            closesocket(ConnectSocket);
            continue;
        }
        break;
    }
    freeaddrinfo(result);

    if (ConnectSocket == INVALID_SOCKET)
    {
        printf("Unable to connect to server\n");
        WSACleanup();
        return -1;
    }

    return ConnectSocket;
}

void closeSock(long sock) {
    //cleanup
    shutdown(sock,SD_SEND);
    closesocket(sock);
    WSACleanup();
}
