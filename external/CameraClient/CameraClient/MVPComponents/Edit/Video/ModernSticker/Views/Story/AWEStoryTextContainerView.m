//
//  AWEStoryTextContainerView.m
//  AWEStudio
//
//  Created by hanxu on 2018/11/19.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEStoryTextContainerView.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitArch/AWEEditGradientView.h>
#import <CreationKitArch/AWEFeedBackGenerator.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import "AWEXScreenAdaptManager.h"
#import "AWEStickerContainerFakeProfileView.h"
#import "AWEEditStickerHintView.h"
#import "AWEEditStickerBubbleManager.h"
#import "ACCFriendsServiceProtocol.h"
#import <CreativeKit/NSTimer+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import "AWEStoryToolBar.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import <YYWebImage/UIImage+YYWebImage.h>
#import <CreationKitArch/ACCCustomFontProtocol.h>
#import <CreationKitInfra/UIView+ACCRTL.h>
#import <CameraClient/AWEInteractionPOIStickerModel.h>

CGFloat AWEStoryTextContainerViewTopMaskMargin = 52;
static const CGFloat kAWEStoryBackgroundTextViewMinScale = 0.3;
static const CGFloat kAWEStoryToolBarHeight = 104;
static BOOL kCanStoryTextContainerViewAngleAdsorbingVibrate = YES;

extern CGFloat kAWEStoryBackgroundTextViewLeftMargin;
extern CGFloat kAWEStoryBackgroundTextViewBackgroundColorLeftMargin;
extern CGFloat kAWEStoryBackgroundTextViewBackgroundColorTopMargin;
extern CGFloat kAWEStoryBackgroundTextViewBackgroundBorderMargin;
extern CGFloat kAWEStoryBackgroundTextViewBackgroundRadius;
extern CGFloat kAWEStoryBackgroundTextViewKeyboardMargin;

typedef NS_OPTIONS(NSUInteger, AWEStoryTextPanDirectionOptions) {
    AWEStoryTextPanDirectionNone  = 0,
    AWEStoryTextPanDirectionLeft  = 1 << 0,
    AWEStoryTextPanDirectionRight = 1 << 1,
    AWEStoryTextPanDirectionUp    = 1 << 2,
    AWEStoryTextPanDirectionDown  = 1 << 3,
};


typedef NS_ENUM(NSInteger, AWEStoryTextEdgeLineType) {
    AWEStoryTextEdgeLineNone = 0,
    AWEStoryTextEdgeLineLeft,
    AWEStoryTextEdgeLineRight,
    AWEStoryTextEdgeLineDown,
    AWEStoryTextEdgeLineCenterVertical,
    AWEStoryTextEdgeLineCenterHorizontal
};

typedef NS_ENUM(NSInteger, AWETextContainerMode) {
    AWETextContainerModeNormal = 0,
    AWETextContainerModeSelectTime,
};


@interface AWEStoryTextContainerView () <UITextViewDelegate, AWEEditorStickerGestureDelegate>

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) AWEStoryToolBar *toolBar;
@property (nonatomic, strong) UIView *textMaskView;
@property (nonatomic, strong) ACCAnimatedButton *finishButton;
@property (nonatomic, strong) UIView *topMaskView;//顶部52pt的范围内部能显示文字，所以在编辑状态下把textView加到topMaskView上。

// 垃圾箱
@property (nonatomic, assign) BOOL isInDeleting;
@property (nonatomic, strong, readwrite) NSValue *playerFrame;
@property (nonatomic, assign) CGPoint mediaCenter;

@property (nonatomic, assign) BOOL beginLabelProgress;
@property (nonatomic, assign) AWEStoryTextContainerType type;
@property (nonatomic, assign) BOOL didClickFinish;
@property (nonatomic, assign) CGFloat leftBeyond;

//poi贴纸对齐
@property (nonatomic, strong) UIView *leftAlignLine;
@property (nonatomic, strong) UIView *rightAlignLine;
@property (nonatomic, strong) UIView *bottomAlignLine;
/// 垂直对齐线
@property (nonatomic, strong) UIView *centerVerticalAlignLine;
/// 水平对齐线
@property (nonatomic, strong) UIView *centerHorizontalAlignLine;
@property (nonatomic, strong) NSTimer *edgeLineTimer;
@property (nonatomic, assign) BOOL isEdgeAdsorbing;
@property (nonatomic, assign) BOOL isAngleAdsorbing;
/// 半透明个人视频页底部元素，用来警示投票贴纸的安全区域
@property (nonatomic, strong) AWEStickerContainerFakeProfileView *fakeProfileView;
@property (nonatomic, assign) BOOL isInPinchOrRotate;//正在手势旋转捏合时不显示对齐线
@property (nonatomic, strong) AWEInteractionStickerLocationModel *lastInteractionStickerLocation;//更换POI贴纸，使用上一次的位置
@property (nonatomic, strong) AWEEditStickerHintView *hintView;
@property (nonatomic, assign) AWETextContainerMode containerMode;
@property (nonatomic, assign) CGRect originalFrame;

// backup
@property (nonatomic, assign) BOOL invalidAction;
@property (nonatomic, assign) BOOL hasBackup;

@end

@implementation AWEStoryTextContainerView

- (void)dealloc
{
    if ([_edgeLineTimer isValid]) {
        [_edgeLineTimer invalidate];
    }
    [self p_removeObservers];
}

- (instancetype)initForSelectTimeWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.originalFrame = frame;
        self.playerFrame = [NSValue valueWithCGRect:frame];
        self.mediaCenter = CGPointMake(CGRectGetMinX(frame) + CGRectGetWidth(frame) / 2.0, CGRectGetMinY(frame) + CGRectGetHeight(frame) / 2.0);
        self.containerMode = AWETextContainerModeSelectTime;
        self.containerView = [[UIView alloc] initWithFrame:self.bounds];
        self.containerView.backgroundColor = [UIColor clearColor];
        self.accrtl_viewType = ACCRTLViewTypeNormal;
        [self addSubview:self.containerView];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame needMask:(BOOL)needMask playerFrame:(CGRect)playerFrame type:(AWEStoryTextContainerType)type
{
    self = [super initWithFrame:frame];
    if (self) {
        self.originalFrame = frame;
        self.type = type;
        self.didClickFinish = YES;
        [self setupUIWithFrame:frame needMask:needMask playerFrame:playerFrame];
        self.accrtl_viewType = ACCRTLViewTypeNormal;
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame needMask:(BOOL)needMask playerFrame:(CGRect)playerFrame textInfo:(AWEStoryTextImageModel *)textInfo type:(AWEStoryTextContainerType)type completion:(void (^)(BOOL))completion
{
    self = [super initWithFrame:frame];
    if (self) {
        self.originalFrame = frame;
        self.type = type;
        self.didClickFinish = YES;
        [self setupUIWithFrame:frame needMask:needMask playerFrame:playerFrame];
        [self addExternalTextViewWithTextInfo:textInfo anchorModels:nil completion:^(BOOL success, AWEStoryBackgroundTextView *textView) {
            if (completion) {
                completion(success);
            }
        }];
        self.accrtl_viewType = ACCRTLViewTypeNormal;
    }
    
    return self;
}

- (void)setupUIWithFrame:(CGRect)frame needMask:(BOOL)needMask playerFrame:(CGRect)playerFrame
{
    self.mediaCenter = CGPointMake(CGRectGetMinX(playerFrame) + CGRectGetWidth(playerFrame) / 2.0, CGRectGetMinY(playerFrame) + CGRectGetHeight(playerFrame) / 2.0);
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    self.containerView.backgroundColor = [UIColor clearColor];
    self.containerView.accrtl_viewType = ACCRTLViewTypeNormal;
    [self addSubview:self.containerView];
    
    [self addSubview:self.toolBar];
    [self addSubview:self.finishButton];
    [self addSubview:self.topMaskView];
    
    if ([AWEXScreenAdaptManager needAdaptScreen]) {
        //对齐线
        [self addSubview:self.leftAlignLine];
        [self addSubview:self.rightAlignLine];
        [self addSubview:self.bottomAlignLine];
        [self addSubview:self.centerVerticalAlignLine];
        [self addSubview:self.centerHorizontalAlignLine];
    }
    
    if (needMask) {
        [self createMaskViewWithFrame:frame playerFrame:playerFrame];
        self.playerFrame = [NSValue valueWithCGRect:playerFrame];
    }
    @weakify(self);
    self.toolBar.colorChooseView.didSelectedColorBlock = ^(AWEStoryColor * selectColor, NSIndexPath *indexPath) {
        @strongify(self);
        self.currentOperationView.color = selectColor;
        self.currentOperationView.textInfoModel.colorIndex = indexPath;
        if (self.didSelectedColorBlock) {
            self.didSelectedColorBlock(selectColor, indexPath);
        }
    };
    
    self.toolBar.fontChooseView.didSelectedFontBlock = ^(AWEStoryFontModel *selectFont, NSIndexPath *indexPath) {
        @strongify(self);
        self.currentOperationView.selectFont = selectFont;
        self.currentOperationView.textInfoModel.fontIndex = indexPath;
        if (selectFont.hasBgColor) {
            self.toolBar.leftButton.enabled = YES;
        } else {
            self.toolBar.leftButton.enabled = NO;
        }
        ACCBLOCK_INVOKE(self.didSelectedFontBlock, selectFont, indexPath);
    };
    
    CGFloat topBeyond = (self.frame.size.height - ACC_SCREEN_HEIGHT) * 0.5 + ([UIDevice acc_isIPhoneX] ? 22 : 16);
    CGFloat leftBeyond = (self.frame.size.width - ACC_SCREEN_WIDTH) * 0.5;
    self.leftBeyond = leftBeyond;
    
    [self.toolBar.leftButton addTarget:self action:@selector(didClickedLeftButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.toolBar.alignmentButton addTarget:self action:@selector(didClickedAlignmentButton:) forControlEvents:UIControlEventTouchUpInside];
    
    ACCMasMaker(self.toolBar, {
        make.leading.equalTo(self.mas_leading).offset(leftBeyond);
        make.trailing.equalTo(self.mas_trailing).offset(-leftBeyond);
        make.height.equalTo(@(kAWEStoryToolBarHeight));
        make.bottom.equalTo(self.mas_bottom).offset(kAWEStoryToolBarHeight + [self correctedBottomValue]);
    });
    
    ACCMasMaker(self.topMaskView, {
        make.top.equalTo(self.mas_top).offset(AWEStoryTextContainerViewTopMaskMargin + ACC_NAVIGATION_BAR_OFFSET);
        make.right.left.bottom.equalTo(self);
    });
    
    CGFloat offsetY = topBeyond + ACC_NAVIGATION_BAR_OFFSET;
    ACCMasMaker(self.finishButton, {
        make.trailing.equalTo(self.mas_trailing).offset(- leftBeyond - 12);
        make.top.equalTo(self.mas_top).offset(offsetY);
        make.height.equalTo(@32);
    });
    
    self.finishButton.alpha = 0;
    self.finishButton.hidden = YES;
    [self p_addObservers];
    
    if (![AWEXScreenAdaptManager needAdaptScreen]) {
        //对齐线
        [self addSubview:self.leftAlignLine];
        [self addSubview:self.rightAlignLine];
        [self addSubview:self.bottomAlignLine];
        [self addSubview:self.centerVerticalAlignLine];
        [self addSubview:self.centerHorizontalAlignLine];
    }
    
    CGFloat wGap = 0.f;
    CGFloat hGap = 0.f;
    if (playerFrame.size.width && playerFrame.size.height) {
        wGap = (playerFrame.size.width - ACC_SCREEN_WIDTH)/2;
        hGap = (playerFrame.size.height - ACC_SCREEN_HEIGHT)/2;
    }
    
    ACCMasUpdate(self.leftAlignLine, {
        make.top.bottom.equalTo(self);
        make.width.mas_equalTo(1.5f);
        if (!ACCRTL().enableRTL) {
            make.left.equalTo(self).offset(14.5+wGap);
        } else {
            make.left.equalTo(self).offset(56.f+(self.acc_width - UIScreen.mainScreen.bounds.size.width)/2.f);
        }
    });
    ACCMasUpdate(self.rightAlignLine, {
        make.top.bottom.equalTo(self);
        make.width.mas_equalTo(1.5f);
        if (!ACCRTL().enableRTL) {
            make.right.equalTo(self).offset(-56.f-(self.acc_width - UIScreen.mainScreen.bounds.size.width)/2.f);
        } else {
            make.right.equalTo(self).offset(-(14.5+wGap));
        }
    });
    ACCMasUpdate(self.bottomAlignLine, {
        make.left.right.equalTo(self);
        make.height.mas_equalTo(1.5f);
        if ((playerFrame.size.width && playerFrame.size.height) && (playerFrame.size.height <= playerFrame.size.width) && self.maskViewTwo.superview) {//上下有黑边
            make.bottom.equalTo(self.maskViewTwo.mas_top);
        } else {
            if (@available(iOS 11.0,*)) {
                if ([AWEXScreenAdaptManager needAdaptScreen]) {
                    CGFloat offset = - ACC_IPHONE_X_BOTTOM_OFFSET - 73 - 100;
                    if ([UIDevice acc_isIPhoneXsMax]) {
                        offset = - ACC_IPHONE_X_BOTTOM_OFFSET - 85 - 100;
                    }
                    make.bottom.equalTo(self).offset(offset);
                } else {
                    make.bottom.equalTo(self).offset(-200.f);
                }
            }else{
                make.bottom.equalTo(self).offset(-200.f);
            }
        }
    });

    ACCMasMaker(self.centerVerticalAlignLine, {
        make.width.mas_equalTo(1.5f);
        make.centerX.equalTo(self);
        if ((playerFrame.size.width && playerFrame.size.height) && (playerFrame.size.height <= playerFrame.size.width) && self.maskViewTwo.superview) {//上下有黑边
            make.top.equalTo(self.maskViewOne.mas_bottom);
            make.bottom.equalTo(self.maskViewTwo.mas_top);
        } else {
            make.top.bottom.equalTo(self);
        }
    });

    ACCMasMaker(self.centerHorizontalAlignLine, {
        make.height.mas_equalTo(1.5f);
        make.left.right.equalTo(self);
        if ([AWEXScreenAdaptManager needAdaptScreen] &&
            ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay)) {
            make.centerY.mas_equalTo(self.mas_top).mas_offset(CGRectGetMidY(playerFrame));
        } else {
            make.centerY.equalTo(self.centerVerticalAlignLine).priorityMedium();
        }
    });

    self.fakeProfileView = [AWEStickerContainerFakeProfileView new];
    [self addSubview:self.fakeProfileView];
    self.fakeProfileView.bottomContainerView.hidden = YES;
    self.fakeProfileView.rightContainerView.hidden = YES;
    ACCMasMaker(self.fakeProfileView, {
        make.left.equalTo(self).offset((self.acc_width - UIScreen.mainScreen.bounds.size.width)/2.f);
        make.width.equalTo(@(UIScreen.mainScreen.bounds.size.width));
        if ((playerFrame.size.width && playerFrame.size.height) && (playerFrame.size.height <= playerFrame.size.width) && self.maskViewTwo.superview) {//上下有黑边
            make.top.equalTo(self.maskViewOne.mas_bottom);
        } else {
            make.top.equalTo(self);
        }
        if ([UIDevice acc_isIPhoneX]) {
            if (ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay)) {
                make.bottom.mas_equalTo(self.mas_top).mas_offset(CGRectGetMaxY(playerFrame) + 52.f);
            } else {
                if ([AWEXScreenAdaptManager needAdaptScreen]) {
                    make.bottom.equalTo(self.maskViewTwo.mas_top).offset(64.f);
                } else {
                    make.bottom.equalTo(self.maskViewTwo.mas_top).offset(-34.f);
                }
            }
        } else {
            if ((playerFrame.size.width && playerFrame.size.height) && (playerFrame.size.height <= playerFrame.size.width) && self.maskViewTwo.superview) {//上下有黑边
                make.bottom.equalTo(self.maskViewTwo.mas_top);
            } else {
                make.bottom.equalTo(self);
            }
        }
    });
    
    [self p_showEdgeLineWithType:AWEStoryTextEdgeLineNone];
    [self layoutIfNeeded];
}

- (void)createMaskViewWithFrame:(CGRect)frame playerFrame:(CGRect)playerFrame
{
    if ([AWEXScreenAdaptManager needAdaptScreen]) {
        //上下有黑边
        CGFloat maskTopHeight = CGRectGetMinY(playerFrame);
        CGFloat maskBottomHeight = frame.size.height - CGRectGetMaxY(playerFrame);
        
        CGFloat radius = 0.0;
        if (!ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay) &&
            ACC_FLOAT_EQUAL_TO([AWEXScreenAdaptManager standPlayerFrame].size.height, playerFrame.size.height) &&
            ACC_FLOAT_LESS_THAN([AWEXScreenAdaptManager standPlayerFrame].size.width, playerFrame.size.width)) {
            radius = 12.0;
        }
        
        self.maskViewOne = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), maskTopHeight + radius)];
        self.maskViewTwo = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(playerFrame) - radius, CGRectGetWidth(frame), maskBottomHeight + radius)];
        self.maskViewOne.backgroundColor = [UIColor blackColor];
        self.maskViewTwo.backgroundColor = [UIColor blackColor];
        
        [self makeMaskLayerForMaskViewOneWithRadius:radius];
        [self makeMaskLayerForMaskViewTwoWithRadius:radius];
        [self addSubview:self.maskViewOne];
        [self addSubview:self.maskViewTwo];
        
        if (CGRectGetWidth(playerFrame) < CGRectGetWidth(frame)) {
            //左右有黑边
            CGFloat maskWidth = (CGRectGetWidth(frame) - CGRectGetWidth(playerFrame)) * 0.5;
            self.maskViewThree = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(0, 0, maskWidth, CGRectGetHeight(frame))];
            self.maskViewFour = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(playerFrame), 0, maskWidth, CGRectGetHeight(frame))];
            self.maskViewThree.backgroundColor = [UIColor blackColor];
            self.maskViewFour.backgroundColor = [UIColor blackColor];
            [self addSubview:self.maskViewThree];
            [self addSubview:self.maskViewFour];
        }
        CGRect actualFrame = CGRectMake(MAX(0, CGRectGetMinX(playerFrame)), MAX(0, CGRectGetMinY(playerFrame)), MIN(CGRectGetWidth(frame),CGRectGetWidth(playerFrame)), MIN(CGRectGetHeight(frame),CGRectGetHeight(playerFrame)));
        AWEEditStickerBubbleManager.interactiveStickerBubbleManager.getParentViewActualFrameBlock = ^CGRect{
            return actualFrame;
        };
        AWEEditStickerBubbleManager.textStickerBubbleManager.getParentViewActualFrameBlock = ^CGRect{
            return actualFrame;
        };
    } else {
        if (CGRectGetHeight(playerFrame) < CGRectGetHeight(frame)) {
            //上下有黑边
            CGFloat maskHeight = (CGRectGetHeight(frame) - CGRectGetHeight(playerFrame)) * 0.5;
            self.maskViewOne = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), maskHeight)];
            self.maskViewTwo = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(playerFrame), CGRectGetWidth(frame), maskHeight)];
        } else if (CGRectGetWidth(playerFrame) < CGRectGetWidth(frame)) {
            //左右有黑边
            CGFloat maskWidth = (CGRectGetWidth(frame) - CGRectGetWidth(playerFrame)) * 0.5;
            self.maskViewOne = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(0, 0, maskWidth, CGRectGetHeight(frame))];
            self.maskViewTwo = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(playerFrame), 0, maskWidth, CGRectGetHeight(frame))];
        }
        self.maskViewOne.backgroundColor = [UIColor blackColor];
        self.maskViewTwo.backgroundColor = [UIColor blackColor];
        [self addSubview:self.maskViewOne];
        [self addSubview:self.maskViewTwo];
    }
}

