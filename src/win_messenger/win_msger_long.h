#pragma once

#include <cstring>
#include "basics/types.h"
#include "win_messenger/msg.h"
class WinMsgerLong
{
private:
    long m_sock;
    String m_serverIP;
    String m_serverPort;
    WinMsgerLong(const String& ip, const String& port) : m_sock(-1)
    {
        if (ip.size() > 0)
            m_serverIP = ip;
        if (port.size() > 0)
            m_serverPort = port;
    }
public:
    virtual ~WinMsgerLong();
    static WinMsgerLong& getInstance(const String& ip = "", const String& port = "")
    {
        static WinMsgerLong _instance(ip,port);
        return _instance;
    }

    void sendAMsgNoFeedback(Message& msg);

    /**
     * Send message to api server and receive feedback
     */
    Message sendAMsgWaitFeedback(Message& msg);
};

typedef WinMsgerLong __WinMessenger;
