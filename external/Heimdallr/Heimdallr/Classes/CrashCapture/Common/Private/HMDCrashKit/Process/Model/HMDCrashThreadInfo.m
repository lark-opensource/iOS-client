//
//  HMDCrashThreadInfo.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import "HMDCrashThreadInfo.h"

@implementation HMDCrashThreadInfo

- (void)updateWithDictionary:(NSDictionary *)dict
{
    [super updateWithDictionary:dict];
    
    self.crashed = [dict hmd_boolForKey:@"crashed"];
    self.stackTrace = [dict hmd_arrayForKey:@"stacktrace"];
    
    self.registers = [HMDCrashRegisters objectWithDictionary:[dict hmd_dictForKey:@"registers"]];
}

- (void)generateFrames:(HMDImageOpaqueLoader *)imageLoader
{
    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:self.stackTrace.count];
    [self.stackTrace enumerateObjectsUsingBlock:^(NSNumber *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        HMDCrashFrameInfo *frame = [HMDCrashFrameInfo frameInfoWithAddr:obj.unsignedIntegerValue imageLoader:imageLoader];
        [frames hmd_addObject:frame];
    }];
    self.frames = frames;
}

- (NSString *)threadName
{
    if (_threadName.length > 0) {
        return _threadName;
    }
    if (self.queueName.length > 0) {
        return self.queueName;
    }
    if (self.pthreadName.length > 0) {
        return self.pthreadName;
    }
    return @"(null)";
}

@end