#pragma mark - interaction sticker methods

- (AWEStoryBackgroundTextView *)addTextViewWithTextImageInfo:(AWEStoryTextImageModel *)textInfo
                                                anchorModels:(ACCStoryTextAnchorModels *)anchorModels
                                               locationModel:(AWEInteractionStickerLocationModel *)location
{
    if (!textInfo || !location) {
        return nil;
    }
    
    AWEStoryBackgroundTextView *textView = [self addExternalTextViewWithTextInfo:textInfo anchorModels:anchorModels completion:nil];
    [self p_recoverPositionForTextView:textView withModel:location];
    
    return textView;
}

- (AWEStoryBackgroundTextView *)addCaptionWithWithFrame:(AWEStoryTextImageModel *)textInfo locationModel:(AWEInteractionStickerLocationModel *)location
{
    if (!textInfo) {
        return nil;
    }
    
    if (!location) {
        location = [[AWEInteractionStickerLocationModel alloc] init];
        location.scale = [NSDecimalNumber decimalNumberWithString:@"1"];
        location.x = [NSDecimalNumber decimalNumberWithString:@"0.1"];
        location.y = [NSDecimalNumber decimalNumberWithString:@"0.05"];
    }
    
    AWEStoryBackgroundTextView *captionView = [self addExternalTextViewWithTextInfo:textInfo anchorModels:nil completion:nil];
    [self p_recoverPositionForTextView:captionView withModel:location];
    self.captionView = captionView;
    
    return captionView;
}

- (AWEStoryBackgroundTextView *)addExternalTextViewWithTextInfo:(AWEStoryTextImageModel *)model
                                                   anchorModels:(ACCStoryTextAnchorModels *)anchorModels
                                                     completion:(void (^)(BOOL success,AWEStoryBackgroundTextView *textView))completion
{
    if (!model || ACC_isEmptyString(model.content)) {
        ACCBLOCK_INVOKE(completion, NO, nil);
        return nil;
    }
    
    AWEStoryBackgroundTextView *textView;
    if (model.isCaptionSticker) {
        textView = [[AWEStoryBackgroundTextView alloc] initAsCaptionGestureView];
    } else {
        textView = [[AWEStoryBackgroundTextView alloc] initWithTextInfo:model anchorModels:anchorModels isForImage:[self isForImage]];
    }

    CGPoint lastCenterInScreen = CGPointMake(ACC_SCREEN_WIDTH * 0.5, ACC_SCREEN_HEIGHT * 0.5);
    CGPoint basicCenterInScreen = CGPointMake(ACC_SCREEN_WIDTH * 0.5, ACC_SCREEN_HEIGHT * 0.27 - 26);
    textView.delegate = self;
    textView.gestureManager = self.gestureManager;
    if (@available(iOS 9.0, *)) {
        textView.lastCenter = [[[UIApplication sharedApplication].delegate window] convertPoint:lastCenterInScreen toView:self];
        textView.basicCenter = [[[UIApplication sharedApplication].delegate window] convertPoint:basicCenterInScreen toView:self];
    } else {
        textView.lastCenter = lastCenterInScreen;
        textView.basicCenter = basicCenterInScreen;
    }
    textView.leftBeyond = self.leftBeyond;
    
    if (!model.isPOISticker && [self isForImage]) {
        textView.isFirstAppear = NO;
    }
    
    @weakify(self);
    textView.textChangedBlock = ^(NSString *content) {
        @strongify(self);
        self.finishButton.enabled = !ACC_isEmptyString(content);
    };
    
    [textView setAutoDismissHandleBlock:^(AWEStoryBackgroundTextView *textView) {
        @strongify(self);
        if (textView == self.currentOperationView) {
            self.currentOperationView = nil;
        }
    }];
    [textView setShouldBeginGestureBlock:^ BOOL(UIGestureRecognizer *panGesture) {
        @strongify(self);
        if (self.currentOperationView && panGesture.view != self.currentOperationView) {
            return NO;
        }
        return YES;
    }];
    
    if (textView.isInteractionSticker) {//remove exist poi sticker
        [self.textViews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AWEStoryBackgroundTextView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            @strongify(self);
            if (obj.isInteractionSticker) {
                [self.textViews removeObject:obj];
                [obj removeFromSuperview];
            }
        }];
    }
    
    if (!textView.isCaption) {
        [self.textViews addObject:textView];
    }
    [textView initPosWithSuperView:self.containerView];
    
    ACCBLOCK_INVOKE(completion, YES, textView);
    
    if (textView.isInteractionSticker) {
        if (self.lastInteractionStickerLocation.width.floatValue && self.lastInteractionStickerLocation.height.floatValue) {//如果是更改POI贴纸则恢复为上一个的位置
            [self p_recoverPositionForTextView:textView withModel:self.lastInteractionStickerLocation];
        } else {
            //record location the first time
            [self recordSickerLocationForView:textView];
            [self showHintTextOnSticker:textView];
        }
    }
    
    return textView;
}

//草稿箱恢复
- (void)recoverDraftInteractionStickerWithModel:(AWEInteractionStickerModel *)info
{
    if (info.type == AWEInteractionStickerTypePOI && info.trackInfo) {
        NSData* data = [info.trackInfo dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *values = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        if ([values count]) {
            NSArray *locationArr = [MTLJSONAdapter modelsOfClass:[AWEInteractionStickerLocationModel class] fromJSONArray:values error:nil];
            if ([locationArr count]) {
                AWEInteractionStickerLocationModel *location = [locationArr firstObject];//only has 1 poi sticker
                
                __block AWEStoryBackgroundTextView *recoverTextView;
                [self.textViews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AWEStoryBackgroundTextView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.isInteractionSticker) {
                        recoverTextView = obj;
                        *stop = YES;
                    }
                }];
                
                recoverTextView.interactionStickerInfo = info;
                [self p_recoverPositionForTextView:recoverTextView withModel:location];
            }
        }
    }
}

