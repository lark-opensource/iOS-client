//
//  TSPKCIADOfBDInstallPipeline.m
//  Aweme
//
//  Created by ByteDance on 2022/8/16.
//

#import "TSPKCIADOfBDInstallPipeline.h"
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import <BDInstall/BDInstall.h>
#import "TSPKPipelineSwizzleUtil.h"

@implementation BDInstall (TSPrivacyKitCIAD)

+ (void)tspk_caid_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKCIADOfBDInstallPipeline class] clazz:self];
}

- (NSString *)tspk_caid_caid {
    TSPKHandleResult *result = [TSPKCIADOfBDInstallPipeline handleAPIAccess:@"caid" className:[TSPKCIADOfBDInstallPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return @"";
    } else {
        return [self tspk_caid_caid];
    }
}


- (NSString *)tspk_caid_prevCaid {
    TSPKHandleResult *result = [TSPKCIADOfBDInstallPipeline handleAPIAccess:@"prevCaid" className:[TSPKCIADOfBDInstallPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return @"";
    } else {
        return [self tspk_caid_prevCaid];
    }
}

@end

@implementation TSPKCIADOfBDInstallPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineCIADOfBDInstall;
}

+ (NSString *)dataType {
    return TSPKDataTypeCIAD;
}

+ (NSString *)stubbedClass
{
  return @"BDInstall";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        @"caid",
        @"prevCaid"
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [BDInstall tspk_caid_preload];
    });
}


@end
