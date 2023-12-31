//
//  BDXBridgePrefetchMethod.m
//  BDXBridgeKit
//
//  Created by David on 2021/4/22.
//

#import "BDXBridgePrefetchMethod.h"

@implementation BDXBridgePrefetchMethod

- (NSString *)methodName
{
    return @"__prefetch";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypeProtected;
}

- (BDXBridgeEngineType)engineTypes
{
    return BDXBridgeEngineTypeWeb | BDXBridgeEngineTypeLynx;
}

- (Class)paramModelClass
{
    return BDXBridgePrefetchMethodParamModel.class;
}

- (Class)resultModelClass
{
    return BDXBridgePrefetchMethodResultModel.class;
}

@end

@implementation BDXBridgePrefetchMethodParamModel

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

@implementation BDXBridgePrefetchMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"cached": @"cached",
        @"raw": @"raw"
    };
}

@end
