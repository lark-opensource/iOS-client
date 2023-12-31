//
//  BDXBridgeSetStorageItemMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/20.
//

#import "BDXBridgeSetStorageItemMethod.h"

@implementation BDXBridgeSetStorageItemMethod

- (NSString *)methodName
{
    return @"x.setStorageItem";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePublic;
}

- (Class)paramModelClass
{
    return BDXBridgeSetStorageItemMethodParamModel.class;
}

@end

@implementation BDXBridgeSetStorageItemMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"key": @"key",
        @"data": @"data",
    };
}

@end
