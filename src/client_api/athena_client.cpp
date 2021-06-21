#define WIN32_LEAN_AND_MEAN

#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <stdlib.h>
#include <cstdlib>
#include <stdio.h>
#include <vector>
#include <locale>
#include <codecvt>
#include "athena_client.h"
#include "win_messenger/msg.h"
#include "win_messenger/win_messenger.h"
#include "fx_action.h"
#include "basics/log.h"
#include "basics/utils.h"
#include "pair_tracker.h"
#define DEFAULT_BUFLEN 512
#define CHARBUFLEN 16
static std::wstring s2ws(const std::string& str)
{
    using convert_typeX = std::codecvt_utf8<wchar_t>;
    std::wstring_convert<convert_typeX, wchar_t> converterX;

    return converterX.from_bytes(str);
}

static std::string ws2s(const std::wstring& wstr)
{
    using convert_typeX = std::codecvt_utf8<wchar_t>;
    std::wstring_convert<convert_typeX, wchar_t> converterX;

    return converterX.to_bytes(wstr);
}
static void sendANumber(FXAct action, Real val)
{
    Message msg(sizeof(Real),0);
    Real* pm = (Real*)msg.getData();
    pm[0] = val;
    msg.setAction(action);

    auto& msger = WinMessenger::getInstance();
    msger.sendAMsgNoFeedback(msg);
}

static void sendArray(FXAct action, Real* data, int len, int n_pts,const String& str="")
{
    auto& msger = WinMessenger::getInstance();
    SerializePack pack;
    pack.real32_vec.assign(data,data+len*n_pts);
    pack.int32_vec.push_back(len);
    pack.int32_vec.push_back(n_pts);
    pack.str_vec.push_back(str);
    String s = serialize(pack);
    Message msg(action,s);
    msger.sendAMsgNoFeedback(msg);
}

static Message sendArrayWaitFeedback(FXAct action, Real* data, int len, int n_pts,const String& str="")
{
    auto& msger = WinMessenger::getInstance();

    SerializePack pack;
    pack.real32_vec.assign(data,data+len*n_pts);
    pack.int32_vec.push_back(len);
    pack.int32_vec.push_back(n_pts);
    pack.str_vec.push_back(str);
    String s = serialize(pack);
    Message msg(action,s);
    Message rcv = msger.sendAMsgWaitFeedback(msg);

    return rcv;
}

