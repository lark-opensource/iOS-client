//
//  ACCMediaSourceManager.m
//  Pods
//
//  Created by Pinka on 2020/5/14.
//

#import "ACCMediaSourceManager.h"
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCMediaSourceManager ()

@end

@implementation ACCMediaSourceManager

#pragma mark - Public API
- (void)assetWithType:(ACCMediaSourceType)type
            ascending:(BOOL)ascending
   configFetchOptions:(nullable void(^)(PHFetchOptions *fetchOptions))configBlock
           completion:(nullable void (^)(PHFetchResult<PHAsset *> *))completion
{
    if ([ACCDeviceAuth isiOS14PhotoNotDetermined]) {
        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(completion, nil);
        });
        return;
    }
    [ACCDeviceAuth requestPhotoLibraryPermission:^(BOOL success) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (success) {
                PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
                NSArray<NSSortDescriptor *> *sortDescriptor = @[
                    [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(creationDate)) ascending:ascending]
                ];
                fetchOptions.sortDescriptors = sortDescriptor;
                fetchOptions.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary | PHAssetSourceTypeiTunesSynced;

                PHFetchResult<PHAsset *> *result;
                PHAssetMediaType mediaType = PHAssetMediaTypeImage;
                if ((type & ACCMediaSourceType_Image) &&
                    (type & ACCMediaSourceType_Video)) {
                    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld || mediaType == %ld", PHAssetMediaTypeImage, PHAssetMediaTypeVideo];
                    if (configBlock) {
                        configBlock(fetchOptions);
                    }
                    
                    result = [PHAsset fetchAssetsWithOptions:fetchOptions];
                } else {
                    if (type & ACCMediaSourceType_Image) {
                        mediaType = PHAssetMediaTypeImage;
                    } else if (type & ACCMediaSourceType_Video) {
                        mediaType = PHAssetMediaTypeVideo;
                    }
                    if (configBlock) {
                        configBlock(fetchOptions);
                    }
                    result = [PHAsset fetchAssetsWithMediaType:mediaType options:fetchOptions];
                }
                
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(result);
                    });
                }
            } else {
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(nil);
                    });
                }
            }
        });
    }];
}

@end
