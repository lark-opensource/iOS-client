//
//  ALAssetsLibrary+EMA.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/3.
//

#import "ALAssetsLibrary+EMA.h"
#import <OPFoundation/EMADeviceHelper.h>
#import <OPFoundation/EMASandBoxHelper.h>
#import <OPFoundation/UIImage+EMA.h>
#import "EMASandBoxHelper.h"
#import "UIImage+EMA.h"
#import <OPFoundation/BDPI18n.h>
#import <OPFoundation/BDPResponderHelper.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/OPFoundation-Swift.h>

@implementation ALAssetsLibrary (EMA)

- (EMASaveImageCompletion)ema_defaultCompleteBlock:(UIWindow * _Nullable)window {
    return ^(NSError *error) {
        if (error != NULL) {
            NSString * errorTip = nil;
            if (([EMADeviceHelper getFreeDiskSpace] / (1024 * 1024.f)) < 5.f) {
                errorTip = BDPI18n.disk_space_not_enough;
            }
            else {
                errorTip = [NSString stringWithFormat:BDPI18n.saved_failed_message, [EMASandBoxHelper appDisplayName]];
            }

            if ([errorTip length] > 0) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:errorTip message:nil preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:BDPI18n.determine style:UIAlertActionStyleDefault handler:nil]];
                UIViewController *topMostVC = [OPNavigatorHelper topMostAppControllerWithWindow:window];
                [topMostVC presentViewController:alert animated:YES completion:nil];
            }
        }
        else {
            [EMAHUD showSuccess:BDPI18n.image_stored_successfully window:window];
        }
    };
}

- (ALAssetsLibraryWriteImageCompletionBlock)ema_defaultALAssetsLibraryWriteImageCompletionBlock:(EMASaveImageCompletion)completionBlock
                                                                                  withAlbumName:(NSString*)albumName{

    if (BDPIsEmptyString(albumName)) {
        NSString * appName = [EMASandBoxHelper appDisplayName];
        if (BDPIsEmptyString(appName)) {
            appName = BDPI18n.toutiao;
        }
        albumName = appName;
    }

    return ^(NSURL *assetURL, NSError *error) {
        if (error) {
            completionBlock(error);
        } else {
            [self assetForURL:assetURL albumName:albumName completionBlock:completionBlock];

            completionBlock(nil);
        }
    };
}

- (void)assetForURL:(NSURL *)assetURL albumName:(NSString*)albumName completionBlock:(EMASaveImageCompletion)completionBlock {
    [self assetForURL:assetURL resultBlock:^(ALAsset *asset) {
        __block BOOL groupHasExist = NO;
        [self enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {

            if ([albumName compare:[group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame) {
                groupHasExist = YES;
                if (group.editable) {
                    [group addAsset:asset];
                }
            }

            if (group == nil && groupHasExist == NO) {
                [self addAssetsGroupAlbumWithName:albumName resultBlock:^(ALAssetsGroup *group) {
                    if (group.editable) {
                        [group addAsset:asset];
                    }
                } failureBlock:completionBlock];
            }

        } failureBlock:completionBlock];
    } failureBlock:completionBlock];
}

#pragma -- mark public method

- (void)ema_saveImageData:(NSData *)imgData window:(UIWindow * _Nullable)window {
    [self ema_saveImageData:imgData toAlbum:nil withCompletionBlock:[self ema_defaultCompleteBlock:window]];
}

- (void)ema_saveImage:(UIImage *)img window:(UIWindow * _Nullable)window {
    [self ema_saveImage:img toAlbum:nil withCompletionBlock:[self ema_defaultCompleteBlock:window]];
}

- (void)ema_saveImage:(UIImage *)img toAlbum:(NSString *)albumName withCompletionBlock:(EMASaveImageCompletion)completionBlock {
    [self writeImageToSavedPhotosAlbum:img.CGImage
                           orientation:(ALAssetOrientation)img.imageOrientation
                       completionBlock:[self ema_defaultALAssetsLibraryWriteImageCompletionBlock:completionBlock withAlbumName:albumName]];
}

- (void)ema_saveImageData:(NSData *)imgData toAlbum:(NSString *)albumName withCompletionBlock:(EMASaveImageCompletion)completionBlock {
    [self writeImageDataToSavedPhotosAlbum:imgData
                                  metadata:nil
                           completionBlock:[self ema_defaultALAssetsLibraryWriteImageCompletionBlock:completionBlock withAlbumName:albumName]];
}

#define MaxImageDataSize (3 * 1024 * 1024)

+ (UIImage *)ema_fullSizeImageForAssetRepresentation:(ALAssetRepresentation *)assetRepresentation
{
    UIImage *result = nil;
    NSData *data = nil;

    uint8_t *buffer = (uint8_t *)malloc(sizeof(uint8_t)*[assetRepresentation size]);
    if (buffer != NULL) {
        NSError *error = nil;
        NSUInteger bytesRead = [assetRepresentation getBytes:buffer fromOffset:0 length:[assetRepresentation size] error:&error];
        data = [NSData dataWithBytes:buffer length:bytesRead];

        free(buffer);
    }

    if ([data length])
    {
        result = [UIImage imageWithData:data];
    }

    return result;
}

+ (UIImage *)ema_getBigImageFromAsset:(ALAsset *)asset
{
    UIImage * image = nil;
    ALAssetRepresentation * assetRepresentation = [asset defaultRepresentation];
    if ([assetRepresentation size] <= 0) {
        image = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
    } else if ([assetRepresentation size] < MaxImageDataSize){

        if (([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo)) {
            image = [UIImage imageWithCGImage:[assetRepresentation fullScreenImage]];
        }
        else {
            image = [ALAssetsLibrary ema_fullSizeImageForAssetRepresentation:assetRepresentation];

            // luohuaqing: Try to use fullScreenImage as far as possible, since it's much smaller in size
            CGFloat longEdge = MAX(image.size.width, image.size.height);
            CGFloat shortEdge = MIN(image.size.width, image.size.height);
            if (longEdge / shortEdge <= [BDPResponderHelper screenSize].height / [BDPResponderHelper screenSize].width) {
                image = [UIImage imageWithCGImage:[assetRepresentation fullScreenImage]];
            }
        }


    } else {
        image = [UIImage imageWithCGImage:[assetRepresentation fullScreenImage]];
    }

    return image;
}

@end
