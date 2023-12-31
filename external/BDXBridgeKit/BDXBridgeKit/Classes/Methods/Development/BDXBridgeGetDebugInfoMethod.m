//
//  BDXBridgeGetDebugInfoMethod.m
//  BDXBridgeKit
//
//  Created by QianGuoQiang on 2021/5/8.
//

#import "BDXBridgeGetDebugInfoMethod.h"

@implementation BDXBridgeGetDebugInfoMethod

- (NSString *)methodName
{
    return @"x.getDebugInfo";
}

- (BOOL)isDevelopmentMethod
{
    return YES;
}

- (Class)resultModelClass
{
    return BDXBridgeGetDebugInfoMethodResultModel.class;
}

@end

@implementation BDXBridgeGetDebugInfoMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"useBOE": @"useBOE",
        @"boeChannel": @"boeChannel",
        @"usePPE": @"usePPE",
        @"ppeChannel": @"ppeChannel",
    };
}

@end
