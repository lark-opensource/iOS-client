//
// Created by wangchengyi.1 on 2021/4/7.
//

#ifndef DavinciLogger_h
#define DavinciLogger_h

#include <functional>
#include <memory>
#include <stdio.h>
#include <stdarg.h>
#include "DAVResourceProtocol.h"

namespace davinci {
    namespace logger {
        enum class DAV_EXPORT DAVLogLevel {
            LEVEL_VERBOSE = 0,  // ERROR + WARNING + INFO + DEBUG + LEVEL_VERBOSE
            LEVEL_DEBUG = 1,    // ERROR + WARNING + INFO + DEBUG
            LEVEL_INFO = 2,     // ERROR + WARNING + INFO
            LEVEL_WARNING = 3,  // ERROR + WARNING
            LEVEL_ERROR = 4,    // ERROR
            LEVEL_OFF = 5,      // nothing
        };

        class DAV_EXPORT DAVLoggerFunc {
        public:
            virtual ~DAVLoggerFunc() = default;

            virtual void onLog(davinci::logger::DAVLogLevel level, const char *fmt, va_list ap) = 0;
        };

        class DAV_EXPORT DAVLoggerListener : public DAVLoggerFunc {
        public:
            void onLog(DAVLogLevel level, const char *fmt, va_list ap) override {
                char logBuf[4096] = {};
                vsprintf(logBuf, fmt, ap);
                onLog(level, logBuf);
            }

            virtual void onLog(davinci::logger::DAVLogLevel level, const char *message) = 0;
        };

        class DAV_EXPORT DAVLogger {
        public:
            static const DAVLogger *obtain();

            void setDelegate(const std::shared_ptr<davinci::logger::DAVLoggerFunc> &delegate) const {
                _delegate = delegate;
            }

            void setLogLevel(DAVLogLevel level) const {
                _level = level;
            }

            void v(const char *fmt, ...) const {
                if (DAVLogLevel::LEVEL_VERBOSE < _level) {
                    return;
                }
                if (_delegate) {
                    va_list params;
                    va_start(params, fmt);
                    _delegate->onLog(DAVLogLevel::LEVEL_VERBOSE, fmt, params);
                    va_end(params);
                }
            }

            void d(const char *fmt, ...) const {
                if (DAVLogLevel::LEVEL_DEBUG < _level) {
                    return;
                }
                if (_delegate) {
                    va_list params;
                    va_start(params, fmt);
                    _delegate->onLog(DAVLogLevel::LEVEL_DEBUG, fmt, params);
                    va_end(params);
                }
            }

            void i(const char *fmt, ...) const {
                if (DAVLogLevel::LEVEL_INFO < _level) {
                    return;
                }
                if (_delegate) {
                    va_list params;
                    va_start(params, fmt);
                    _delegate->onLog(DAVLogLevel::LEVEL_INFO, fmt, params);
                    va_end(params);
                }
            }

            void w(const char *fmt, ...) const {
                if (DAVLogLevel::LEVEL_WARNING < _level) {
                    return;
                }
                if (_delegate) {
                    va_list params;
                    va_start(params, fmt);
                    _delegate->onLog(DAVLogLevel::LEVEL_WARNING, fmt, params);
                    va_end(params);
                }
            }

            void e(const char *fmt, ...) const {
                if (DAVLogLevel::LEVEL_ERROR < _level) {
                    return;
                }
                if (_delegate) {
                    va_list params;
                    va_start(params, fmt);
                    _delegate->onLog(DAVLogLevel::LEVEL_ERROR, fmt, params);
                    va_end(params);
                }
            }

        private:
            mutable DAVLogLevel _level = DAVLogLevel::LEVEL_WARNING;
            mutable std::shared_ptr<DAVLoggerFunc> _delegate;
        };
    }
}

#define LOGGER davinci::logger::DAVLogger::obtain()

#endif //DavinciLogger_h
