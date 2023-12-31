//
//  BDXBridgeReportADLogMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/28.
//

#import "BDXBridgeReportADLogMethod.h"

@implementation BDXBridgeReportADLogMethod

- (NSString *)methodName
{
    return @"x.reportADLog";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePublic;
}

- (Class)paramModelClass
{
    return BDXBridgeReportADLogMethodParamModel.class;
}

@end

@implementation BDXBridgeReportADLogMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"label": @"label",
        @"tag": @"tag",
        @"refer": @"refer",
        @"groupID": @"groupID",
        @"creativeID": @"creativeID",
        @"logExtra": @"logExtra",
        @"extraParams": @"extraParams",
    };
}

@end
