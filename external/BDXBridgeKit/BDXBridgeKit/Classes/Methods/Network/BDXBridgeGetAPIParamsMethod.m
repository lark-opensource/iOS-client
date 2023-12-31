//
//  BDXBridgeGetAPIParamsMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/10.
//

#import "BDXBridgeGetAPIParamsMethod.h"

@implementation BDXBridgeGetAPIParamsMethod

- (NSString *)methodName
{
    return @"x.getAPIParams";
}

- (Class)resultModelClass
{
    return BDXBridgeGetAPIParamsMethodResultModel.class;
}

@end

@implementation BDXBridgeGetAPIParamsMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"apiParams": @"apiParams",
    };
}

@end
