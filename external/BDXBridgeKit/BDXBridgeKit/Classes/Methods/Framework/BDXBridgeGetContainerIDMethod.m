//
//  BDXBridgeGetContainerIDMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/13.
//

#import "BDXBridgeGetContainerIDMethod.h"

@implementation BDXBridgeGetContainerIDMethod

- (NSString *)methodName
{
    return @"x.getContainerID";
}

- (Class)resultModelClass
{
    return BDXBridgeGetContainerIDMethodResultModel.class;
}

@end

@implementation BDXBridgeGetContainerIDMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"containerID": @"containerID",
    };
}

@end
