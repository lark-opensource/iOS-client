//
//  BDXBridgeReportALogMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/11.
//

#import "BDXBridgeReportALogMethod.h"
#import "BDXBridgeCustomValueTransformer.h"

@implementation BDXBridgeReportALogMethod

- (NSString *)methodName
{
    return @"x.reportALog";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePrivate;
}

- (Class)paramModelClass
{
    return BDXBridgeReportALogMethodParamModel.class;
}

@end

@implementation BDXBridgeReportALogMethodParamCodePositionModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"file": @"file",
        @"function": @"function",
        @"line": @"line",
    };
}

@end

@implementation BDXBridgeReportALogMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"level": @"level",
        @"message": @"message",
        @"tag": @"tag",
        @"codePosition": @"codePosition",
    };
}

+ (NSValueTransformer *)levelJSONTransformer
{
    return [BDXBridgeCustomValueTransformer enumTransformerWithDictionary:@{
        @"verbose": @(BDXBridgeLogLevelVerbose),
        @"debug": @(BDXBridgeLogLevelDebug),
        @"info": @(BDXBridgeLogLevelInfo),
        @"warn": @(BDXBridgeLogLevelWarn),
        @"error": @(BDXBridgeLogLevelError),
    }];
}

@end
