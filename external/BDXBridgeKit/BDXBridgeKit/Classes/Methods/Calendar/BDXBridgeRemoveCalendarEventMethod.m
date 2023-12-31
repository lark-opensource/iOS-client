//
//  BDXBridgeRemoveCalendarEventMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/15.
//

#import "BDXBridgeRemoveCalendarEventMethod.h"

@implementation BDXBridgeRemoveCalendarEventMethod

- (NSString *)methodName
{
    return @"x.removeCalendarEvent";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePrivate;
}

- (Class)paramModelClass
{
    return BDXBridgeRemoveCalendarEventMethodParamModel.class;
}

@end

@implementation BDXBridgeRemoveCalendarEventMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"eventID": @"eventID",
    };
}

@end
