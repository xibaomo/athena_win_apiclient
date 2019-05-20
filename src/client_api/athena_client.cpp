#define WIN32_LEAN_AND_MEAN

#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <stdlib.h>
#include <cstdlib>
#include <stdio.h>
#include "athena_client.h"
#include "win_messenger/msg.h"
#include "win_messenger/win_messenger.h"
#include "fx_action.h"
#include "basics/log.h"
#define DEFAULT_BUFLEN 512
#define CHARBUFLEN 16

static void sendANumber(FXAction action, Real val)
{
    Message msg(sizeof(Real),0);
    Real* pm = (Real*)msg.getData();
    pm[0] = val;
    msg.setAction((ActionType)action);

    auto& msger = WinMessenger::getInstance();
    msger.sendAMsgNoFeedback(msg);
}

__declspec(dllexport) int __stdcall athena_init(wchar_t* symbol, wchar_t* hostip, wchar_t* port)
{
    char cip[CHARBUFLEN];
    char cport[CHARBUFLEN];
    char csymbol[CHARBUFLEN];
    std::wcstombs(cip,hostip,CHARBUFLEN);
    std::wcstombs(cport,port,CHARBUFLEN);
    std::wcstombs(csymbol,symbol,CHARBUFLEN);
    String ssymbol = String(csymbol);
    auto& msger = WinMessenger::getInstance(String(cip),String(cport));
    int databytes = 0;
    int charbytes = ssymbol.size();
    Message msg(databytes,charbytes);
    msg.setComment(ssymbol);
    msg.setAction((ActionType)FXAction::CHECKIN);
    msger.sendAMsgNoFeedback(msg);

    //Log(LOG_INFO) << "Athena client created";
    return 0;
}

__declspec(dllexport) wchar_t* __stdcall sendInitTime(wchar_t* timeString)
{
    char ts[DEFAULT_BUFLEN];
    std::wcstombs(ts,timeString,DEFAULT_BUFLEN);
    String tstr = String(ts);

    auto& msger = WinMessenger::getInstance();
    int charbytes = tstr.size();
    Message msg(0,charbytes);
    msg.setComment(tstr);
    msg.setAction((ActionType)FXAction::INIT_TIME);

    Message msgrecv = std::move(msger.sendAMsgWaitFeedback(msg));
    FXAction action = (FXAction)msgrecv.getAction();

    switch(action) {
    case FXAction::REQUEST_HISTORY_MINBAR: {
        int* pm = (int*)msgrecv.getData();
        int histLen = pm[0];
        tstr = msgrecv.getComment();
        wchar_t* rts = new wchar_t[tstr.size()+1];
        std::mbstowcs(rts,tstr.c_str(),tstr.size()+1);
        return rts;
    }
        break;
    default:
        break;
    }

    return NULL;
}

__declspec(dllexport) int __stdcall sendHistoryTicks(Real* data, int len, wchar_t* pos_type)
{
    char pt[CHARBUFLEN];
    std::wcstombs(pt,pos_type,CHARBUFLEN);
    String posType = String(pt);
    auto& msger = WinMessenger::getInstance();
    int databytes = len*sizeof(Real);
    int charbytes = posType.size();
    Message msg(databytes,charbytes);
    memcpy((void*)msg.getData(), (void*)data, databytes);
    msg.setComment(posType);
    msg.setAction((ActionType)FXAction::HISTORY);
    msger.sendAMsgNoFeedback(msg);
}

__declspec(dllexport) int __stdcall sendHistoryMinBars(Real* data, int len, int n_pts)
{
    auto& msger = WinMessenger::getInstance();
    int databytes = len*n_pts*sizeof(Real);
    int charbytes = 2*sizeof(int);
    Message msg(databytes,charbytes);
    memcpy((void*)msg.getData(),(void*)data,databytes);
    int *pc = (int*)msg.getChar();
    pc[0] = len;
    pc[1] = n_pts;
    msg.setAction((ActionType)FXAction::HISTORY_MINBAR);
    msger.sendAMsgNoFeedback(msg);
    return 0;
}