- (void)recoverDraftInteractionStickerWithModel:(AWEInteractionStickerModel *)info poiLocation:(AWEInteractionStickerLocationModel *)location
{
    if (info.type == AWEInteractionStickerTypePOI && info.trackInfo) {
        if (location) {
            __block AWEStoryBackgroundTextView *recoverTextView;
            [self.textViews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(AWEStoryBackgroundTextView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.isInteractionSticker) {
                    recoverTextView = obj;
                    *stop = YES;
                }
            }];
            
            recoverTextView.interactionStickerInfo = info;
            [self p_recoverPositionForTextView:recoverTextView withModel:location];
        }
    }
}

// 恢复位置信息
- (void)recoverPositionForTextView:(AWEStoryBackgroundTextView *)textView locationModel:(AWEInteractionStickerLocationModel *)location
{
    [self p_recoverPositionForTextView:textView withModel:location];
}

- (void)p_recoverPositionForTextView:(AWEStoryBackgroundTextView *)textView withModel:(AWEInteractionStickerLocationModel *)location
{
    if (!location.scale) {
        location.scale = [NSDecimalNumber decimalNumberWithString:@"1.0"];
    }
    CGFloat radius = location.rotation.floatValue / (180 / M_PI);
    textView.currentScale = location.scale.floatValue;
    textView.transform = CGAffineTransformRotate(textView.transform, radius);
    CGAffineTransform currentOperationViewTranform = CGAffineTransformMakeRotation(radius);
    textView.transform = CGAffineTransformScale(currentOperationViewTranform, textView.currentScale, textView.currentScale);
    
    if (textView.isInteractionSticker) {
        if (!self.playerFrame) {
            textView.center = CGPointMake(self.bounds.size.width*location.x.floatValue,self.bounds.size.height*location.y.floatValue);
        } else {
            CGRect playerFrame = [self.playerFrame CGRectValue];
            if (CGRectGetHeight(playerFrame) < CGRectGetHeight(self.frame)) {
                //上下有黑边
                textView.acc_centerX = self.bounds.size.width*location.x.floatValue;
                textView.acc_centerY = playerFrame.size.height*location.y.floatValue + playerFrame.origin.y;
            } else if (CGRectGetWidth(playerFrame) < CGRectGetWidth(self.frame)) {
                //左右有黑边
                textView.acc_centerX = playerFrame.size.width*location.x.floatValue + playerFrame.origin.x;
                textView.acc_centerY = self.bounds.size.height*location.y.floatValue;
            } else {
                textView.center = CGPointMake(self.bounds.size.width*location.x.floatValue,self.bounds.size.height*location.y.floatValue);
            }
        }
    } else {
        textView.center = CGPointMake(self.mediaCenter.x + location.x.floatValue - self.originalFrame.origin.x, self.mediaCenter.y + location.y.floatValue - self.originalFrame.origin.y);
        textView.lastCenter = textView.center;
    }
    
    [self p_handleBorderViewTransformWithAbsoluteScale:textView.currentScale forTextView:textView];
}

- (AWEStoryTextPanDirectionOptions)p_getDirectionWithTranslation:(CGPoint)currentPoint
{
    AWEStoryTextPanDirectionOptions direction = AWEStoryTextPanDirectionNone;
    if (currentPoint.x > 0.f) {
        direction |= AWEStoryTextPanDirectionRight;
    } else if (currentPoint.x < 0.f){
        direction |= AWEStoryTextPanDirectionLeft;
    }
    if (currentPoint.y > 0.f) {
        direction |= AWEStoryTextPanDirectionDown;
    } else if (currentPoint.y < 0.f) {
        direction |= AWEStoryTextPanDirectionUp;
    }
    return direction;
}

- (void)p_resetAdsorbingWithEditView:(UIView *)editView width:(CGFloat)true_w height:(CGFloat)true_h
{
    BOOL reachLeftEdge = ACC_FLOAT_EQUAL_TO(editView.center.x,self.leftAlignLine.acc_right + true_w/2);
    BOOL reachRightEdge = ACC_FLOAT_EQUAL_TO(editView.center.x,self.rightAlignLine.acc_left - true_w/2);
    BOOL reachBottomEdge = ACC_FLOAT_EQUAL_TO(editView.center.y,self.bottomAlignLine.acc_top - true_h/2);
    BOOL reachCenterHorizontalLine = ACC_FLOAT_EQUAL_TO(editView.center.y, self.centerHorizontalAlignLine.acc_centerY);
    BOOL reachCenterVerticalLine = ACC_FLOAT_EQUAL_TO(editView.center.x, self.centerVerticalAlignLine.acc_centerX);
    if (!(reachBottomEdge || reachRightEdge || reachLeftEdge || reachCenterHorizontalLine || reachCenterVerticalLine)) {
        self.isEdgeAdsorbing = NO;
    }
}

- (void)p_checkAdsorbingWithEditView:(UIView *)editView width:(CGFloat)true_w height:(CGFloat)true_h direction:(AWEStoryTextPanDirectionOptions)direction
{
    BOOL reachLeftEdge = ACC_FLOAT_EQUAL_TO(editView.center.x,self.leftAlignLine.acc_right + true_w/2) && (direction & AWEStoryTextPanDirectionLeft);//从右往左移直到触左边线
    BOOL reachRightEdge = ACC_FLOAT_EQUAL_TO(editView.center.x,self.rightAlignLine.acc_left - true_w/2) && (direction & AWEStoryTextPanDirectionRight);//从左往右移直到触右边线
    BOOL reachBottomEdge = ACC_FLOAT_EQUAL_TO(editView.center.y,self.bottomAlignLine.acc_top - true_h/2) && (direction & AWEStoryTextPanDirectionDown);//从上往下移直到触底边线
    BOOL reachCenterHorizontalWhenMoveVertically = ACC_FLOAT_EQUAL_TO(editView.center.y, self.centerHorizontalAlignLine.acc_centerY) &&
    ((direction & AWEStoryTextPanDirectionDown) || direction & AWEStoryTextPanDirectionUp);
    BOOL reachCenterVerticalWhenMoveHorizontally = ACC_FLOAT_EQUAL_TO(editView.center.x, self.centerVerticalAlignLine.acc_centerX) &&
    ((direction & AWEStoryTextPanDirectionLeft) || direction & AWEStoryTextPanDirectionRight);

    if (reachLeftEdge || reachRightEdge || reachBottomEdge || reachCenterHorizontalWhenMoveVertically || reachCenterVerticalWhenMoveHorizontally) {
        self.isEdgeAdsorbing = YES;
    }
}

- (void)p_updateTranslationWithGesture:(UIPanGestureRecognizer *)gesture
                                  view:(AWEStoryBackgroundTextView *)editView
                                center:(CGPoint)newCenter
                             direction:(AWEStoryTextPanDirectionOptions)direction {
    if (gesture.state == UIGestureRecognizerStateChanged) {
        editView.center = newCenter;
        [self p_alignEdgeWithView:editView direction:direction];
        [self recordSickerLocationForView:self.currentOperationView];
        [gesture setTranslation:CGPointZero inView:editView.superview];
    }
}

- (void)p_alignEdgeWithView:(AWEStoryBackgroundTextView *)editView  direction:(AWEStoryTextPanDirectionOptions)direction {
    //[self setAnchorPoint:CGPointMake(0.5, 0.5) forView:editView];
    CGFloat radius = atan2f(editView.transform.b, editView.transform.a);
    CGPoint position = editView.center;
    //position.x = editView.frame.origin.x + (editView.layer.anchorPoint.x) * (editView.bounds.size.width);
    //position.y = editView.frame.origin.y + (editView.layer.anchorPoint.y) * (editView.bounds.size.height);
    CGSize scaleSize = CGSizeMake(editView.textView.bounds.size.width*editView.currentScale, editView.textView.bounds.size.height*editView.currentScale);
    if (!editView.isInteractionSticker) {
        scaleSize = CGSizeMake(editView.textView.textContainer.size.width * editView.currentScale, editView.textView.textContainer.size.height * editView.currentScale);
    }
    
    CGFloat true_h = fabs(scaleSize.width * sin(fabs(radius))) + fabs(scaleSize.height * cos(fabs(radius)));
    CGFloat true_w = fabs(scaleSize.width * cos(fabs(radius))) + fabs(scaleSize.height * sin(fabs(radius)));
    
    if ((direction & AWEStoryTextPanDirectionLeft) || (direction & AWEStoryTextPanDirectionRight)) {
        //left edge line
        if (ACC_FLOAT_EQUAL_TO(position.x - true_w/2,self.leftAlignLine.acc_right)) {
            [self p_showEdgeLineWithType:AWEStoryTextEdgeLineLeft];
        } else {
            [self p_hideEdgeLineWithType:AWEStoryTextEdgeLineLeft];
        }
        
        //right edge line
        if (ACC_FLOAT_EQUAL_TO(position.x + true_w/2,self.rightAlignLine.acc_left)) {
            [self p_showEdgeLineWithType:AWEStoryTextEdgeLineRight];
        } else {
            [self p_hideEdgeLineWithType:AWEStoryTextEdgeLineRight];
        }

        // center vertical line
        if (ACC_FLOAT_EQUAL_TO(position.x, self.centerVerticalAlignLine.acc_centerX)) {
            [self p_showEdgeLineWithType:AWEStoryTextEdgeLineCenterVertical];
        } else {
            [self p_hideEdgeLineWithType:AWEStoryTextEdgeLineCenterVertical];
        }
    }
    
    if ((direction & AWEStoryTextPanDirectionDown) || (direction & AWEStoryTextPanDirectionUp)) {
        //bottom edge line
        if (ACC_FLOAT_EQUAL_TO(position.y + true_h/2,self.bottomAlignLine.acc_top)) {
            [self p_showEdgeLineWithType:AWEStoryTextEdgeLineDown];
        } else {
            [self p_hideEdgeLineWithType:AWEStoryTextEdgeLineDown];
        }

        //center horizontal line
        if (ACC_FLOAT_EQUAL_TO(position.y, self.centerHorizontalAlignLine.acc_centerY)) {
            [self p_showEdgeLineWithType:AWEStoryTextEdgeLineCenterHorizontal];
        } else {
            [self p_hideEdgeLineWithType:AWEStoryTextEdgeLineCenterHorizontal];
        }
    }
}

- (void)p_hideEdgeLineWithType:(AWEStoryTextEdgeLineType)type {
    switch (type) {
        case AWEStoryTextEdgeLineLeft:{
            if (!self.leftAlignLine.hidden) {
                self.leftAlignLine.hidden = YES;
                self.leftAlignLine.alpha = 0.f;
            }
        }
            break;
        case AWEStoryTextEdgeLineRight:{
            if (!self.rightAlignLine.hidden) {
                self.rightAlignLine.hidden = YES;
                self.rightAlignLine.alpha = 0.f;
            }
        }
            break;
        case AWEStoryTextEdgeLineDown:{
            if (!self.bottomAlignLine.hidden) {
                self.bottomAlignLine.hidden = YES;
                self.bottomAlignLine.alpha = 0.f;
            }
        }
            break;
        case AWEStoryTextEdgeLineCenterVertical:{
            if (!self.centerVerticalAlignLine.hidden) {
                self.centerVerticalAlignLine.hidden = YES;
                self.centerVerticalAlignLine.alpha = 0.f;
            }
        }
            break;
        case AWEStoryTextEdgeLineCenterHorizontal:{
            if (!self.centerHorizontalAlignLine.hidden) {
                self.centerHorizontalAlignLine.hidden = YES;
                self.centerHorizontalAlignLine.alpha = 0.f;
            }
        }
            break;
        case AWEStoryTextEdgeLineNone:
            break;
    }
}

