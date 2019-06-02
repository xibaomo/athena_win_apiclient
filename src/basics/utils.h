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
#endif   /* ----- #ifndef _BASIC_UTILS_H_  ----- */
