//
//  AWEInformationStickerCollectionViewCell.h
//  AWEStudio
//
//  Created by guochenxiang on 2018/9/21.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AWECircularProgressView, ACCStickerPannelUIConfig;

typedef NS_ENUM(NSUInteger, AWEInfoStickerDownloadStatus) {
    AWEInfoStickerDownloadStatusUndownloaded,
    AWEInfoStickerDownloadStatusDownloading,
    AWEInfoStickerDownloadStatusDownloaded,
};

@interface AWEBaseStickerCollectionViewCell : UICollectionViewCell

@property (nonatomic, assign) AWEInfoStickerDownloadStatus downloadStatus;
@property (nonatomic, strong) ACCStickerPannelUIConfig *uiConfig;
@property (nonatomic, copy) NSString *stickerName;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *downloadImgView;
@property (nonatomic, strong) AWECircularProgressView *downloadProgressView;

@property (nonatomic, copy) NSString *stickerId;

+ (NSString *)identifier;
- (void)setupUI;

- (void)configCellWithImage:(NSArray<NSString *> *)image;

- (void)updateDownloadProgress:(CGFloat)progress;

@end

@interface AWEVideoEditStickerCollectionViewHeaderView : UICollectionReusableView

@property (nonatomic, strong) ACCStickerPannelUIConfig *uiConfig;

- (void)updateWithTitle:(NSString *)title;

+ (NSString *)identifier;

@end


@interface AWEInformationStickerCollectionViewCell : AWEBaseStickerCollectionViewCell

@end

@interface AWEInformationStickerCollectionViewFooter : UICollectionReusableView

@property (nonatomic, strong) UIView *seperatorView;

+ (NSString *)identifier;

@end

NS_ASSUME_NONNULL_END

@interface ACCSearchStickerCollectionViewHeader : UICollectionReusableView

@property (nonatomic, nullable ,copy) dispatch_block_t didClickBlock;

- (void)updateWithTitle:(NSString *)title;

+ (NSString *)identifier;

@end

@interface ACCSearchStickerCollectionViewCell : AWEBaseStickerCollectionViewCell

@property (nonatomic, assign) BOOL didSetupUI;

@end