- (void)p_showEdgeLineWithType:(AWEStoryTextEdgeLineType)type {
    
    if (self.isInPinchOrRotate && (type != AWEStoryTextEdgeLineNone)) {
        return;
    }
    
    switch (type) {
        case AWEStoryTextEdgeLineLeft:{
//            if (self.leftAlignLine.hidden) {
//                self.leftAlignLine.hidden = NO;
//                [UIView animateWithDuration:0.2f animations:^{
//                    self.leftAlignLine.alpha = 1.f;
//                }];
//            }
        }
            break;
        case AWEStoryTextEdgeLineRight:{
//            if (self.rightAlignLine.hidden) {
//                self.rightAlignLine.hidden = NO;
//                [UIView animateWithDuration:0.2f animations:^{
//                    self.rightAlignLine.alpha = 1.f;
//                }];
//            }
        }
            break;
        case AWEStoryTextEdgeLineDown:{
//            if (self.bottomAlignLine.hidden) {
//                self.bottomAlignLine.hidden = NO;
//                [UIView animateWithDuration:0.2f animations:^{
//                    self.bottomAlignLine.alpha = 1.f;
//                }];
//            }
        }
            break;
        case AWEStoryTextEdgeLineCenterVertical:{
            if (self.centerVerticalAlignLine.hidden) {
                self.centerVerticalAlignLine.hidden = NO;
                [UIView animateWithDuration:0.2f animations:^{
                    self.centerVerticalAlignLine.alpha = 1.f;
                }];
            }
        }
            break;
        case AWEStoryTextEdgeLineCenterHorizontal:{
            if (self.centerHorizontalAlignLine.hidden) {
                self.centerHorizontalAlignLine.hidden = NO;
                [UIView animateWithDuration:0.2f animations:^{
                    self.centerHorizontalAlignLine.alpha = 1.f;
                }];
            }
        }
            break;
        case AWEStoryTextEdgeLineNone: {
            if ((!self.leftAlignLine.hidden || !self.rightAlignLine.hidden || !self.bottomAlignLine.hidden || !self.centerVerticalAlignLine.hidden || !self.centerHorizontalAlignLine.hidden) && !self.isInPinchOrRotate) {
                @weakify(self);
                self.edgeLineTimer = [NSTimer acc_timerWithTimeInterval:1.f block:^(NSTimer * _Nonnull timer) {
                    @strongify(self);
                    self.leftAlignLine.hidden = YES;
                    self.rightAlignLine.hidden = YES;
                    self.bottomAlignLine.hidden = YES;
                    self.centerVerticalAlignLine.hidden = YES;
                    self.centerHorizontalAlignLine.hidden = YES;
                    self.fakeProfileView.bottomContainerView.hidden = YES;
                    self.fakeProfileView.rightContainerView.hidden = YES;
                    [UIView animateWithDuration:0.2f animations:^{
                        self.leftAlignLine.alpha = 0.f;
                        self.rightAlignLine.alpha = 0.f;
                        self.bottomAlignLine.alpha = 0.f;
                        self.centerVerticalAlignLine.alpha = 0;
                        self.centerHorizontalAlignLine.alpha = 0;
                    }];
                } repeats:NO];
                [[NSRunLoop currentRunLoop] addTimer:self.edgeLineTimer forMode:NSRunLoopCommonModes];
                [self.edgeLineTimer fire];
            } else {
                if ([self.edgeLineTimer isValid]) {
                    [self.edgeLineTimer invalidate];
                }
                self.leftAlignLine.hidden = YES;
                self.rightAlignLine.hidden = YES;
                self.bottomAlignLine.hidden = YES;
                self.fakeProfileView.bottomContainerView.hidden = YES;
                self.fakeProfileView.rightContainerView.hidden = YES;
                self.centerVerticalAlignLine.hidden = YES;
                self.centerHorizontalAlignLine.hidden = YES;
                self.leftAlignLine.alpha = 0.f;
                self.rightAlignLine.alpha = 0.f;
                self.bottomAlignLine.alpha = 0.f;
                self.centerVerticalAlignLine.alpha = 0;
                self.centerHorizontalAlignLine.alpha = 0;
            }
        }
            break;
    }
}

- (void)recordSickerLocationForView:(AWEStoryBackgroundTextView *)textView {
    if (![textView isKindOfClass:[AWEStoryBackgroundTextView class]]) {
        return;
    }
    
    CGRect playerFrame = self.frame;
    if (self.playerFrame != nil) {
        playerFrame = [self.playerFrame CGRectValue];
    }
    
    // record poi  sticker location info
    if (textView.isInteractionSticker) {
        if (playerFrame.size.width && playerFrame.size.height) {
            
            NSString *x = [NSString stringWithFormat:@"%.4f",(CGFloat)(textView.center.x/playerFrame.size.width)];
            NSString *y = [NSString stringWithFormat:@"%.4f",(CGFloat)(textView.center.y/playerFrame.size.height)];
            if (CGRectGetHeight(playerFrame) < CGRectGetHeight(self.frame)) {
                //上下有黑边
                y = [NSString stringWithFormat:@"%.4f",(CGFloat)((textView.center.y - playerFrame.origin.y)/playerFrame.size.height)];
            } else if (CGRectGetWidth(playerFrame) < CGRectGetWidth(self.frame)) {
                //左右有黑边
                x = [NSString stringWithFormat:@"%.4f",(CGFloat)((textView.center.x - playerFrame.origin.x)/playerFrame.size.width)];
            }
            
            AWEInteractionStickerLocationModel *locationInfoModel = textView.stickerLocation;
            
            locationInfoModel.x = [NSDecimalNumber decimalNumberWithString:x];
            locationInfoModel.y = [NSDecimalNumber decimalNumberWithString:y];
            
            if (textView.currentScale) {
                CGFloat touchScale = 1.f;
                NSString *width = [NSString stringWithFormat:@"%.4f",(CGFloat)(touchScale*textView.textView.bounds.size.width*textView.currentScale/playerFrame.size.width)];
                NSString *height = [NSString stringWithFormat:@"%.4f",(CGFloat)(touchScale*textView.textView.bounds.size.height*textView.currentScale/playerFrame.size.height)];
                locationInfoModel.width = [NSDecimalNumber decimalNumberWithString:width];
                locationInfoModel.height = [NSDecimalNumber decimalNumberWithString:height];
                
                NSString *scaleStr = [NSString stringWithFormat:@"%.4f",textView.currentScale];
                locationInfoModel.scale = [NSDecimalNumber decimalNumberWithString:scaleStr];
                CGFloat radius = atan2f(textView.transform.b, textView.transform.a);
                CGFloat degree = radius * (180 / M_PI);
                NSString *dStr = [NSString stringWithFormat:@"%.4f",degree];
                locationInfoModel.rotation = [NSDecimalNumber decimalNumberWithString:dStr];
            }
            if (textView.isInteractionSticker) {
                [self p_recordLastSickerLocationForTextView:textView];
            }
        }
    }
    if (textView.isInteractionSticker) {
        return;
    }
    if (playerFrame.size.width && playerFrame.size.height) {
        CGFloat offsetX = textView.center.x - self.mediaCenter.x + self.originalFrame.origin.x;
        CGFloat offsetY = textView.center.y - self.mediaCenter.y + self.originalFrame.origin.y;
        NSString *offsetXStr = [NSString stringWithFormat:@"%.4f",(CGFloat)offsetX];
        NSString *offsetYStr = [NSString stringWithFormat:@"%.4f",(CGFloat)offsetY];
        AWEInteractionStickerLocationModel *locationModelToModified = textView.stickerLocation;
        locationModelToModified.x = [NSDecimalNumber decimalNumberWithString:offsetXStr];
        locationModelToModified.y = [NSDecimalNumber decimalNumberWithString:offsetYStr];
        
        if (textView.currentScale) {
            CGFloat touchScale = 1.f;
            NSString *width = [NSString stringWithFormat:@"%.4f",(CGFloat)(touchScale*textView.textView.bounds.size.width*textView.currentScale/playerFrame.size.width)];
            NSString *height = [NSString stringWithFormat:@"%.4f",(CGFloat)(touchScale*textView.textView.bounds.size.height*textView.currentScale/playerFrame.size.height)];

            locationModelToModified.width = [NSDecimalNumber decimalNumberWithString:width];
            locationModelToModified.height = [NSDecimalNumber decimalNumberWithString:height];
            
            NSString *scaleStr = [NSString stringWithFormat:@"%.4f",textView.currentScale];
            locationModelToModified.scale = [NSDecimalNumber decimalNumberWithString:scaleStr];
            
            CGFloat radius = atan2f(textView.transform.b, textView.transform.a);
            CGFloat degree = radius * (180 / M_PI);
            NSString *dStr = [NSString stringWithFormat:@"%.4f",degree];

            locationModelToModified.rotation = [NSDecimalNumber decimalNumberWithString:dStr];
        }
    }
    
    if (textView.isCaption && [self.delegate respondsToSelector:@selector(captionView:updateLocation:)]) {
        [self.delegate captionView:textView updateLocation:textView.stickerLocation];
    }
}

//更换POI贴纸的时候要使用之前的位置信息
- (void)p_recordLastSickerLocationForTextView:(AWEStoryBackgroundTextView *)textView {
    if (!textView) {
        return;
    }
    
    __block BOOL hasInteractionSticker = NO;
    [self.textViews enumerateObjectsUsingBlock:^(AWEStoryBackgroundTextView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.isInteractionSticker) {
            hasInteractionSticker = YES;
            *stop = YES;
        }
    }];
    
    if (textView.isInteractionSticker && hasInteractionSticker) {
        self.lastInteractionStickerLocation.x = textView.stickerLocation.x;
        self.lastInteractionStickerLocation.y = textView.stickerLocation.y;
        self.lastInteractionStickerLocation.scale = textView.stickerLocation.scale;
        self.lastInteractionStickerLocation.rotation = textView.stickerLocation.rotation;
        
        //只是用来做条件判断
        self.lastInteractionStickerLocation.width = textView.stickerLocation.width;
        self.lastInteractionStickerLocation.height = textView.stickerLocation.height;
    }
}

#pragma mark - observers

