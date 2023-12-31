//
//  HMDBacktraceLog.m
//  AppleCrashLog
//
//  Created by 谢俊逸 on 8/3/2018.
//

#import "HMDBacktraceLog.h"
#import "HMDThreadBacktrace+Private.h"
#import "HMDLog.h"


@interface HMDBacktraceLog()
{
}
@end

@implementation HMDBacktraceLog
+ (NSString *)backtraceLogStringWithBacktraceInfo:(HMDThreadBacktrace *)backtraceInfo
{
    // thread name
    NSMutableString *backtrace = [NSMutableString stringWithFormat:@"Thread %lu name:  %@\n", (unsigned long)backtraceInfo.threadIndex, backtraceInfo.name];

    if (backtraceInfo.crashed == YES) {
        [backtrace appendFormat:@"Thread %lu Crashed:\n", (unsigned long)backtraceInfo.threadIndex];
    }
    else {
        [backtrace appendFormat:@"Thread %lu:\n", (unsigned long)backtraceInfo.threadIndex];
    }
    // frames
    for (HMDThreadBacktraceFrame* frame in backtraceInfo.stackFrames) {
        NSString *addFramePreamble = [NSString stringWithFormat:FMT_TRACE_PREAMBLE, (int)frame.stackIndex, frame.imageName ? frame.imageName.UTF8String : "NULL", frame.address];

        // image address + frame.address - frame.symbolAddress
        NSString *unsymbolicated = [NSString stringWithFormat:FMT_TRACE_UNSYMBOLICATED,frame.imageAddress, frame.address - frame.imageAddress];
        
        NSString *symbolicated = [NSString stringWithFormat:FMT_TRACE_SYMBOLICATED, (frame.symbolName && frame.symbolName.length > 0) ? frame.symbolName : nil, frame.address - frame.symbolAddress];

        [backtrace appendFormat:@"%@ %@ (%@)\n", addFramePreamble, unsymbolicated, symbolicated];
    }
    [backtrace appendFormat:@"\n\n"];
    return backtrace;
}



@end
