//
//  BDXBridgeGetStorageInfoMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/20.
//

#import "BDXBridgeGetStorageInfoMethod.h"

@implementation BDXBridgeGetStorageInfoMethod

- (NSString *)methodName
{
    return @"x.getStorageInfo";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePublic;
}

- (Class)resultModelClass
{
    return BDXBridgeGetStorageInfoResultModel.class;
}

@end

@implementation BDXBridgeGetStorageInfoResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"keys": @"keys",
    };
}

@end