- (void)p_addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardChangeFrameNoti:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHideNoti:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)p_removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)handleKeyboardChangeFrameNoti:(NSNotification *)noti
{
    if (!self.window || !self.superview || !self.beginLabelProgress) {
        return;
    }
    
    NSTimeInterval duration = [[noti.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [[noti.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    CGRect keyboardBounds;
    [[noti.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    
    CGFloat offset = 0;
    if (keyboardBounds.origin.y > ACC_SCREEN_HEIGHT - 1) {
        //隐藏
        offset = self.toolBar.acc_height;
    } else {
        //出现
        offset = - (ACC_SCREEN_HEIGHT - keyboardBounds.origin.y);
    }
    
    ACCMasUpdate(self.toolBar, {
        make.bottom.equalTo(self.mas_bottom).offset(offset + [self correctedBottomValue]);
    });
    
    self.currentOperationView.keyboardHeight = (keyboardBounds.size.height > 0) ? keyboardBounds.size.height : 260;
    ACCBLOCK_INVOKE(self.keyboardShowBlock, self.currentOperationView.keyboardHeight);
    
    [UIView animateWithDuration:duration delay:0 options:(curve<<16) animations:^{
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)handleKeyboardWillHideNoti:(NSNotification *)noti
{
    if (!self.didClickFinish) {
        [self didFinishEdit];
    }
}

#pragma mark -

- (void)deselectTextView
{
    if (self.currentOperationView) {
        [self.currentOperationView hideHandle];
        self.currentOperationView = nil;
    }
}

- (void)startLabelProgress:(AWEStoryBackgroundTextView *)textView withGesture:(UIGestureRecognizer *)gesture videoDuration:(CGFloat)videoDuration
{
    if (textView.isCaption) {
        return;
    }
    
    //interaction sticker
    if (textView.isInteractionSticker || self.isForInteractionSticker) {
        return;
    }
    
    if (!textView && ![self checkForAddText]) {
        return;
    }
    
    if (self.beginLabelProgress) {
        return;
    }
    
    self.beginLabelProgress = YES;
    
    ACCBLOCK_INVOKE(self.startEditBlock);

    [self addSubview:self.textMaskView];
    
    self.finishButton.alpha = 0;
    self.textMaskView.alpha = 0;
    self.finishButton.hidden = NO;
    if (self.type == AWEStoryTextContainerTypeCamera) {
        self.textMaskView.backgroundColor = [UIColor clearColor];
        self.finishButton.enabled = !ACC_isEmptyString(textView.textView.text);
    }
    
    self.toolBar.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.finishButton.alpha = 1;
        self.textMaskView.alpha = 1;
    }];
    
    if (!textView) {
        textView = [[AWEStoryBackgroundTextView alloc] initWithIsForImage:[self isForImage]];
        textView.leftBeyond = self.leftBeyond;
        CGPoint lastCenterInScreen = CGPointMake(ACC_SCREEN_WIDTH * 0.5, ACC_SCREEN_HEIGHT * 0.5);
        CGPoint basicCenterInScreen = CGPointMake(ACC_SCREEN_WIDTH * 0.5, ACC_SCREEN_HEIGHT * 0.27 - 26);
        textView.delegate = self;
        textView.selectFont = self.toolBar.fontChooseView.selectFont;
        textView.gestureManager = self.gestureManager;
        textView.lastCenter = [[[UIApplication sharedApplication].delegate window] convertPoint:lastCenterInScreen toView:self];
        textView.basicCenter = [[[UIApplication sharedApplication].delegate window] convertPoint:basicCenterInScreen toView:self];
        @weakify(self);
        textView.textChangedBlock = ^(NSString *content) {
            @strongify(self);
            self.finishButton.enabled = !ACC_isEmptyString(content);
        };
        textView.realDuration = videoDuration;
        [textView setAutoDismissHandleBlock:^(AWEStoryBackgroundTextView *textView) {
            @strongify(self);
            if (textView == self.currentOperationView) {
                self.currentOperationView = nil;
            }
        }];
        [textView setShouldBeginGestureBlock:^ BOOL(UIGestureRecognizer *panGesture) {
            @strongify(self);
            if (self.currentOperationView && panGesture.view != self.currentOperationView) {
                return NO;
            }
            return YES;
        }];
        [self.textViews addObject:textView];
    }
    
    if (ACC_FLOAT_EQUAL_ZERO(textView.realDuration)) {
        textView.realStartTime = 0;
        textView.realDuration = videoDuration + 0.1;
    }
    
    self.currentOperationView = textView;
    self.topMaskView.hidden = NO;
    [textView resetWithSuperView:self.topMaskView];
    [self updateToolBarEnable:textView.selectFont];
    [self bringSubviewToFront:self.topMaskView];
    [self bringSubviewToFront:self.toolBar];
    [self bringSubviewToFront:self.finishButton];

    self.didClickFinish = NO;
    
    if (textView) {
        NSString *imageName = [NSString stringWithFormat:@"icTextStyle_%@", @(textView.style)];
        [self.toolBar.leftButton setImage:ACCResourceImage(imageName) forState:UIControlStateNormal];
        NSString *title = @"文本样式";
        if (textView.style == AWEStoryTextStyleStroke) {
            title = [title stringByAppendingString:@",描边"];
        } else if (textView.style == AWEStoryTextStyleBackground) {
            title = [title stringByAppendingString:@",背景"];
        } else if (textView.style == AWEStoryTextStyleAlphaBackground) {
            title = [title stringByAppendingString:@",半透明背景"];
        } else {
            title = [title stringByAppendingString:@",无"];
        }
        self.toolBar.leftButton.accessibilityLabel = title;
        NSString *alignImgName = [NSString stringWithFormat:@"icTextAlignment_%@", @(textView.alignmentType)];
        [self.toolBar.alignmentButton setImage:ACCResourceImage(alignImgName) forState:UIControlStateNormal];
        [self.toolBar.colorChooseView.collectionView selectItemAtIndexPath:textView.textInfoModel.colorIndex animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        
        __block NSUInteger index = NSNotFound;
        [ACCCustomFont().stickerFonts enumerateObjectsUsingBlock:^(AWEStoryFontModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.title isEqualToString:textView.textInfoModel.fontModel.title]) {
                index = idx;
                *stop = YES;
            }
        }];
        
        if (index != NSNotFound) {
            textView.textInfoModel.fontIndex = [NSIndexPath indexPathForRow:index inSection:0];
        } else {
            if (textView.textInfoModel.fontIndex.row >= ACCCustomFont().stickerFonts.count) {
                textView.textInfoModel.fontIndex = [NSIndexPath indexPathForRow:0 inSection:0];
            }
        }
        [self.toolBar.fontChooseView selectWithIndexPath:textView.textInfoModel.fontIndex];

        UIColor *color = textView.textInfoModel.fontColor.color;
        if (color && ![self.toolBar.colorChooseView.selectedColor.color isEqual: color]) {
            [self.toolBar.colorChooseView selectWithColor:color];
        }
    }
    
    [self p_showEdgeLineWithType:AWEStoryTextEdgeLineNone];
}

- (void)updateToolBarEnable:(AWEStoryFontModel *)font
{
    if (!font) {
        return;
    }
    
    if (font.hasBgColor) {
        self.toolBar.leftButton.enabled = YES;
    } else {
        self.toolBar.leftButton.enabled = NO;
    }
}

- (void)deleteTextView:(AWEStoryBackgroundTextView *)textView
{
    if (!textView) {
        return;
    }
    
    [textView removeFromSuperview];
    [self.textViews removeObject:textView];
}

- (void)removeAllTextStickerViews
{
    NSArray<AWEStoryBackgroundTextView *> *textStickerViews = [self.textViews copy];
    for (AWEStoryBackgroundTextView *textStickerView in textStickerViews) {
        [textStickerView removeFromSuperview];
    }
    [self.textViews removeAllObjects];
    
    self.currentOperationView = nil;
    kCanStoryTextContainerViewAngleAdsorbingVibrate = YES;
    [self.lastInteractionStickerLocation reset];
}

#pragma mark - 选时长相关

- (void)startSelectTimeForTextView:(AWEStoryBackgroundTextView *)textView isAlpha:(BOOL)isAlpha
{
    [self.textViews enumerateObjectsUsingBlock:^(AWEStoryBackgroundTextView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!isAlpha || [obj.textStickerId isEqualToString:textView.textStickerId]) {
            obj.alpha = 1;
        } else {
            obj.alpha = 0.34;
        }
    }];
}

- (void)endSelectTimeForTextView
{
    [self.textViews enumerateObjectsUsingBlock:^(AWEStoryBackgroundTextView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.alpha = 1;
    }];
}

- (void)updateTextViewsStatusWithCurrentPlayerTime:(CGFloat)currentPlayerTime isSelectTime:(BOOL)isSelectTime;
{
    for (AWEStoryBackgroundTextView *textView in self.textViews) {
        CGFloat startTime = textView.realStartTime;
        CGFloat duration = textView.realDuration;
        if (isSelectTime) {
            startTime = textView.finalStartTime;
            duration = textView.finalDuration;
        }
        
        if (!isSelectTime && [textView.textStickerId isEqualToString:self.currentOperationView.textStickerId]) {
            continue;
        }
        
        if ((ACC_FLOAT_GREATER_THAN(currentPlayerTime, startTime) || fabs(currentPlayerTime - startTime) < 0.1) && duration < 0) {
            textView.hidden = NO;
            continue;
        }
        
        if (textView.hidden && ACC_FLOAT_GREATER_THAN(currentPlayerTime, startTime) && ACC_FLOAT_LESS_THAN(currentPlayerTime, startTime + duration)) {
            textView.hidden = NO;
        }
        
        if (textView.hidden && (fabs(currentPlayerTime - startTime) < 0.1 || fabs(currentPlayerTime - startTime - duration) < 0.1)) {
            textView.hidden = NO;
        }

        if (!textView.hidden && (ACC_FLOAT_GREATER_THAN(currentPlayerTime, startTime + duration) || ACC_FLOAT_LESS_THAN(currentPlayerTime, startTime))) {
            textView.hidden = YES;
        }
    }
}

#pragma mark - AWEEditorStickerGestureProtocol

- (void)editorSticker:(AWEStoryBackgroundTextView *)editView receivedTapGesture:(UITapGestureRecognizer *)gesture
{
    // 字幕手势
    if (editView.isCaption && self.containerMode == AWETextContainerModeSelectTime) {
        ACCBLOCK_INVOKE(self.didTapCaptionBlock, editView.stickerEditId);
        return;
    }
    
    // 手势未选中目标
    if (!editView) {
        if (self.currentOperationView) {
            [self deselectTextView];
        } else {
            CGPoint loc = [gesture locationInView:gesture.view];
            BOOL isInPreview = CGRectContainsPoint([self.playerFrame CGRectValue], loc);
            if ((!self.isForStory && ![IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) isTextStickerShortcutEnabled]) || !isInPreview) {
                return;
            }
            [self startLabelProgress:nil withGesture:nil videoDuration:self.videoDuration];
            ACCBLOCK_INVOKE(self.startEditFromTapScreenBlock);
        }
        return;
    }
    
    if (![editView isKindOfClass:[AWEStoryBackgroundTextView class]]) {
        return;
    }
    
    if (self.containerMode == AWETextContainerModeSelectTime) {
        [self startSelectTimeForTextView:editView isAlpha:YES];
        return;
    }
    
    // 手势选中目标
    if (!editView.selected) {
        if (self.currentOperationView) {
            [self.currentOperationView hideHandle];
        }
        ACCBLOCK_INVOKE(self.firstTapBlock, editView);
        self.currentOperationView = editView;
        [editView showHandleThenDismiss];
        [self.containerView bringSubviewToFront:self.currentOperationView];
        
        if (!editView.isCaption &&
            self.textViews.lastObject != editView) {
            [self.textViews removeObject:editView];
            [self.textViews addObject:editView];
        }
    } else {
        BOOL textViewHidden = !editView.isInteractionSticker && editView.isHidden;
        if (!textViewHidden && !editView.isCaption) {
            ACCBLOCK_INVOKE(self.secondTapBlock, editView);
            // 双击编辑后下次不再展示
            [AWEEditStickerHintView setNoNeedShowForType:(editView.isInteractionSticker?AWEEditStickerHintTypeInteractive:AWEEditStickerHintTypeText)];
            [self dismissHintText];
        }
        if (!editView.isInteractionSticker && !editView.isHidden && !editView.isCaption) {
            [self startLabelProgress:editView withGesture:nil videoDuration:self.videoDuration];
            [editView hideHandle];
        } else {
            [editView hideHandle];
        }
    }
}

- (void)editorSticker:(AWEStoryBackgroundTextView *)editView receivedPanGesture:(UIPanGestureRecognizer *)gesture
{
    // 手势未选中目标
    if (!editView || ![editView isKindOfClass:[AWEStoryBackgroundTextView class]]) {
        return;
    }
    
    // 手势选中目标
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self gestureStartedWithTextSticker:editView];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        self.isInPinchOrRotate = NO;
    }
    
    ACCBLOCK_INVOKE(self.startPanGestureBlock);
    if (editView.enableEdit) {
        CGPoint currentPoint = [gesture translationInView:editView.superview];
        if ((editView.frame.origin.y + currentPoint.y >= 0) || editView.center.y + currentPoint.y < editView.editCenter.y) {
            editView.center = CGPointMake(editView.center.x, editView.center.y);
        } else {
            editView.center = CGPointMake(editView.center.x, editView.center.y + currentPoint.y);
        }
        [gesture setTranslation:CGPointZero inView:editView.superview];
        return;
    }
    
    CGPoint currentPoint = [gesture translationInView:editView.superview];
    
    // 字幕只可上下移动
    if (editView.isCaption) {
        currentPoint.x = 0;
    }
    
    CGPoint position = CGPointMake(editView.center.x+ currentPoint.x,editView.center.y + currentPoint.y);
    {
        CGSize scaleSize = CGSizeMake(editView.textView.bounds.size.width*editView.currentScale, editView.textView.bounds.size.height*editView.currentScale);
        if (!editView.isInteractionSticker) {
            scaleSize = CGSizeMake(editView.textView.textContainer.size.width * editView.currentScale, editView.textView.textContainer.size.height * editView.currentScale);
        }
        
        CGFloat radius = atan2f(editView.transform.b, editView.transform.a);
        CGFloat true_h = fabs(scaleSize.width * sin(fabs(radius))) + fabs(scaleSize.height * cos(fabs(radius)));
        CGFloat true_w = fabs(scaleSize.width * cos(fabs(radius))) + fabs(scaleSize.height * sin(fabs(radius)));
        CGPoint newCenter = position;
        if (editView.isCaption) {
            true_w = editView.bounds.size.width;
        }
        
        //set direction
        AWEStoryTextPanDirectionOptions direction = [self p_getDirectionWithTranslation:currentPoint];
        
        if (gesture.state == UIGestureRecognizerStateBegan) {//旋转后恢复可拖动状态
            [self p_resetAdsorbingWithEditView:editView width:true_w height:true_h];
        }
        
        //set limit edge
        CGFloat edgesShift = 0.5f;
        CGFloat continueMoveShift = 5.f;
        CGFloat sensitivity = 0.5f;

        static BOOL canHorizontalMoveVibrate = YES;
        static BOOL canVerticalMoveVibrate = YES;
        /** ============ 水平居中 && 垂直居中的处理 BEGIN ========== */
        if (direction & AWEStoryTextPanDirectionLeft || direction & AWEStoryTextPanDirectionRight) {
            // center vertical
            BOOL centerXWhenDirectionLeft = (direction & AWEStoryTextPanDirectionLeft) &&
            ACC_FLOAT_GREATER_THAN(editView.acc_centerX, self.centerVerticalAlignLine.acc_centerX) &&
            ACC_FLOAT_LESS_THAN(newCenter.x, self.centerVerticalAlignLine.acc_centerX);

            BOOL centerXWhenDirectionRight = (direction & AWEStoryTextPanDirectionRight) &&
            ACC_FLOAT_LESS_THAN(editView.acc_centerX, self.centerVerticalAlignLine.acc_centerX) &&
            ACC_FLOAT_GREATER_THAN(newCenter.x, self.centerVerticalAlignLine.acc_centerX);

            if (centerXWhenDirectionLeft || centerXWhenDirectionRight) {
                newCenter.x = self.centerVerticalAlignLine.acc_centerX;
                if (canHorizontalMoveVibrate) {
                    canHorizontalMoveVibrate = NO;
                }
            }

            if (self.isEdgeAdsorbing) {
                if (ACC_FLOAT_EQUAL_TO(editView.acc_centerX, self.centerVerticalAlignLine.acc_centerX)) {
                    // 垂直线吸附后继续左右移动的条件
                    if (currentPoint.x > continueMoveShift) {
                        // 向右移动
                        self.isEdgeAdsorbing = NO;
                        newCenter.x = self.centerVerticalAlignLine.acc_centerX + edgesShift;
                        canHorizontalMoveVibrate = YES;
                    } else if (currentPoint.x < -continueMoveShift) {
                        // 向左移动
                        self.isEdgeAdsorbing = NO;
                        newCenter.x = self.centerHorizontalAlignLine.acc_centerX - edgesShift;
                        canHorizontalMoveVibrate = YES;
                    }
                } else {
                    // 水平线吸附后继续左右移动的条件
                    if (ACC_FLOAT_EQUAL_TO(editView.acc_centerY, self.centerHorizontalAlignLine.acc_centerY)) {
                        if (fabs(currentPoint.x) > sensitivity) {//灵敏度
                            newCenter.y = self.centerHorizontalAlignLine.acc_centerY;
                            [self p_updateTranslationWithGesture:gesture view:editView center:newCenter direction:direction];
                        }
                    }
                }
            }
        }
        if (direction & AWEStoryTextPanDirectionUp || direction & AWEStoryTextPanDirectionDown) {
            // center horizontal
            BOOL centerYWhenDirectionUp = (direction & AWEStoryTextPanDirectionUp) &&
            ACC_FLOAT_GREATER_THAN(editView.acc_centerY, self.centerHorizontalAlignLine.acc_centerY) &&
            ACC_FLOAT_LESS_THAN(newCenter.y, self.centerHorizontalAlignLine.acc_centerY);

            BOOL centerYWhenDirectionDown = (direction & AWEStoryTextPanDirectionDown) &&
            ACC_FLOAT_LESS_THAN(editView.acc_centerY, self.centerHorizontalAlignLine.acc_centerY) &&
            ACC_FLOAT_GREATER_THAN(newCenter.y, self.centerHorizontalAlignLine.acc_centerY);
            if (centerYWhenDirectionUp || centerYWhenDirectionDown) {
                newCenter.y = self.centerHorizontalAlignLine.acc_centerY;
                if (canVerticalMoveVibrate) {
                    canVerticalMoveVibrate = NO;
                }
            }

            if (self.isEdgeAdsorbing) {
                if (ACC_FLOAT_EQUAL_TO(editView.acc_centerY, self.centerHorizontalAlignLine.acc_centerY)) {
                    // 水平线吸附后继续上下移动的条件
                    if (currentPoint.y > continueMoveShift) {
                        // 向下移动
                        self.isEdgeAdsorbing = NO;
                        newCenter.y = self.centerHorizontalAlignLine.acc_centerY + edgesShift;
                        canVerticalMoveVibrate = YES;
                    } else if (currentPoint.y < -continueMoveShift) {
                        // 向上移动
                        self.isEdgeAdsorbing = NO;
                        newCenter.y = self.centerHorizontalAlignLine.acc_centerY - edgesShift;
                        canVerticalMoveVibrate = YES;
                    }
                } else {
                    // 垂直线吸附后继续上下移动的条件
                    if (ACC_FLOAT_EQUAL_TO(editView.acc_centerX, self.centerVerticalAlignLine.acc_centerX)) {
                        if (fabs(currentPoint.y) > sensitivity) {//灵敏度
                            newCenter.x = self.centerVerticalAlignLine.acc_centerX;
                            [self p_updateTranslationWithGesture:gesture view:editView center:newCenter direction:direction];
                        }
                    }
                }
            }
        }
        /** ============ 水平居中 && 垂直居中的处理 END ========== */

        if (direction & AWEStoryTextPanDirectionLeft) {
            if (self.isEdgeAdsorbing) {
                if (!ACC_FLOAT_EQUAL_TO(editView.center.x,self.leftAlignLine.acc_right + true_w/2)) {
                    if (ACC_FLOAT_EQUAL_TO(editView.center.x,self.rightAlignLine.acc_left - true_w/2)) {
                        self.isEdgeAdsorbing = NO;//触右边线后往左移
                    } else if (ACC_FLOAT_EQUAL_TO(editView.center.y,self.bottomAlignLine.acc_top - true_h/2)) {//触底后可以左右移动
                        if (fabs(currentPoint.x) > sensitivity) {//灵敏度
                            newCenter.y = self.bottomAlignLine.acc_top - true_h/2;
                            [self p_updateTranslationWithGesture:gesture view:editView center:newCenter direction:direction];
                        }
                    }
                }
            }
        }
        if (direction & AWEStoryTextPanDirectionRight) {
            if (self.isEdgeAdsorbing) {
                if (!ACC_FLOAT_EQUAL_TO(editView.center.x,self.rightAlignLine.acc_left - true_w/2)) {
                    if (ACC_FLOAT_EQUAL_TO(editView.center.x,self.leftAlignLine.acc_right + true_w/2)) {
                        self.isEdgeAdsorbing = NO;//触左边线后往右移
                    } else if (ACC_FLOAT_EQUAL_TO(editView.center.y,self.bottomAlignLine.acc_top - true_h/2)) {//触底后可以左右移动
                        if (fabs(currentPoint.x) > sensitivity) {//灵敏度
                            newCenter.y = self.bottomAlignLine.acc_top - true_h/2;
                            [self p_updateTranslationWithGesture:gesture view:editView center:newCenter direction:direction];
                        }
                    }
                }
            }
        }
        if (direction & AWEStoryTextPanDirectionDown) {
            if (self.isEdgeAdsorbing) {
                if (ACC_FLOAT_EQUAL_TO(editView.center.y,self.bottomAlignLine.acc_top - true_h/2)) {//触底边线后还能再往下移的条件
                    if (currentPoint.y > continueMoveShift) {
                        self.isEdgeAdsorbing = NO;
                        newCenter.y = self.bottomAlignLine.acc_top - true_h/2 + edgesShift;
                    }
                } else {//触两边后还可以上下滑动
                    if (fabs(currentPoint.y) > sensitivity) {//灵敏度
                        BOOL canMoveDown = NO;
                        if (ACC_FLOAT_EQUAL_TO(editView.center.x,self.leftAlignLine.acc_right + true_w/2)) {
                            newCenter.x = self.leftAlignLine.acc_right + true_w/2;
                            canMoveDown = YES;
                        }
                        if (ACC_FLOAT_EQUAL_TO(editView.center.x,self.rightAlignLine.acc_left - true_w/2)) {
                            newCenter.x = self.rightAlignLine.acc_left - true_w/2;
                            canMoveDown = YES;
                        }
                        if (canMoveDown) {
                            [self p_updateTranslationWithGesture:gesture view:editView center:newCenter direction:direction];
                        }
                    }
                }
            }
        }
        if (direction & AWEStoryTextPanDirectionUp) {
            if (self.isEdgeAdsorbing) {
                if (ACC_FLOAT_EQUAL_TO(editView.center.y,self.bottomAlignLine.acc_top - true_h/2)) {//触底边线后往上移动
                    self.isEdgeAdsorbing = NO;
                } else {//触两边后还可以上下滑动
                    if (fabs(currentPoint.y) > sensitivity) {//灵敏度
                        BOOL canMoveUP = NO;
                        if (ACC_FLOAT_EQUAL_TO(editView.center.x,self.leftAlignLine.acc_right + true_w/2)) {
                            newCenter.x = self.leftAlignLine.acc_right + true_w/2;
                            canMoveUP = YES;
                        }
                        if (ACC_FLOAT_EQUAL_TO(editView.center.x,self.rightAlignLine.acc_left - true_w/2)) {
                            newCenter.x = self.rightAlignLine.acc_left - true_w/2;
                            canMoveUP = YES;
                        }
                        if (canMoveUP) {
                            [self p_updateTranslationWithGesture:gesture view:editView center:newCenter direction:direction];
                        }
                    }
                }
            }
        }

        // 移动的状态先控制右边和下面的边界UI提示，并且需要边界线不展示
        if (gesture.state == UIGestureRecognizerStateChanged) {
            if (ACCRTL().enableRTL) {
                if (newCenter.x - true_w / 2.f <= self.leftAlignLine.acc_right) {
                    self.fakeProfileView.rightContainerView.hidden = NO;
                } else {
                    self.fakeProfileView.rightContainerView.hidden = YES;
                }
            } else {
                if (newCenter.x + true_w / 2.f >= self.rightAlignLine.acc_left) {
                    self.fakeProfileView.rightContainerView.hidden = NO;
                } else {
                    self.fakeProfileView.rightContainerView.hidden = YES;
                }
            }



            if (newCenter.y + true_h / 2.f >= self.bottomAlignLine.acc_top) {
                self.fakeProfileView.bottomContainerView.hidden = NO;
            } else {
                self.fakeProfileView.bottomContainerView.hidden = YES;
            }
            
            CGRect invalidFrame = [self.gestureInvalidFrameValue CGRectValue];
            if (!CGRectIsEmpty(invalidFrame) && CGRectIntersectsRect(invalidFrame, editView.frame)) {
                self.invalidAction = YES;
            } else {
                self.invalidAction = NO;
            }
        }
        
        if (gesture.state == UIGestureRecognizerStateChanged && !self.isEdgeAdsorbing) {
            [self p_updateTranslationWithGesture:gesture view:editView center:newCenter direction:direction];
            [self p_checkAdsorbingWithEditView:editView width:true_w height:true_h direction:direction];
        }
    }
    
    //拖动到顶部删除按钮区域
    BOOL isInDeleteRect = NO;
    CGRect rect = [AWEStoryDeleteView handleFrame];
    rect = [[UIApplication sharedApplication].keyWindow convertRect:rect toView:editView.superview];
    currentPoint = [gesture locationInView:editView.superview];
    if (CGRectContainsPoint(rect, currentPoint)) {
        isInDeleteRect = YES;
    }
    if (self.playerFrame) {
        if (CGRectIsNull(CGRectIntersection(self.playerFrame.CGRectValue, editView.frame))) {
            isInDeleteRect = YES;
        }
    }
    
    //如果手指拖动到删除框里了
    if (isInDeleteRect && self.containerMode != AWETextContainerModeSelectTime) {
        //触发删除
        [self.storyDeleteView startAnimation];
        editView.alpha = 0.34;
    } else {
        [self.storyDeleteView stopAnimation];
        editView.alpha = 1;
    }
    
    if (self.invalidAction) {
        editView.alpha = 0.34;
    }
    
    //字幕处理
    if (editView.isCaption && [self.delegate respondsToSelector:@selector(captionView:updateAlpha:)]) {
        [self.delegate captionView:editView updateAlpha:editView.alpha];
    }
    
    if ((isInDeleteRect ^ self.isInDeleting) && self.containerMode != AWETextContainerModeSelectTime) {
        [[AWEFeedBackGenerator sharedInstance] doFeedback];
    }
    self.isInDeleting = isInDeleteRect;
        
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        if (isInDeleteRect && self.containerMode != AWETextContainerModeSelectTime) {
            if (self.dragDeleteBlock) {
                self.dragDeleteBlock();
            }
            
            [editView removeFromSuperview];
            [self.textViews removeObject:editView];
            self.isInDeleting = NO;
            [self.lastInteractionStickerLocation reset];
            
            // 删除字幕
            if (editView.isCaption && [self.delegate respondsToSelector:@selector(removeCaptionSticker)]) {
                [self.delegate removeCaptionSticker];
            }
            self.invalidAction = NO;
        } else if (self.invalidAction) {
            [self p_resetTranslationWithView:editView];
        }
        [self gestureFinished];
    }
}

