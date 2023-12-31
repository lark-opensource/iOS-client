//
//  BDXBridgeGetMethodListMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/14.
//

#import "BDXBridgeGetMethodListMethod.h"

@implementation BDXBridgeGetMethodListMethod

- (NSString *)methodName
{
    return @"x.getMethodList";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePrivate;
}

- (BOOL)isDevelopmentMethod
{
    return YES;
}

- (Class)resultModelClass
{
    return BDXBridgeGetMethodListMethodResultModel.class;
}

@end

@implementation BDXBridgeGetMethodListMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"methodList": @"methodList",
    };
}

@end
