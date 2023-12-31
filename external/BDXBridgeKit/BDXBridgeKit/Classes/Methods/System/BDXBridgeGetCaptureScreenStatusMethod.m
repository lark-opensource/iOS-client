//
//  BDXBridgeGetCaptureScreenStatusMethod.m
//  BDXBridgeKit-Pods-Aweme
//
//  Created by yihan on 2021/5/7.
//

#import "BDXBridgeGetCaptureScreenStatusMethod.h"

@implementation BDXBridgeGetCaptureScreenStatusMethod

- (NSString *)methodName
{
    return @"x.getCaptureScreenStatus";
}

- (Class)resultModelClass
{
    return BDXBridgeGetCaptureScreenStatusMethodResultModel.class;
}

@end

@implementation BDXBridgeGetCaptureScreenStatusMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"capturing": @"capturing",
    };
}

@end
