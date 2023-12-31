//
//  TSPKAlbumOfPHAssetPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKAlbumOfPHAssetPipeline.h"
#import <Photos/PHAsset.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation PHAsset (TSPrivacyKitAlbum)

+ (void)tspk_album_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKAlbumOfPHAssetPipeline class] clazz:self];
}

+ (PHFetchResult<PHAsset *> *)tspk_album_fetchAssetsWithOptions:(nullable PHFetchOptions *)options
{
    NSString *method = NSStringFromSelector(@selector(fetchAssetsWithOptions:));
    NSString *className = [TSPKAlbumOfPHAssetPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKAlbumOfPHAssetPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        PHFetchResult<PHAsset *> *originResult = [self tspk_album_fetchAssetsWithOptions:options];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    }
    return [self tspk_album_fetchAssetsWithOptions:options];
}

+ (PHFetchResult<PHAsset *> *)tspk_album_fetchAssetsWithMediaType:(PHAssetMediaType)mediaType options:(nullable PHFetchOptions *)options
{
    NSString *method = NSStringFromSelector(@selector(fetchAssetsWithMediaType:options:));
    NSString *className = [TSPKAlbumOfPHAssetPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKAlbumOfPHAssetPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        PHFetchResult<PHAsset *> *originResult = [self fetchAssetsWithMediaType:mediaType options:options];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    }
    return [self tspk_album_fetchAssetsWithMediaType:mediaType options:options];
}

@end

@implementation TSPKAlbumOfPHAssetPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineAlbumOfPHAsset;
}

+ (NSString *)dataType {
    return TSPKDataTypeAlbum;
}

+ (NSString *)stubbedClass
{
  return @"PHAsset";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return @[
        NSStringFromSelector(@selector(fetchAssetsWithOptions:)),
        NSStringFromSelector(@selector(fetchAssetsWithMediaType:options:))
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
        [PHAsset tspk_album_preload];
    });
}

@end
