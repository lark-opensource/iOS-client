//
//  HMDThreadBacktrace+Private.h
//  Pods
//
//  Created by 白昆仑 on 2020/4/20.
//

#import "HMDThreadBacktrace.h"
#import "hmd_thread_backtrace.h"
#import "HMDThreadBacktraceFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDThreadBacktrace (Private)

+ (NSArray <HMDThreadBacktrace *>*)createBacktraceList:(hmdbt_backtrace_t *)backtraces
                                                  size:(NSInteger)size
                                             keyThread:(thread_t)keyThread
                                           symbolicate:(BOOL)symbolicate;


@end

NS_ASSUME_NONNULL_END
