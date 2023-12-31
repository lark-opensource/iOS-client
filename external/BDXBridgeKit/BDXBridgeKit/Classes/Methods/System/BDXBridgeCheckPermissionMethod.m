//
//  BDXBridgeCheckPermissionMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeCheckPermissionMethod.h"
#import "BDXBridgeCustomValueTransformer.h"

@implementation BDXBridgeCheckPermissionMethod

- (NSString *)methodName
{
    return @"x.checkPermission";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePrivate;
}

- (Class)paramModelClass
{
    return BDXBridgeCheckPermissionMethodParamModel.class;
}

- (Class)resultModelClass
{
    return BDXBridgeCheckPermissionMethodResultModel.class;
}

@end

@implementation BDXBridgeCheckPermissionMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"permission": @"permission",
    };
}

+ (NSValueTransformer *)permissionJSONTransformer
{
    return [BDXBridgeCustomValueTransformer enumTransformerWithDictionary:@{
        @"camera": @(BDXBridgePermissionTypeCamera),
        @"microphone": @(BDXBridgePermissionTypeMicrophone),
        @"photoAlbum": @(BDXBridgePermissionTypePhotoAlbum),
        @"vibrate": @(BDXBridgePermissionTypeVibration),
    }];
}

@end

@implementation BDXBridgeCheckPermissionMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"status": @"status",
    };
}

+ (NSValueTransformer *)statusJSONTransformer
{
    return [BDXBridgeCustomValueTransformer enumTransformerWithDictionary:@{
        @"permitted": @(BDXBridgePermissionStatusPermitted),
        @"denied": @(BDXBridgePermissionStatusDenied),
        @"undetermined": @(BDXBridgePermissionStatusUndetermined),
        @"restricted": @(BDXBridgePermissionStatusRestricted),
    }];
}

@end
