//
//  TSPKAlbumOfPHAssetCollectionPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKAlbumOfPHAssetCollectionPipeline.h"
#import "NSObject+TSAddition.h"
#import <Photos/PHCollection.h>
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"
#import "TSPKPipelineSwizzleUtil.h"


@implementation PHAssetCollection (TSPrivacyKitAlbum)

+ (void)tspk_album_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKAlbumOfPHAssetCollectionPipeline class] clazz:self];
}

+ (PHFetchResult<PHAssetCollection *> *)tspk_album_fetchAssetCollectionsWithType:(PHAssetCollectionType)type subtype:(PHAssetCollectionSubtype)subtype options:(nullable PHFetchOptions *)options
{
    NSString *method = NSStringFromSelector(@selector(fetchAssetCollectionsWithType:subtype:options:));
    NSString *className = [TSPKAlbumOfPHAssetCollectionPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKAlbumOfPHAssetCollectionPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        PHFetchResult<PHAssetCollection *> *originResult = [self tspk_album_fetchAssetCollectionsWithType:type subtype:subtype options:options];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    }
    return [self tspk_album_fetchAssetCollectionsWithType:type subtype:subtype options:options];
}

+ (PHFetchResult<PHCollection *> *)tspk_album_fetchTopLevelUserCollectionsWithOptions:(nullable PHFetchOptions *)options
{
    NSString *method = NSStringFromSelector(@selector(fetchTopLevelUserCollectionsWithOptions:));
    NSString *className = [TSPKAlbumOfPHAssetCollectionPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKAlbumOfPHAssetCollectionPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        PHFetchResult<PHCollection *> *originResult = [self tspk_album_fetchTopLevelUserCollectionsWithOptions:options];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    }
    return [self tspk_album_fetchTopLevelUserCollectionsWithOptions:options];
}

+ (PHFetchResult<PHAssetCollection *> *)tspk_album_fetchAssetCollectionsWithLocalIdentifiers:(NSArray<NSString *> *)identifiers options:(nullable PHFetchOptions *)options
{
    NSString *method = NSStringFromSelector(@selector(fetchAssetCollectionsWithLocalIdentifiers:options:));
    NSString *className = [TSPKAlbumOfPHAssetCollectionPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKAlbumOfPHAssetCollectionPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        PHFetchResult<PHAssetCollection *> *originResult = [self tspk_album_fetchAssetCollectionsWithLocalIdentifiers:identifiers options:options];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    }
    return [self tspk_album_fetchAssetCollectionsWithLocalIdentifiers:identifiers options:options];
}
@end

@implementation TSPKAlbumOfPHAssetCollectionPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineAlbumOfPHAssetCollection;
}

+ (NSString *)dataType {
    return TSPKDataTypeAlbum;
}

+ (NSString *)stubbedClass
{
  return @"PHAssetCollection";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return @[
        NSStringFromSelector(@selector(fetchAssetCollectionsWithType:subtype:options:)),
        NSStringFromSelector(@selector(fetchTopLevelUserCollectionsWithOptions:)),
        NSStringFromSelector(@selector(fetchAssetCollectionsWithLocalIdentifiers:options:))
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
        [PHAssetCollection tspk_album_preload];
    });
}

@end
