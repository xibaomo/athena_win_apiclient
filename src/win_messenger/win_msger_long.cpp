#include "win_msger_long.h"
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
#define ACK_STR "ROGER_THAT"
//#define DEFAULT_PORT "27015"

using namespace std;

WinMsgerLong::~WinMsgerLong() {
    closeSock(m_sock);
}

void
WinMsgerLong::sendAMsgNoFeedback(Message& msg)
{
    msg.setNoQuery();
    if (m_sock < 0) {
        m_sock = connectAddr(m_serverIP,m_serverPort);
    }
    //send an initial buffer
    int iResult = send(m_sock,(char*)msg.getHead(),(int)msg.getMsgSize(),0);
    if (iResult == SOCKET_ERROR)
    {
        printf("send failed with error: %d\n",WSAGetLastError());
        closesocket(m_sock);
        WSACleanup();
        return;
    }

    printf("Bytes sent: %d\n",iResult);

    // Receive until the peer closes the connection
    while (1)
    {
        char recvbuf[512];
        iResult = recv(m_sock,recvbuf,512,0);
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

    //cleanup
    //closesocket(ConnectSocket);
    //WSACleanup();

    return;
}

Message
WinMsgerLong::sendAMsgWaitFeedback(Message& msg)
{
    msg.setQuery();
    Message nullmsg(1);
    if (m_sock < 0) {
        m_sock = connectAddr(m_serverIP,m_serverPort);
    }
    if (m_sock < 0)
        return nullmsg;
    //send an initial buffer
    int iResult = send(m_sock,(char*)msg.getHead(),(int)msg.getMsgSize(),0);
    if (iResult == SOCKET_ERROR)
    {
        printf("send failed with error: %d\n",WSAGetLastError());
        closesocket(m_sock);
        WSACleanup();
        return nullmsg;
    }

    printf("Bytes sent: %d\n",iResult);

    // Receive until the peer closes the connection
    iResult = 0;
    do
    {
        char recvbuf[512];
        iResult = recv(m_sock,recvbuf,512,0);
        if (iResult > 0)
        {
            printf("Bytes received: %d\n",iResult);
            Message outmsg;
            outmsg.setMsgSize(iResult);
            memcpy((void*)outmsg.getHead(),(void*)recvbuf,iResult);

            return outmsg;
        }
        else if (iResult == 0)
            printf("Connection closed\n");
        else
            printf("recv failed with error: %d\n",WSAGetLastError());
    }
    while(iResult==0);

    return nullmsg;
}
