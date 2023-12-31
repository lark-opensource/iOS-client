//
//  BDXBridgeDeleteCalendarEventMethod.m
//  BDXBridgeKit
//
//  Created by QianGuoQiang on 2021/4/27.
//

#import "BDXBridgeDeleteCalendarEventMethod.h"

@implementation BDXBridgeDeleteCalendarEventMethod

- (NSString *)methodName
{
    return @"x.deleteCalendarEvent";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePrivate;
}

- (Class)paramModelClass
{
    return BDXBridgeDeleteCalendarEventMethodParamModel.class;
}

@end

@implementation BDXBridgeDeleteCalendarEventMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"identifier": @"identifier",
    };
}

@end
