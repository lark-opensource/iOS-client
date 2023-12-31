//
//  BDXBridgeReportAppLogMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/28.
//

#import "BDXBridgeReportAppLogMethod.h"

@implementation BDXBridgeReportAppLogMethod

- (NSString *)methodName
{
    return @"x.reportAppLog";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePublic;
}

- (Class)paramModelClass
{
    return BDXBridgeReportAppLogMethodParamModel.class;
}

@end

@implementation BDXBridgeReportAppLogMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"eventName": @"eventName",
        @"params": @"params",
    };
}

@end
