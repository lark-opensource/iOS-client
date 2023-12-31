//
//  BDXBridgeGetCalendarEventMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/15.
//

#import "BDXBridgeGetCalendarEventMethod.h"

@implementation BDXBridgeGetCalendarEventMethod

- (NSString *)methodName
{
    return @"x.getCalendarEvent";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypeSecure;
}

- (Class)paramModelClass
{
    return BDXBridgeGetCalendarEventMethodParamModel.class;
}

- (Class)resultModelClass
{
    return BDXBridgeGetCalendarEventMethodResultModel.class;
}

@end

@implementation BDXBridgeGetCalendarEventMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"eventID": @"eventID",
    };
}

@end

@implementation BDXBridgeGetCalendarEventMethodResultModel

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
