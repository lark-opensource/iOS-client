//
//  HMDThreadCPUInfo.m
//  Heimdallr
//
//  Created by bytedance on 2020/5/12.
//

#import "HMDCPUThreadInfo.h"
#import "HMDThreadBacktrace.h"
#import "HMDBinaryImage.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDInfo+DeviceInfo.h"

static NSString *const kHMDCallTreeNodeAddress = @"address";
static NSString *const kHMDCallTreeNodeThreadPriority = @"priority";
static NSString *const kHMDCallTreeNodeImageName = @"image_name";
static NSString *const kHMDCallTreeNodeImageAddress = @"image_address";
static NSString *const kHMDCallTreeNodeWeight = @"weight";
static NSString *const kHMDCallTreeNodeRepeatCount = @"repeat_count";
static NSString *const kHMDCallTreeNodeChildNode = @"child";
static NSString *const kHMDCallTreeNodeCPUUage = @"cpu_usage";
static NSString *const kHMDCallTreeNodeAppNode = @"is_app_node";
static NSString *const kHMDCallTreeNodeThreadName = @"thread_name";
static NSString *const kHMDCallTreeNodeThreadID = @"thread_Id";
static NSString *const kHMDCallTreeNodeThreadBackTrace = @"thread_back_trace";

#pragma mark
#pragma mark--- HMDThreadCPUInfo ---
@implementation HMDCPUThreadInfo

- (NSDictionary *)reportDict {
    NSMutableArray *backTraceArray = [NSMutableArray array];
    for (HMDThreadBacktraceFrame *backTraceFrame in self.backtrace.stackFrames) {
        NSString *address = [NSString stringWithFormat:@"0x%lx", backTraceFrame.address];
        NSString *imageAddress = [NSString stringWithFormat:@"0x%lx", backTraceFrame.imageAddress];
        BOOL isUserNode = [backTraceFrame isAppAddress];
        NSDictionary *backTraceDict = @{
            kHMDCallTreeNodeAddress: address ?: @"",
            kHMDCallTreeNodeImageName: backTraceFrame.imageName ?: @"",
            kHMDCallTreeNodeImageAddress: imageAddress ?: @"",
            kHMDCallTreeNodeWeight: @(self.weight),
            kHMDCallTreeNodeAppNode: @(isUserNode),
        };
        [backTraceArray hmd_addObject:backTraceDict];
    }

    NSDictionary *reportDict = @{
        kHMDCallTreeNodeThreadPriority: @(self.priority),
        kHMDCallTreeNodeThreadID: @(self.thread),
        kHMDCallTreeNodeThreadName: self.backtrace.name ?: @"null",
        kHMDCallTreeNodeWeight: @(self.weight),
        kHMDCallTreeNodeCPUUage: @(self.usage),
        kHMDCallTreeNodeThreadBackTrace: backTraceArray ?: @[]
    };

    return reportDict;
}

@end