static int action2int(FXAct action)
{
    switch(action) {
    case FXAct::NOACTION:
        return 0;
        break;
    case FXAct::PLACE_BUY:
        return 1;
        break;
    case FXAct::PLACE_SELL:
        return 2;
        break;
    case FXAct::CLOSE_ALL_POS:
        return 3;
        break;
    case FXAct::CLOSE_BUY:
        return 4;
    case FXAct::CLOSE_SELL:
        return 5;
    default:
        break;
    }

    return -1;
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
    msg.setAction((ActionType)MsgAct::CHECK_IN);
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
    msg.setAction((ActionType)FXAct::INIT_TIME);

    Message msgrecv = std::move(msger.sendAMsgWaitFeedback(msg));
    FXAct action = (FXAct)msgrecv.getAction();

    switch(action) {
    case FXAct::REQUEST_HISTORY_MINBAR: {
        //int* pm = (int*)msgrecv.getData();
        //int histLen = pm[0];
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
    msg.setAction((ActionType)FXAct::HISTORY);
    msger.sendAMsgNoFeedback(msg);

    return 0;
}

__declspec(dllexport) int __stdcall sendHistoryMinBars(Real* data, int len, int n_pts)
{
    sendArray(FXAct::HISTORY_MINBAR,data,len,n_pts);
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
    msg.setAction((ActionType)FXAct::TICK);

    Message msgrecv = std::move(msger.sendAMsgWaitFeedback(msg));
    FXAct action = (FXAct)msgrecv.getAction();
    switch(action) {
    case FXAct::NOACTION:
        return 0;
        break;
    case FXAct::PLACE_BUY:
        //Log(LOG_INFO) << "Good to open buy position at " + std::to_string(price);
        return 1;
        break;
    case FXAct::PLACE_SELL:
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
    msg.setAction((ActionType)FXAct::MINBAR);

    Message msgrecv = std::move(msger.sendAMsgWaitFeedback(msg));
    FXAct action = (FXAct)msgrecv.getAction();
    switch(action) {
    case FXAct::NOACTION:
        return 0;
        break;
    case FXAct::PLACE_BUY:
        //Log(LOG_INFO) << "Good to open buy position at " + std::to_string(close);
        return 1;
        break;
    case FXAct::PLACE_SELL:
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
    sendANumber(FXAct::PROFIT, profit);

    return 0;
}

__declspec(dllexport) int __stdcall sendPositionProfit(Real profit)
{
    sendANumber(FXAct::CLOSE_POS, profit);

    return 0;
}
__declspec(dllexport) int __stdcall athena_finish()
{
    Message msg;
    msg.setAction((ActionType)MsgAct::NORMAL_EXIT);
    auto& msger = WinMessenger::getInstance();
    msger.sendAMsgNoFeedback(msg);

    return 0;
}

////////////////////////////////////////////////////////////
////////////////////// Pair trader  ////////////////////////
////////////////////////////////////////////////////////////
__declspec(dllexport) int __stdcall askSymPair(CharArray& c_arr)
{
    Message msg;
    msg.setAction(FXAct::ASK_PAIR);
    auto& msger = WinMessenger::getInstance();
    Message rcvmsg = msger.sendAMsgWaitFeedback(msg);
    String cmt = rcvmsg.getComment();

    strcpy(c_arr.a, cmt.c_str());

    return 0;
}

__declspec(dllexport) int __stdcall sendPairHistX(Real* data, int len, int n_pts, double tick_size, double tick_val)
{
    auto& msger = WinMessenger::getInstance();
    SerializePack pack;
    pack.real32_vec.assign(data,data+len*n_pts);
    pack.int32_vec.push_back(len);
    pack.int32_vec.push_back(n_pts);
    pack.real64_vec.push_back(tick_size);
    pack.real64_vec.push_back(tick_val);
    String s = serialize(pack);
    Message msg(FXAct::PAIR_HIST_X,s);
    msger.sendAMsgNoFeedback(msg);
    return 0;
}

__declspec(dllexport) Real __stdcall sendPairHistY(Real* data, int len, int n_pts, double tick_size, double tick_val)
{
    auto& msger = WinMessenger::getInstance();

    SerializePack pack;
    pack.real32_vec.assign(data,data+len*n_pts);
    pack.int32_vec.push_back(len);
    pack.int32_vec.push_back(n_pts);
    pack.real64_vec.push_back(tick_size);
    pack.real64_vec.push_back(tick_val);
    String s = serialize(pack);
    Message msg(FXAct::PAIR_HIST_Y,s);
    Message rcv = msger.sendAMsgWaitFeedback(msg);

    Real* pm = (Real*)rcv.getData();

    return pm[0];
}

__declspec(dllexport) int __stdcall sendMinPair(wchar_t* timeString, Real x_ask, Real x_bid,
                                                Real y_ask, Real y_bid,Real& hedge_factor)
{
    char ts[DEFAULT_BUFLEN];
    std::wcstombs(ts,timeString,DEFAULT_BUFLEN);
    String tstr = String(ts);

    Real data[4];
    data[0] = x_ask; data[1] = x_bid;
    data[2] = y_ask; data[3] = y_bid;
    Message backmsg = sendArrayWaitFeedback(FXAct::PAIR_MIN_OPEN,data,4,1,tstr);

    FXAct act = (FXAct)backmsg.getAction();
    int pc = action2int(act);

    Real* pm = (Real*)backmsg.getData();
    hedge_factor = pm[0];

    return pc;
}

__declspec(dllexport) int __stdcall __registerPair(long tx, long ty)
{
    auto& pair_tracker = PairTracker::getInstance();
    pair_tracker.addPair(tx,ty);

    Message msg(sizeof(ulong)*2,0);
    ulong* pm = (ulong*) msg.getData();
    pm[0] = tx;
    pm[1] = ty;
    msg.setAction(FXAct::PAIR_POS_PLACED);

    auto& msger = WinMessenger::getInstance();
    msger.sendAMsgNoFeedback(msg);

    return 0;
}

__declspec(dllexport) int __stdcall registerPairStr(CharArray& arr, bool isSend)
{
    auto& pair_tracker = PairTracker::getInstance();
    String tx = String(arr.a);
    String ty = String(arr.b);
    pair_tracker.addPair(tx,ty);

    std::cout<<"pair registered " << tx << ":" << ty<<std::endl;
    if (!isSend) return 0;

    String cmt = tx + "/" + ty;

    Message msg(0,cmt.size());
    msg.setComment(cmt);
    msg.setAction(FXAct::PAIR_POS_PLACED);

    auto& msger = WinMessenger::getInstance();
    msger.sendAMsgNoFeedback(msg);

    return 0;
}

__declspec(dllexport) int __stdcall __sendPairProfit(long tx,long ty, Real profit)
{
    Message msg(2*sizeof(long),sizeof(Real));
    long* pm =  (long*)msg.getData();
    pm[0] = tx;
    pm[1] = ty;
    Real* pc = (Real*)msg.getChar();
    pc[0] = profit;

    msg.setAction(FXAct::PAIR_POS_CLOSED);

    auto& msger = WinMessenger::getInstance();
    msger.sendAMsgNoFeedback(msg);

    return 0;
}

__declspec(dllexport) int __stdcall sendPairProfitStr(CharArray& arr, Real profit)
{
    String stx = String (arr.a);
    String sty = String (arr.b);
    String txy = stx + "/" + sty;
    Message msg(sizeof(Real),txy.size());
    Real* pm = (Real*)msg.getData();
    pm[0] = profit;
    msg.setComment(txy);
    msg.setAction(FXAct::PAIR_POS_CLOSED);

    auto& msger = WinMessenger::getInstance();
    msger.sendAMsgNoFeedback(msg);

    return 0;
}

__declspec(dllexport) long __stdcall __getPairedTicket(long tx)
{
    auto& pair_tracker = PairTracker::getInstance();
    long ty = pair_tracker.getPairedTicket(tx);
    return ty;
}

__declspec(dllexport) int __stdcall getPairedTicketStr(CharArray& arr)
{
    auto& pt = PairTracker::getInstance();
    String tx = String(arr.a);
    String ty = pt.getPairedTicket(tx);

    strcpy(arr.b,ty.c_str());
    return 0;
}
__declspec(dllexport) int __stdcall sendSymbolHistory(Real* data, int len, CharArray& c_arr)
{
    //char ts[CHARBUFLEN];
    //std::wcstombs(ts,sym,CHARBUFLEN);
    String symstr = String(c_arr.a);
    String timestr = String(c_arr.b);

    sendArray(FXAct::SYM_HIST_OPEN,data,len,1,symstr+ " - " + timestr);

    return 0;
}

__declspec(dllexport) int __stdcall reportNumPos(int num)
{
    sendANumber(FXAct::NUM_POS,(Real)num*1.);
    return 0;
}

__declspec(dllexport) int __stdcall sendAllSymOpen(Real* data, int len, CharArray& c_arr)
{
    // data contains: ask1,bid1,ask2,bid2,...
    // c_arr.a: sym1,sym2,sym3,...
    String str(c_arr.a);
    Message msg(sizeof(Real)*len,str.size());
    memcpy((void*)msg.getData(),(void*)data, sizeof(Real)*len);
    msg.setComment(str);
    msg.setAction(FXAct::ALL_SYM_OPEN);

    auto& msger = WinMessenger::getInstance();
    Message backmsg = msger.sendAMsgWaitFeedback(msg);
    // backmag contains
    // syms:action, separated by ','

    String cmt = backmsg.getComment();
    strcpy(c_arr.b,cmt.c_str());

    return 0;
}
/////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
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
