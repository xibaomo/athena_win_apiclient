/*
 * =====================================================================================
 *
 *       Filename:  log.h
 *
 *    Description:
 *
 *        Version:  1.0
 *        Created:  10/27/2018 12:26:22 PM
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  YOUR NAME (),
 *   Organization:
 *
 * =====================================================================================
 */

#ifndef  _BASICS_LOG_H_
#define  _BASICS_LOG_H_

#include <boost/log/core.hpp>
#include <boost/log/trivial.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/sinks/text_file_backend.hpp>
#include <boost/log/utility/setup/common_attributes.hpp>
#include <boost/log/utility/setup/file.hpp>
#include <boost/log/sources/severity_logger.hpp>
#include <boost/log/sources/record_ostream.hpp>
#include <boost/log/support/date_time.hpp>
#include <boost/log/utility/setup/console.hpp>
#include <unordered_map>
#include <typeinfo>
#include "types.h"

#define BASE_METHOD_WARN Log(LOG_FATAL) << "Should be implemented in concrete class"

namespace logging = boost::log;
namespace src = boost::log::sources;
namespace sinks = boost::log::sinks;
namespace keywords = boost::log::keywords;

enum LogLevel {
    LOG_FATAL = 0,
    LOG_ERROR,
    LOG_WARNING,
    LOG_INFO,
    LOG_VERBOSE,
    LOG_DEBUG
};

class LogStream
{
private:
    LogLevel m_setLevel;
    LogLevel m_curLevel;
    src::severity_logger < logging::trivial::severity_level > m_lg;
    std::unordered_map<int, ::boost::log::trivial::severity_level> m_lvlDict;
    LogStream()
    {
        m_lvlDict[(int)LogLevel::LOG_FATAL] = logging::trivial::fatal;
        m_lvlDict[(int)LogLevel::LOG_ERROR] = logging::trivial::error;
        m_lvlDict[(int)LogLevel::LOG_WARNING] = logging::trivial::warning;
        m_lvlDict[(int)LogLevel::LOG_INFO] = logging::trivial::info;
        m_lvlDict[(int)LogLevel::LOG_VERBOSE] = logging::trivial::debug;
        m_lvlDict[(int)LogLevel::LOG_DEBUG] = logging::trivial::trace;

        logging::register_simple_formatter_factory<logging::trivial::severity_level, char>("Severity");
//        String logName = "athena_pid" + std::to_string(getpid()) + ".log";
//        logging::add_file_log(keywords::file_name = logName.c_str(),
//                              keywords::auto_flush = true,
//                              keywords::format = "[%TimeStamp%][%ProcessID%][%Severity%]: %Message%"
//                              );

        logging::add_console_log(std::cout, boost::log::keywords::format = "[%TimeStamp%][%Severity%]: %Message%");

        logging::add_common_attributes();
    }
public:
    static LogStream& getInstance()
    {
        static LogStream _instance;
        return _instance;
    }

    void setLogLevel(LogLevel lvl)
    {
        m_setLevel = lvl;
        auto loglvl = m_lvlDict[(int)lvl];

        logging::core::get()->set_filter(logging::trivial::severity >= loglvl);
    }

    LogLevel getLogLevel() { return m_setLevel; }

    void setCurLogLevel(LogLevel lvl)
    {
        m_curLevel = lvl;
    }

    template <typename T>
    LogStream& operator << (const T& msg)
    {
        auto loglvl = m_lvlDict[(int)m_curLevel];
//        BOOST_LOG_STREAM_WITH_PARAMS(::boost::log::trivial::logger::get(), \
//                                     (::boost::log::keywords::severity = loglvl)) << msg << std::endl;
//        BOOST_LOG_SEV(m_lg, loglvl) << msg;
        BOOST_LOG_STREAM_WITH_PARAMS(::boost::log::trivial::logger::get(), \
                (::boost::log::keywords::severity = loglvl)) << msg;
        if ( m_curLevel == LogLevel::LOG_FATAL )
            exit(1);
        return *this;
    }
};

class Logger
{
public:

    Logger(LogLevel lvl)
    {
        auto& logger = LogStream::getInstance();
        logger.setCurLogLevel(lvl);
    }

    static void setLogLevel(LogLevel lvl)
    {
        auto& logger = LogStream::getInstance();
        logger.setLogLevel(lvl);
    }

    static int getLogLevel() {
        auto& logger = LogStream::getInstance();
        return (int)logger.getLogLevel();
    }

    template <typename T>
    Logger& operator << (const T& msg)
    {
        auto& logger = LogStream::getInstance();
        logger << msg;
        return *this;
    }
};

typedef Logger Log;
//extern Logger Log;
#endif   /* ----- #ifndef _BASICS_LOG_H_  ----- */