- (void)editorSticker:(AWEStoryBackgroundTextView *)editView receivedPinchGesture:(UIPinchGestureRecognizer *)gesture
{
    // 手势未选中目标
    if (!editView || ![editView isKindOfClass:[AWEStoryBackgroundTextView class]]) {
        self.isInPinchOrRotate = NO;
        return;
    }
    
    // 手势选中目标
    self.currentOperationView = editView;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self gestureStartedWithTextSticker:self.currentOperationView];
        [self setAnchorForRotateAndScaleWithGesture:gesture];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        self.isInPinchOrRotate = YES;
        double scale = gesture.scale;
        [self p_handelScale:scale];
        gesture.scale = 1;

        [self refreshFakeProfileViewHidden];

    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        self.isInPinchOrRotate = NO;
        [self gestureFinished];
    }
}

- (void)editorSticker:(AWEStoryBackgroundTextView *)editView receivedRotationGesture:(UIRotationGestureRecognizer *)gesture
{
    // 字幕手势
    if (editView.isCaption) {
        return;
    }
    
    // 手势未选中目标
    if (!editView || ![editView isKindOfClass:[AWEStoryBackgroundTextView class]]) {
        self.isInPinchOrRotate = NO;
        return;
    }
    
    // 手势选中目标
    self.currentOperationView = editView;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self gestureStartedWithTextSticker:self.currentOperationView];
        [self setAnchorForRotateAndScaleWithGesture:gesture];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        self.isInPinchOrRotate = YES;
        [self interceptToAngleAdSorbingWith:gesture editedView:editView];
    }

    if (!_isAngleAdsorbing) {
        float rota = gesture.rotation;
        if (ACCRTL().enableRTL) {
            rota = -rota;
        }
        self.currentOperationView.transform = CGAffineTransformRotate(self.currentOperationView.transform, rota);
        gesture.rotation = 0;
    }

    // 移动的状态先控制右边和下面的边界UI提示，并且需要边界线不展示
    if (gesture.state == UIGestureRecognizerStateChanged) {
        [self refreshFakeProfileViewHidden];
    }

    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        self.isInPinchOrRotate = NO;
        [self gestureFinished];
    }
}

