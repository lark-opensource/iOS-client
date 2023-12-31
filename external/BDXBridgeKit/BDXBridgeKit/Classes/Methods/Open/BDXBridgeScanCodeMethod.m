//
//  BDXBridgeScanCodeMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeScanCodeMethod.h"

@implementation BDXBridgeScanCodeMethod

- (NSString *)methodName
{
    return @"x.scanCode";
}

- (Class)paramModelClass
{
    return BDXBridgeScanCodeMethodParamModel.class;
}

- (Class)resultModelClass
{
    return BDXBridgeScanCodeMethodResultModel.class;
}

@end

@implementation BDXBridgeScanCodeMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"cameraOnly": @"cameraOnly",
        @"closeCurrent": @"closeCurrent",
    };
}

@end

@implementation BDXBridgeScanCodeMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"result": @"result",
    };
}

@end
