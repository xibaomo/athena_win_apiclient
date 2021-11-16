/*
 * =====================================================================================
 *
 *       Filename:  utils.h
 *
 *    Description:  common utilities
 *
 *        Version:  1.0
 *        Created:  10/27/2018 02:31:18 PM
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  YOUR NAME (),
 *   Organization:
 *
 * =====================================================================================
 */

#ifndef  _BASIC_UTILS_H_
#define  _BASIC_UTILS_H_

#include <vector>
#include <chrono>
#include <boost/archive/text_oarchive.hpp>
#include <boost/archive/text_iarchive.hpp>
#include <boost/serialization/vector.hpp>
#include "basics/log.h"
#include "types.h"

/*-----------------------------------------------------------------------------
 *  Sleep in units of ms
 *-----------------------------------------------------------------------------*/
void sleepMilliSec(int num_ms);

/*-----------------------------------------------------------------------------
 *  Split a string
 *-----------------------------------------------------------------------------*/
std::vector<String>
splitString(const String& str, const String delimiters=":");

/**
 * Case-insensitive string comparison
 */

bool
compareStringNoCase(const String& str1, const String& str2);

class Timer {
protected:
    std::chrono::time_point<std::chrono::system_clock> m_start;
public:
    Timer() { m_start = std::chrono::system_clock::now();}
    double getElapsedTime() {
        auto now = std::chrono::system_clock::now();
        std::chrono::duration<double> elapsed = now - m_start;
        return elapsed.count();
    }

};

struct SerializePack {
    std::vector<int>   int32_vec;
    std::vector<float> real32_vec;
    std::vector<double> real64_vec;
    std::vector<std::string> str_vec;
    std::vector<int>   int32_vec1;
    std::vector<float> real32_vec1;
    std::vector<double> real64_vec1;
    std::vector<std::string> str_vec1;
    std::vector<unsigned long> ulong_vec;

    template<class Archive>
    void serialize(Archive & ar, const unsigned int version)
    {
        ar & int32_vec;
        ar & real32_vec;
        ar & real64_vec;
        ar & str_vec;
        ar & int32_vec1;
        ar & real32_vec1;
        ar & real64_vec1;
        ar & str_vec1;
        ar & ulong_vec;
    }
};
inline
std::string serialize(SerializePack& pack) {
    std::stringstream ss;
    boost::archive::text_oarchive oa(ss);
    oa << pack;
    return ss.str();
}
inline void
unserialize(const std::string& str, SerializePack& pack) {
    std::stringstream ss(str);
    boost::archive::text_iarchive ia(ss);
    ia >> pack;
}
#endif   /* ----- #ifndef _BASIC_UTILS_H_  ----- */
