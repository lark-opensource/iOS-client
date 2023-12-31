//
//  PNSBacktraceImpl.m
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/20.
//

#import "PNSBacktraceImpl.h"
#import "PNSServiceCenter+private.h"
#import <Heimdallr/HMDCrashTracker.h>
#import <Heimdallr/HMDCrashConfig.h>
#import <Heimdallr/HMDAppleBacktracesLog.h>
#import <Heimdallr/HMDAppleBacktracesParameter.h>
#import <Heimdallr/HMDUserExceptionTracker.h>
#import <Heimdallr/HMDThreadBacktraceFrame.h>

PNS_BIND_DEFAULT_SERVICE(PNSBacktraceImpl, PNSBacktraceProtocol)

static thread_t PNSThread_self() {
    thread_t thread_self = mach_thread_self();
    mach_port_deallocate(mach_task_self(), thread_self);
    return (thread_t)thread_self;
}

@implementation PNSBacktraceImpl

- (NSString * _Nullable)formatBacktraces:(NSArray * _Nonnull)backtraces {
    return [HMDAppleBacktracesLog logWithBacktraces:backtraces type:HMDLogUserException exception:nil reason:nil];
}

- (NSArray * _Nullable)getBacktracesWithSkippedDepth:(NSUInteger)skippedDepth
                                      needAllThreads:(BOOL)needAllThreads {
    return [[HMDUserExceptionTracker sharedTracker] getBacktracesWithKeyThread:PNSThread_self() skippedDepth:skippedDepth needAllThreads:needAllThreads];
}

- (void)getFormatBacktracesWithNeedAllThreads:(BOOL)needAllThreads
                                     callback:(void (^ _Nonnull)(BOOL, NSString * _Nonnull))callback {
    HMDAppleBacktracesParameter *parameter = [HMDAppleBacktracesParameter new];
    parameter.needDebugSymbol = NO;
    parameter.logType = HMDLogUserException;
    parameter.needAllThreads = needAllThreads;
    if (!needAllThreads) {
        parameter.keyThread = PNSThread_self();
    }
    
    [HMDAppleBacktracesLog getThreadLogByParameter:parameter
                                          callback:^(BOOL success, NSString * _Nonnull formatBacktraces) {
        callback(success, formatBacktraces);
    }];
}

- (NSArray <NSNumber *> * _Nullable)getCurrentBacktraceAddressesWithSkippedDepth:(NSUInteger)skippedDepth {
    NSArray *backtraces = [self getBacktracesWithSkippedDepth:skippedDepth needAllThreads:NO];
    
    HMDThreadBacktrace *caredBacktrace;
    for (HMDThreadBacktrace *backtrace in backtraces) {
        if (backtrace.crashed) {
            caredBacktrace = backtrace;
            break;
        }
    }
    
    if (!caredBacktrace) {
        return nil;
    }

    NSArray <HMDThreadBacktraceFrame*> *stackFrames = caredBacktrace.stackFrames;
    NSMutableArray *mutableAddresses = [NSMutableArray arrayWithCapacity:stackFrames.count];
    [stackFrames enumerateObjectsUsingBlock:^(HMDThreadBacktraceFrame * _Nonnull stackframe, NSUInteger idx, BOOL * _Nonnull stop) {
        [mutableAddresses addObject:@(stackframe.address)];
    }];

    return mutableAddresses.copy;
}

- (NSArray * _Nullable)mergeBacktracesWithFirst:(NSArray *_Nonnull)firstBacktraces second:(NSArray *_Nonnull)secondBacktraces {
    if (firstBacktraces.count == 0 || secondBacktraces.count == 0) {
        return secondBacktraces;
    }
    
    // only merge cared backtrace
    HMDThreadBacktrace *firstBacktrace;
    HMDThreadBacktrace *secondBacktrace;
    
    for (HMDThreadBacktrace *backtrace in firstBacktraces) {
        if (backtrace.crashed) {
            firstBacktrace = backtrace;
            break;
        }
    }
    
    for (HMDThreadBacktrace *backtrace in secondBacktraces) {
        if (backtrace.crashed) {
            secondBacktrace = backtrace;
            break;
        }
    }
    
    NSMutableArray *result = [NSMutableArray array];
    
    [result addObjectsFromArray:firstBacktrace.stackFrames];
    [result addObjectsFromArray:secondBacktrace.stackFrames];
    
    secondBacktrace.stackFrames = result.copy;
    
    return secondBacktraces;
}

- (vm_address_t)getImageHeaderAddressWithName:(NSString *)name {
    return [HMDThreadBacktrace getImageHeaderAddressWithName:name];
}

- (BOOL)isMultipleAsyncStackTraceEnabled {
    if ([[HMDCrashTracker sharedTracker].config isMemberOfClass:[HMDCrashConfig class]]) {
        HMDCrashConfig *config = (HMDCrashConfig *)[HMDCrashTracker sharedTracker].config;
        return config.enableMultipleAsyncStackTrace;
    }
    return NO;
}

- (BOOL)isSameBacktracesWithFirst:(NSArray * _Nullable)firstBacktraces second:(NSArray * _Nullable)secondBacktraces
{
    HMDThreadBacktrace *firstBacktrace = firstBacktraces.firstObject;
    HMDThreadBacktrace *secondBacktrace = secondBacktraces.firstObject;
    
    NSUInteger firstCount = firstBacktrace.stackFrames.count;
    NSUInteger secondCount = secondBacktrace.stackFrames.count;
    
    if (firstCount != secondCount) {
        return NO;
    }
    
    for (int i = 0; i < firstCount; i++){
        if (firstBacktrace.stackFrames[i].address != secondBacktrace.stackFrames[i].address) {
            return NO;
        }
    }
    
    return YES;
}

@end
