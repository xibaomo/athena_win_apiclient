#define WIN32_LEAN_AND_MEAN
#include "win_messenger/win_msger_short.h"
#include "basics/utils.h"
#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <stdlib.h>
#include <cstdlib>
#include <stdio.h>
#include <string>
using namespace std;
#define DEFAULT_BUFLEN 512
//#define DEFAULT_PORT "27015"

const std::string ACK_STR = "ROGER_THAT";
void
WinMsgerShort::sendAMsgNoFeedback(Message& msg)
{
    msg.setNoQuery();
    WSADATA wsaData;
    SOCKET ConnectSocket = INVALID_SOCKET;
    struct addrinfo *result=NULL,
                         *ptr = NULL,
                          hints;

    char recvbuf[DEFAULT_BUFLEN];
    int iResult;
    int recvbuflen = DEFAULT_BUFLEN;

    // Initialize winsock
    iResult = WSAStartup(MAKEWORD(2,2),&wsaData);
    if (iResult !=0)
    {
        printf("WSAStartup failed with error: %d\n",iResult);
        return;
    }
    ZeroMemory(&hints,sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;

    //Resolve the server address and port
    iResult = getaddrinfo(m_serverIP.c_str(),m_serverPort.c_str(),&hints,&result);
    if (iResult!=0)
    {
        printf("getaddrinfo failed with error: %d\n",iResult);
        WSACleanup();
        return;
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
            return;
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
        return;
    }
    //send an initial buffer
    iResult = send(ConnectSocket,(char*)msg.getHead(),(int)msg.getMsgSize(),0);
    if (iResult == SOCKET_ERROR)
    {
        printf("send failed with error: %d\n",WSAGetLastError());
        closesocket(ConnectSocket);
        WSACleanup();
        return;
    }

    printf("Bytes sent: %d\n",iResult);

    // shutdown the connection since no more data will be sent
    //iResult = shutdown(ConnectSocket,SD_SEND);
    if (iResult == SOCKET_ERROR)
    {
        printf("shutdown failed with error: %d\n",WSAGetLastError());
        closesocket(ConnectSocket);
        WSACleanup();
        return;
    }

    // Receive until the peer closes the connection
    do
    {
        iResult = recv(ConnectSocket,recvbuf,recvbuflen,0);
        if (iResult > 0) {
            printf("Bytes received: %d\n",iResult);
            string s(recvbuf,iResult);
            if (s == ACK_STR) break;
        }
        else if (iResult == 0)
            printf("Connection closed\n");
        else
            printf("recv failed with error: %d\n",WSAGetLastError());
    }
    while(iResult==0);

    //cleanup
    closesocket(ConnectSocket);
    WSACleanup();

    return;
}

Message
WinMsgerShort::sendAMsgWaitFeedback(Message& msg)
{
    msg.setQuery();
    Message nullmsg(1);
    WSADATA wsaData;
    SOCKET ConnectSocket = INVALID_SOCKET;
    struct addrinfo *result=NULL,
                         *ptr = NULL,
                          hints;
    char recvbuf[DEFAULT_BUFLEN];
    int iResult;
    int recvbuflen = DEFAULT_BUFLEN;

    // Initialize winsock
    iResult = WSAStartup(MAKEWORD(2,2),&wsaData);
    if (iResult !=0)
    {
        printf("WSAStartup failed with error: %d\n",iResult);
        return nullmsg;
    }
    ZeroMemory(&hints,sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;

    //Resolve the server address and port
    iResult = getaddrinfo(m_serverIP.c_str(),m_serverPort.c_str(),&hints,&result);
    if (iResult!=0)
    {
        printf("getaddrinfo failed with error: %d\n",iResult);
        WSACleanup();
        return nullmsg;
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
            return nullmsg;
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
        return nullmsg;
    }
    //send an initial buffer
    iResult = send(ConnectSocket,(char*)msg.getHead(),(int)msg.getMsgSize(),0);
    if (iResult == SOCKET_ERROR)
    {
        printf("send failed with error: %d\n",WSAGetLastError());
        closesocket(ConnectSocket);
        WSACleanup();
        return nullmsg;
    }

    printf("Bytes sent: %d\n",iResult);

    // shutdown the connection since no more data will be sent
    //iResult = shutdown(ConnectSocket,SD_SEND);
    if (iResult == SOCKET_ERROR)
    {
        printf("shutdown failed with error: %d\n",WSAGetLastError());
        closesocket(ConnectSocket);
        WSACleanup();
        return nullmsg;
    }

    // Receive until the peer closes the connection
    iResult = 0;
    do
    {
        iResult = recv(ConnectSocket,recvbuf,recvbuflen,0);
        if (iResult > 0)
        {
            printf("Bytes received: %d\n",iResult);
            Message outmsg;
            outmsg.setMsgSize(iResult);
            memcpy((void*)outmsg.getHead(),(void*)recvbuf,iResult);
            shutdown(ConnectSocket,SD_SEND);
            closesocket(ConnectSocket);
            WSACleanup();
            return outmsg;
        }
        else if (iResult == 0)
            printf("Connection closed\n");
        else
            printf("recv failed with error: %d\n",WSAGetLastError());
    }
    while(iResult==0);

    //cleanup
    closesocket(ConnectSocket);
    WSACleanup();

    return nullmsg;
}
