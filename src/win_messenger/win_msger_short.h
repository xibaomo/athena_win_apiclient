#ifndef WIN_MESSENGER_H_INCLUDED
#define WIN_MESSENGER_H_INCLUDED
#include <cstring>
#include "basics/types.h"
#include "win_messenger/msg.h"
class WinMsgerShort
{
private:
    String m_serverIP;
    String m_serverPort;
    WinMsgerShort(const String& ip, const String& port)
    {
        if (ip.size() > 0)
            m_serverIP = ip;
        if (port.size() > 0)
            m_serverPort = port;
    }
public:
    virtual ~WinMsgerShort() {;}
    static WinMsgerShort& getInstance(const String& ip = "", const String& port = "")
    {
        static WinMsgerShort _instance(ip,port);
        return _instance;
    }

    void sendAMsgNoFeedback(Message& msg);

    /**
     * Send message to api server and receive feedback
     */
    Message sendAMsgWaitFeedback(Message& msg);

};

#endif // WIN_MESSENGER_H_INCLUDED
