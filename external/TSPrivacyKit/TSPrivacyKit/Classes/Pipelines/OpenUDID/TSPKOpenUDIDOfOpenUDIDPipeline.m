//
//  TSPKOpenUDIDOfOpenUDIDPipeline.m
//  Aweme
//
//  Created by ByteDance on 2022/8/16.
//

#import "TSPKOpenUDIDOfOpenUDIDPipeline.h"
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import <OpenUDID/OpenUDID.h>
#import "TSPKPipelineSwizzleUtil.h"

@implementation OpenUDID (TSPrivacyKitOpenUDID)

+ (void)tspk_openudid_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKOpenUDIDOfOpenUDIDPipeline class] clazz:self];
}

+ (NSString *)tspk_openudid_valueWithError:(NSError **)error {
    TSPKHandleResult *result = [TSPKOpenUDIDOfOpenUDIDPipeline handleAPIAccess:NSStringFromSelector(@selector(valueWithError:)) className:[TSPKOpenUDIDOfOpenUDIDPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return @"";
    } else {
        return [self tspk_openudid_valueWithError:error];
    }
}

@end

@implementation TSPKOpenUDIDOfOpenUDIDPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineOpenUDIDOfOpenUDID;
}

+ (NSString *)dataType {
    return TSPKDataTypeOpenUDID;
}

+ (NSString *)stubbedClass
{
    return @"OpenUDID";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return @[
        NSStringFromSelector(@selector(valueWithError:))
    ];
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return nil;
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [OpenUDID tspk_openudid_preload];
    });
}

@end
