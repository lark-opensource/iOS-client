//
//  HMDThreadBacktraceParameter.m
//  Heimdallr
//
//  Created by wangyinhui on 2021/9/6.
//

#import "HMDThreadBacktraceParameter.h"

@implementation HMDThreadBacktraceParameter

- (instancetype)init
{
    self = [super init];
    if (self) {
        _maxThreadCount = HMD_THREAD_BACKTRACE_MAX_THREAD_COUNT;
        _skippedDepth = 0;
        _suspend = NO;
        _needDebugSymbol = NO;
    }
    return self;
}

@end
