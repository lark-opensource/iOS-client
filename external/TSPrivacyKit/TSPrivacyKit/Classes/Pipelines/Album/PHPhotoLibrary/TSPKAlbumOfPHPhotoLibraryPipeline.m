//
//  TSPKAlbumOfPHPhotoLibraryPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKAlbumOfPHPhotoLibraryPipeline.h"
#import "NSObject+TSAddition.h"
#import "TSPKPipelineSwizzleUtil.h"
#import <Photos/PHPhotoLibrary.h>

@implementation PHPhotoLibrary (TSPrivacyKitAlbum)

+ (void)tspk_album_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKAlbumOfPHPhotoLibraryPipeline class] clazz:self];
}

- (void)tspk_registerChangeObserver:(id<PHPhotoLibraryChangeObserver>)observer
{
    TSPKHandleResult *result = [TSPKAlbumOfPHPhotoLibraryPipeline handleAPIAccess:NSStringFromSelector(@selector(registerChangeObserver:)) className:[TSPKAlbumOfPHPhotoLibraryPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return;
    } else {
        [self tspk_registerChangeObserver:observer];
    }
}


+ (void)tspk_album_requestAuthorization:(void (^)(PHAuthorizationStatus))handler
{
    TSPKHandleResult *result = [TSPKAlbumOfPHPhotoLibraryPipeline handleAPIAccess:NSStringFromSelector(@selector(requestAuthorization:)) className:[TSPKAlbumOfPHPhotoLibraryPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (handler) {
            handler(PHAuthorizationStatusDenied);
        }
    } else {
        [self tspk_album_requestAuthorization:handler];
    }
}

+ (void)tspk_album_requestAuthorizationForAccessLevel:(PHAccessLevel)accessLevel handler:(void (^)(PHAuthorizationStatus))handler API_AVAILABLE(ios(14)) {
    TSPKHandleResult *result = [TSPKAlbumOfPHPhotoLibraryPipeline handleAPIAccess:NSStringFromSelector(@selector(requestAuthorizationForAccessLevel:handler:)) className:[TSPKAlbumOfPHPhotoLibraryPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (handler) {
            handler(PHAuthorizationStatusDenied);
        }
    } else {
        [self tspk_album_requestAuthorizationForAccessLevel:accessLevel handler:handler];
    }
}

@end

@implementation TSPKAlbumOfPHPhotoLibraryPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineAlbumOfPHPhotoLibrary;
}

+ (NSString *)dataType {
    return TSPKDataTypeAlbum;
}

+ (NSString *)stubbedClass
{
  return @"PHPhotoLibrary";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    NSArray *method = @[
        NSStringFromSelector(@selector(requestAuthorization:))
    ];
    NSMutableArray *methodWithLevel = [method mutableCopy];
    if (@available(iOS 14.0, *)) {
        [methodWithLevel addObject:NSStringFromSelector(@selector(requestAuthorizationForAccessLevel:handler:))];
    }
    return [methodWithLevel copy];
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(registerChangeObserver:))
    ];
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [PHPhotoLibrary tspk_album_preload];
    });
}

@end
