//
//  CAKAlbumAssetModel.h
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/2.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>
#import <Mantle/Mantle.h>

typedef NS_ENUM(NSInteger, CAKAlbumAssetModelMediaType) {
    CAKAlbumAssetModelMediaTypeUnknow,
    CAKAlbumAssetModelMediaTypePhoto,
    CAKAlbumAssetModelMediaTypeVideo,
    CAKAlbumAssetModelMediaTypeAudio,
};

typedef NS_ENUM(NSInteger, CAKAlbumAssetModelMediaSubType) {
    CAKAlbumAssetModelMediaSubTypeUnknow = 0,
    //视频
    CAKAlbumAssetModelMediaSubTypeVideoHighFrameRate = 1,
    //图片
    CAKAlbumAssetModelMediaSubTypePhotoGif,
    CAKAlbumAssetModelMediaSubTypePhotoLive,
};

@class CAKAlbumAssetCacheKey;

@interface CAKAlbumAssetModel : MTLModel<MTLJSONSerializing, NSCopying>

@property (nonatomic, strong) PHAsset *phAsset;
@property (nonatomic, strong) AVAsset *avAsset;
@property (nonatomic, assign) CAKAlbumAssetModelMediaType mediaType;
@property (nonatomic, assign) CAKAlbumAssetModelMediaSubType mediaSubType;

@property (nonatomic, assign) NSInteger allCellIndex;
@property (nonatomic, assign) NSInteger categoriedCellIndex;
@property (nonatomic, strong) NSNumber *selectedNum;
@property (nonatomic, copy) NSString *videoDuration;
@property (nonatomic, strong) NSIndexPath *cellIndexPath;
@property (nonatomic, strong) UIImage *coverImage;
@property (nonatomic, strong) UIImage *highQualityImage;
@property (nonatomic, assign) BOOL isFromICloud;

@property (nonatomic, assign) BOOL didFailFetchingiCloudAsset;
@property (nonatomic, assign) CGFloat iCloudSyncProgress;
@property (nonatomic, assign) BOOL canUnobserveAssetModel;

@property (nonatomic, copy) NSDictionary *info;
@property (nonatomic, assign) BOOL isShowingInPreview;
@property (nonatomic, assign) BOOL isDegraded;

@property (nonatomic, copy) NSString *UUIDString; // 唯一标识符

+ (instancetype)createWithPHAsset:(PHAsset *)asset;
- (BOOL)isEqualToAssetModel:(CAKAlbumAssetModel *)object
                   identity:(BOOL)identity;
- (void)generateUUIDStringIfNeeded;

@end

@interface CAKAlbumModel : NSObject

@property (nonatomic, copy) NSString *localIdentifier;
@property (nonatomic, strong) PHFetchResult * result;
@property (nonatomic, strong) CAKAlbumAssetCacheKey *resultKey;

@property (nonatomic, strong) PHAssetCollection * assetCollection;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) BOOL isCameraRoll;
@property (nonatomic, strong) NSDate *lastUpdateDate;

@property (nonatomic, strong) NSArray<CAKAlbumAssetModel *> *models;

@end

@interface AVAsset (MixedUploading)

@property (nonatomic, strong) NSURL *frameImageURL;

@property (nonatomic, strong) UIImage *thumbImage;

@end
