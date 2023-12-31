//
//  BDPTracker+BDPLoadService.m
//  Timor
//
//  Created by 傅翔 on 2019/7/24.
//

#import <UIKit/UIKit.h>

#import "BDPTracker+BDPLoadService.h"
#import <OPFoundation/BDPTracker+Private.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <OPFoundation/BDPUniqueID.h>
#import <ECOInfra/BDPLog.h>

#import <objc/runtime.h>
#import <OPFoundation/NSUUID+BDPExtension.h>

#define POINTS_LIMIT 50
#define ADD_CPU_TIME_POINTS_COUNT (POINTS_LIMIT / 2)

@interface BDPLoadTimelinePoints : NSObject

@property (nonatomic, strong) BDPUniqueID *uniqueId;
@property (nonatomic, copy) NSMutableArray<NSDictionary *> *points;

@property (nonatomic, readonly) NSString *pointsJSON;

@property (nonatomic, assign) int groupIdx;

@end

@implementation BDPTracker (BDPLoadService)

- (void)monitorLoadTimelineWithName:(NSString *)name extra:(NSDictionary *)extra uniqueId:(BDPUniqueID *)uniqueId {
    [self monitorLoadTimelineWithName:name extra:extra date:nil uniqueId:uniqueId];
}

// 文档: https://bytedance.feishu.cn/space/doc/doccnZlC5heOR6Fwc3VbJW1vE4b#
- (void)monitorLoadTimelineWithName:(NSString *)name extra:(NSDictionary *)extra date:(NSDate *)date uniqueId:(BDPUniqueID *)uniqueId {
    if (!name.length || ![uniqueId isKindOfClass:[BDPUniqueID class]]) {
        return;
    }
    NSDate *time = [date isKindOfClass:[NSDate class]] ? date : [NSDate date];
    [self executeBlkInTaskQueue:^{
        [self addLoadTimelinePointWithName:name extra:extra date:time cpuTime:0 uniqueId:uniqueId];
    }];
}

- (void)monitorLoadTimelineWithName:(NSString *)name extra:(NSDictionary *)extra date:(NSDate *)date cpuTime:(int64_t)cpuTime uniqueId:(BDPUniqueID *)uniqueId {
    if (!name.length || ![uniqueId isKindOfClass:[BDPUniqueID class]]) {
        return;
    }
    NSDate *time = [date isKindOfClass:[NSDate class]] ? date : [NSDate date];
    [self executeBlkInTaskQueue:^{
        [self addLoadTimelinePointWithName:name extra:extra date:time cpuTime:cpuTime uniqueId:uniqueId];
    }];
}

- (void)monitorLoadTimelineWithJSONPoints:(NSString *)jsonPoints
                                 uniqueId:(BDPUniqueID *)uniqueId {
    if (!jsonPoints.length || ![uniqueId isKindOfClass:[BDPUniqueID class]] || !uniqueId) {
        return;
    }
    [self executeBlkInTaskQueue:^{
        NSString *lifecycleId = self.lifecycleIdsDict[uniqueId];
        BDPLoadTimelinePoints *tlPoints = [self loadTimelinePointsForLifecycleId:lifecycleId];
        if (tlPoints) {
            int64_t cpuTime = CACurrentMediaTime() * 1000;
            [[self class] monitorService:@"mp_load_timeline"
                                   extra:@{
                                           @"points": jsonPoints,
                                           @"unique_id": lifecycleId,
                                           @"index": @(tlPoints.groupIdx++),
                                           @"cpu_time": @(cpuTime),
                                           }
                    uniqueID:uniqueId];
        }
    }];
}

