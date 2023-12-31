//
//  HMDWPCapture.m
//  Pods
//
//  Created by 白昆仑 on 2020/4/9.
//

#import "HMDWPCapture.h"
#import "HMDTimeSepc.h"
#import "HMDSessionTracker.h"

@implementation HMDWPCapture

+ (HMDWPCapture *)captureCurrentBacktraceWithSkippedDepth:(NSUInteger)depth {
    HMDWPCapture *capture = [[HMDWPCapture alloc] init];
    HMDThreadBacktrace *bt = [HMDThreadBacktrace backtraceOfThread:[HMDThreadBacktrace currentThread] symbolicate:NO skippedDepth:depth+1 suspend:NO];
    if (bt) {
        capture.backtraces = @[bt];
    }
    
    return capture;
};

- (instancetype)init {
    self = [super init];
    if (self) {
        _type = HMDWPCaptureExceptionTypeWarning;
        _timestamp = HMD_XNUSystemCall_timeSince1970();
        _inAppTime = _timestamp - [HMDSessionTracker currentSession].timestamp;
    }
    
    return self;
}

@end
