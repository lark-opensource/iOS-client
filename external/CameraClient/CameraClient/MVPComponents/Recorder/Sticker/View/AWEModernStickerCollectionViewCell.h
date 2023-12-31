//
//  AWEModernStickerCollectionViewCell.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/15.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEStudioBaseCollectionViewCell.h"
#import <EffectPlatformSDK/IESEffectModel.h>
#import <CreationKitInfra/AWECircularProgressView.h>

typedef NS_ENUM(NSUInteger, AWEModernStickerDownloadStatus) {
    AWEModernStickerDownloadStatusUndownloaded,
    AWEModernStickerDownloadStatusDownloading,
    AWEModernStickerDownloadStatusDownloaded,
};

@interface AWEModernStickerCollectionViewCell : AWEStudioBaseCollectionViewCell
@property (nonatomic, strong, readonly) UIImageView *iconImageView;
@property (nonatomic, strong, readonly) UIImageView *downloadImgView;
@property (nonatomic, strong, readonly) AWECircularProgressView *progressView;
@property (nonatomic, strong, readonly) UIImageView *loadingImgView;
@property (nonatomic, strong, readonly) UIView *containerView;

@property (nonatomic, assign) AWEModernStickerDownloadStatus downloadStatus;
@property (nonatomic, readonly) IESEffectModel *effect;
@property (nonatomic, readonly) IESEffectModel *childEffect; // 聚合类贴纸的childEffect.
@property (nonatomic, strong) UIView *selectedIndicatorView;
@property (nonatomic, assign) BOOL isStickerSelected;
@property (nonatomic, assign) BOOL isInPropPanel;

- (void)configWithEffectModel:(IESEffectModel *)model childEffectModel:(IESEffectModel *)childEffectModel;

- (void)startDownloadAnimation;

- (void)stopDownloadAnimation;

- (void)startPropNameScrollingAnimation;

- (void)makeSelectedWithDelay;

- (void)makeSelected;

- (void)makeUnselected;

- (void)startLoadingAnimation;

- (void)stopLoadingAnimation;

- (void)updateDownloadProgress:(CGFloat)progress;

- (void)updateStickerIconImage;

@end
