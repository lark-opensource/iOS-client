//
//  BDXBridgeRequestMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/28.
//

#import "BDXBridgeRequestMethod.h"

@implementation BDXBridgeRequestMethod

- (NSString *)methodName
{
    return @"x.request";
}

- (Class)paramModelClass
{
    return BDXBridgeRequestMethodParamModel.class;
}

- (Class)resultModelClass
{
    return BDXBridgeRequestMethodResultModel.class;
}

@end

@implementation BDXBridgeRequestMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"url": @"url",
        @"method": @"method",
        @"params": @"params",
        @"header": @"header",
        @"body": @"body",
    };
}

@end

@implementation BDXBridgeRequestMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"httpCode": @"httpCode",
        @"header": @"header",
        @"response": @"response",
    };
}

@end
