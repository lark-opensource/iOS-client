//
//  TSPKStatisticEvent.m
//  Indexer
//
//  Created by admin on 2022/2/14.
//

#import "TSPKStatisticEvent.h"

NSString * const TSPKEventTagStatistic = @"Statistic";

@implementation TSPKStatisticEvent

- (NSString *)tag {
    return TSPKEventTagStatistic;
}

+ (instancetype)initWithService:(NSString *)serviceName metric:(NSDictionary *)metric category:(NSDictionary *)category attributes:(NSDictionary *)attributes {
    TSPKStatisticEvent *event = [TSPKStatisticEvent new];
    event.serviceName = serviceName;
    event.metric = metric;
    event.category = category;
    event.attributes = attributes;
    return event;
}

+ (instancetype)initWithMethodName:(NSString *)methodName startedTime:(CFAbsoluteTime)startedTime; {
    TSPKStatisticEvent *event = [TSPKStatisticEvent new];
    event.serviceName = @"tspk_perf";
    event.metric = @{methodName: @((CFAbsoluteTimeGetCurrent() - startedTime) * 1000)};
    return event;
}

@end
