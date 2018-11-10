#ifndef WIN_MESSENGER_H_INCLUDED
#define WIN_MESSENGER_H_INCLUDED
#include <cstring>
#include "common/types.h"
#include "msg.h"
class WinMessenger
{
private:
    String m_serverIP;
    String m_serverPort;
    WinMessenger(const String& ip, const String& port): m_serverIP(ip),m_serverPort(port){;}
public:
    virtual ~WinMessenger() {;}
    static WinMessenger& getInstance(const String& ip, const String& port)
    {
        static WinMessenger _instance(ip,port);
        return _instance;
    }

    void sendAMsg(Message& msg);
};

#endif // WIN_MESSENGER_H_INCLUDED