__declspec(dllexport) int __stdcall classifyATick(Real price, wchar_t* position_type)
{
    char posType[CHARBUFLEN];
    std::wcstombs(posType,position_type,CHARBUFLEN);
    String pos_type = String(posType);
    auto& msger = WinMessenger::getInstance();
    int databytes = sizeof(Real);
    int charbytes = pos_type.size();
    Message msg(databytes,charbytes);
    Real* pm = (Real*)msg.getData();
    pm[0] = price;
    msg.setComment(pos_type);
    msg.setAction((ActionType)FXAction::TICK);

    Message msgrecv = std::move(msger.sendAMsgWaitFeedback(msg));
    FXAction action = (FXAction)msgrecv.getAction();
    switch(action) {
    case FXAction::NOACTION:
        return 0;
        break;
    case FXAction::PLACE_BUY:
        //Log(LOG_INFO) << "Good to open buy position at " + std::to_string(price);
        return 1;
        break;
    case FXAction::PLACE_SELL:
        //Log(LOG_INFO) << "Good to open sell position at " + std::to_string(price);
        return 2;
        break;
    default:
        //Log(LOG_FATAL) << "Unexpected action";
        break;
    }

    return 0;
}
__declspec(dllexport) int __stdcall classifyAMinBar(Real open, Real high, Real low, Real close, Real tickvol,wchar_t* timeString)
{
    char ts[DEFAULT_BUFLEN];
    std::wcstombs(ts,timeString,DEFAULT_BUFLEN);
    String tstr = String(ts);

    auto& msger = WinMessenger::getInstance();
    int databytes = sizeof(Real)*5;
    int charbytes = tstr.size();
    Message msg(databytes,charbytes);
    Real* pm = (Real*)msg.getData();
    pm[0] = open;
    pm[1] = high;
    pm[2] = low;
    pm[3] = close;
    pm[4] = tickvol;
    msg.setComment(tstr);
    msg.setAction((ActionType)FXAction::MINBAR);

    Message msgrecv = std::move(msger.sendAMsgWaitFeedback(msg));
    FXAction action = (FXAction)msgrecv.getAction();
    switch(action) {
    case FXAction::NOACTION:
        return 0;
        break;
    case FXAction::PLACE_BUY:
        //Log(LOG_INFO) << "Good to open buy position at " + std::to_string(close);
        return 1;
        break;
    case FXAction::PLACE_SELL:
        //Log(LOG_INFO) << "Good to open sell position at " + std::to_string(close);
        return 2;
        break;
    default:
        //Log(LOG_FATAL) << "Unexpected action";
        break;
    }

    return 0;
}

__declspec(dllexport) int __stdcall sendCurrentProfit(Real profit)
{
    sendANumber(FXAction::PROFIT, profit);

    return 0;
}

__declspec(dllexport) int __stdcall sendPositionProfit(Real profit)
{
    sendANumber(FXAction::CLOSE_POS, profit);

    return 0;
}
__declspec(dllexport) int __stdcall athena_finish()
{
    Message msg;
    msg.setAction((ActionType)MsgAction::NORMAL_EXIT);
    auto& msger = WinMessenger::getInstance();
    msger.sendAMsgNoFeedback(msg);

    return 0;
}

/////////////////////////////////////////////////////////////////////////////////////////////
__declspec(dllexport) int __stdcall test_api_server(wchar_t* hostip, wchar_t* port)
{
    char cip[CHARBUFLEN];
    char cport[CHARBUFLEN];
    std::wcstombs(cip,hostip,CHARBUFLEN);
    std::wcstombs(cport,port,CHARBUFLEN);
    WSADATA wsaData;
    SOCKET ConnectSocket = INVALID_SOCKET;
    struct addrinfo *result=NULL,
                         *ptr = NULL,
                          hints;
    char *sendbuf = (char*)"this is a test";
    char recvbuf[DEFAULT_BUFLEN];
    int iResult;
    int recvbuflen = DEFAULT_BUFLEN;

    // Initialize winsock
    iResult = WSAStartup(MAKEWORD(2,2),&wsaData);
    if (iResult !=0)
    {
        printf("WSAStartup failed with error: %d\n",iResult);
        return 1;
    }
    ZeroMemory(&hints,sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;

    //Resolve the server address and port
    iResult = getaddrinfo(cip,cport,&hints,&result);
    if (iResult!=0)
    {
        printf("getaddrinfo failed with error: %d\n",iResult);
        WSACleanup();
        return 1;
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
            return 1;
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
        return 1;
    }
    //send an initial buffer
    iResult = send(ConnectSocket,sendbuf,(int)strlen(sendbuf),0);
    if (iResult == SOCKET_ERROR)
    {
        printf("send failed with error: %d\n",WSAGetLastError());
        closesocket(ConnectSocket);
        WSACleanup();
        return 1;
    }

    printf("Bytes sent: %d\n",iResult);

    // shutdown the connection since no more data will be sent
    iResult = shutdown(ConnectSocket,SD_SEND);
    if (iResult == SOCKET_ERROR)
    {
        printf("shutdown failed with error: %d\n",WSAGetLastError());
        closesocket(ConnectSocket);
        WSACleanup();
        return 1;
    }

    // Receive until the peer closes the connection
    do
    {
        iResult = recv(ConnectSocket,recvbuf,recvbuflen,0);
        if (iResult > 0)
            printf("Bytes received: %d\n",iResult);
        else if (iResult == 0)
            printf("Connection closed\n");
        else
            printf("recv failed with error: %d\n",WSAGetLastError());
    }
    while(iResult>0);

    //cleanup
    closesocket(ConnectSocket);
    WSACleanup();

    return 0;
}
