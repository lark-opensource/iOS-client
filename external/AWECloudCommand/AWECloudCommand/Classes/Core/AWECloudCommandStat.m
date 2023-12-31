//
//  AWECloudCommandStat.m
//  Pods
//
//  Created by willorfang on 2017/1/23.
//
//

#import "AWECloudCommandStat.h"
#import "AWECloudMemoryUtility.h"
#import "AWECloudCPUUtility.h"
#import "AWECloudDiskUtility.h"
#import "AWECloudHardWireUtility.h"
#import "AWECloudCommandMacros.h"

typedef NS_ENUM(NSUInteger, AWECloudCommandStatType) {
    AWECloudCommandStatTypeAll = 0,
    AWECloudCommandStatTypeStack,
    AWECloudCommandStatTypeResourceUsage,
};

@implementation AWECloudCommandStat

AWE_REGISTER_CLOUD_COMMAND(@"performance")

+ (instancetype)createInstance
{
    return [[self alloc] init];
}

- (void)excuteCommand:(AWECloudCommandModel *)model completion:(AWECloudCommandResultCompletion)completion
{
    AWECloudCommandResult *result = [self _resultWithCommand:model];
    AWESAFEBLOCK_INVOKE(completion, result);
}

- (AWECloudCommandResult *)_resultWithCommand:(AWECloudCommandModel *)model
{
    AWECloudCommandResult *result = [[AWECloudCommandResult alloc] init];
    result.fileName = @"Stat.txt";
    result.fileType = @"json";
    result.commandId = model.commandId;
    result.operateTimestamp = [[NSDate date] timeIntervalSince1970];
    
    // 命令参数解析
    NSDictionary *params = model.params;
    NSInteger type = [params objectForKey:@"type"] ? [[params objectForKey:@"type"] integerValue] : 0;
    
    // data
    NSDictionary *dataDict = nil;
    switch (type) {
        case AWECloudCommandStatTypeStack:
            dataDict = callStackDict();
            break;
        case AWECloudCommandStatTypeResourceUsage:
            dataDict = resourceUsageDict();
            break;
        case AWECloudCommandStatTypeAll:
        default:{
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict addEntriesFromDictionary:callStackDict()];
            [dict addEntriesFromDictionary:resourceUsageDict()];
            dataDict = dict;
        }
            break;
    }
    result.mimeType = @"text/plain";
    result.data = [NSJSONSerialization dataWithJSONObject:dataDict options:NSJSONWritingPrettyPrinted error:nil];
    
    return result;
}

static NSDictionary *resourceUsageDict()
{
    return @{
             @"cpu" : @{
                     @"usage" : @(AWECloudCPUUtility.cpuUsage),
                     },
             @"mem" : @{
                     @"total" : [NSString stringWithFormat:@"%.0f MB", [AWECloudMemoryUtility totalMemory]],
                     @"free" : [NSString stringWithFormat:@"%.0f%%", [AWECloudMemoryUtility freeMemory:YES]],
                     @"used" : [NSString stringWithFormat:@"%.0f%%", [AWECloudMemoryUtility usedMemory:YES]],
                     @"active" : [NSString stringWithFormat:@"%.0f%%", [AWECloudMemoryUtility activeMemory:YES]],
                     @"inactive" : [NSString stringWithFormat:@"%.0f%%", [AWECloudMemoryUtility inactiveMemory:YES]],
                     @"wired" : [NSString stringWithFormat:@"%.0f%%", [AWECloudMemoryUtility wiredMemory:YES]],
                     },
             @"disk" : @{
                     @"total" : [AWECloudDiskUtility diskSpace],
                     @"free" : [AWECloudDiskUtility freeDiskSpace:NO],
                     },
             @"device" : @{
                     @"uptime" : [AWECloudHardWireUtility systemUptime],
                     @"deviceName" : [AWECloudHardWireUtility deviceName],
                     @"systemName" : [AWECloudHardWireUtility systemName],
                     @"systemVersion" : [AWECloudHardWireUtility systemVersion],
                     },
             };
}

static NSDictionary *callStackDict()
{
    __block NSDictionary *result = nil;
    
    static dispatch_group_t group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        group = dispatch_group_create();
    });
    
    dispatch_group_async(group, dispatch_get_main_queue(), ^{
        result = @{
                   @"stack" : [NSThread callStackSymbols],
                   };
    });
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    return result;
}

@end
