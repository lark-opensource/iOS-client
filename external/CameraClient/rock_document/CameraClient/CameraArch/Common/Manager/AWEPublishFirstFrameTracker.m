//
//  AWEPublishFirstFrameTracker.m
//  AWEStudioService-Pods-Aweme
//
//  Created by Leon on 2021/7/12.
//

#import "AWEPublishFirstFrameTracker.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCENVProtocol.h>

NSString * const kAWEPublishEventFirstFrame = @"first_frame_duration";

@interface AWEPublishFirstFrameTracker()

@property (nonatomic, strong) NSMutableDictionary *eventBeginDictionary;
@property (nonatomic, strong) NSMutableDictionary *eventEndDictionary;

@end

@implementation AWEPublishFirstFrameTracker

+ (instancetype)sharedTracker
{
    static id shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc] init];
    });
    return shareInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _eventBeginDictionary = @{}.mutableCopy;
        _eventEndDictionary = @{}.mutableCopy;
    }
    return self;
}

- (void)eventBegin:(NSString *)event
{
    if (!event) {
        return;
    }
    self.eventBeginDictionary[event] = @(CACurrentMediaTime());
}

- (void)eventEnd:(NSString *)event
{
    if (!event) {
        return;
    }
    self.eventEndDictionary[event] = @(CACurrentMediaTime());
}

- (void)finishTrackWithInputData:(AWERepoTrackModel *)trackModel
{
    NSArray *eventArray = @[kAWEPublishEventFirstFrame];
    if (!trackModel || !self.eventEndDictionary[kAWEPublishEventFirstFrame]) {//had tracked or no data
        return;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (NSString *event in eventArray) {
        if (self.eventBeginDictionary[event] && self.eventEndDictionary[event]) {
            NSInteger duration = ([self.eventEndDictionary[event] doubleValue] - [self.eventBeginDictionary[event] doubleValue]) * 1000.f;
            [params setObject:@(duration) forKey:event];
        }
    }
    //track
    if (trackModel.referExtra) {
        [params addEntriesFromDictionary:trackModel.referExtra];
    }
    [params addEntriesFromDictionary:trackModel.commonTrackInfoDic?:@{}];
    // saf test add metric
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCENVProtocol) currentEnv] == ACCENVSaf) {
        NSMutableDictionary *metricExtra = @{}.mutableCopy;
        UInt64 end_time = (UInt64)([[NSDate date] timeIntervalSince1970] * 1000);
        UInt64 start_time = end_time - (UInt64)([params[kAWEPublishEventFirstFrame] integerValue]);
        [metricExtra addEntriesFromDictionary:@{@"metric_name": kAWEPublishEventFirstFrame, @"start_time": @(start_time), @"end_time": @(end_time)}];
        params[@"metric_extra"] = @[metricExtra];
    }
    [ACCTracker() trackEvent:@"tool_performance_publish_first_frame" params:params.copy needStagingFlag:NO];
    //monitor
    params[@"service"] = @"tool_performance_publish_first_frame";
    [ACCMonitor() trackData:params logTypeStr:@"dmt_studio_performance_log"];
    
    //makesure trackEvent tool_performance_publish_first_frame for one time
    [self clear];
}

- (void)clear
{
    [self.eventBeginDictionary removeAllObjects];
    [self.eventEndDictionary removeAllObjects];
}

@end
