/*
 * =====================================================================================
 *
 *       Filename:  utils.cpp
 *
 *    Description:
 *
 *        Version:  1.0
 *        Created:  10/27/2018 02:33:24 PM
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  YOUR NAME (),
 *   Organization:
 *
 * =====================================================================================
 */

#include "utils.h"
#include <memory>
#include <array>
#include <chrono>
#include <thread>
#include <unistd.h>
#include <boost/algorithm/string.hpp>
using namespace std;

String
execSysCall_block(const String& cmd)
{
    array<char, 128> buffer;
    String result;
    shared_ptr<FILE> pipe(popen(cmd.c_str(), "r"), pclose);
    if ( !pipe )
        throw runtime_error("popen() failed");

    while ( !feof(pipe.get()) ) {
        if ( fgets(buffer.data(), 128, pipe.get()) != nullptr )
            result += buffer.data();
    }

    result.erase(result.find('\n'));

    return result;
}

void sleepMilliSec(int num_ms)
{
    std::this_thread::sleep_for(std::chrono::milliseconds(num_ms));
}

vector<String>
splitString(const String& str, const String delimiters)
{
    vector<String> res;
    boost::split(res, str, [delimiters](char c) {
                 for (auto a : delimiters) {
                    if (c == a) return true;
                 }
                 return false;});
    return res;
}

bool
compareStringNoCase(const String& str1, const String& str2)
{
    return boost::iequals(str1,str2);
}
