//
//  BDXBridgeReadCalendarEventMethod.m
//  BDXBridgeKit
//
//  Created by QianGuoQiang on 2021/4/27.
//

#import "BDXBridgeReadCalendarEventMethod.h"

@implementation BDXBridgeReadCalendarEventMethod

- (NSString *)methodName
{
    return @"x.readCalendarEvent";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePrivate;
}

- (Class)paramModelClass
{
    return BDXBridgeReadCalendarEventMethodParamModel.class;
}

- (Class)resultModelClass
{
    return BDXBridgeReadCalendarEventMethodResultModel.class;
}

@end

@implementation BDXBridgeReadCalendarEventMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"identifier": @"identifier",
    };
}

@end

@implementation BDXBridgeReadCalendarEventMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"startDate": @"startDate",
        @"endDate": @"endDate",
        @"alarmOffset": @"alarmOffset",
        @"allDay": @"allDay",
        @"title": @"title",
        @"notes": @"notes",
        @"location": @"location",
        @"url": @"url",
    };
}

@end
