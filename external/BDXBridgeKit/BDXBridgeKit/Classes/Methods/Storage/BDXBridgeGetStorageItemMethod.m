//
//  BDXBridgeGetStorageItemMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/20.
//

#import "BDXBridgeGetStorageItemMethod.h"

@implementation BDXBridgeGetStorageItemMethod

- (NSString *)methodName
{
    return @"x.getStorageItem";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePublic;
}

- (Class)paramModelClass
{
    return BDXBridgeGetStorageItemMethodParamModel.class;
}

- (Class)resultModelClass
{
    return BDXBridgeGetStorageItemMethodResultModel.class;
}

@end

@implementation BDXBridgeGetStorageItemMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"key": @"key",
    };
}

@end

@implementation BDXBridgeGetStorageItemMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"data": @"data",
    };
}

@end