- (void)editorStickerGestureStarted
{
    [self deselectTextView];
}


/// resetTranslation
- (void)p_resetTranslationWithView:(AWEStoryBackgroundTextView *)editView
{
    editView.alpha = 1.0f;
    [UIView animateWithDuration:0.49 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0.30 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        editView.center = editView.backupCenter;
        editView.transform = editView.backupTransform;
    } completion:^(BOOL finished) {
        editView.stickerLocation = [editView.backupStickerLocation copy];
    }];
}

#pragma mark - Utils

- (void)refreshFakeProfileViewHidden {
    if (ACCRTL().enableRTL) {
        if (self.currentOperationView.acc_centerX - self.currentOperationView.frame.size.width / 2.f <= self.leftAlignLine.acc_right) {
            self.fakeProfileView.rightContainerView.hidden = NO;
        } else {
            self.fakeProfileView.rightContainerView.hidden = YES;
        }
    } else {
        if (self.currentOperationView.acc_centerX + self.currentOperationView.frame.size.width / 2.f >= self.rightAlignLine.acc_left) {
            self.fakeProfileView.rightContainerView.hidden = NO;
        } else {
            self.fakeProfileView.rightContainerView.hidden = YES;
        }
    }

    if (self.currentOperationView.acc_centerY + self.currentOperationView.frame.size.height / 2.f >= self.bottomAlignLine.acc_top) {
        self.fakeProfileView.bottomContainerView.hidden = NO;
    } else {
        self.fakeProfileView.bottomContainerView.hidden = YES;
    }
}

/**
 拦截角度的变化，实现特殊角度的吸附效果
 @param gesture 触发的手势
 @param editedView 当前正在操作的
 */
- (void)interceptToAngleAdSorbingWith:(UIGestureRecognizer *)gesture
                           editedView:(AWEStoryBackgroundTextView *)editedView {
    CGAffineTransform _trans = editedView.transform;
    // 已有的角度
    CGFloat rotate = atanf(_trans.b/_trans.a);
    if (_trans.a < 0 && _trans.b > 0) {
        rotate += M_PI;
    }else if(_trans.a <0 && _trans.b < 0){
        rotate -= M_PI;
    }
    // 当前旋转产生的角度
    float currentRota = 0;
    if ([gesture isKindOfClass:[UIRotationGestureRecognizer class]]) {
        currentRota = ((UIRotationGestureRecognizer *)gesture).rotation;
    } else if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]){
        CGPoint center = editedView.center;
        CGPoint currentTouchPoint = [((UIPanGestureRecognizer *)gesture) locationInView:editedView.superview];
        CGPoint translation = [((UIPanGestureRecognizer *)gesture) translationInView:editedView.superview];
        CGPoint previousTouchPoint = CGPointMake(currentTouchPoint.x - translation.x, currentTouchPoint.y - translation.y);
        currentRota = atan2f(currentTouchPoint.y - center.y, currentTouchPoint.x - center.x) - atan2f(previousTouchPoint.y - center.y, previousTouchPoint.x - center.x);
    }

    CGFloat continuousMoveThreshold = 4.f * M_PI / 180;
    if (self.isAngleAdsorbing && fabs(currentRota) > (6.f * M_PI / 180)) {
        // 在已经吸附的状态下大于阈值即可继续旋转
        self.isAngleAdsorbing = NO;
        [editedView hideAngleHelperDashLine];
        kCanStoryTextContainerViewAngleAdsorbingVibrate = YES;
        return;
    }

    if (currentRota == 0 || self.isAngleAdsorbing) {
        return;
    }

    // 如果需要吸附效果记录当前的scale,trans重建transform
    CGFloat tx = _trans.tx;
    CGFloat ty = _trans.ty;
    CGFloat scale = sqrt(_trans.a * _trans.a + _trans.c * _trans.c);
    __block CGAffineTransform aimedTransform = CGAffineTransformMakeTranslation(tx, ty);
    aimedTransform = CGAffineTransformScale(aimedTransform, scale, scale);

    NSArray<NSNumber *> *adsorbingAngleInRadians = @[@(-M_PI / 4), @(-M_PI / 2), @(-M_PI / 4 * 3), @(-M_PI), @(-M_PI / 4 * 5), @(-M_PI / 2 * 3), @(-M_PI / 4 * 7),
                                                     @0,
                                                     @(M_PI / 4), @(M_PI / 2), @(M_PI / 4 * 3), @(M_PI), @(M_PI / 4 * 5), @(M_PI / 2 * 3), @(M_PI / 4 * 7)];
    [adsorbingAngleInRadians enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (((rotate + currentRota) > (-continuousMoveThreshold + obj.floatValue)) && ((rotate + currentRota) < (continuousMoveThreshold + obj.floatValue))) {
            self.isAngleAdsorbing = YES;
            aimedTransform = CGAffineTransformRotate(aimedTransform, obj.floatValue);
            *stop = YES;
        }
    }];

    if (self.isAngleAdsorbing) {
        [self generateLightImpactFeedBack];
        kCanStoryTextContainerViewAngleAdsorbingVibrate = NO;
        editedView.transform = aimedTransform;
        [editedView showAngleHelperDashLine];
    }
}

- (void)generateLightImpactFeedBack {
    if (!kCanStoryTextContainerViewAngleAdsorbingVibrate ||
        self.containerMode == AWETextContainerModeSelectTime ||
        !self.currentOperationView.centerHorizontalDashLayer.hidden) {
        return;
    }
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *fbGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [fbGenerator prepare];
        [fbGenerator impactOccurred];
    }
}

- (void)setAnchorForRotateAndScaleWithGesture:(UIGestureRecognizer *)gesture
{
    if (self.currentOperationView.setAnchorForRotateAndScale) {
        return;
    }
    self.currentOperationView.setAnchorForRotateAndScale = YES;
    UIView *targetView = self.currentOperationView;
    CGPoint locationInView = [gesture locationInView:targetView];
    [self setAnchorPoint:CGPointMake(locationInView.x / targetView.bounds.size.width, locationInView.y / targetView.bounds.size.height) forView:targetView];
}

- (void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view
{
    //字幕不处理position、anchorpoint
    if ([view isKindOfClass:[AWEStoryBackgroundTextView class]] && ((AWEStoryBackgroundTextView *)view).isCaption) {
        view.layer.anchorPoint = CGPointMake(0.5, 0.5);
        return;
    }
    
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x,
                                   view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x,
                                   view.bounds.size.height * view.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    
    CGPoint position = view.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;

    if (isnan(position.x) || isnan(position.y)) {
        position = view.layer.position;
    }
    
    if (isnan(anchorPoint.x) || isnan(anchorPoint.y)) {
        anchorPoint = view.layer.anchorPoint;
    }

    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}

- (void)p_handelScale:(CGFloat)scale
{
    CGFloat currentScale = self.currentOperationView.currentScale;
    if (currentScale * scale < kAWEStoryBackgroundTextViewMinScale) {
        scale = kAWEStoryBackgroundTextViewMinScale / currentScale;
    } else if (currentScale * scale >= 20.f) {//max scale 
        scale = 20.f/currentScale;
    }
    
    if (self.currentOperationView.isCaption) {
        if (currentScale * scale < 0.5) {
            scale = 0.5 / currentScale;
            return;
        } else if (currentScale * scale >= 2.f) {//max scale
            scale = 2.f/currentScale;
            return;
        }
    }
    
    self.currentOperationView.currentScale *= scale;
    self.currentOperationView.relativeScale = scale;
    
    [self p_handleBorderViewTransformWithAbsoluteScale:self.currentOperationView.currentScale forTextView:self.currentOperationView];
    self.currentOperationView.transform = CGAffineTransformScale(self.currentOperationView.transform, scale, scale);
}

- (void)gestureStartedWithTextSticker:(AWEStoryBackgroundTextView *)operateView
{
    AWEEditStickerBubbleManager *bubble = operateView.isInteractionSticker ? [AWEEditStickerBubbleManager interactiveStickerBubbleManager] : [AWEEditStickerBubbleManager textStickerBubbleManager];
    [bubble setBubbleVisible:NO animated:NO];
    [self dismissHintText];
    [operateView hideHandle];
    if (self.containerMode == AWETextContainerModeSelectTime) {
        [self startSelectTimeForTextView:operateView isAlpha:YES];
        if ([self.delegate respondsToSelector:@selector(didFocusOnCaption)]) {
            [self.delegate didFocusOnCaption];
        }
    }
    
    self.invalidAction = NO;
    if (!self.hasBackup) {
        self.hasBackup = YES;
        [operateView backupLocation];
    }
    
    if (!operateView || self.gestureManager.gestureActiveStatus != AWEGestureActiveTypeNone) {
        return;
    }
    if (self.currentOperationView != operateView) {
        [self.currentOperationView hideHandle];
        self.currentOperationView = nil;
    }
    self.currentOperationView = operateView;
    [self.containerView bringSubviewToFront:self.currentOperationView];
    
    ACCBLOCK_INVOKE(self.startOperationBlock);
    
    if (self.textViews.lastObject != operateView && !operateView.isCaption) {
        [self.textViews removeObject:operateView];
        [self.textViews addObject:operateView];
    }
    [self bringSubviewToFront:operateView];
    [self bringSubviewToFront:self.maskViewTwo];
    [self bringSubviewToFront:self.maskViewOne];
}

- (void)gestureFinished
{
    [self p_showEdgeLineWithType:AWEStoryTextEdgeLineNone];
    self.fakeProfileView.bottomContainerView.hidden = YES;
    self.fakeProfileView.rightContainerView.hidden = YES;
    self.hasBackup = NO;
    if (self.gestureManager.gestureActiveStatus != AWEGestureActiveTypeNone) {
        return;
    }
    
    [self setAnchorPoint:CGPointMake(0.5, 0.5) forView:self.currentOperationView];
    [self recordSickerLocationForView:self.currentOperationView];
    
    self.currentOperationView.setAnchorForRotateAndScale = NO;
    [self.currentOperationView handleContentScaleFactor];
    [self.currentOperationView hideAngleHelperDashLine];
    if (self.currentOperationView.lastHandleState) {
        // may active current view 
    } else {
        self.currentOperationView = nil;
    }
    kCanStoryTextContainerViewAngleAdsorbingVibrate = YES;
    ACCBLOCK_INVOKE(self.finishPanGestureBlock);
}

- (BOOL)checkForAddText
{
    if ([self textsArray].count >= ACCConfigInt(kConfigInt_text_sticker_max_count)) {
        [ACCToast() show:ACCLocalizedCurrentString(@"com_mig_maximum_text_stickers_selected")];
        return NO;
    }

    return YES;
}

- (CGFloat)correctedBottomValue
{
    return ACC_SCREEN_HEIGHT - CGRectGetMaxY(self.frame);
}

- (BOOL)isForImage
{
    return self.type == AWEStoryTextContainerTypeImageEdit || self.type == AWEStoryTextContainerTypeCamera;
}

- (void)updateMusicCoverWithMusicModel:(id<ACCMusicModelProtocol>)model {
    [self.fakeProfileView updateMusicCoverWithMusicModel:model];
}

#pragma mark - Hint

- (void)showHintTextOnSticker:(AWEStoryBackgroundTextView *)stickerView {
    if (!self.hintView.superview) {
        [self addSubview:self.hintView];
    }
    NSString *hint = stickerView.isInteractionSticker ? ACCLocalizedString(@"creation_edit_sticker_poi_double_click",@"双击可重新选择定位") : ACCLocalizedString(@"creation_edit_text_double_click", @"双击可编辑文字");
    AWEEditStickerHintType type = stickerView.isInteractionSticker ? AWEEditStickerHintTypeInteractive : AWEEditStickerHintTypeText;
    [self.hintView showHint:hint type:type];
    self.hintView.bounds = (CGRect){CGPointZero, self.hintView.intrinsicContentSize};
    self.hintView.center = [stickerView convertPoint:CGPointMake(stickerView.borderView.acc_centerX, stickerView.borderView.acc_top - self.hintView.acc_height) toView:self];
}

- (void)dismissHintText {
    [self.hintView dismissWithAnimation:YES];
}


#pragma mark - AWEEditorStickerGestureDelegate

- (void)editorSticker:(AWEStoryBackgroundTextView *)editView clickedDeleteButton:(UIButton *)sender
{
    if (self.clickDeleteBlock) {
        self.clickDeleteBlock();
    }
    [editView removeFromSuperview];
    [self.textViews removeObject:editView];
    self.currentOperationView = nil;
    kCanStoryTextContainerViewAngleAdsorbingVibrate = YES;
    [self.lastInteractionStickerLocation reset];

    // 删除字幕
    if (editView.isCaption && [self.delegate respondsToSelector:@selector(removeCaptionSticker)]) {
        [self.delegate removeCaptionSticker];
    }
}

- (void)editorSticker:(AWEStoryBackgroundTextView *)editView clickedSelectTimeButton:(UIButton *)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(selectTimeForTextStickerView:)]) {
        [self.delegate selectTimeForTextStickerView:editView];
    }
    [editView hideHandle];
}

