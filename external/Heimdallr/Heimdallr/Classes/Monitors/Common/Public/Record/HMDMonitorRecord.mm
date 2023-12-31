//
//  HMDMonitorRecord.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDMonitorRecord.h"
#import "HMDSessionTracker.h"
#import "HMDMonitorRecord+DBStore.h"
#import "HMDDynamicCall.h"
#import "HMDInfo+AppInfo.h"
#import "HMDInfo+SystemInfo.h"
#import "HMDNetworkHelper.h"
#import "HMDUITrackerTool.h"

NSString *const kHMDMonitorLaunchTagIn10sec = @"launch_in_10s";
NSString *const kHMDMonitorLaunchTagIn30sec = @"launch_greater_10s_less_30s";
NSString *const kHMDMonitorLaunchTagInOneMin = @"launch_greater_30s_less_1min";
NSString *const kHMDMonitorLaunchTagGreaterThanOneMin = @"launch_greater_1min";

@implementation HMDMonitorRecord

- (instancetype)init {
    self = [super init];
    if (self) {

    }
    return self;
}

+ (instancetype)newRecord
{
    HMDMonitorRecord *record = [[self alloc] init];
    record.timestamp = [[NSDate date] timeIntervalSince1970];
    record.sessionID = [HMDSessionTracker currentSession].sessionID;
    record.inAppTime = [HMDSessionTracker currentSession].timeInSession;
    id<HMDUITrackerManagerSceneProtocol> monitor = hmd_get_uitracker_manager();
    record.scene = [monitor scene];
    return record;
}

- (void)addInfo {
    self.isReported = NO;
    self.netQualityType = [HMDNetworkHelper currentNetQuality];
    self.business = [HMDInjectedInfo defaultInfo].business ?: @"unknown";
    self.filters = [HMDInjectedInfo defaultInfo].filters;
    self.updateVersionCode = [HMDInfo defaultInfo].buildVersion;
    self.osVersion = [HMDInfo defaultInfo].systemVersion;
    self.appVersion = [HMDInfo defaultInfo].shortVersion;
}

- (NSComparisonResult)compare:(HMDMonitorRecord *)record forKeyPath:(NSString *)keyPath
{
    double currentValue = [[self valueForKeyPath:keyPath] doubleValue];
    double recordValue = [[record valueForKeyPath:keyPath] doubleValue];
    if (currentValue > recordValue) {
        return NSOrderedDescending;
    } else if (currentValue < recordValue){
        return NSOrderedAscending;
    }
    return NSOrderedSame;
}

- (HMDMonitorRecordValue)value {
    return 0;
}

#pragma mark - setter

- (void)setTimestamp:(NSTimeInterval)timestamp{
  _timestamp = timestamp;
}

- (NSDictionary *)reportDictionary
{
    return nil;
}

+ (NSArray *)aggregateDataWithRecords:(NSArray<HMDMonitorRecord *> *)records
{
    return nil;
}

- (BOOL)needAggregate {
    return YES;
}

@end
