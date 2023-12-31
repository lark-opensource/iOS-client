//
//  HMDBacktraceLog.h
//  AppleCrashLog
//
//  Created by 谢俊逸 on 8/3/2018.
//

#import <Foundation/Foundation.h>
#import "HMDThreadBacktrace.h"

@interface HMDBacktraceLog : NSObject
+ (NSString * _Nonnull)backtraceLogStringWithBacktraceInfo:(HMDThreadBacktrace* _Nonnull)backtraceInfo;
@end