- (void)editorSticker:(AWEStoryBackgroundTextView *)editView clickedTextEditButton:(UIButton *)sender
{
    ACCBLOCK_INVOKE(self.secondTapBlock, editView);
    [self startLabelProgress:editView withGesture:nil videoDuration:self.videoDuration];
    [editView hideHandle];
}

- (void)p_handleBorderViewTransformWithAbsoluteScale:(CGFloat)currentScale forTextView:(AWEStoryBackgroundTextView *)textView
{
    CGFloat textViewWidth = CGRectGetWidth(textView.textView.bounds) - 2 * kAWEStoryBackgroundTextViewContainerInset;
    CGFloat textViewHeight = CGRectGetHeight(textView.textView.bounds) - 2 * kAWEStoryBackgroundTextViewContainerInset;
    if (textView.isInteractionSticker) {
        textViewWidth = CGRectGetWidth(textView.textView.bounds);
        textViewHeight = CGRectGetHeight(textView.textView.bounds);
    }
    
    CGFloat borderViewScaleY = (textViewHeight * currentScale + 2 * kAWEStoryBackgroundTextViewBackgroundColorTopMargin * currentScale + 2 * kAWEStoryBackgroundTextViewBackgroundBorderMargin) / ((textViewHeight + 2 * kAWEStoryBackgroundTextViewBackgroundColorTopMargin + 2 * kAWEStoryBackgroundTextViewBackgroundBorderMargin) * currentScale);
    
    CGFloat borderViewScaleX = (textViewWidth * currentScale + 2 * kAWEStoryBackgroundTextViewBackgroundColorLeftMargin * currentScale + 2 * kAWEStoryBackgroundTextViewBackgroundBorderMargin) / ((textViewWidth + 2 * kAWEStoryBackgroundTextViewBackgroundColorLeftMargin + 2 * kAWEStoryBackgroundTextViewBackgroundBorderMargin) * currentScale);
    
    textView.borderView.transform = CGAffineTransformMakeScale(borderViewScaleX, borderViewScaleY);
    textView.borderShapeLayer.borderWidth = 1 / (borderViewScaleX * currentScale);
    
    [self recordSickerLocationForView:textView];
}

#pragma mark - setter

- (void)setIsInPinchOrRotate:(BOOL)isInPinchOrRotate {
    _isInPinchOrRotate = isInPinchOrRotate;
    if (_isInPinchOrRotate) {
        [self p_showEdgeLineWithType:AWEStoryTextEdgeLineNone];
    }
}

#pragma mark - getter

- (void)setIsForStory:(BOOL)isForStory
{
    _isForStory = isForStory;
    if (isForStory) {
        [_finishButton setTitle:@"" forState:UIControlStateNormal];
        [_finishButton setBackgroundImage:ACCResourceImage(@"iconARTextDone") forState:UIControlStateNormal];
    } else {
        [_finishButton setTitle: ACCLocalizedString(@"done", @"完成") forState:UIControlStateNormal];
    }
}

- (UIView *)topMaskView
{
    if (!_topMaskView) {
        _topMaskView = [[AWEEditGradientView alloc] init];
        _topMaskView.backgroundColor = [UIColor clearColor];
        _topMaskView.clipsToBounds = YES;
    }
    return _topMaskView;
}

- (UIView *)textMaskView
{
    if (_textMaskView == nil) {
        _textMaskView = [[UIView alloc] initWithFrame:self.bounds];
        _textMaskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        [_textMaskView acc_addSingleTapRecognizerWithTarget:self action:@selector(didClickedTextMaskView)];
    }
    return _textMaskView;
}

- (AWEStoryToolBar *)toolBar
{
    if (!_toolBar) {
        _toolBar = [[AWEStoryToolBar alloc] initWithType:AWEStoryToolBarTypeColorAndFont];
        // default hidden, will show before animation and restore hidden after text dismiss
        // it would be better to refactor using inputView
        _toolBar.hidden = YES;
    }
    
    return _toolBar;
}

- (ACCAnimatedButton *)finishButton
{
    if (_finishButton == nil) {
        _finishButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        [_finishButton.titleLabel setFont:[ACCFont() systemFontOfSize:17 weight:ACCFontWeightMedium]];
        [_finishButton setTitle:ACCLocalizedString(@"save", @"save")  forState:UIControlStateNormal];
        [_finishButton addTarget:self action:@selector(didClickedFinish:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _finishButton;
}

- (NSArray<NSString *> *)textsArray
{
    if (!self.textViews.count) {
        return nil;
    }
    NSMutableArray *strArray = [NSMutableArray array];
    NSArray *stortedTextViews = [self textViewsAscendingByStartTime];
    for (AWEStoryBackgroundTextView *tv in stortedTextViews) {
        NSString *str = tv.textView.text;//poi sticker has no textView.text
        if (str.length) {
            [strArray addObject:str];
        }
    }
    return strArray;
}

- (NSArray<NSString *> *)textFontsArray
{
    if (!self.textViews.count) {
        return nil;
    }
    NSMutableArray *fontsArray = [NSMutableArray array];
    for (AWEStoryBackgroundTextView *tv in self.textViews) {
        NSString *font = tv.selectFont.title;//poi sticker has no textView.text
        if (font.length) {
            [fontsArray addObject:font];
        }
    }
    return fontsArray;
}

- (NSArray *)textViewsAscendingByStartTime
{
    NSSortDescriptor *startTime = [NSSortDescriptor sortDescriptorWithKey:@"_realStartTime" ascending:YES];
    return [self.textViews sortedArrayUsingDescriptors:@[startTime]];
}

- (NSArray<NSString *> *)textFontEffectIdsArray
{
    if (!self.textViews.count) {
        return nil;
    }
    NSMutableArray *fontsArray = [NSMutableArray array];
    for (AWEStoryBackgroundTextView *tv in self.textViews) {
        NSString *font = tv.selectFont.effectId;//poi sticker has no textView.text
        if (font.length) {
            [fontsArray addObject:font];
        }
    }

    return fontsArray;
}

- (NSString *)textsArrayInString
{
    if (!self.textViews.count) {
        return nil;
    }
    NSArray<NSString *> *textsArray = [self textsArray];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:textsArray options:0 error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSString *)textFontsArrayInString
{
    if (!self.textViews.count) {
        return @"";
    }
    NSArray<NSString *> *textFontsArray = [self textFontsArray];
    if (textFontsArray) {
        return [textFontsArray componentsJoinedByString:@","];
    } else {
        return @"";
    }
}

- (NSString *)textFontEffectIdsArrayInString
{
    if (!self.textViews.count) {
        return @"";
    }
    NSArray<NSString *> *textFontsArray = [self textFontEffectIdsArray];
    if (textFontsArray) {
        return [textFontsArray componentsJoinedByString:@","];
    } else {
        return @"";
    }
}

- (NSMutableArray<AWEStoryBackgroundTextView *> *)textViews
{
    if (!_textViews) {
        _textViews = [@[] mutableCopy];
    }
    return _textViews;
}

- (UIImage *)generateImage
{
    if (!self.textViews.count) {
        return nil;
    }
    
    UIImage *image = [self.containerView acc_imageWithViewOnScreenScale];
    if (self.playerFrame) {
        image = [image yy_imageByCropToRect:self.playerFrame.CGRectValue];
    }
    return image;
}

- (UIImage *)generateImageWithRect:(CGRect)rect
{
    if (!self.textViews.count) {
        return nil;
    }
    
    UIImage *image = [self.containerView acc_imageWithViewOnScreenScale];
    if (self.playerFrame) {
        image = [image yy_imageByCropToRect:rect];
    }
    return image;
}

- (AWEEditStickerHintView *)hintView {
    if (!_hintView) {
        _hintView = [AWEEditStickerHintView new];
    }
    return _hintView;
}
- (UIView *)leftAlignLine
{
    if (!_leftAlignLine) {
        _leftAlignLine = [self createLine];
    }
    return _leftAlignLine;
}

- (UIView *)rightAlignLine
{
    if (!_rightAlignLine) {
        _rightAlignLine = [self createLine];
    }
    return _rightAlignLine;
}

- (UIView *)bottomAlignLine
{
    if (!_bottomAlignLine) {
        _bottomAlignLine = [self createLine];
    }
    return _bottomAlignLine;
}

- (UIView *)centerVerticalAlignLine {
    if (!_centerVerticalAlignLine) {
        _centerVerticalAlignLine = [self createLine];
    }
    return _centerVerticalAlignLine;
}
- (UIView *)centerHorizontalAlignLine {
    if (!_centerHorizontalAlignLine) {
        _centerHorizontalAlignLine = [self createLine];
    }
    return _centerHorizontalAlignLine;
}

- (UIView *)createLine
{
    UIView *line = [UIView new];
    line.backgroundColor = ACCResourceColor(ACCUIColorConstSecondary);
    return line;
}

- (AWEInteractionStickerLocationModel *)lastInteractionStickerLocation
{
    if (!_lastInteractionStickerLocation) {
        _lastInteractionStickerLocation = [[AWEInteractionStickerLocationModel alloc]init];
    }
    return _lastInteractionStickerLocation;
}

#pragma mark - action

- (void)didClickedLeftButton:(UIButton *)button
{
    AWEStoryTextStyle style = (self.currentOperationView.style + 1) % AWEStoryTextStyleCount;
    self.currentOperationView.style = style;
    NSString *imageName = [NSString stringWithFormat:@"icTextStyle_%@", @(style)];
    [button setImage:ACCResourceImage(imageName) forState:UIControlStateNormal];
    NSString *title = @"文本样式";
    if (style == AWEStoryTextStyleStroke) {
        title = [title stringByAppendingString:@",描边"];
    } else if (style == AWEStoryTextStyleBackground) {
        title = [title stringByAppendingString:@",背景"];
    } else if (style == AWEStoryTextStyleAlphaBackground) {
        title = [title stringByAppendingString:@",半透明背景"];
    } else {
        title = [title stringByAppendingString:@",无"];
    }
    button.accessibilityLabel = title;
    if (self.didChangeStyleBlock) {
        self.didChangeStyleBlock(style);
    }
}

- (void)didClickedAlignmentButton:(UIButton *)button
{
    AWEStoryTextAlignmentStyle type = (self.currentOperationView.alignmentType + 1) % AWEStoryTextAlignmentCount;
    self.currentOperationView.alignmentType = type;
    NSString *imgName = [NSString stringWithFormat:@"icTextAlignment_%@", @(type)];
    [button setImage:ACCResourceImage(imgName) forState:UIControlStateNormal];
    ACCBLOCK_INVOKE(self.didChangeAlignmentBlock, type);
}

- (void)didClickedFinish:(UIButton *)button
{
    if (self.type == AWEStoryTextContainerTypeCamera) {
        [self didFinishEditAndToEditView];
    } else {
        [self didFinishEdit];
    }
}

- (void)didClickedTextMaskView
{
    [self didFinishEdit];
}

- (void)didFinishEditAndToEditView
{
    self.didClickFinish = YES;
    [self endEditing:YES];
    ACCBLOCK_INVOKE(self.finishButtonWillClickBlock);
    
    AWEStoryBackgroundTextView *textView = self.currentOperationView;
    self.currentOperationView = nil;
    self.finishButton.hidden = YES;
    self.finishButton.alpha = 0;
    self.textMaskView.alpha = 0;
    self.beginLabelProgress = NO;
    
    textView.hidden = YES;
    ACCBLOCK_INVOKE(self.finishButtonClickBlock, [self textsArray].count, textView.textView.text);
}

- (void)didFinishEdit
{
    self.didClickFinish = YES;
    
    [self endEditing:YES];
    
    AWEStoryBackgroundTextView *textView = self.currentOperationView;
    
    [textView transToRecordPosWithSuperView:self.containerView completion:^{
        [self bringSubviewToFront:self.maskViewTwo];
        [self bringSubviewToFront:self.maskViewOne];
        [self recordSickerLocationForView:self.currentOperationView];
        if (!ACC_isEmptyString(self.currentOperationView.textView.text)) {
            [self showHintTextOnSticker:self.currentOperationView];
        }
        self.currentOperationView = nil;
    }];
    
    if (ACC_isEmptyString(textView.textView.text)) {
        [textView removeFromSuperview];
        [self.textViews removeObject:textView];
    }
    
    self.finishButton.hidden = YES;
    [UIView animateWithDuration:0.2 animations:^{
        self.textMaskView.alpha = 0;
        self.finishButton.alpha = 0;
    } completion:^(BOOL finished) {
        self.beginLabelProgress = NO;
        self.toolBar.hidden = YES;
    }];
    
    ACCBLOCK_INVOKE(self.finishEditBlock, [self textsArray].count, textView.textView.text);
}


#pragma mark - UIViewGeometry

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView* tmpView = [super hitTest:point withEvent:event];
    
    if (tmpView == self || tmpView == self.containerView) {
        return nil;
    }
    return tmpView;
}


@end
