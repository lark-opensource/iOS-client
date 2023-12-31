//
//  BDAutoTrackVisualLogger.m
//  RangersAppLog
//
//  Created by bytedance on 7/5/22.
//

#import "BDAutoTrackVisualLogger.h"
#import "RangersLogManager.h"
#import "BDAutoTrackDevLogger.h"

@interface BDAutoTrackVisualLogger ()<RangersLogger>

@property (nonatomic, strong) NSMutableArray *cachedLogs;

@property (nonatomic, strong) NSMutableSet *moduleSet;

@end

@implementation BDAutoTrackVisualLogger


- (void)log:(nonnull RangersLogObject *)log {
    
    if ([self.cachedLogs count] > 999) {
        [self.cachedLogs removeObjectAtIndex:0];
    }
    [self.cachedLogs addObject:log];
    [self.moduleSet addObject:log.module?:@""];
}

- (NSArray<RangersLogObject *> *)currentLogs
{
    __block NSArray *logs;
    dispatch_sync([self queue], ^{
        logs = [self.cachedLogs copy];
    });
    return logs;
}

- (void)didAddLogger
{
    self.cachedLogs = [NSMutableArray arrayWithCapacity:1000];
    self.moduleSet = [NSMutableSet set];
}

- (NSArray<NSString *> *)currentModules
{
    return [self.moduleSet allObjects];
}

- (nonnull dispatch_queue_t)queue {
    static dispatch_queue_t file_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *name = [NSString stringWithFormat:@"volcengine.logger.visual.%p",self];
        file_queue = dispatch_queue_create([name UTF8String], DISPATCH_QUEUE_SERIAL);
    });
    return file_queue;
}

@end
