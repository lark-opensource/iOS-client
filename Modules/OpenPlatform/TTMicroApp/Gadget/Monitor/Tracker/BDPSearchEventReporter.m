//
//  BDPSearchEventReporter.m
//  Timor
//
//  Created by 维旭光 on 2019/8/15.
//
//  为搜索服务提供的排序模型埋点上报

#import "BDPSearchEventReporter.h"
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPTracker.h>
#import <OPFoundation/BDPTrackerEvent.h>

@interface BDPSearchEventReporter ()

@property (nonatomic, assign) BOOL isApp; // 是否是小程序
@property (nonatomic, copy) NSString *launchFrom;   // schema launch_from
@property (nonatomic, copy) NSDictionary *commonParams; // 搜索埋点通用参数

@property (nonatomic, assign) NSUInteger startType; // 0冷启动，1热启动
@property (nonatomic, assign) NSUInteger loadTime;  // 启动加载时长
@property (nonatomic, strong) BDPTrackerTimingEvent *timingEvent;

@end

@implementation BDPSearchEventReporter

+ (instancetype)reporterWithCommonParams:(NSDictionary *)commonParams launchFrom:(NSString *)launchFrom isApp:(BOOL)isApp {
    return [[[self class] alloc] initWithCommonParams:commonParams launchFrom:launchFrom isApp:isApp];
}

- (instancetype)initWithCommonParams:(NSDictionary*)commonParams launchFrom:(NSString *)launchFrom isApp:(BOOL)isApp {
    if (self = [super init]) {
        self.commonParams = commonParams ?: [NSDictionary new];
        self.launchFrom = launchFrom;
        self.isApp = isApp;
        self.timingEvent = [BDPTrackerTimingEvent new];
    }
    return self;
}

- (void)eventLoadDetail:(NSUInteger)loadSuccess {
    // 只上报一次
    if ([self needReport]) {
        if (self.loadTime == 0) {
            self.loadTime = self.timingEvent.duration;
            NSDictionary *params = @{
                                     @"group_from": @(2),
                                     @"load_time": @(self.loadTime),
                                     @"start_type": @(self.startType),
                                     @"load_success": @(loadSuccess), // 1|0|2 成功|失败|加载中
                                     @"fail_reason": loadSuccess == 0 ? @"SDK ERROR" : @""
                                     };
            [self _event:BDPTESearchRankLoadDetail params:params];
        }
    }
}

- (void)evnetWarmBootLoadDetail {
    self.startType = 1;
    [self eventLoadDetail:1];
}

- (void)eventStayPage {
    if ([self needReport]) {
        if (self.loadTime == 0) {
            [self eventLoadDetail:2];
        }
        NSUInteger stayTime = self.timingEvent.duration;
        NSDictionary *params = @{
                                 @"group_from": @(2),
                                 @"load_time": @(self.loadTime),
                                 @"stay_time": @(stayTime),
                                 @"read_time": @(stayTime-self.loadTime)
                                 };
        [self _event:BDPTESearchRankStayPage params:params];
    }
}

- (BOOL)needReport {
    return self.isApp && [self isLaunchFromSearch];
}

- (BOOL)isLaunchFromSearch {
    return [self.launchFrom isEqualToString:@"search_result"] || [self.launchFrom isEqualToString:@"toutiao_search"] || [self.launchFrom isEqualToString:@"byte_search"] || [self.launchFrom isEqualToString:@"search_aladdin"];
}

- (void)_event:(NSString *)eventId params:(NSDictionary *)params {
    NSMutableDictionary *innerParams = [self.commonParams mutableCopy];
    if (!BDPIsEmptyDictionary(params)) {
        [innerParams addEntriesFromDictionary:params];
    }
    [BDPTracker event:eventId attributes:innerParams withCommonParams:NO uniqueID:nil];
}

@end
