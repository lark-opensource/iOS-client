//
//  TSPKAlbumOfPHPickerViewControllerPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/13.
//

#import "TSPKAlbumOfPHPickerViewControllerPipeline.h"
#import "NSObject+TSAddition.h"
#import <PhotosUI/PHPicker.h>
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation PHPickerViewController (TSPrivacyKitAlbum)

+ (void)tspk_album_preload
{
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKAlbumOfPHPickerViewControllerPipeline class] clazz:self];
}

- (instancetype)tspk_album_initWithConfiguration:(PHPickerConfiguration *)configuration
{
    NSString *method = NSStringFromSelector(@selector(initWithConfiguration:));
    NSString *className = [TSPKAlbumOfPHPickerViewControllerPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKAlbumOfPHPickerViewControllerPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];
        if (!result.cacheNeedUpdate) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        PHPickerViewController *originResult = [self tspk_album_initWithConfiguration:configuration];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_album_initWithConfiguration:configuration];
    }
}

@end

@implementation TSPKAlbumOfPHPickerViewControllerPipeline

+(NSString *)pipelineType
{
    return TSPKPipelineAlbumOfPHPickerViewController;
}

+ (NSString *)dataType {
    return TSPKDataTypeAlbum;
}

+ (NSString *)stubbedClass
{
    if (@available(iOS 14.0, *)) {
        return @"PHPickerViewController";
    }
    return nil;
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(initWithConfiguration:))
    ];
}

+ (void)preload {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 14.0, *)) {
            [PHPickerViewController tspk_album_preload];
        }
    });
}

@end
