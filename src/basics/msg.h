/*
 * =====================================================================================
 *
 *       Filename:  msg.h
 *
 *    Description:
 *
 *        Version:  1.0
 *        Created:  10/27/2018 03:05:03 AM
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  YOUR NAME (),
 *   Organization:
 *
 * =====================================================================================
 */

#ifndef _COMMON_MSG_H_
#define _COMMON_MSG_H_
#include <cstring>
#include <malloc.h>
#include <iostream>
#include "basics/types.h"
#include "basics/log.h"

typedef unsigned int ActionType;
typedef int TagType;
typedef size_t SizeType;

enum class MsgAction {
    GET_READY = 0,
    NORMAL_EXIT = 1,
    ERROR_EXIT,
    CHECK_IN
};

/*****************************************************************************************
*  Message uses an 1D char array to store
    size_t   uint   int  size_t  size_t       Real / int []          char[]
   +-------+------+-----+-------+------+-----------------------+---------------+
   |       |      |     |       |      |                       |               |
   |msgSize|Action| tag | data  |cmmnt |         data          |    comment    |
   |       |      |     | bytes |bytes |                       |               |
   |       |      |     |       |      |                       |               |
   +-------+------+-----+-------+------+-----------------------+---------------+
****************************************************************************************/

class Message {
protected:

    Uchar      *m_entireMsg;    // pointer to start of the entire Msg

    bool        m_own;

public:

    /**
     *  Constructor with action and dataBytes and actual payload data
     *  total message size = sizeof(SizeType) + sizeof(ActionType) + sizeof(TagType) +
     *      sizeof(size_t)*2
     *                     + size_of_payload
     */

    Message(const size_t dataBytes = 0, const size_t charBytes = 0) : m_entireMsg(nullptr)
    {
        size_t msgSize = sizeof(SizeType) + sizeof(ActionType) + sizeof(TagType) +
                sizeof(size_t)*2 + dataBytes + charBytes + sizeof(char)*3;
        m_entireMsg = (Uchar*)malloc(msgSize);
        *getMsgSizePtr() = msgSize;
        *getDataBytesPtr() = dataBytes;
        *getCharBytesPtr() = charBytes;
        m_entireMsg[msgSize-3]='E';
        m_entireMsg[msgSize-2]='N';
        m_entireMsg[msgSize-1]='D';

        setAction(MsgAction::GET_READY);
        m_own = true;
    }

    Message(const Message& other)
    {
        size_t msgSize = other.getMsgSize();
        m_entireMsg = (Uchar*)malloc(msgSize);
        memcpy(m_entireMsg, other.m_entireMsg, msgSize);
        m_own = true;
    }

    Message (char* head) {
        m_entireMsg = (Uchar*)head;
        m_own = false;
    }

    Message& operator=(const Message& other)
    {
        if ( m_entireMsg && m_own )
            free(m_entireMsg);

        size_t msgSize = other.getMsgSize();
        m_entireMsg = (Uchar*)malloc(msgSize);
        memcpy(m_entireMsg, other.m_entireMsg, msgSize);
        m_own = true;

        return *this;
    }

    Message(Message&& other)

    {
        if ( !other.m_own )
            Log(LOG_FATAL) << "Cannot transfer ownership if not own it";

        if ( !other.m_entireMsg ) {
            m_entireMsg = nullptr;
            Log(LOG_FATAL) << "Null msg cannot be moved";
        }

        else {
            m_entireMsg = other.m_entireMsg;
            other.m_entireMsg = nullptr;
        }

        m_own = true;
        other.m_own = false;
    }

    Message& operator=(Message&& other)
    {
        if ( !other.m_own )
            Log(LOG_FATAL) << "Cannot transfer ownership if not own it";

        if ( m_own && m_entireMsg )
            free(m_entireMsg);

        m_entireMsg = other.m_entireMsg;
        other.m_entireMsg = nullptr;

        m_own = true;

        other.m_own = false;

        return *this;
    }

    ~Message()
    {
        if ( m_entireMsg && m_own ) free(m_entireMsg);
        m_entireMsg = nullptr;
    }

    /**
     *  Return the size of data in bytes
     */
    size_t    getDataBytes() const
    {
        return *getDataBytesPtr();
    }

