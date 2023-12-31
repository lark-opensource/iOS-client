//
//  Log.cpp
//  TangramLayoutKit
//
//  Created by qihongye on 2021/4/6.
//

#include <stdio.h>
#include <stdexcept>
#include "Log.h"
#include "TLNodeOptions.h"

namespace TangramLayoutKit {
namespace Log {

#define AVOID_UNUSED(P) (void)(P);
inline
int DefaultLog(TLNodeConstRef node,
                      LogLevel level,
                      const char* format,
                      va_list args) {
#if DEBUG
    AVOID_UNUSED(node);
    switch (level) {
        case LogLevelError:
        case LogLevelFatal:
            return vfprintf(stderr, format, args);
        case LogLevelWarning:
        case LogLevelInfo:
        default:
            return vprintf(format, args);
    }
#else
    return 0;
#endif
}

void Log(TLNodeConstRef node, LogLevel level, const char* format, ...) noexcept {
    va_list args;
    va_start(args, format);
    TLNodeOptions* options = node->getOptions();
    if (options == nullptr) {
        DefaultLog(node, level, format, args);
        va_end(args);
        return;
    }
    switch (level) {
        case LogLevelWarning:
            options->logWarning(node, format, args);
            break;
        case LogLevelError:
            options->logError(node, format, args);
            break;
        case LogLevelFatal:
            options->logFatal(node, format, args);
            break;
        case LogLevelInfo:
        default:
            options->logInfo(node, format, args);
            break;
    }
    va_end(args);
}

int DefaultLogInfo(TLNodeConstRef node, const char* format, va_list args) {
    return DefaultLog(node, LogLevelInfo, format, args);
}

int DefaultLogWarning(TLNodeConstRef node, const char* format, va_list args) {
    return DefaultLog(node, LogLevelWarning, format, args);
}

int DefaultLogError(TLNodeConstRef node, const char* format, va_list args) {
    return DefaultLog(node, LogLevelError, format, args);
}

int DefaultLogFatal(TLNodeConstRef node, const char* format, va_list args) {
    return DefaultLog(node, LogLevelFatal, format, args);
}

}
}

void assertWithLogicMessage(const char* message) {
    throw std::logic_error(message);
}
