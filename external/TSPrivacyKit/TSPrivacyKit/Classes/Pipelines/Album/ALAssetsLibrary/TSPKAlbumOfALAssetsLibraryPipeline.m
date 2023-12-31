//
//  TSPKAlbumOfALAssetsLibraryPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKAlbumOfALAssetsLibraryPipeline.h"
#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
#import "NSObject+TSAddition.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"
#import "TSPKPipelineSwizzleUtil.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
@implementation ALAssetsLibrary (TSPrivacyKitAlbum)

+ (void)tspk_album_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKAlbumOfALAssetsLibraryPipeline class] clazz:self];
}

- (instancetype)tspk_album_init {
    NSString *method = NSStringFromSelector(@selector(init));
    NSString *className = [TSPKAlbumOfALAssetsLibraryPipeline stubbedClass];
    
    TSPKHandleResult *result = [TSPKAlbumOfALAssetsLibraryPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        ALAssetsLibrary *originResult = [self tspk_album_init];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_album_init];
    }
}

@end
#pragma clang diagnostic pop

#endif

@implementation TSPKAlbumOfALAssetsLibraryPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineAlbumOfALAssetsLibrary;
}

+ (NSString *)dataType {
    return TSPKDataTypeAlbum;
}

+ (NSString *)stubbedClass
{
    return @"ALAssetsLibrary";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
    return @[
        NSStringFromSelector(@selector(init))
    ];
#else
    return [NSArray array];
#endif
}

+ (void)preload
{
#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [ALAssetsLibrary tspk_album_preload];
#pragma clang diagnostic pop
    });
#endif
}

@end
