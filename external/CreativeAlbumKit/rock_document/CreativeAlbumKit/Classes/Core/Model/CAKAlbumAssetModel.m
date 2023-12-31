//
//  CAKAlbumAssetModel.m
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/2.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import "CAKAlbumAssetModel.h"
#import <objc/runtime.h>

@implementation CAKAlbumAssetModel

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
    CAKAlbumAssetModel *model = [[self.class allocWithZone:zone] init];
    
    model.phAsset = [self.phAsset copy];
    model.avAsset = [self.avAsset copy];
    model.mediaType = self.mediaType;
    model.mediaSubType = self.mediaSubType;
    model.allCellIndex = self.allCellIndex;
    model.categoriedCellIndex = self.categoriedCellIndex;
    model.selectedNum = [self.selectedNum copy];
    model.videoDuration = [self.videoDuration copy];
    model.cellIndexPath = [self.cellIndexPath copy];
    model.coverImage = self.coverImage;
    model.highQualityImage = self.highQualityImage;
    model.isFromICloud = self.isFromICloud;
    model.didFailFetchingiCloudAsset = self.didFailFetchingiCloudAsset;
    model.iCloudSyncProgress = self.iCloudSyncProgress;
    model.canUnobserveAssetModel = self.canUnobserveAssetModel;
    model.info = [self.info copy];
    model.isShowingInPreview = self.isShowingInPreview;
    model.isDegraded = self.isDegraded;
    model.UUIDString = self.UUIDString;
    
    return model;
}

+ (instancetype)createWithPHAsset:(PHAsset *)asset
{
    CAKAlbumAssetModel *model = [[CAKAlbumAssetModel alloc] init];
    CAKAlbumAssetModelMediaType type = CAKAlbumAssetModelMediaTypeUnknow;
    CAKAlbumAssetModelMediaSubType subType = CAKAlbumAssetModelMediaSubTypeUnknow;
    switch (asset.mediaType) {
        case PHAssetMediaTypeVideo:
            type = CAKAlbumAssetModelMediaTypeVideo;
            if (asset.mediaSubtypes == PHAssetMediaSubtypeVideoHighFrameRate) {
                subType = CAKAlbumAssetModelMediaSubTypeVideoHighFrameRate;
            }
            break;
        case PHAssetMediaTypeAudio:
            type = CAKAlbumAssetModelMediaTypeAudio;
            break;
        case PHAssetMediaTypeImage: {
            type = CAKAlbumAssetModelMediaTypePhoto;
            if (@available(iOS 9.1, *)) {
                if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
                    subType = CAKAlbumAssetModelMediaSubTypePhotoLive;
                }
                break;
            }
            if ([[asset valueForKey:@"filename"] hasSuffix:@"GIF"]) {
                subType = CAKAlbumAssetModelMediaSubTypePhotoGif;
            }
            // The code above will not be able to return the correct subtype GIF even if the asset is indeed a GIF for any devices running on iOS 9.1 or above, which will break the switch loop within the first if statement. However, it has been around for quite some time and the other code calling this method may not considered or tested the possibility of this function returning a subtype of gif. The implications of fixing it can introduce unpredictable results. Therefore I can only leave it like this until a more detailed investigation on the calling part is made.
        }
            break;
        default:
            break;
    }

    model.mediaType = type;
    model.mediaSubType = subType;
    model.selectedNum = nil;
    model.phAsset = asset;
    if (type == CAKAlbumAssetModelMediaTypeVideo) {
        NSTimeInterval duration = asset.duration;
        NSInteger seconds = (NSInteger)round(duration);
        NSInteger second = seconds % 60;
        NSInteger minute = seconds / 60;
        model.videoDuration = [NSString stringWithFormat:@"%02ld:%02ld", (long)minute, (long)second];
    }

    return model;
}

- (BOOL)isEqualToAssetModel:(CAKAlbumAssetModel *)object identity:(BOOL)identity
{
    if (!object) {
        return NO;
    }

    if (identity) {
        if (self.UUIDString.length > 0 && ![self.UUIDString isEqualToString:object.UUIDString]) {
            return NO;
        }
    }
    BOOL hasEqualLoalIdentifier = (object.phAsset != nil && !self.phAsset.localIdentifier && !object.phAsset.localIdentifier) ||
    (object.phAsset != nil && [self.phAsset.localIdentifier isEqualToString:object.phAsset.localIdentifier]);

    if (hasEqualLoalIdentifier) {
        return YES;
    }
    if (self.avAsset &&
        object.avAsset &&
        [self.avAsset isKindOfClass:[AVURLAsset class]] &&
        [object.avAsset isKindOfClass:[AVURLAsset class]])
    {
        NSURL *URLInSelf = [(AVURLAsset *)self.avAsset URL];
        NSURL *URLInObject = [(AVURLAsset *)object.avAsset URL];
        return [URLInSelf isEqual:URLInObject];
    }

    return NO;
}

- (void)generateUUIDStringIfNeeded
{
    if (self.UUIDString.length == 0) {
        self.UUIDString = [[NSUUID UUID] UUIDString];
    }
}

@end

@implementation CAKAlbumModel


@end

@implementation AVAsset (MixedUploading)

- (NSURL *)frameImageURL {
    return objc_getAssociatedObject(self, @selector(frameImageURL));
}

- (void)setFrameImageURL:(NSURL *)frameImageURL {
    objc_setAssociatedObject(self, @selector(frameImageURL), frameImageURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)thumbImage {
    return objc_getAssociatedObject(self, @selector(thumbImage));
}

- (void)setThumbImage:(UIImage *)thumbImage {
    objc_setAssociatedObject(self, @selector(thumbImage), thumbImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
