//
//  CAKAlbumAssetModel+Cover.m
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by Pinka on 2021/4/30.
//

#import "CAKAlbumAssetModel+Cover.h"
#import "CAKPhotoManager.h"
#import <CreationKitInfra/ACCLogHelper.h>

#import <CreativeKit/ACCMacros.h>

@implementation CAKAlbumAssetModel (Cover)

- (void)fetchCoverImageIfNeededWithCompletion:(void (^)(void))completion
{
    CGFloat screenScale = ACC_SCREEN_SCALE;
    if (screenScale >= 2) {
        screenScale = 2;
    }
    if (ACC_SCREEN_WIDTH > 700) {
        screenScale = 1.5;
    }
    CGSize size = CGSizeMake(64 * screenScale, 64 * screenScale);
    if (!self.coverImage) {
        [CAKPhotoManager getUIImageWithPHAsset:self.phAsset imageSize:size networkAccessAllowed:NO progressHandler:^(CGFloat progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {
            if (error) {
                AWELogToolInfo(AWELogToolTagImport, @"upload: refetch coverImage with error : %@", error);
                
                if (completion) {
                    completion();
                }
            }
        } completion:^(UIImage * _Nonnull photo, NSDictionary * _Nonnull info, BOOL isDegraded) {
            self.coverImage = photo;
            if (completion) {
                completion();
            }
        }];
    }
}

+ (void)fetchCoverImagesIfNeeded:(NSArray<CAKAlbumAssetModel *> *)assetModels completion:(void (^)(void))completion
{
    __block NSUInteger count = 0;
    NSUInteger total = assetModels.count;
    NSLock *countLock = [[NSLock alloc] init];
    
    [assetModels enumerateObjectsUsingBlock:^(CAKAlbumAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:CAKAlbumAssetModel.class]) {
            [obj fetchCoverImageIfNeededWithCompletion:^{
                [countLock lock];
                
                count += 1;
                if (count == total && completion) {
                    completion();
                }
                
                [countLock unlock];
            }];
        }
    }];
}

@end
