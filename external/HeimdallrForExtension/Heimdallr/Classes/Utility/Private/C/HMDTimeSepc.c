//
//  HMDTimeSepc.m
//  AFgzipRequestSerializer
//
//  Created by sunrunwang on 2019/7/11.
//

#include "HMDTimeSepc.h"
#include <sys/sysctl.h>

#ifndef MICROSEC_PER_SEC
#define MICROSEC_PER_SEC 1000000ul
#endif

#ifndef DEBUG_ELSE
#ifdef DEBUG
#define DEBUG_ELSE else __builtin_trap();
#else
#define DEBUG_ELSE
#endif
#endif
#ifndef DEBUG_ASSERT
#ifdef DEBUG
#define DEBUG_ASSERT(x) if(!(x)) DEBUG_POINT
#else
#define DEBUG_ASSERT(x)
#endif
#endif
#ifndef DEBUG_POINT
#ifdef DEBUG
#define DEBUG_POINT __builtin_trap();
#else
#define DEBUG_POINT
#endif
#endif

void HMD_timespec_getCurrent(struct timespec *ts) {
    if(ts == NULL) return;
    struct timeval tv;
    gettimeofday(&tv, NULL);
    ts->tv_sec = tv.tv_sec;
    ts->tv_nsec = tv.tv_usec * 1000ul;
}

void HMD_timespec_offset(struct timespec *ts, time_t sec, long nanosec) {
    if(ts == NULL) return;
    
    if(ts->tv_nsec > LONG_MAX - nanosec) return;
    long add_sec = (ts->tv_nsec + nanosec) / NSEC_PER_SEC;
    long re_nano = (ts->tv_nsec + nanosec) % NSEC_PER_SEC;
    time_t new_sec = ts->tv_sec + add_sec + sec;
    ts->tv_sec = new_sec;
    ts->tv_nsec = re_nano;
}

void HMD_timespec_offset_from_timeval(struct timespec * ts, struct timeval * tv) {
    if(ts == NULL)
        return;
    
    long add_sec = 0;
    ts->tv_nsec = ts->tv_nsec + tv->tv_usec * NSEC_PER_USEC;
    if (ts->tv_nsec > NSEC_PER_SEC) {
        ts->tv_nsec = ts->tv_nsec % NSEC_PER_SEC;
        add_sec = 1;
    }
    
    ts->tv_sec = ts->tv_sec + tv->tv_sec + add_sec;
}

void HMD_timespec_from_interval(struct timespec * ts, CFTimeInterval interval) {
    double sec;
    double frac = modf(interval, &sec);
    ts->tv_sec = (__darwin_time_t)sec;
    ts->tv_nsec = (long)(frac * NSEC_PER_SEC);
}

void HMD_timeval_from_interval(struct timeval * ts, CFTimeInterval interval) {
    double sec;
    double frac = modf(interval, &sec);
    ts->tv_sec = (__darwin_time_t)sec;
    ts->tv_usec = (__darwin_suseconds_t)(frac * USEC_PER_SEC);
}

struct timespec HMD_CFTimeInterval_to_timespec(CFTimeInterval interval) {
    double sec;
    double frac = modf(interval, &sec);
    return (struct timespec){.tv_sec = sec, .tv_nsec = frac * NSEC_PER_SEC};
}

CFTimeInterval HMD_timespec_to_CFTimeInterval(struct timespec ts) {
    return ts.tv_sec + (CFTimeInterval) ts.tv_nsec / NSEC_PER_SEC;
}

struct timespec HMD_timespec_getTimeSinceNow(CFTimeInterval internval) {
    struct timespec result;
    struct timespec offset = HMD_CFTimeInterval_to_timespec(internval);
    HMD_timespec_getCurrent(&result);
    HMD_timespec_offset(&result, offset.tv_sec, offset.tv_nsec);
    return result;
}

CFTimeInterval HMD_timespec_differ(struct timespec ts1, struct timespec ts2) {
    if(ts1.tv_sec >= 0 && ts2.tv_sec >= 0 && ts1.tv_nsec >= 0 && ts1.tv_nsec >= 0) {
        int64_t  sec = ts1.tv_sec  - ts2.tv_sec;
        int64_t nsec = ts1.tv_nsec - ts2.tv_nsec;
        CFTimeInterval nsec_to_sec = (CFTimeInterval) nsec / NSEC_PER_SEC;
        return sec + nsec_to_sec;
    }
    DEBUG_ELSE
    return -1.0;
}

struct timespec HMD_timespec_create(time_t sec, long nanosec) {
    DEBUG_ASSERT(nanosec < NSEC_PER_SEC)
    return (struct timespec){.tv_sec = sec, .tv_nsec = nanosec};
}

CFTimeInterval HMD_XNUSystemCall_timeSince1970(void) {
    struct timeval tv;
    if(!gettimeofday(&tv, NULL)) {
        return tv.tv_sec + ( (CFTimeInterval)tv.tv_usec / MICROSEC_PER_SEC);
    }
    return - 1.0;
}
