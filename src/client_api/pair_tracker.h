#include <unordered_map>

class PairTracker {
protected:
    PairTracker(){;}
    std::unordered_map<long,long> m_ticketPairs;
    std::unordered_map<String,String> m_strTicketPairs;
public:
    virtual ~PairTracker() {;}

    static PairTracker& getInstance() {
        static PairTracker _ins;
        return _ins;
    }

    void addPair(long tx, long ty) {
        m_ticketPairs[tx] = ty;
        m_ticketPairs[ty] = tx;
    }

    void addPair(String& tx, String& ty) {
        m_strTicketPairs[tx] = ty;
        m_strTicketPairs[ty] = tx;
    }


    long getPairedTicket(long tx) {
        if (m_ticketPairs.find(tx) == m_ticketPairs.end())
            return 0;

        return m_ticketPairs[tx];
    }

    String getPairedTicket(String& tx) {
        if (m_strTicketPairs.find(tx) == m_strTicketPairs.end())
            return "0";

        return m_strTicketPairs[tx];
    }
};
