//
//  TSPKMediaOfMPMediaLibraryPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKMediaOfMPMediaLibraryPipeline.h"
#import <MediaPlayer/MPMediaLibrary.h>
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation MPMediaLibrary (TSPrivacyKitMedia)

+ (void)tspk_media_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKMediaOfMPMediaLibraryPipeline class] clazz:self];
}

- (void)tspk_media_addItemWithProductID:(NSString *)productID completionHandler:(nullable void (^)(NSArray <__kindof MPMediaEntity *> *entities, NSError * __nullable error))completionHandler
{
    TSPKHandleResult *result = [TSPKMediaOfMPMediaLibraryPipeline handleAPIAccess:NSStringFromSelector(@selector(addItemWithProductID:completionHandler:)) className:[TSPKMediaOfMPMediaLibraryPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (completionHandler) {
            completionHandler(nil, [TSPKUtils fuseError]);
            return;
        }
    }
    [self tspk_media_addItemWithProductID:productID completionHandler:completionHandler];
}

- (void)tspk_media_getPlaylistWithUUID:(NSUUID *)uuid creationMetadata:(nullable MPMediaPlaylistCreationMetadata *)creationMetadata completionHandler:(void (^)(MPMediaPlaylist * __nullable playlist, NSError * __nullable error))completionHandler  MP_API(ios(9.3))
{
    TSPKHandleResult *result = [TSPKMediaOfMPMediaLibraryPipeline handleAPIAccess:NSStringFromSelector(@selector(getPlaylistWithUUID:creationMetadata:completionHandler:)) className:[TSPKMediaOfMPMediaLibraryPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (completionHandler) {
            completionHandler(nil, [TSPKUtils fuseError]);
            return;
        }
    }
    [self tspk_media_getPlaylistWithUUID:uuid creationMetadata:creationMetadata completionHandler:completionHandler];
}

+ (void)tspk_media_requestAuthorization:(void (^)(MPMediaLibraryAuthorizationStatus status))handler
API_AVAILABLE(ios(9.3))
{
    TSPKHandleResult *result = [TSPKMediaOfMPMediaLibraryPipeline handleAPIAccess:NSStringFromSelector(@selector(requestAuthorization:)) className:[TSPKMediaOfMPMediaLibraryPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        if (handler) {
            handler(MPMediaLibraryAuthorizationStatusDenied);
        }
    } else {
        [self tspk_media_requestAuthorization:handler];
    }
}

@end

@implementation TSPKMediaOfMPMediaLibraryPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineMediaOfMPMediaLibrary;
}

+ (NSString *)dataType {
    return TSPKDataTypeMedia;
}

+ (NSString *)stubbedClass
{
    return @"MPMediaLibrary";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    if (@available(iOS 9.3, *)) {
        return @[
            NSStringFromSelector(@selector(requestAuthorization:))
        ];
    }
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    if (@available(iOS 9.3, *)) {
        return @[
            NSStringFromSelector(@selector(addItemWithProductID:completionHandler:)),
            NSStringFromSelector(@selector(getPlaylistWithUUID:creationMetadata:completionHandler:))
        ];
    }
    return nil;
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [MPMediaLibrary tspk_media_preload];
    });
}

@end
