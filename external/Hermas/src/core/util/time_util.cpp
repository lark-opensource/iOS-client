//
// Created by bytedance on 2020/8/20.
//

#include <chrono>

#include "time_util.h"
#ifdef HERMAS_WIN
#include <windows.h>
#else
#include <sys/time.h>
#endif
#ifdef HERMAS_WIN
static int gettimeofday(struct timeval* tp, void* tzp)
{
    time_t clock;
    struct tm tm;
    SYSTEMTIME wtm;
    GetLocalTime(&wtm);
    tm.tm_year = wtm.wYear - 1900;
    tm.tm_mon = wtm.wMonth - 1;
    tm.tm_mday = wtm.wDay;
    tm.tm_hour = wtm.wHour;
    tm.tm_min = wtm.wMinute;
    tm.tm_sec = wtm.wSecond;
    tm.tm_isdst = -1;
    clock = mktime(&tm);
    tp->tv_sec = clock;
    tp->tv_usec = wtm.wMilliseconds * 1000;
    return (0);
}
#endif

using namespace hermas;

int64_t hermas::CurTimeMillis() {
    auto microsecondsUTC = std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::system_clock::now().time_since_epoch()).count() / 1000;
    return microsecondsUTC;
}

int64_t hermas::CurTimeSecond() {
    timeval tv;
    gettimeofday(&tv, nullptr);
    return ((int64_t)tv.tv_sec);
}

int64_t hermas::TenMinutesAgoMillis() {
    return CurTimeMillis() - 10 * 60 * 1000;
}
