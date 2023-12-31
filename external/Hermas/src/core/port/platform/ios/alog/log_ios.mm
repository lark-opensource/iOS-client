//
// Created by bytedance on 2020/8/7.
//

#include "log.h"
#include <stdarg.h>
#include "env.h"
#import <BDAlogProtocol/BDAlogProtocol.h>

void logd_ios(const char* tag, const char* msg, ...) {
    if (hermas::IsDebug()) {
        @autoreleasepool {
            va_list pArgList;
            va_start(pArgList, msg);
            unsigned int nLen = 1024 * 100;
            char* szBuffer = (char*)malloc(nLen);
            if (szBuffer == NULL) return;
            vsprintf(szBuffer, msg, pArgList);
            szBuffer[nLen - 1] = 0;
            va_end(pArgList);
            ALOG_PROTOCOL_DEBUG_TAG(tag, szBuffer);
            free(szBuffer);
        }
    }
}

void loge_ios(const char* tag, const char* msg, ...) {
    @autoreleasepool {
        va_list pArgList;
        va_start(pArgList, msg);
        unsigned int nLen = 1024 * 100;
        char* szBuffer = (char*)malloc(nLen);
        if (szBuffer == NULL) return;
        vsprintf(szBuffer, msg, pArgList);
        szBuffer[nLen - 1] = 0;
        va_end(pArgList);
        ALOG_PROTOCOL_ERROR_TAG(tag, szBuffer);
        free(szBuffer);
    }
}

void logi_ios(const char* tag, const char* msg, ...) {
    @autoreleasepool {
        va_list pArgList;
        va_start(pArgList, msg);
        unsigned int nLen = 1024 * 100;
        char* szBuffer = (char*)malloc(nLen);
        if (szBuffer == NULL) return;
        vsprintf(szBuffer, msg, pArgList);
        szBuffer[nLen - 1] = 0;
        va_end(pArgList);
        ALOG_PROTOCOL_INFO_TAG(tag, szBuffer);
        free(szBuffer);
    }
}

void logw_ios(const char* tag, const char* msg, ...) {
    @autoreleasepool {
        va_list pArgList;
        va_start(pArgList, msg);
        unsigned int nLen = 1024 * 100;
        char* szBuffer = (char*)malloc(nLen);
        if (szBuffer == NULL) return;
        vsprintf(szBuffer, msg, pArgList);
        szBuffer[nLen - 1] = 0;
        va_end(pArgList);
        ALOG_PROTOCOL_WARN_TAG(tag, szBuffer);
        free(szBuffer);
    }
}

void logf_ios(const char* tag, const char* msg, ...) {
    @autoreleasepool {
        va_list pArgList;
        va_start(pArgList, msg);
        unsigned int nLen = 1024 * 100;
        char* szBuffer = (char*)malloc(nLen);
        if (szBuffer == NULL) return;
        vsprintf(szBuffer, msg, pArgList);
        szBuffer[nLen - 1] = 0;
        va_end(pArgList);
        ALOG_PROTOCOL_FATAL_TAG(tag, szBuffer);
        free(szBuffer);
    }
}
