//
//  AWEStoryTextContainerView.h
//  AWEStudio
//
//  Created by hanxu on 2018/11/19.
//  Copyright © 2018 bytedance. All rights reserved.
//  文字贴纸、POI贴纸的容器

#import <UIKit/UIKit.h>
#import "AWEStoryBackgroundTextView.h"
#import "AWEEditorStickerGestureViewController.h"
#import <CreationKitArch/AWEStoryTextImageModel.h>
#import "AWEStoryBackgroundTextView.h"
#import "AWEStickerBaseContainerView.h"
#import <CameraClient/AWEInteractionStickerModel+DAddition.h>
#import "AWEStoryTextContainerViewProtocol.h"
#import "ACCStoryTextAnchorModels.h"

@class AWEStoryDeleteView;
@class AWEStoryFontModel;
@class AWEPOIInfoModel;
@protocol ACCMusicModelProtocol;

typedef NS_ENUM(NSInteger, AWEStoryTextContainerType) {
    AWEStoryTextContainerTypeEdit   = 0,
    AWEStoryTextContainerTypeCamera = 1,
    AWEStoryTextContainerTypeImageEdit = 2,
};

@protocol AWEStoryTextContainerViewDelegate <NSObject>

@optional

- (void)captionView:(AWEStoryBackgroundTextView *)captionView updateLocation:(AWEInteractionStickerLocationModel *)location;

- (void)captionView:(AWEStoryBackgroundTextView *)captionView updateAlpha:(CGFloat )alpha;

- (void)didFocusOnCaption;

- (void)removeCaptionSticker;

- (void)selectTimeForTextStickerView:(AWEStoryBackgroundTextView *)textView;

@end

extern CGFloat kAWEStoryBackgroundTextViewContainerInset;
extern CGFloat AWEStoryTextContainerViewTopMaskMargin;

@interface AWEStoryTextContainerView : AWEStickerBaseContainerView<AWEEditorStickerGestureProtocol,AWEStoryTextContainerViewProtocol>

@property (nonatomic, weak) id<AWEStoryTextContainerViewDelegate> delegate;
@property (nonatomic, weak) AWEStoryDeleteView *storyDeleteView;
@property (nonatomic, weak) AWEStoryBackgroundTextView *currentOperationView;//当前手指拖动的是哪个view

@property (nonatomic, weak) AWEEditorStickerGestureViewController *gestureManager;

@property (nonatomic, copy) AWEStoryTextViewBlock firstTapBlock;//第一次点击textView
@property (nonatomic, copy) AWEStoryTextViewBlock secondTapBlock;//第2次点击textView
@property (nonatomic, copy) void (^finishButtonWillClickBlock) (void);
@property (nonatomic, copy) void (^finishButtonClickBlock) (NSUInteger textViewCount, NSString *lastContent);
@property (nonatomic, copy) void (^finishEditBlock) (NSUInteger textViewCount, NSString *lastContent);
@property (nonatomic, copy) void (^startEditBlock) (void);
@property (nonatomic, copy) void (^startEditFromTapScreenBlock) (void);
@property (nonatomic, copy) void (^startOperationBlock) (void);
@property (nonatomic, copy) void (^startPanGestureBlock)(void);
@property (nonatomic, copy) void (^finishPanGestureBlock)(void);
@property (nonatomic, copy) void (^keyboardShowBlock) (CGFloat height);
@property (nonatomic, copy) void (^didSelectedColorBlock) (AWEStoryColor *selectColor, NSIndexPath *indexPath);
@property (nonatomic, copy) void (^didSelectedFontBlock) (AWEStoryFontModel *model, NSIndexPath *indexPath);
@property (nonatomic, copy) void (^didChangeStyleBlock) (AWEStoryTextStyle style);
@property (nonatomic, copy) void (^didChangeAlignmentBlock) (AWEStoryTextAlignmentStyle style);
@property (nonatomic, copy) void (^didTapCaptionBlock) (NSInteger stickerId);
@property (nonatomic, copy) dispatch_block_t dragDeleteBlock;
@property (nonatomic, copy) dispatch_block_t clickDeleteBlock;

