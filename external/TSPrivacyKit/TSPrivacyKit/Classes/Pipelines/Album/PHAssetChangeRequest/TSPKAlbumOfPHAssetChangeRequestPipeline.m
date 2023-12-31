//
//  TSPKAlbumOfPHAssetChangeRequestPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKAlbumOfPHAssetChangeRequestPipeline.h"
#import "NSObject+TSAddition.h"
#import <Photos/PHAssetChangeRequest.h>
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation PHAssetChangeRequest (TSPrivacyKitAlbum)

+ (void)tspk_album_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKAlbumOfPHAssetChangeRequestPipeline class] clazz:self];
}

+ (nullable instancetype)tspk_album_creationRequestForAssetFromImageAtFileURL:(NSURL *)fileURL
{
    NSString *method = NSStringFromSelector(@selector(creationRequestForAssetFromImageAtFileURL:));
    NSString *className = [TSPKAlbumOfPHAssetChangeRequestPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKAlbumOfPHAssetChangeRequestPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        PHAssetChangeRequest *originResult = [self tspk_album_creationRequestForAssetFromImageAtFileURL:fileURL];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    }
    return [self tspk_album_creationRequestForAssetFromImageAtFileURL:fileURL];
}

@end

@implementation TSPKAlbumOfPHAssetChangeRequestPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineAlbumOfPHAssetChangeRequest;
}

+ (NSString *)dataType {
    return TSPKDataTypeAlbum;
}

+ (NSString *)stubbedClass
{
  return @"PHAssetChangeRequest";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return @[
        NSStringFromSelector(@selector(creationRequestForAssetFromImageAtFileURL:))
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
        [PHAssetChangeRequest tspk_album_preload];
    });
}

@end
