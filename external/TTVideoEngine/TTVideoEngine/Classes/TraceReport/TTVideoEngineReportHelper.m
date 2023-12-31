//
//  TTVideoEngineReportHelper.m
//  TTVideoEngine
//
//  Created by haocheng on 2021/1/11.
//

#import "TTVideoEngineReportHelper.h"
#import "TTVideoEngineEventManager.h"
#import <BDTrackerProtocol/BDTrackerProtocol+CustomEvent.h>

@implementation TTVideoEngineReportHelper

+ (instancetype)sharedManager {
    static TTVideoEngineReportHelper *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TTVideoEngineReportHelper alloc] init];
    });
    return manager;
}

- (void)autoReportEventlogIfNeededV1:(TTVideoEngineEventManager *)eventManager {
    if (!self.enableAutoReportLog) return;
    NSArray *dics = [eventManager popAllEvents];
    int64_t uniqueKey = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    for (NSDictionary *dict in dics) {
        NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithDictionary:dict];
        [tmpDict setValue:@(uniqueKey) forKey:@"log_id"];
        [BDTrackerProtocol trackLogDataEvent:tmpDict];
    }
}

- (void)autoReportEventlogIfNeededV1WithParams:(NSDictionary *)params {
    if (!self.enableAutoReportLog) return;
    int64_t uniqueKey = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithDictionary:params];
    [tmpDict setValue:@(uniqueKey) forKey:@"log_id"];
    [BDTrackerProtocol trackLogDataEvent:tmpDict];
}

- (void)autoReportEventlogIfNeededV2WithEventName:(NSString *)eventName
                                           params:(NSDictionary *)params {
    if (!self.enableAutoReportLog) return;
    int64_t uniqueKey = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithDictionary:params];
    [tmpDict setValue:@(uniqueKey) forKey:@"log_id"];
    [BDTrackerProtocol eventV3:eventName params:tmpDict];
}

@end