@property (nonatomic, copy) AWEStoryTextViewShouldBeginGestureBlock shouldBeginGestureBlock;

@property (nonatomic, strong) NSMutableArray<AWEStoryBackgroundTextView *> *textViews;

@property (nonatomic, assign) CGFloat videoDuration;
@property (nonatomic, assign) BOOL isForStory;
@property (nonatomic, assign, readonly) CGPoint mediaCenter;

//caption
@property (nonatomic, strong, readonly) NSValue *playerFrame;
@property (nonatomic, strong) AWEStoryBackgroundTextView *captionView;

//interaction sticker
@property (nonatomic, assign) BOOL isForInteractionSticker;
@property (nonatomic, copy) NSString *poiStickerID;

//live
@property (nonatomic, strong) NSValue *gestureInvalidFrameValue;


- (instancetype)initForSelectTimeWithFrame:(CGRect)frame;

- (instancetype)initWithFrame:(CGRect)frame needMask:(BOOL)needMask playerFrame:(CGRect)playerFrame type:(AWEStoryTextContainerType)type;

- (instancetype)initWithFrame:(CGRect)frame needMask:(BOOL)needMask playerFrame:(CGRect)playerFrame textInfo:(AWEStoryTextImageModel *)textInfo type:(AWEStoryTextContainerType)type completion:(void (^)(BOOL success))completion;

// 添加贴纸，不进入编辑模式
- (AWEStoryBackgroundTextView *)addTextViewWithTextImageInfo:(AWEStoryTextImageModel *)textInfo
                                                anchorModels:(ACCStoryTextAnchorModels *)anchorModels
                                               locationModel:(AWEInteractionStickerLocationModel *)location;

// 添加字幕
- (AWEStoryBackgroundTextView *)addCaptionWithWithFrame:(AWEStoryTextImageModel *)textInfo locationModel:(AWEInteractionStickerLocationModel *)location;

// 直接进入编辑模式
- (void)startLabelProgress:(AWEStoryBackgroundTextView *)textView withGesture:(UIGestureRecognizer *)gesture videoDuration:(CGFloat)videoDuration;

// 取消选中
- (void)deselectTextView;

// check是否可添加文字
- (BOOL)checkForAddText;

- (NSString *)textsArrayInString;
- (NSString *)textFontsArrayInString;
- (NSString *)textFontEffectIdsArrayInString;
- (UIImage *)generateImage;
- (UIImage *)generateImageWithRect:(CGRect)rect;

- (void)deleteTextView:(AWEStoryBackgroundTextView *)textView;

// 进入选时长模式
- (void)startSelectTimeForTextView:(AWEStoryBackgroundTextView *)textView isAlpha:(BOOL)isAlpha;

// 更新贴纸有效性
- (void)updateTextViewsStatusWithCurrentPlayerTime:(CGFloat)currentPlayerTime isSelectTime:(BOOL)isSelectTime;

// 更新贴纸位置信息
- (void)recoverPositionForTextView:(AWEStoryBackgroundTextView *)textView locationModel:(AWEInteractionStickerLocationModel *)location;

// store sticker current location info.
- (void)recordSickerLocationForView:(AWEStoryBackgroundTextView *)textView;

- (void)updateMusicCoverWithMusicModel:(id<ACCMusicModelProtocol>)model;

#pragma mark - interaction sticker methods

- (AWEStoryBackgroundTextView *)addExternalTextViewWithTextInfo:(AWEStoryTextImageModel *)model
                                                   anchorModels:(ACCStoryTextAnchorModels *)anchorModels
                                                     completion:(void (^)(BOOL success,AWEStoryBackgroundTextView *textView))completion;

- (void)recoverDraftInteractionStickerWithModel:(AWEInteractionStickerModel *)info;
- (void)recoverDraftInteractionStickerWithModel:(AWEInteractionStickerModel *)info poiLocation:(AWEInteractionStickerLocationModel *)location;

- (void)removeAllTextStickerViews;

@end
