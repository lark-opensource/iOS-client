//
//  ACCToolUIReactTracker.m
//  Indexer
//
//  Created by Leon on 2021/11/10.
//

#import "ACCToolUIReactTracker.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>

NSString * const kAWEUIEventLatestEvent = @"latest_event";

NSString * const kAWEUIEventClickPlus = @"click_plus";
NSString * const kAWEUIEventClickAlbum = @"click_album";
NSString * const kAWEUIEventClickRecord = @"click_record";
NSString * const kAWEUIEventClickTakePicture = @"click_take_picture";
NSString * const kAWEUIEventClickCloseCamera = @"click_close_camera";
NSString * const kAWEUIEventFinishFastRecord = @"finish_fast_record";
NSString * const kAWEUIEventClickRecordNext = @"click_record_next";
NSString * const kAWEUIEventClickBackInEdit = @"click_back_in_edit";
NSString * const kAWEUIEventClickPublishDaily = @"click_publish_daily";
NSString * const kAWEUIEventClickNextInEdit = @"click_next_in_edit";
NSString * const kAWEUIEventClickBackInPublish = @"click_back_in_publish";
NSString * const kAWEUIEventClickPublish = @"click_publish";

#pragma mark - ACCToolUIReactTrackerEventModel

@interface ACCToolUIReactTrackerEventModel:NSObject

@property (nonatomic, copy) NSString *actionName;

@property (nonatomic, assign) double reactDuration; //ms

- (NSDictionary *)getCustomTrackParams;

@end


@implementation ACCToolUIReactTrackerEventModel

- (NSDictionary *)getCustomTrackParams {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:self.actionName forKey:@"action_name"];
    [params setObject:@(self.reactDuration) forKey:@"react_duration"];
    return [params copy];
}

@end

#pragma mark - ACCToolUIReactTracker

@interface ACCToolUIReactTracker()

@property (nonatomic, strong) NSMutableDictionary *pendingDic;

@property (nonatomic, copy) NSString *latestEventName;

@end

@implementation ACCToolUIReactTracker

- (instancetype)init {
    if (self = [super init]) {
        self.pendingDic = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)latestEventName {
    return _latestEventName;
}

- (void)eventBegin:(NSString *)event {
    [self eventBegin:event withExcuting:nil];
}

- (void)eventBegin:(NSString *)event withExcuting:(dispatch_block_t)excuting {
    acc_infra_main_async_safe(^{
        if (event.length <= 0) {
            return;
        }
        ACCBLOCK_INVOKE(excuting);
        self.pendingDic[event] = @(CACurrentMediaTime());
        self.latestEventName = event;
    });
}

- (void)eventEnd:(NSString *)event withParams:(NSDictionary *)params {
    [self eventEnd:event withParams:params excuting:nil];
}

- (void)eventEnd:(NSString *)event withParams:(NSDictionary *)params excuting:(dispatch_block_t)excuting {
    acc_infra_main_async_safe(^{
        NSString *realEvent = event;
        if ([event isEqualToString:kAWEUIEventLatestEvent] && self.latestEventName != nil) {
            realEvent = self.latestEventName;
            self.latestEventName = nil;
        }
        if (realEvent.length <= 0 || [self.pendingDic objectForKey:realEvent] == nil) {
            return;
        }
        ACCBLOCK_INVOKE(excuting);
        NSNumber *endTime = @(CACurrentMediaTime());
        NSNumber *beginTime = [self.pendingDic objectForKey:realEvent] ? : @(0);
        ACCToolUIReactTrackerEventModel *eventModel = [[ACCToolUIReactTrackerEventModel alloc] init];
        eventModel.actionName = realEvent;
        eventModel.reactDuration = (endTime.doubleValue - beginTime.doubleValue) * 1000.f;
        [self startTrackEvent:eventModel params:params];
    });
}

#pragma mark - Private

- (void)startTrackEvent:(ACCToolUIReactTrackerEventModel *)eventModel params:(NSDictionary *)params {
    NSMutableDictionary *mParams = [NSMutableDictionary dictionary];
    [mParams addEntriesFromDictionary:[eventModel getCustomTrackParams]];
    [mParams addEntriesFromDictionary:params ? : @{}];
    //track
    [ACCTracker() trackEvent:@"tool_performance_ui_react_event" params:mParams.copy needStagingFlag:NO];
    //monitor
    mParams[@"service"] = @"tool_performance_ui_react_event";
    [ACCMonitor() trackData:mParams.copy logTypeStr:@"dmt_studio_performance_log"];
}

@end