    ActionType* getActionPtr() { return (ActionType*)(m_entireMsg + sizeof(SizeType)); }

    ActionType  getAction() { return *getActionPtr(); }

    const size_t * getMsgSizePtr() const
    {
        return (const size_t*) m_entireMsg;
    }

    size_t *       getMsgSizePtr()
    {
        return const_cast<size_t*>(static_cast<const Message&>(*this).getMsgSizePtr());
    }

    const size_t *  getDataBytesPtr() const
    {
        return (const size_t*)(m_entireMsg + sizeof(SizeType) + sizeof(ActionType) +
                sizeof(TagType));
    }

    size_t *        getDataBytesPtr()
    {
        return const_cast<size_t*>(static_cast<const Message&>(*this).getDataBytesPtr());
    }

    /**
     *  Return size of chars in bytes
     */

    size_t    getCharBytes() const
    {
        return *getCharBytesPtr();
    }

    const size_t *  getCharBytesPtr() const
    {
        return getDataBytesPtr() + 1;   // in units of size_t
    }

    size_t *        getCharBytesPtr()
    {
        return const_cast<size_t*>(static_cast<const Message&>(*this).getCharBytesPtr());
    }

    /**
    *  Set the Action
    */

    void      setAction(ActionType action)  { *getActionPtr() = action; }

    void      setAction(MsgAction action) { setAction((ActionType)action); }

    /**
    * Return the total size of the message
    */

    size_t    getMsgSize() const            { return *getMsgSizePtr(); }

    /**
     * Set the msg size
     * Usually use gMessenger.detectDataBytes(&size) first and then set msg size.
     */

    void      setMsgSize(size_t msgSize)
    {
        if ( m_entireMsg ) free(m_entireMsg);

        m_entireMsg = (Uchar*) malloc(msgSize);
        *getDataBytesPtr() = 0;
        *getCharBytesPtr() = 0;
        *getMsgSizePtr() = msgSize;
    }

    /**
    *  Return the head of msg
     */

    Uchar*     getHead() { return m_entireMsg; }

    /**
     *  Return the pointer to data
     */

    const Uchar*    getData() const
    {
        const Uchar *dataStart = m_entireMsg + sizeof(SizeType) + sizeof(ActionType) + sizeof(TagType) + 2*sizeof(size_t);

        return dataStart;
    }

    Uchar*          getData()
    {
        return const_cast<Uchar*>(static_cast<const Message&>(*this).getData());
    }

    /**
     *  Return comment
     */

    String     getComment() const
    {
        size_t charBytes = getCharBytes();

        if ( charBytes == 0 || charBytes > getMsgSize()) return String(); // no comment

        const Uchar* p = getChar();

        String comment((char*)p, charBytes);

        return comment;
    }

    /**
     *  Return pointer to comment
     */
    const Uchar*    getChar() const
    {
        const Uchar* p = getData() + getDataBytes();

        return p;
    }

    Uchar*          getChar()
    {
        return const_cast<Uchar*>(static_cast<const Message&>(*this).getChar());
    }

    /**
     *  Set comment
     */

    void        setComment(const String& s)
    {
        const size_t n = getCharBytes();

        if ( n < s.length() ) {
            // allocate a new piece of memory
            const size_t msgSize = getMsgSize() - getCharBytes() + s.size();

            Uchar* p = (Uchar*)malloc(msgSize);

            memcpy(p, m_entireMsg, getMsgSize());

            free(m_entireMsg);

            m_entireMsg = p;

            *getMsgSizePtr() = msgSize;
        }

        *getMsgSizePtr() = getMsgSize() - getCharBytes() + s.size();

        memcpy(getChar(), s.c_str(), s.size());

        *(getCharBytesPtr()) = s.size();
    }

    /**
     *  Get pointer to tag
     */
    TagType* getTagPtr()
    {
        TagType* p = (TagType*)(m_entireMsg + sizeof(SizeType) + sizeof(ActionType));

        return p;
    }

    /**
     *  Get tag value
     */
    TagType getTagVal()
    {
        TagType *p = getTagPtr();
        return *p;
    }

    /**
     *  Set tag
     */
    void    setTag(TagType tag)
    {
        TagType *p = getTagPtr();
        *p = tag;
    }
};

#endif
