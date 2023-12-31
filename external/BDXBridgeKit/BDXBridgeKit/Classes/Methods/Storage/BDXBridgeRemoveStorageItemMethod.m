//
//  BDXBridgeRemoveStorageItemMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/20.
//

#import "BDXBridgeRemoveStorageItemMethod.h"

@implementation BDXBridgeRemoveStorageItemMethod

- (NSString *)methodName
{
    return @"x.removeStorageItem";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePublic;
}

- (Class)paramModelClass
{
    return BDXBridgeRemoveStorageItemMethodParamModel.class;
}

@end

@implementation BDXBridgeRemoveStorageItemMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"key": @"key",
    };
}

@end
