//
//  AWEAssetModel.h
//  AWEStudio
//
//  Created by 旭旭 on 2018/3/20.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <CreationKitArch/HTSVideoDefines.h>
#import <CreationKitArch/AWEAVMutableCompositionBuilderDefine.h>
#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <Mantle/Mantle.h>

@class AWEDTOVideoCutInfo;

@interface AWEAssetModel : MTLModel<MTLJSONSerializing, NSCopying>

@property (nonatomic, assign) NSInteger allCellIndex;
@property (nonatomic, assign) NSInteger categoriedCellIndex;
@property (nonatomic, strong) NSIndexPath *cellIndexPath;

@property (class, nonatomic, readonly) NSInteger videoUploadMaxSeconds;

@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, copy) NSString *videoDuration;
@property (nonatomic, assign) AWEAssetModelMediaType mediaType;
@property (nonatomic, assign) AWEAssetModelMediaSubType mediaSubType;
@property (nonatomic, strong) NSNumber *selectedNum;
@property (nonatomic, copy) NSString *albumId;

@property (nonatomic, strong, readonly) NSDate *creationDate;
@property (nonatomic, strong, readonly) NSDate *modificationDate;

//Albums sorted by date
@property (nonatomic, copy) NSString *dateFormatStr;
@property (nonatomic, copy) NSString *dateFormatBriefStr;

//做多段视频时增加的字段
@property (nonatomic, strong) UIImage *coverImage;
@property (nonatomic, strong) AVAsset *avAsset;
@property (nonatomic, assign) HTSVideoSpeed speed;
@property (nonatomic, assign) AWEVideoCompositionRotateType rotateType;
@property (nonatomic, strong) NSValue *clipTimeRange;       // 总体选择的Range
@property (nonatomic, strong) NSValue *aiClipTimeRange;     // ai选择的Range
@property (nonatomic, strong) NSValue *initialTimeRange;    // 原始的Range
@property (nonatomic, strong) NSValue *assetClipTimeRange;  // 当前asset选择的Range
@property (nonatomic, strong) NSValue *assetBackupClipTimeRange;  // 当前asset选择的Range备份
@property (nonatomic, strong) NSValue *originSizeOfVideo;
@property (nonatomic, copy) NSDictionary *info;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSTimeInterval clipDuration;
@property (nonatomic, strong) NSValue *cmTimeDuration;
@property (nonatomic, assign) BOOL isDegraded;

//视频原始的resolution
@property (nonatomic, copy) NSString *originalResolution;

@property (nonatomic, strong) AWEVideoFragmentInfo  *fragmentInfo;

- (CGSize)videoSizeWithCurrentRotateType;
- (CGSize)videoSizeWithRotateType:(AWEVideoCompositionRotateType)rotateType;

@property (nonatomic, strong) NSNumber *collectionOffsetX; // 普通模式的裁剪相关信息
@property (nonatomic, strong) NSNumber *actualLeftPosition;
@property (nonatomic, strong) NSNumber *actualRightPosition;

@property (nonatomic, copy) NSString *UUIDString; // 唯一标识符
@property (nonatomic, copy) NSString *localIdentifier;

// 音乐卡点模式相关信息
- (void)setReadableClipTimeString:(NSString *)timeString
                       forMusicID:(id<NSCopying>)musicID;

- (void)setClipTimeRange:(NSValue *)clipTimeRange forMusicID:(id<NSCopying>)musicID changeByUser:(BOOL)changeByUser;
- (void)setCollectionOffsetX:(NSNumber *)collectionOffsetX forMusicID:(id<NSCopying>)musicID changeByUser:(BOOL)changeByUser;

- (void)setActualLeftPosition:(NSNumber *)actualLeftPosition forMusicID:(id<NSCopying>)musicID;
- (void)setActualRightPosition:(NSNumber *)actualRightPosition forMusicID:(id<NSCopying>)musicID;

- (NSString *)readableClipTimeStringForMusicID:(id<NSCopying>)musicID;

- (NSValue *)clipTimeRangeForMusicID:(id<NSCopying>)musicID;
- (NSNumber *)collectionOffsetXForMusicID:(id<NSCopying>)musicID;

- (BOOL)isClipTimeRangeChangedByUserForMusicID:(id<NSCopying>)musicID;
- (BOOL)isCollectionOffsetXChangedByUserForMusicID:(id<NSCopying>)musicID;

- (NSNumber *)actualLeftPositionForMusicID:(id<NSCopying>)musicID;
- (NSNumber *)actualRightPositionForMusicID:(id<NSCopying>)musicID;

@property (nonatomic, strong) NSMutableDictionary *imageDict;

@property (nonatomic, assign) CGFloat iCloudSyncProgress;
@property (nonatomic, assign) BOOL isFromICloud;
@property (nonatomic, assign) BOOL isBeClipped;
@property (nonatomic, assign) BOOL isShowingInPreview;
@property (nonatomic, assign) BOOL didFailFetchingiCloudAsset;
@property (nonatomic, assign) BOOL canUnobserveAssetModel;

@property (nonatomic, assign) BOOL isFromLv;

- (void)setImageArrayForSpeed:(HTSVideoSpeed)speed imageArray:(NSArray *)imageArray;
- (void)setImageArrayForIndex:(NSInteger)index imageArray:(NSArray *)imageArray;
- (NSArray<UIImage *> *)getImageArrayForSpeed:(HTSVideoSpeed)speed;

/*
 * identity: 是否严格相等，YES: 会比较UUIDString NO: 校验AVAsset资源和PHAsset资源相等性
 * isEqual方法 相当于调用 -isEqualToAssetModel:obj identity:YES
 */
- (BOOL)isEqualToAssetModel:(AWEAssetModel *)object
                   identity:(BOOL)identity;

- (void)generateUUIDStringIfNeeded;

- (CMTimeRange)currentAssetClippedRange;

+ (instancetype)createWithPHAsset:(PHAsset *)asset;

@end

@interface AWEAlbumModel : NSObject

@property (nonatomic, copy) NSString *localIdentifier;
@property (nonatomic, strong) PHFetchResult * result;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) BOOL isCameraRoll;
@property (nonatomic, strong) NSDate *lastUpdateDate;

@property (nonatomic, strong) NSArray<AWEAssetModel *> *models;

@end

@interface AVAsset (MixexUploading)

// 用来标记对应的图片资源 URL
@property (nonatomic, strong) NSURL *frameImageURL;

@property (nonatomic, strong) UIImage *thumbImage;
/** 是否是不需要限制时长的场景 */
@property (nonatomic, assign) BOOL isSceneDoNotNeedLimitDuration;

@end
