//
//  AWEEditorStickerGestureViewController.h
//  AWEStudio
//
//  Created by li xingdong on 2018/12/4.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWEStickerEditBaseView.h"
#import "ACCEditorStickerArtboardProtocol.h"
#import "ACCStickerContainerView+CameraClient.h"

@class AWEStickerContainerView;
@class AWEVideoStickerEditCircleView;

@class AWEStoryTextContainerView;
@class AWEStoryBackgroundTextView;

@class AWESimplifiedStickerContainerView;

@class AWEVideoPublishViewModel;

@protocol AWEEditorStickerGestureDelegate <NSObject>

- (void)editorSticker:(UIView *)editView clickedDeleteButton:(UIButton *)sender;

@optional

- (void)editorSticker:(UIView *)editView clickedSelectTimeButton:(UIButton *)sender;

- (void)editorSticker:(UIView *)editView clickedPinStickerButton:(UIButton *)sender;

- (void)editorSticker:(UIView *)editView clickedTextEditButton:(UIButton *)sender;

- (void)resignActiveFinished;

- (AWEVideoPublishViewModel *)publishModel;

@end

@protocol AWEEditorStickerGestureViewControllerDelegate <NSObject>

@optional
- (BOOL)enableTapGesture;

@end

typedef NS_OPTIONS(NSInteger, AWEGestureActiveType) {
    AWEGestureActiveTypeNone = 0,
    AWEGestureActiveTypeTap = 1 << 1,
    AWEGestureActiveTypePan = 1 << 2,
    AWEGestureActiveTypePinch = 1 << 3,
    AWEGestureActiveTypeRotate = 1 << 4
};

@interface AWEEditorStickerGestureViewController : UIViewController

@property (nonatomic, copy) BOOL(^gestureStartBlock)(UIView *editView);

@property (nonatomic, weak) id<AWEEditorStickerGestureViewControllerDelegate> delegate;
@property (nonatomic, strong) AWEVideoStickerEditCircleView *currentInfoStickerView;
@property (nonatomic, strong) AWEStoryBackgroundTextView *currentTextStickerView;

@property (nonatomic, strong, readonly) AWEStickerContainerView *infoStickerContainer;//信息化贴纸容器
@property (nonatomic, strong, readonly) AWEStoryTextContainerView *textStickerContainer;//文字贴纸、POI贴纸容器
@property (nonatomic, strong, readonly) AWESimplifiedStickerContainerView *simplifiedStickerContainer;//贴纸选时长用
@property (nonatomic, assign, readonly) AWEGestureActiveType gestureActiveStatus;
@property (nonatomic, strong) ACCStickerContainerView *stickerContainerView;

@property (nonatomic, copy) void (^tapToTextEdit)(void);

- (UIView *)hitTargetStickerWithGesture:(UIGestureRecognizer *)gesture deSelected:(BOOL)deSelected;

- (void)configInfoStickerContainer:(AWEStickerContainerView *)container;

- (void)configTextStickerContainer:(AWEStoryTextContainerView *)container;

- (void)configSimpliedInfoStickerContainer:(AWESimplifiedStickerContainerView *)container;

- (void)focuseOn:(UIView *)focusedView rootView:(UIView *)rootView;
- (void)resetContainerHierachy:(UIView *)rootView;
@end