- (void)addLoadTimelinePointWithName:(NSString *)name extra:(NSDictionary *)extra date:(NSDate *)date cpuTime:(int64_t)cpuTime uniqueId:(BDPUniqueID *)uniqueId {
    NSString *lifecycleId = self.lifecycleIdsDict[uniqueId];
    BDPLoadTimelinePoints *tlPoints = [self loadTimelinePointsForLifecycleId:lifecycleId];
    if (!tlPoints) {
        return;
    }
    int64_t cpu_time = cpuTime;
    if (cpu_time <= 0 && tlPoints.points.count % ADD_CPU_TIME_POINTS_COUNT == 0) {
        cpu_time = CACurrentMediaTime() * 1000.0;
    }
    [tlPoints.points addObject:({
        NSMutableDictionary *point = [NSMutableDictionary dictionary];
        
        if (cpu_time > 0) {
            NSMutableDictionary *mExtra = [extra mutableCopy] ?: [NSMutableDictionary dictionary];
            mExtra[@"cpu_time"] = @(cpu_time);
            extra = [mExtra copy];
        }
        
        int64_t timestamp = [date timeIntervalSince1970] * 1000.0;
        point[@"name"] = name;
        point[@"timestamp"] = @(timestamp);
        point[@"extra"] = extra.count ? [extra JSONRepresentation] : @"";
        BDPLogTagInfo(@"Timeline", @"addLoadTimelinePoint %@", point);
        point;
    })];
    tlPoints.uniqueId = uniqueId;
    if (tlPoints.points.count >= POINTS_LIMIT) {
        [self flushLoadTimelineWithUniqueId:uniqueId];
    }
}

- (void)flushLoadTimelineWithUniqueId:(BDPUniqueID *)uniqueId {
    if (![uniqueId isKindOfClass:[BDPUniqueID class]] || !uniqueId) {
        return;
    }
    [self executeBlkInTaskQueue:^{
        NSString *lifecycleId = self.lifecycleIdsDict[uniqueId];
        BDPLoadTimelinePoints *tlPoints = [self loadTimelinePointsForLifecycleId:lifecycleId];
        if (tlPoints.points.count) {
            [self monitorLoadTimelineWithJSONPoints:tlPoints.pointsJSON uniqueId:tlPoints.uniqueId];
            [tlPoints.points removeAllObjects];
        }
    }];
}

#pragma mark -
- (void)generateLifecycleIdIfNeededForUniqueId:(BDPUniqueID *)uniqueId {
    if (!uniqueId) {
        return;
    }
    [self executeBlkInTaskQueue:^{
        if (!self.lifecycleIdsDict[uniqueId]) {
            self.lifecycleIdsDict[uniqueId] = [NSUUID bdp_timestampUUIDString];
        }
    }];
}

- (void)removeLifecycleIdWithUniqueId:(BDPUniqueID *)uniqueId {
    if (!uniqueId) {
        return;
    }
    [self executeBlkInTaskQueue:^{
        NSString *lifecycleId = self.lifecycleIdsDict[uniqueId];
        self.lifecycleIdsDict[uniqueId] = nil;
        [self removePointsForLifecycleId:lifecycleId];
    }];
}

#pragma mark -
- (NSMutableDictionary<NSString *, BDPLoadTimelinePoints *> *)loadTimelinePointsDict {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (!dict) {
        dict = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

- (BDPLoadTimelinePoints *)loadTimelinePointsForLifecycleId:(NSString *)lifecycleId {
    if (!lifecycleId) {
        return nil;
    }
    NSMutableDictionary *pointsDict = [self loadTimelinePointsDict];
    BDPLoadTimelinePoints *points = pointsDict[lifecycleId];
    if (!points) {
        points = [[BDPLoadTimelinePoints alloc] init];
        pointsDict[lifecycleId] = points;
    }
    return points;
}

- (void)removePointsForLifecycleId:(NSString *)lifecycleId {
    if (!lifecycleId) {
        return;
    }
    [self loadTimelinePointsDict][lifecycleId] = nil;
}

@end

@implementation BDPLoadTimelinePoints
- (NSString *)pointsJSON {
    return _points.count ? [_points JSONRepresentation] : nil;
}

- (NSMutableArray<NSDictionary *> *)points {
    if (!_points) {
        _points = [[NSMutableArray<NSDictionary *> alloc] init];
    }
    return _points;
}
@end
