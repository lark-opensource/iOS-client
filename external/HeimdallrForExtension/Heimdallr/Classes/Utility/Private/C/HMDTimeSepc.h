//
//  HMDTimeSepc.h
//  AFgzipRequestSerializer
//
//  Created by sunrunwang on 2019/7/11.
//

#ifndef HMDTimeSepc_h
#define HMDTimeSepc_h

#import <CoreFoundation/CoreFoundation.h>
#include <sys/time.h>

#ifdef __cplusplus
extern "C" {
#endif

void HMD_timespec_getCurrent(struct timespec * ts);
void HMD_timespec_offset(struct timespec * ts, time_t sec, long nsec);
void HMD_timespec_offset_from_timeval(struct timespec * ts, struct timeval * tv);
void HMD_timespec_from_interval(struct timespec * ts, CFTimeInterval interval);
void HMD_timeval_from_interval(struct timeval * ts, CFTimeInterval interval);
struct timespec HMD_CFTimeInterval_to_timespec(CFTimeInterval interval);
CFTimeInterval HMD_timespec_to_CFTimeInterval(struct timespec ts);
struct timespec HMD_timespec_getTimeSinceNow(CFTimeInterval internval);
CFTimeInterval HMD_timespec_differ(struct timespec ts1, struct timespec ts2);
struct timespec HMD_timespec_create(time_t sec, long nanosec);
CFTimeInterval HMD_XNUSystemCall_timeSince1970(void);
    
#ifdef __cplusplus
}
#endif

#endif /* HMDTimeSepc_h */
