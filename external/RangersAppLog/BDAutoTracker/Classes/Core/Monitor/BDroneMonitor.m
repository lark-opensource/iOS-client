//
//  BDroneMonitor.m
//  Drone
//
//  Created by SoulDiver on 2022/4/14.
//

#import "BDroneMonitor.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackMetricsCollector.h"
#import "BDroneDefines.h"
#import "BDAutoTrackMonitorStore.h"

#import "BDroneMonitorDefines.h"
#import "RangersLog.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackEventGenerator.h"
#import "BDAutoTrackBatchService.h"
#import "BDAutoTrackConfig+BDroneMonitor.h"

#pragma mark - BDroneMonitor

@interface BDroneMonitor ()<BDroneModule> {
    BOOL changed;
    dispatch_queue_t monitorQueue;
    void* onMonitorQueueTag;
    
    BDAutoTrackMetricsCollector *collector;
    
    NSMutableDictionary *presetAggregations;
}

@property (nonatomic, weak) BDAutoTrack* tracker;

@end

@implementation BDroneMonitor



- (void)upload
{
    dispatch_block_t block = ^{
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground ) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
            return;
        }
        [self _dataUpload];
    };
    if ([NSThread mainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
    
}

- (void)onEnterForeground
{
    [self _dataUpload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_dataUpload
{
    [self uploadUsingBlock:^BOOL(NSArray * _Nonnull eventsList) {
        return [BDAutoTrackBatchService syncBatch:self.tracker withEvents:eventsList];
    }];
}


- (void)uploadUsingBlock:(BOOL (^)(NSArray *eventsList))block;
{
    NSString *appId = [self.tracker appID];
    RL_DEBUG(self.tracker, @"Monitor",@"Uploading...");
    
    BOOL (^uploadBlock)(NSArray *eventsList) = [block copy];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [[BDAutoTrackMonitorStore sharedStore] dequeue:appId usingBlock:^BOOL(NSArray<BDAutoTrackMetrics *> * _Nonnull metricsList) {
            NSMutableArray *eventList = NSMutableArray.array;
            for (BDAutoTrackMetrics *metrics in metricsList) {
                id event = [metrics transformLogEvent];
                if (event) {
                    [eventList addObject:event];
                }
            }
            RL_DEBUG(self.tracker, @"Monitor",@"upload start...[%d]", [metricsList count]);
            BOOL result = uploadBlock(eventList.copy);
            RL_DEBUG(self.tracker, @"Monitor",@"upload %@...[%d]", result?@"success":@"failure",[metricsList count]);
            return result; 
        }];
    });
}



+ (instancetype)moduleWithTracker:(id<BDroneTracker>)tracker
{
    BDroneMonitor *monitor = [[BDroneMonitor alloc] init];
    monitor.tracker = tracker;
    [monitor commonInit];
    return monitor;
}

- (void)commonInit
{
    if (!self.tracker) {
        return;
    }
    NSString *name = [NSString stringWithFormat:@"volcengine.tracker.monitor.%@",[self.tracker appID]];
    monitorQueue = dispatch_queue_create([name UTF8String], DISPATCH_QUEUE_SERIAL);
    onMonitorQueueTag = &onMonitorQueueTag;
    void *nonNullUnusedPointer = (__bridge void *)self;
    dispatch_queue_set_specific(monitorQueue, onMonitorQueueTag, nonNullUnusedPointer, NULL);
    
    presetAggregations = [NSMutableDictionary dictionary];
    
    collector = [[BDAutoTrackMetricsCollector alloc] initWithApplicationId:[self.tracker appID]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    
    [self async:^{
        [BDAutoTrackMonitorStore sampling:self.tracker.config.monitorSamplingRate];
        [BDAutoTrackMonitorStore sharedStore];
    }];
    
}

- (BDAutoTrackMetricsCollector *)metricsCollector
{
    return collector;
}

- (void)onEnterBackground
{
    
}

- (void)onWillTerminate
{
    dispatch_barrier_sync([self.tracker.eventGenerator executionQueue], ^{
        [self flush:YES];
    });
}

- (void)presetAggregation:(BDroneMonitorAggregation *)aggregation
               forMetrics:(NSString *)metric_
                 category:(NSString *)category_
{
    if (metric_.length == 0
        || category_.length == 0) {
        return;
    }
    NSString *metrics = [metric_ copy];
    NSString *category = [category_ copy];
    
    [self async:^{
        
        NSString *key = [NSString stringWithFormat:@"%@|%@", [category lowercaseString],[metrics lowercaseString]];
        [self->presetAggregations setValue:aggregation forKey:key];
            
    }];
}



- (void)async:(dispatch_block_t)block
{
    if (dispatch_get_specific(onMonitorQueueTag))
        block();
    else
        dispatch_async(monitorQueue, block);
}

- (void)trackMetrics:(NSString *)metrics_
               value:(NSNumber *)val_
            category:(NSString *)category_
          dimensions:(NSDictionary *)dimensions_
{
   
    [self trackMetrics:metrics_ value:val_ category:category_ dimensions:dimensions_ processId:nil];
}

- (void)trackMetrics:(NSString *)metrics_
               value:(NSNumber *)val_
            category:(NSString *)category_
          dimensions:(nullable NSDictionary *)dimensions_
           processId:(nullable NSString *)procId
{
    if (metrics_.length == 0 || category_.length == 0) {
        return;
    }
    NSString *category = [category_ copy];
    NSString *metrics = [metrics_ copy];
    NSNumber *val = [val_ copy];
    NSDictionary *dimensions = [[NSDictionary alloc] initWithDictionary:dimensions_ copyItems:YES];
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
    
    __weak typeof(self) weak_self = self;
    [self async:^{
        
        typeof(weak_self) block_self = weak_self;
        if (!block_self) {
            return;
        }
        NSString *key = [NSString stringWithFormat:@"%@|%@", [category lowercaseString],[metrics lowercaseString]];
        BDroneMonitorAggregation *aggregation = aggregation = [self->presetAggregations objectForKey:key];
        [[block_self metricsCollector] trackMetrics:metrics value:val category:category dimensions:dimensions aggregation:aggregation time:current processId:procId];
        
    }];
}

- (void)flush:(BOOL)sync
{
    if (sync) {
        dispatch_sync(self->monitorQueue, ^{
            [[self metricsCollector] flush];
        });
    } else {
        [self async:^{
            [[self metricsCollector] flush];
        }];
    }
    
}

- (void)endProcess:(NSString *)processId
{
    [[self metricsCollector] endProcess:processId];
}


@end
