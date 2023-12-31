//
// Created by zhangyeqi on 2019-11-19.
//

#ifndef CUTSAMEAPP_COMLOGGER_H
#define CUTSAMEAPP_COMLOGGER_H

#include <stdio.h>
#include <iostream>

namespace cut {
    class ComLogger {
    public:
        void d(const char *fmt, ...);

        void i(const char *fmt, ...);

        void w(const char *fmt, ...);

        void e(const char *fmt, ...);
    };
}
extern cut::ComLogger *LOGGER;

namespace cut {

enum Level: int {
    LevelDebug,
    LevelInfo,
    LevelWarning,
    LevelError
};
void log(Level level, const char *file, const char *function, int line, const char *fmt, ...);
}

#define CSLogDebug(format, ...) cut::log(cut::LevelDebug, __FILE__, __FUNCTION__, __LINE__, format, ##__VA_ARGS__);
#define CSLogInfo(format, ...) cut::log(cut::LevelInfo, __FILE__, __FUNCTION__, __LINE__, format, ##__VA_ARGS__);
#define CSLogWarn(format, ...) cut::log(cut::LevelWarning, __FILE__, __FUNCTION__, __LINE__, format, ##__VA_ARGS__);
#define CSLogError(format, ...) cut::log(cut::LevelError, __FILE__, __FUNCTION__, __LINE__, format, ##__VA_ARGS__);


#endif //CUTSAMEAPP_COMLOGGER_H
