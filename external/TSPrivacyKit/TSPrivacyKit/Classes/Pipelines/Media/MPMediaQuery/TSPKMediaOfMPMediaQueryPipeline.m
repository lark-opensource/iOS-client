//
//  TSPKMediaOfMPMediaQueryPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKMediaOfMPMediaQueryPipeline.h"
#import <MediaPlayer/MPMediaQuery.h>
#import "NSObject+TSAddition.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation MPMediaQuery (TSPrivacyKitMedia)

+ (void)tspk_media_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKMediaOfMPMediaQueryPipeline class] clazz:self];
}

+ (instancetype)tspk_media_init
{
    TSPKHandleResult *result = [TSPKMediaOfMPMediaQueryPipeline handleAPIAccess:NSStringFromSelector(@selector(init)) className:[TSPKMediaOfMPMediaQueryPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    }
    return [self tspk_media_init];
}

@end

@implementation TSPKMediaOfMPMediaQueryPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineMediaOfMPMediaQuery;
}

+ (NSString *)dataType {
    return TSPKDataTypeMedia;
}

+ (NSString *)stubbedClass
{
    return @"MPMediaQuery";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return @[
        NSStringFromSelector(@selector(init))
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
        [MPMediaQuery tspk_media_preload];
    });
}

@end
