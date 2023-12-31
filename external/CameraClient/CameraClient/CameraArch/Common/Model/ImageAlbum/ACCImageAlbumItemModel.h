//
//  ACCImageAlbumItemModel.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/9.
//

#import <Foundation/Foundation.h>
#import "ACCImageAlbumStickerModel.h"
#import <Mantle/MTLModel.h>
#import "ACCImageAlbumItemBaseResourceModel.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEInteractionStickerModel;
@class ACCImageAlbumItemOriginalImageInfo, ACCImageAlbumItemHDRInfo;
@class ACCImageAlbumItemFilterInfo, ACCImageAlbumItemStickerInfo;
@class ACCImageAlbumItemBackupImageInfo, ACCImageAlbumItemCropInfo;
@protocol ACCSerializationProtocol;

@interface ACCImageAlbumItemModel : ACCImageAlbumItemBaseItemModel

ACCImageEditModeObjUsingCustomerInitOnly;
- (instancetype)initWithTaskId:(NSString *)taskId NS_UNAVAILABLE;
- (instancetype)initWithTaskId:(NSString *)taskId index:(NSInteger)index;

/// 每张图片数据的唯一标识，之所以不用index来做唯一标识， 是为了以后插入 删除 移动图片的功能不会留下巨大的坑
@property (nonatomic, copy, readonly) NSString *itemIdentify;

@property (nonatomic, strong, readonly) ACCImageAlbumItemOriginalImageInfo *_Nonnull originalImageInfo;

@property (nonatomic, strong, readonly) ACCImageAlbumItemBackupImageInfo *_Nonnull backupImageInfo;

@property (nonatomic, strong, readonly) ACCImageAlbumItemHDRInfo *_Nonnull HDRInfo;

@property (nonatomic, strong, readonly) ACCImageAlbumItemFilterInfo *_Nonnull filterInfo;

@property (nonatomic, strong, readonly) ACCImageAlbumItemStickerInfo *_Nonnull stickerInfo;

@property (nonatomic, strong, readonly) ACCImageAlbumItemCropInfo *_Nonnull cropInfo;


@end


@interface ACCImageAlbumItemOriginalImageInfo : ACCImageAlbumItemDraftResourceRestorableModel

ACCImageEditModeObjUsingCustomerInitOnly;

@property (nonatomic, assign) CGFloat width;

@property (nonatomic, assign) CGFloat height;

- (CGSize)imageSize;

@property (nonatomic, assign) CGFloat scale;

- (void)resetImageWithAbsoluteFilePath:(NSString *)filePath
                             imageSize:(CGSize)imageSize
                            imageScale:(CGFloat)imageScale;

/// 压缩过的占位图，用于低端机渲染完成前的占位使用
@property (nonatomic, strong) ACCImageAlbumItemDraftResourceRestorableModel *placeHolderImageInfo;

@end

@interface ACCImageAlbumItemBackupImageInfo : ACCImageAlbumItemDraftResourceRestorableModel

ACCImageEditModeObjUsingCustomerInitOnly;

@property (nonatomic, assign) CGFloat width;

@property (nonatomic, assign) CGFloat height;

@end

@interface ACCImageAlbumItemHDRInfo: ACCImageAlbumItemVEResourceRestorableModel

ACCImageEditModeObjUsingCustomerInitOnly;

- (void)updateLensHDRModelWithFilePath:(NSString *)filePath;

- (NSString *)lensHDRModelFilePath;

@property (nonatomic, assign) BOOL enableHDRNet;

@end

@interface ACCImageAlbumItemFilterInfo: ACCImageAlbumItemVEResourceRestorableModel

ACCImageEditModeObjUsingCustomerInitOnly;

// VE实际应用的强度
// property name 应该叫 filterIntensity， 之前加了Ratio属于错误
@property (nonatomic, strong) NSNumber *filterIntensityRatio;

// 滑竿的值，和publishViewmodel里的colorFilterIntensityRatio是一致的
// 实际上这个值应该存到repo或者其他地方而不是image data里，目前先这样 后续在优化
// 蜜汁逻辑是publishViewmodel里的colorFilterIntensityRatio和实际应用到effect里的是不一样的 中间可能经过了换算
@property (nonatomic, strong) NSNumber *slideRatio;
- (BOOL)isValidFilter;

@end

@interface ACCImageAlbumStickerSearchResult : NSObject

@property (nonatomic, strong) ACCImageAlbumStickerModel *sticker;
@property (nonatomic, assign) NSInteger imageIndex;

@end

@interface ACCImageAlbumItemStickerInfo: ACCImageAlbumItemBaseItemModel

ACCImageEditModeObjUsingCustomerInitOnly;
// 打入视频的贴纸，无论是否可以交互
@property (nonatomic, copy) NSArray <ACCImageAlbumStickerModel *> *_Nullable stickers;
// 可交互贴纸
@property (nonatomic, copy) NSArray <AWEInteractionStickerModel *> *_Nullable interactionStickers;

/// Just for recovery by sliding
@property (nonatomic, copy) NSArray<NSObject<ACCSerializationProtocol> *> *textStickers;

@property (nonatomic, assign) CGSize mediaActualSize;

- (NSArray <ACCImageAlbumStickerModel *> *_Nullable)orderAscendingStickers; // ascending sort by 'order'

- (ACCImageAlbumStickerModel *)stickerWithUniqueId:(NSInteger)uniqueId;

- (BOOL)containStickerWithUniqueId:(NSInteger)uniqueId;

- (NSInteger)maxOrder;

- (void)addStickerWithSticker:(ACCImageAlbumStickerModel *)sticker;

- (void)removeStickerWithUniqueId:(NSInteger)uniqueId;

- (void)removeAllStickers;

@end

@interface ACCImageAlbumItemCropInfo : ACCImageAlbumItemDraftResourceRestorableModel

ACCImageEditModeObjUsingCustomerInitOnly;

@property (nonatomic, assign) ACCImageAlbumItemCropRatio cropRatio;
@property (nonatomic, copy, readonly) NSString *cropRatioString;

@property (nonatomic, assign) CGFloat zoomScale;

@property (nonatomic, assign) CGPoint contentOffset;

// 对原图的裁切 rect
@property (nonatomic, assign) CGRect cropRect;

/// 是否做过裁切
@property (nonatomic, assign, readonly) BOOL hasCropped;

+ (NSString *)cropRatioString:(ACCImageAlbumItemCropRatio)cropRatio;

@end


NS_ASSUME_NONNULL_END
