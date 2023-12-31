//
//  BDXBridgeCreateCalendarEventMethod.m
//  BDXBridgeKit
//
//  Created by QianGuoQiang on 2021/4/27.
//

#import "BDXBridgeCreateCalendarEventMethod.h"
#import "BDXBridgeCustomValueTransformer.h"

@implementation BDXBridgeCreateCalendarEventMethod

- (NSString *)methodName
{
    return @"x.createCalendarEvent";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePrivate;
}

- (Class)paramModelClass
{
    return BDXBridgeCreateCalendarEventMethodParamModel.class;
}

@end

@implementation BDXBridgeCreateCalendarEventMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"identifier": @"identifier",
        @"repeatFrequency" : @"repeatFrequency",
        @"repeatInterval" : @"repeatInterval",
        @"repeatCount" : @"repeatCount",
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

+ (NSValueTransformer *)repeatFrequencyJSONTransformer
{
    return [BDXBridgeCustomValueTransformer enumTransformerWithDictionary:@{
        @"daily": @(BDXBridgeCreateCalendarEventFrequencyTypeDaily),
        @"weekly": @(BDXBridgeCreateCalendarEventFrequencyTypeWeekly),
        @"monthly": @(BDXBridgeCreateCalendarEventFrequencyTypeMonthly),
        @"yearly": @(BDXBridgeCreateCalendarEventFrequencyTypeYearly),
    }];
}

@end
