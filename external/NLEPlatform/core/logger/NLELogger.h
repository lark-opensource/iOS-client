//
// Created by bytedance on 2020/12/11.
//

#ifndef NLELOGGER_NLELOGGER_H
#define NLELOGGER_NLELOGGER_H

#include "nle_export.h"
#include <functional>
#include <cstdarg>
#include <memory>

namespace nle::logger {

    enum class LogLevel
    {
        LEVEL_VERBOSE = 0,  // ASSERT + ERROR + WARNING + INFO + DEBUG + LEVEL_VERBOSE
        LEVEL_DEBUG = 1,    // ASSERT + ERROR + WARNING + INFO + DEBUG
        LEVEL_INFO = 2,     // ASSERT + ERROR + WARNING + INFO
        LEVEL_WARNING = 3,  // ASSERT + ERROR + WARNING
        LEVEL_ERROR = 4,    // ASSERT + ERROR
        LEVEL_ASSERT = 5,   // ASSERT
        LEVEL_OFF = 6,      // nothing
    };

    class NLE_EXPORT_CLASS NLELoggerFunc {
    public:
        virtual ~NLELoggerFunc() = default;
        virtual void onLog(nle::logger::LogLevel level, const char *fmt, va_list ap) = 0;
    };

    class NLE_EXPORT_CLASS NLELoggerListener : public NLELoggerFunc {
    public:
        void onLog(LogLevel level, const char *fmt, va_list ap) override {
            char logBuf[4096] = {};
            vsnprintf(logBuf, sizeof(logBuf), fmt, ap);
            onLog(level, logBuf);
        }

        virtual void onLog(nle::logger::LogLevel level, const char * message) = 0;
    };

    class NLE_EXPORT_CLASS NLELogger {
    public:
        static const NLELogger * obtain();

        void setDelegate(const std::shared_ptr<nle::logger::NLELoggerFunc>& delegate) const {
            _delegate = delegate;
        }
        void setLogLevel(LogLevel level) const {
            _level = level;
        }
        /**
         * VERBOSE
         */
        void v(const char *fmt, ...) const {
            if (LogLevel::LEVEL_VERBOSE < _level) {
                return;
            }
            if (_delegate) {
                va_list params;
                va_start(params, fmt);
                _delegate->onLog(LogLevel::LEVEL_VERBOSE, fmt, params);
                va_end(params);
            }
        }
        /**
         * DEBUG
         */
        void d(const char *fmt, ...) const {
            if (LogLevel::LEVEL_DEBUG < _level) {
                return;
            }
            if (_delegate) {
                va_list params;
                va_start(params, fmt);
                _delegate->onLog(LogLevel::LEVEL_DEBUG, fmt, params);
                va_end(params);
            }
        }
        /**
         * INFO
         */
        void i(const char *fmt, ...) const {
            if (LogLevel::LEVEL_INFO < _level) {
                return;
            }
            if (_delegate) {
                va_list params;
                va_start(params, fmt);
                _delegate->onLog(LogLevel::LEVEL_INFO, fmt, params);
                va_end(params);
            }
        }
        /**
         * WARN
         */
        void w(const char *fmt, ...) const {
            if (LogLevel::LEVEL_WARNING < _level) {
                return;
            }
            if (_delegate) {
                va_list params;
                va_start(params, fmt);
                _delegate->onLog(LogLevel::LEVEL_WARNING, fmt, params);
                va_end(params);
            }
        }
        /**
         * ERROR
         */
        void e(const char *fmt, ...) const {
            if (LogLevel::LEVEL_ERROR < _level) {
                return;
            }
            if (_delegate) {
                va_list params;
                va_start(params, fmt);
                _delegate->onLog(LogLevel::LEVEL_ERROR, fmt, params);
                va_end(params);
            }
        }
        /**
         * What a Terrible Failure: Report a condition that should never happen.
         */
        void wtf(const char *fmt, ...) const {
            if (LogLevel::LEVEL_ASSERT < _level) {
                return;
            }
            if (_delegate) {
                va_list params;
                va_start(params, fmt);
                _delegate->onLog(LogLevel::LEVEL_ASSERT, fmt, params);
                va_end(params);
            }
        }

    private:
        mutable LogLevel _level = LogLevel::LEVEL_WARNING;
        mutable std::shared_ptr<NLELoggerFunc> _delegate;
    };
}

#define LOGGER nle::logger::NLELogger::obtain()

#define Error(fmt, ...) LOGGER->e((fmt), ##__VA_ARGS__)
#define Warn(fmt, ...) LOGGER->w((fmt), ##__VA_ARGS__)
#define Info(fmt, ...) LOGGER->i((fmt), ##__VA_ARGS__)
#define Debug(fmt, ...) LOGGER->d((fmt), ##__VA_ARGS__)
#define Trace(fmt, ...) LOGGER->w((fmt), ##__VA_ARGS__)

#endif //NLELOGGER_NLELOGGER_H
