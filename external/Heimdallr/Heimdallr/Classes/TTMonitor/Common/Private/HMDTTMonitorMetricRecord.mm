//
//  HMDTTMonitorMetricRecord.m
//  Heimdallr
//
//  Created by joy on 2018/3/27.
//

#import "HMDTTMonitorMetricRecord.h"
#import "HMDSessionTracker.h"

@implementation HMDTTMonitorMetricRecord

+ (NSString *)tableName {
    return @"TTMetricEvent";
}

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}
#pragma mark - getter

+ (instancetype)newRecord
{
    HMDTTMonitorMetricRecord *record = [[self alloc] init];
    
    record.timestamp = [[NSDate date] timeIntervalSince1970];
    record.sessionID = [HMDSessionTracker currentSession].sessionID;
    record.inAppTime = [HMDSessionTracker currentSession].timeInSession;
    
    return record;
}

@end




