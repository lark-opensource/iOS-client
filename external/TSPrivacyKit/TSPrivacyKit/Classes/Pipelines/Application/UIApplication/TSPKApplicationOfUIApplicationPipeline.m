//
//  TSPKApplicationOfUIApplicationPipeline.m
//  Aweme
//
//  Created by ByteDance on 2022/8/16.
//

#import "TSPKApplicationOfUIApplicationPipeline.h"
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation UIApplication (TSPrivacyKitApplication)

+ (void)tspk_application_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKApplicationOfUIApplicationPipeline class] clazz:self];
}

- (BOOL)tspk_application_canOpenURL:(NSURL *)url {
    TSPKHandleResult *result = [TSPKApplicationOfUIApplicationPipeline handleAPIAccess:NSStringFromSelector(@selector(canOpenURL:)) className:[TSPKApplicationOfUIApplicationPipeline stubbedClass] params:@{
        @"url": [url absoluteString] ?: @""
    }];
    if (result.action == TSPKResultActionFuse) {
        return NO;
    } else {
        return [self tspk_application_canOpenURL:url];
    }
}

@end

@implementation TSPKApplicationOfUIApplicationPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineApplicationOfUIApplication;
}

+ (NSString *)dataType {
    return TSPKDataTypeApplication;
}

+ (NSString *)stubbedClass
{
  return @"UIApplication";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(canOpenURL:))
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIApplication tspk_application_preload];
    });
}

@end
