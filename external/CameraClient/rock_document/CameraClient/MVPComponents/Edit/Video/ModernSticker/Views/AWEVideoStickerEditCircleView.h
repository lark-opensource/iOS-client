//
//  AWEVideoStickerEditCircleView.h
//  AWEStudio
//
//  Created by guochenxiang on 2018/9/25.
//  Copyright © 2018年 bytedance. All rights reserved.
//  信息化贴纸操作框view

#import <UIKit/UIKit.h>
#import "AWEEditorStickerGestureViewController.h"
#import "AWEStickerEditBaseView.h"
#import "AWEInfoStickerEditViewProtocol.h"
#import <TTVideoEditor/IESInfoSticker.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoStickerEditCircleView;
@class AWEInteractionStickerModel;
@class AWEStickerContainerView;

@interface AWEVideoStickerEditCircleView : AWEStickerEditBaseView<AWEInfoStickerEditViewProtocol>

@property (nonatomic, weak) id<AWEEditorStickerGestureDelegate> delegate;
@property (nonatomic, strong, readonly) UIView *borderView;
@property (nonatomic, weak) AWEEditorStickerGestureViewController *gestureManager;

@property (nonatomic, assign, readonly) NSInteger stickerEditId;
@property (nonatomic, assign, readonly) BOOL isActive;
@property (nonatomic, assign) CGSize originalSize;
@property (nonatomic, strong) IESInfoStickerProps *stickerInfos;
@property (nonatomic, strong, readonly) CAShapeLayer *centerHorizontalDashLayer;
@property (nonatomic, assign) BOOL isLyricSticker;

//backup
@property (nonatomic, assign, readonly) CGRect backupBounds;
@property (nonatomic, strong, readonly) IESInfoStickerProps *backupStickerInfos;

//interaction sticker
@property (nonatomic, strong) AWEInteractionStickerModel *interactionStickerInfo;

@property (nonatomic, assign) BOOL isCustomUploadSticker;

@property (nonatomic, assign) CGPoint origin;   //Effect使用的origin

+ (CGFloat)linePadding;

- (instancetype)initWithFrame:(CGRect)frame isForImage:(BOOL)isForImage;

- (BOOL)setBounds:(CGRect)bounds scale:(CGFloat)scale;
- (void)updateBorderCenter:(CGPoint)center;

- (void)becomeActive;
- (void)resignActive;
- (void)backupActive;
- (void)restoreActive;
- (void)showAngleHelperDashLine;
- (void)hideAngleHelperDashLine;
- (void)hideHandle;

- (void)backupLocationInfo;

@end

NS_ASSUME_NONNULL_END
