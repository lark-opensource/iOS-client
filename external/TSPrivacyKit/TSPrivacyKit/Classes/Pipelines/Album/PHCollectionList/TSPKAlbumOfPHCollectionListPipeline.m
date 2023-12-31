//
//  TSPKAlbumOfPHCollectionListPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKAlbumOfPHCollectionListPipeline.h"
#import "NSObject+TSAddition.h"
#import <Photos/PHCollection.h>
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation PHCollectionList (TSPrivacyKitAlbum)

+ (void)tspk_album_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKAlbumOfPHCollectionListPipeline class] clazz:self];
}

+ (PHFetchResult<PHCollection *> *)tspk_album_fetchTopLevelUserCollectionsWithOptions:(nullable PHFetchOptions *)options
{
    NSString *method = NSStringFromSelector(@selector(fetchTopLevelUserCollectionsWithOptions:));
    NSString *className = [TSPKAlbumOfPHCollectionListPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKAlbumOfPHCollectionListPipeline handleAPIAccess:method className:className];
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
@end

@implementation TSPKAlbumOfPHCollectionListPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineAlbumOfPHCollectionList;
}

+ (NSString *)dataType {
    return TSPKDataTypeAlbum;
}

+ (NSString *)stubbedClass
{
  return @"PHCollectionList";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return @[
        NSStringFromSelector(@selector(fetchTopLevelUserCollectionsWithOptions:))
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
        [PHCollectionList tspk_album_preload];
    });
}

@end
