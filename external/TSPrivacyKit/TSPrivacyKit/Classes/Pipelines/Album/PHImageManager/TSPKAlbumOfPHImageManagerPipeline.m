//
//  TSPKAlbumOfPHImageManagerPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKAlbumOfPHImageManagerPipeline.h"
#import <Photos/PHImageManager.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation PHImageManager (TSPrivacyKitAlbum)

+ (void)tspk_album_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKAlbumOfPHImageManagerPipeline class] clazz:self];
}


- (PHImageRequestID)tspk_album_requestImageForAsset:(PHAsset *)asset targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(nullable PHImageRequestOptions *)options resultHandler:(void (^)(UIImage *_Nullable result, NSDictionary *_Nullable info))resultHandler
{
    NSString *method = NSStringFromSelector(@selector(requestImageForAsset:targetSize:contentMode:options:resultHandler:));
    NSString *className = [TSPKAlbumOfPHImageManagerPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKAlbumOfPHImageManagerPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return PHInvalidImageRequestID;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[[TSPKCacheEnv shareEnv] get:api] intValue];
        }
        PHImageRequestID originResult = [self tspk_album_requestImageForAsset:asset targetSize:targetSize contentMode:contentMode options:options resultHandler:resultHandler];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:@(originResult)];
        return originResult;
    } else {
        return [self tspk_album_requestImageForAsset:asset targetSize:targetSize contentMode:contentMode options:options resultHandler:resultHandler];
    }
}

- (PHImageRequestID)tspk_album_requestImageDataAndOrientationForAsset:(PHAsset *)asset options:(nullable PHImageRequestOptions *)options resultHandler:(void (^)(NSData *_Nullable imageData, NSString *_Nullable dataUTI, CGImagePropertyOrientation orientation, NSDictionary *_Nullable info))resultHandler
{
    NSString *method = NSStringFromSelector(@selector(requestImageDataAndOrientationForAsset:options:resultHandler:));
    NSString *className = [TSPKAlbumOfPHImageManagerPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKAlbumOfPHImageManagerPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return PHInvalidImageRequestID;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[[TSPKCacheEnv shareEnv] get:api] intValue];
        }
        PHImageRequestID originResult = [self tspk_album_requestImageDataAndOrientationForAsset:asset options:options resultHandler:resultHandler];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:@(originResult)];
        return originResult;
    } else {
        return [self tspk_album_requestImageDataAndOrientationForAsset:asset options:options resultHandler:resultHandler];
    }
}

- (PHImageRequestID)tspk_album_requestLivePhotoForAsset:(PHAsset *)asset targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(nullable PHLivePhotoRequestOptions *)options resultHandler:(void (^)(PHLivePhoto *__nullable livePhoto, NSDictionary *__nullable info))resultHandler
API_AVAILABLE(ios(9.1)){
    NSString *method = NSStringFromSelector(@selector(requestLivePhotoForAsset:targetSize:contentMode:options:resultHandler:));
    NSString *className = [TSPKAlbumOfPHImageManagerPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKAlbumOfPHImageManagerPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return PHInvalidImageRequestID;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[[TSPKCacheEnv shareEnv] get:api] intValue];
        }
        PHImageRequestID originResult = [self tspk_album_requestLivePhotoForAsset:asset targetSize:targetSize contentMode:contentMode options:options resultHandler:resultHandler];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:@(originResult)];
        return originResult;
    } else {
        return [self tspk_album_requestLivePhotoForAsset:asset targetSize:targetSize contentMode:contentMode options:options resultHandler:resultHandler];
    }
}

- (PHImageRequestID)tspk_album_requestPlayerItemForVideo:(PHAsset *)asset options:(nullable PHVideoRequestOptions *)options resultHandler:(void (^)(AVPlayerItem *__nullable playerItem, NSDictionary *__nullable info))resultHandler
{
    NSString *method = NSStringFromSelector(@selector(requestPlayerItemForVideo:options:resultHandler:));
    NSString *className = [TSPKAlbumOfPHImageManagerPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKAlbumOfPHImageManagerPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return PHInvalidImageRequestID;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[[TSPKCacheEnv shareEnv] get:api] intValue];
        }
        PHImageRequestID originResult = [self tspk_album_requestPlayerItemForVideo:asset options:options resultHandler:resultHandler];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:@(originResult)];
        return originResult;
    } else {
        return [self tspk_album_requestPlayerItemForVideo:asset options:options resultHandler:resultHandler];
    }
}

- (PHImageRequestID)tspk_album_requestExportSessionForVideo:(PHAsset *)asset options:(nullable PHVideoRequestOptions *)options exportPreset:(NSString *)exportPreset resultHandler:(void (^)(AVAssetExportSession *__nullable exportSession, NSDictionary *__nullable info))resultHandler
{
    NSString *method = NSStringFromSelector(@selector(requestExportSessionForVideo:options:exportPreset:resultHandler:));
    NSString *className = [TSPKAlbumOfPHImageManagerPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKAlbumOfPHImageManagerPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return PHInvalidImageRequestID;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[[TSPKCacheEnv shareEnv] get:api] intValue];
        }
        PHImageRequestID originResult = [self tspk_album_requestExportSessionForVideo:asset options:options exportPreset:exportPreset resultHandler:resultHandler];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:@(originResult)];
        return originResult;
    } else {
        return [self tspk_album_requestExportSessionForVideo:asset options:options exportPreset:exportPreset resultHandler:resultHandler];
    }
}

- (PHImageRequestID)tspk_album_requestAVAssetForVideo:(PHAsset *)asset options:(nullable PHVideoRequestOptions *)options resultHandler:(void (^)(AVAsset *__nullable asset, AVAudioMix *__nullable audioMix, NSDictionary *__nullable info))resultHandler
{
    NSString *method = NSStringFromSelector(@selector(requestAVAssetForVideo:options:resultHandler:));
    NSString *className = [TSPKAlbumOfPHImageManagerPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKAlbumOfPHImageManagerPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return PHInvalidImageRequestID;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[[TSPKCacheEnv shareEnv] get:api] intValue];
        }
        PHImageRequestID originResult = [self tspk_album_requestAVAssetForVideo:asset options:options resultHandler:resultHandler];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:@(originResult)];
        return originResult;
    } else {
        return [self tspk_album_requestAVAssetForVideo:asset options:options resultHandler:resultHandler];
    }
}

@end

@implementation TSPKAlbumOfPHImageManagerPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineAlbumOfPHImageManager;
}

+ (NSString *)dataType {
    return TSPKDataTypeAlbum;
}

+ (NSString *)stubbedClass
{
  return @"PHImageManager";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    NSArray *methods = @[
        NSStringFromSelector(@selector(requestImageForAsset:targetSize:contentMode:options:resultHandler:)),
        NSStringFromSelector(@selector(requestImageDataAndOrientationForAsset:options:resultHandler:)),
        NSStringFromSelector(@selector(requestPlayerItemForVideo:options:resultHandler:)),
        NSStringFromSelector(@selector(requestExportSessionForVideo:options:exportPreset:resultHandler:)),
        NSStringFromSelector(@selector(requestAVAssetForVideo:options:resultHandler:))
    ];
    NSMutableArray *methodWithLevel = [methods mutableCopy];
    if (@available(iOS 9.1, *)) {
        [methodWithLevel addObject:NSStringFromSelector(@selector(requestLivePhotoForAsset:targetSize:contentMode:options:resultHandler:))];
    }
    
    return [methodWithLevel copy];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [PHImageManager tspk_album_preload];
    });
}

@end
