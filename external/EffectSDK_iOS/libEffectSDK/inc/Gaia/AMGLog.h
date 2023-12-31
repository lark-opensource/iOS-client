/**
 * @file AMGLog.h
 * @author wangze (wangze.happy@bytedance.com)
 * @brief Log system
 * @version 10.20.0
 * @date 2019-12-18
 * @copyright Copyright (c) 2019
 */
#ifndef AELog_h
#define AELog_h

#include "Gaia/AMGPrerequisites.h"
#include "Gaia/AMGSharePtr.h"
#include "Gaia/AMGThreadPool.h"
#include <future>
#include <mutex>
#include <thread>
#include <time.h>
#include <stdarg.h>

NAMESPACE_AMAZING_ENGINE_BEGIN

/// internal
inline std::string _aeformat(const char* fmt, va_list args)
{
    char szBuffer[AE_LOG_MESSAGE_MAXSIZE] = {0};
    vsnprintf(szBuffer, AE_LOG_MESSAGE_MAXSIZE - 1, fmt, args);
    std::string strRet = szBuffer;
    return strRet;
}

/// internal
inline std::string _aeformat(const char* fmt, ...)
{
    char szBuffer[AE_LOG_MESSAGE_MAXSIZE] = {0};
    va_list args;
    va_start(args, fmt);
    vsnprintf(szBuffer, AE_LOG_MESSAGE_MAXSIZE - 1, fmt, args);
    va_end(args);
    std::string strRet = szBuffer;
    return strRet;
}

/// internal
inline const char* _aeLogLevelName(int dLevel)
{
    switch (dLevel)
    {
        case static_cast<int>(AMGLogLevelType::AMGLOG_ERROR):
            return TT("ERROR");

        case static_cast<int>(AMGLogLevelType::AMGLOG_WARNING):
            return TT("WARNING");

        case static_cast<int>(AMGLogLevelType::AMGLOG_SYSTEM):
            return TT("SYSTEM");

        case static_cast<int>(AMGLogLevelType::AMGLOG_DEBUG):
            return TT("DEBUG");

        case static_cast<int>(AMGLogLevelType::AMGLOG_INFO):
            return TT("INFO");

        case static_cast<int>(AMGLogLevelType::AMGLOG_VERBOSE):
            return TT("VERBOSE");

        default:
            return TT("?");
    }
}

/**
 * @brief Log system
 */
class GAIA_LIB_EXPORT AELogSystem
{
public:
    /**
     * @brief Get instance of log system
     * @return instance of log system
     */
    static AELogSystem* instance();

    /**
     * @brief Print log function
     * @param pszFile log file
     * @param dLine line
     * @param dLevel log level
     * @param pszTag log tag
     * @param pszFormat log string format
     * @param args arguments
     */
    void PrintV(const char* pszFile,
                int dLine,
                int dLevel,
                const char* pszTag,
                const char* pszFormat,
                va_list args);

    /**
     * @brief Set log level
     * @param backend log backend, to file or console
     * @param level log level
     */
    void SetLogLevel(int backend, int level);

    /**
     * @brief Set the log file path
     * @param name file path
     */
    void SetLogFilePath(const std::string& name);

    /**
     * @brief Set log sync mode
     * @param sync sync mode or not
     */
    void SetLogSync(bool sync);

    /**
     * @brief Set the coustom Print Functor object
     *
     * @param f Set to nullptr to print to the console by default
     */
    void SetPrintFunc(const std::function<void(const char*, bool)>& f);
    /**
     * @brief Get the Print Functor object
     *
     * @return std::function<void(const char*, bool)>
     */
    const std::function<void(const char*, bool)>& GetPrintFunc();

    /**
     * @brief Set the log file function caller
     * @param f functor
     */
    void SetLogFileFuncCaller(const std::function<void(int, const char*)>& f);

    /**
     * @brief Get the log file function caller
     * @return functor
     */
    const std::function<void(int, const char*)> GetLogFileFuncCaller();

    /**
     * @brief Get the log thread pool
     * @return Log Thread Pool
     */
    SharePtr<ThreadPool>& GetLogThreadPool();

private:
    AELogSystem();
    virtual ~AELogSystem();

private:
    static AELogSystem* s_instance;
    static std::mutex mMutex;

    int mConsoleLevel;
    // int mFileLevel;
    bool mbSync = true;
    std::string mLogFilePath;

    SharePtr<ThreadPool> mThreadPool;

    // log print function
    std::function<void(const char*, bool)> m_printFunc = nullptr;

    std::function<void(int, const char*)> m_logFileFuncCaller = nullptr;
    std::mutex m_callerMutex;
};

NAMESPACE_AMAZING_ENGINE_END

#endif // AELog_h
