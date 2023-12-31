//
//  BDXBridgeReportMonitorLogMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/30.
//

#import "BDXBridgeReportMonitorLogMethod.h"

@implementation BDXBridgeReportMonitorLogMethod

- (NSString *)methodName
{
    return @"x.reportMonitorLog";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePublic;
}

- (Class)paramModelClass
{
    return BDXBridgeReportMonitorLogMethodParamModel.class;
}

@end

@implementation BDXBridgeReportMonitorLogMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"logType": @"logType",
        @"service": @"service",
        @"status": @"status",
        @"value": @"value",
    };
}

@end
