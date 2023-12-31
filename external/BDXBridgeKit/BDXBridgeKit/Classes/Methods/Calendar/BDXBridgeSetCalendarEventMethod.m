//
//  BDXBridgeSetCalendarEventMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/15.
//

#import "BDXBridgeSetCalendarEventMethod.h"

@implementation BDXBridgeSetCalendarEventMethod

- (NSString *)methodName
{
    return @"x.setCalendarEvent";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePrivate;
}

- (Class)paramModelClass
{
    return BDXBridgeSetCalendarEventMethodParamModel.class;
}

- (Class)resultModelClass
{
    return BDXBridgeSetCalendarEventMethodResultModel.class;
}

@end

@implementation BDXBridgeSetCalendarEventMethodParamModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _allDay = NO;
    }
    return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"eventID": @"eventID",
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


@implementation BDXBridgeSetCalendarEventMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"eventID": @"eventID",
    };
}

@end
