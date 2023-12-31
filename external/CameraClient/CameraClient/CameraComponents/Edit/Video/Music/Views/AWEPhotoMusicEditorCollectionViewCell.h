//
//  AWEPhotoMusicEditorCollectionViewCell.h
//  AWEStudio
//
//  Created by 黄鸿森 on 2018/3/21.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWEPhotoMovieMusicStatus.h"
#import "AWEPhotoMovieMusicItemView.h"

@interface AWEPhotoMusicEditorCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) AWEPhotoMovieMusicItemView *musicItemView;
@property (nonatomic, strong, readonly) UIImageView *downloadIcon;
@property (nonatomic, strong, readonly) UIImageView *loadingIcon;
@property (nonatomic, assign, readonly) AWEPhotoMovieMusicStatus downloadStatus;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UIImageView *recommendedImageView;
@property (nonatomic, copy, readonly) NSString *orignalText;
@property (nonatomic, strong) UIColor *titleLabelColor;

- (void)setMusicThumbnailURLList:(NSArray *)thumbnailURLList;
- (void)setMusicThumbnailURLList:(NSArray *)thumbnailURLList placeholder:(UIImage *)placeholder;
- (void)setMusicThumbnailImage:(UIImage *)image;
- (void)setDownloadStatus:(AWEPhotoMovieMusicStatus)downloadStatus;
- (void)setIsRecommended:(BOOL)isRecommended;

- (void)setIsCurrent:(BOOL)isCurrent animated:(BOOL)animated;
- (void)setIsCurrent:(BOOL)isCurrent animated:(BOOL)animated completion:(void (^)(BOOL))completion;
- (void)updateText:(NSString *)text;
- (void)setDuration:(NSTimeInterval)duration show:(BOOL)show;
- (void)startPlayingAnimation;
- (void)stopPalyingAnimation;

@property (nonatomic, assign) BOOL useBigLoadingIcon;

@end
