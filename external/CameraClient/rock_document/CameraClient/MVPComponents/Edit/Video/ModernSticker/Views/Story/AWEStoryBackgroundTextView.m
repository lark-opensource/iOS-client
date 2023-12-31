//
//  AWEStoryBackgroundTextView.m
//  AWEStudio
//
//  Created by hanxu on 2018/11/20.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEStoryTextContainerView.h"
#import "AWEEditStickerBubbleManager.h"

#import <CreativeKit/UIView+AWESubtractMask.h>
#import "AWEEditStickerHintView.h"
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreationKitArch/ACCCustomFontProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitArch/ACCEditPageLayoutManager.h>
#import <CameraClient/ACCEditPageTextStorage.h>
#import <CameraClient/AWEStoryColorChooseView.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import "AWEInteractionPOIStickerModel.h"
#import <CreationKitInfra/ACCRTLProtocol.h>

CGFloat kAWEStoryBackgroundTextViewLeftMargin = 32;//整个距离屏幕左边
CGFloat kAWEStoryBackgroundTextViewBackgroundColorLeftMargin = 12;
CGFloat kAWEStoryBackgroundTextViewBackgroundColorTopMargin = 6;
CGFloat kAWEStoryBackgroundTextViewBackgroundBorderMargin = 6;
CGFloat kAWEStoryBackgroundTextViewBackgroundRadius = 6;
CGFloat kAWEStoryBackgroundTextViewKeyboardMargin = 122;
CGFloat kAWEStoryBackgroundTextViewContainerInset = 20;

static const CGFloat kAWEStoryBackgroundCenterHelperLineWidth = 1.f;
static const CGFloat kAWEStoryBackgroundCenterHelperLineLength = 2000.f;
static const CGFloat kAWEStoryBackgroundDefaultFontSize = 28.f;

@interface AWEStoryBackgroundTextView () <UIGestureRecognizerDelegate>

//操作框
@property (nonatomic, assign) CGFloat lastBorderViewBorderWidth;

//
@property (nonatomic, strong) NSMutableArray *layerPool;
@property (nonatomic, strong) NSMutableArray<CALayer *> *currentShowLayerArray;
@property (nonatomic, strong) UIColor *fillColor;
//在编辑页的状态
@property (nonatomic, assign) CGAffineTransform lastTransForm;
@property (nonatomic, assign) CGPoint lastAnchorPoint;
@property (nonatomic, assign) CGAffineTransform lastBorderViewTransform;

@property (nonatomic, assign, readwrite) BOOL enableEdit;
@property (nonatomic, assign, readwrite) BOOL lastHandleState;
@property (nonatomic, strong, readwrite) UIView *borderView;
@property (nonatomic, strong, readwrite) CAShapeLayer *borderShapeLayer;
//水平居中的虚线，当达到特定角度时展示，比如0, 45 90 135
@property (nonatomic, strong) CAShapeLayer *centerHorizontalDashLayer;
//写文字时的center
@property (nonatomic, assign, readwrite) CGPoint editCenter;

@property (nonatomic, assign) BOOL hasFeedback;
@property (nonatomic, assign) BOOL notRefresh;
@property (nonatomic, assign) BOOL isForImage;
@property (nonatomic, assign) BOOL forCoverText;
@property (nonatomic, assign, readwrite) BOOL isCaption;

@property (nonatomic, assign) CGFloat defaultFontSize;

// --- 新交互的气泡
@property (nonatomic, weak, readonly) AWEEditStickerBubbleManager *bubble;
@property (nonatomic, copy) NSArray<AWEEditStickerBubbleItem *> *bubbleItems;
@property (nonatomic, assign) CGPoint touchPoint;
// Wikipedia
@property (nonatomic, strong) ACCEditPageLayoutManager *layoutManager;
@property (nonatomic, strong) ACCEditPageTextStorage *textStorage;

@end


@implementation AWEStoryBackgroundTextView


- (void)dealloc
{
    ACCLog(@"%@ dealloc",self.class);
}

- (instancetype)initWithIsForImage:(BOOL)isForImage
{
    self = [super init];
    if (self) {
        self.isForImage = isForImage;
        self.stickerEditId = -1;
        self.defaultFontSize = kAWEStoryBackgroundDefaultFontSize;
        self.zoomScale = 1.0;
        self.textStickerId = [NSString stringWithFormat:@"%@", @([[NSDate date] timeIntervalSince1970])];
        [self setupUI];
    }
    return self;
}

- (instancetype)initForCoverText:(BOOL)coverText
{
    self = [super init];
    if (self) {
        self.forCoverText = coverText;
        self.isForImage = YES;
        self.stickerEditId = -1;
        self.defaultFontSize = 26.0f;
        self.zoomScale = 1.0;
        self.textStickerId = [NSString stringWithFormat:@"%@", @([[NSDate date] timeIntervalSince1970])];
        [self setupUI];
    }
    return self;
}

- (instancetype)initAsCaptionGestureView
{
    self = [super init];
    if (self) {
        self.isForImage = NO;
        self.isCaption = YES;
        self.stickerEditId = -1;
        self.zoomScale = 1.0;
        
        self.currentScale = 1.f;
        self.isFirstAppear = YES;
        self.lastAnchorPoint = CGPointMake(0.5, 0.5);
        self.lastTransForm = CGAffineTransformIdentity;
        self.textStickerId = [NSString stringWithFormat:@"%@", @([[NSDate date] timeIntervalSince1970])];
        
        [self setupDashLineLayers];
        
        //self.layer.borderColor = ACCResourceColor(ACCUIColorConstBGContainer).CGColor;
        //self.layer.borderWidth = 1.f;
        //self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4];
    }
    
    return self;
}

- (instancetype)initWithTextInfo:(AWEStoryTextImageModel *)model
                    anchorModels:(ACCStoryTextAnchorModels *)anchorModels
                      isForImage:(BOOL)isForImage
{
    self = [super init];
    if (self) {
        self.zoomScale = 1.0;
        self.textStickerId = [NSString stringWithFormat:@"%@", @([[NSDate date] timeIntervalSince1970])];
        [self initializeWithTextInfo:model anchorModels:anchorModels isForImage:isForImage];
        [self setupUI];
    }
    return self;
}

- (void)initializeWithTextInfo:(AWEStoryTextImageModel *)model
                  anchorModels:(ACCStoryTextAnchorModels *)anchorModels
                    isForImage:(BOOL)isForImage
{
    self.notRefresh = YES;
    self.stickerEditId = -1;
    self.isForImage = isForImage;
    self.defaultFontSize = kAWEStoryBackgroundDefaultFontSize;
    if (!ACC_FLOAT_EQUAL_ZERO(model.fontSize)) {
        self.defaultFontSize = model.fontSize;
    }
    
    if (model.isPOISticker) {
        self.isInteractionSticker = YES;
        self.interactionStickerInfo.type = AWEInteractionStickerTypePOI;
        self.stickerLocation.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
        self.poiName = model.content;
    } else {
        self.textView.attributedText = [[NSAttributedString alloc] initWithString:model.content ? : @""];
    }
    
    if (model.isCaptionSticker) {
        self.isCaption = YES;
    }
    
    self.selectFont = model.fontModel;
    self.color = model.fontColor;
    self.alignmentType = model.alignmentType;
    self.style = model.textStyle;
    self.keyboardHeight = model.keyboardHeight;
    self.realStartTime = model.realStartTime;
    self.realDuration = model.realDuration;
    self.finalStartTime = model.realStartTime;
    self.finalDuration = model.realDuration;
    self.notRefresh = NO;
    self.textInfoModel = model;
}

- (void)setupUI
{
    self.currentScale = 1.f;
    self.isFirstAppear = YES;
    self.lastAnchorPoint = CGPointMake(0.5, 0.5);
    self.lastTransForm = CGAffineTransformIdentity;

    [self setupDashLineLayers];
    if (!self.borderView.superview) {
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
        [self addGestureRecognizer:panGesture];
        
        [self addSubview:self.borderView];
        [self hideHandle];
        
        [self addSubview:self.textView];
        [self.textStorage setTextView:self.textView];
        
        [self.borderView.layer addSublayer:self.borderShapeLayer];
    }
    
    if (self.isInteractionSticker) {
        [self insertSubview:self.darkBGView belowSubview:self.textView];
        self.textView.editable = NO;
        self.enableEdit = NO;
    }

    self.color = self.color ?: [AWEStoryColorChooseView storyColors].firstObject;
    
    [self refreshFont];
}

- (void)setupDashLineLayers {
    [self.layer addSublayer:self.centerHorizontalDashLayer];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.centerHorizontalDashLayer.frame = CGRectMake(- kAWEStoryBackgroundCenterHelperLineLength / 2.f,
                                                      (self.bounds.size.height-1)/2.f,
                                                      kAWEStoryBackgroundCenterHelperLineLength,
                                                      kAWEStoryBackgroundCenterHelperLineWidth);
    self.centerHorizontalDashLayer.hidden = YES;
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    self.centerHorizontalDashLayer.frame = CGRectMake(- kAWEStoryBackgroundCenterHelperLineLength / 2.f,
                                                      (self.bounds.size.height-1)/2.f,
                                                      kAWEStoryBackgroundCenterHelperLineLength,
                                                      kAWEStoryBackgroundCenterHelperLineWidth);
    self.centerHorizontalDashLayer.hidden = YES;
}

- (void)setTransform:(CGAffineTransform)transform {
    [super setTransform:transform];
    // 保证dashLineLayer在外部缩放的同时效果不变
    CGFloat aimedScale = 1 / sqrt(transform.a*transform.a + transform.c*transform.c);
    CGAffineTransform aimedTransform = CGAffineTransformMakeScale(aimedScale, aimedScale);
    self.centerHorizontalDashLayer.affineTransform = aimedTransform;
}

- (void)p_updateFrame
{
    CGSize textViewSize;
    if (self.isInteractionSticker) {
        textViewSize = CGSizeMake([self poiContainerWidth], [self poiContainerHeight]);
        self.textView.backgroundColor = [UIColor whiteColor];
        self.textView.layer.cornerRadius = 6.f;
        self.textView.layer.masksToBounds = YES;
        
        self.darkBGView.layer.cornerRadius = 6.f;
        self.darkBGView.layer.masksToBounds = YES;
    } else {
        self.textView.backgroundColor = [UIColor clearColor];
        textViewSize = [self.textView sizeThatFits:CGSizeMake(ACC_SCREEN_WIDTH - 2 * kAWEStoryBackgroundTextViewLeftMargin + 2 * kAWEStoryBackgroundTextViewContainerInset, HUGE)];
    }
    
    if (textViewSize.width <= 0.0001) {
        textViewSize.width = 20;
    } else if (self.isInteractionSticker && textViewSize.width > (ACC_SCREEN_WIDTH - 32)) {
        textViewSize.width = ACC_SCREEN_WIDTH - 32;
    }
    
    if (self.isCaption) {
        textViewSize = [self.textView sizeThatFits:CGSizeMake((ACC_SCREEN_WIDTH - 48) * 2, HUGE)];
    }
    
    CGFloat selfWidth = textViewSize.width + (kAWEStoryBackgroundTextViewBackgroundColorLeftMargin + kAWEStoryBackgroundTextViewBackgroundBorderMargin) * 2 - 2 * kAWEStoryBackgroundTextViewContainerInset;
    CGFloat selfHeight = textViewSize.height + (kAWEStoryBackgroundTextViewBackgroundColorTopMargin + kAWEStoryBackgroundTextViewBackgroundBorderMargin) * 2 - 2 * kAWEStoryBackgroundTextViewContainerInset;
    if (self.isInteractionSticker) {
        selfWidth = textViewSize.width + (kAWEStoryBackgroundTextViewBackgroundColorLeftMargin + kAWEStoryBackgroundTextViewBackgroundBorderMargin) * 2;
        selfHeight = textViewSize.height + (kAWEStoryBackgroundTextViewBackgroundColorTopMargin + kAWEStoryBackgroundTextViewBackgroundBorderMargin) * 2;
    }
    self.bounds = CGRectMake(0, 0, selfWidth, selfHeight);
    if (self.isCaption) {
        self.bounds = CGRectMake(0, 0, textViewSize.width, textViewSize.height);
    }
    
    CGFloat del = self.basicCenter.y + textViewSize.height * 0.5 - (ACC_SCREEN_HEIGHT - self.keyboardHeight - (kAWEStoryBackgroundTextViewKeyboardMargin + kAWEStoryBackgroundTextViewBackgroundBorderMargin + kAWEStoryBackgroundTextViewBackgroundColorTopMargin));
    if (del > 0) {
        self.center = CGPointMake(self.basicCenter.x, self.basicCenter.y - AWEStoryTextContainerViewTopMaskMargin - del);
    } else {
        self.center = CGPointMake(self.basicCenter.x, self.basicCenter.y - AWEStoryTextContainerViewTopMaskMargin);
    }
    
    if (self.alignmentType == AWEStoryTextAlignmentLeft) {
        self.acc_left = kAWEStoryBackgroundTextViewLeftMargin - kAWEStoryBackgroundTextViewContainerInset + self.leftBeyond;
    } else if (self.alignmentType == AWEStoryTextAlignmentRight) {
        self.acc_right = ACC_SCREEN_WIDTH - kAWEStoryBackgroundTextViewLeftMargin + kAWEStoryBackgroundTextViewContainerInset + self.leftBeyond;
    }
    
    self.editCenter = self.center;
    self.borderView.frame = self.bounds;
    self.borderShapeLayer.frame = self.borderView.bounds;
    
    self.textView.frame = CGRectMake(kAWEStoryBackgroundTextViewBackgroundColorLeftMargin + kAWEStoryBackgroundTextViewBackgroundBorderMargin - kAWEStoryBackgroundTextViewContainerInset, kAWEStoryBackgroundTextViewBackgroundColorTopMargin + kAWEStoryBackgroundTextViewBackgroundBorderMargin - kAWEStoryBackgroundTextViewContainerInset, textViewSize.width, textViewSize.height);
    if (self.isInteractionSticker) {
        self.textView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        [self.textView awe_setSubtractMaskView:[self poiLblWithAlpha:0.8f]];
        self.darkBGView.frame = CGRectMake(self.textView.frame.origin.x+2, self.textView.frame.origin.y+2, self.textView.frame.size.width-4, self.textView.frame.size.height-4);
        self.darkBGView.center = self.textView.center;
    }
}

#pragma mark -

//进入编辑状态
- (void)resetWithSuperView:(UIView *)superView
{
    //是否允许编辑状态下拖动
    self.enableEdit = YES;
    
    self.lastTransForm = self.transform;
    if (self.isFirstAppear) {
        self.isFirstAppear = NO;
    } else {
        self.lastCenter = self.center;
    }
    
    self.lastAnchorPoint = self.layer.anchorPoint;
    
    self.lastBorderViewTransform = self.borderView.transform;
    self.lastBorderViewBorderWidth = self.borderShapeLayer.borderWidth;
    
    //把textView从全屏的containerview上移动到有上边距的topmaskview上
    if (self.superview) {
        CGPoint centerInContainer = self.center;
        CGPoint centerInMaskTop = [superView convertPoint:centerInContainer fromView:self.superview];
        [self removeFromSuperview];
        [superView addSubview:self];
        self.center = centerInMaskTop;
    } else {
        [superView addSubview:self];
        [self p_updateFrame];
    }

    [self.textView becomeFirstResponder];
    [UIView animateWithDuration:0.35 animations:^{
        self.layer.anchorPoint = CGPointMake(0.5, 0.5);
        self.transform = CGAffineTransformIdentity;
        self.center = self.editCenter;
        self.borderView.transform = CGAffineTransformIdentity;
        self.borderShapeLayer.borderWidth = 1;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)transToRecordPosWithSuperView:(UIView *)superView
                    animationDuration:(CGFloat)duration
                           completion:(void (^)(void))completion
{
    self.enableEdit = NO;
    //把textView从有上边距的topmaskview上移动到全屏的containerview上
    if (self.superview) {
        CGPoint centerInMaskTop = self.center;
        CGPoint centerInContainer = [superView convertPoint:centerInMaskTop fromView:self.superview];
        self.superview.hidden = YES;
        [self removeFromSuperview];
        
        [superView addSubview:self];
        self.center = centerInContainer;
    } else {
        [superView addSubview:self];
    }
    
    [self handleContentScaleFactor];
    
    [UIView animateWithDuration:duration animations:^{
        self.layer.anchorPoint = self.lastAnchorPoint;
        self.center = self.lastCenter;
        self.borderView.transform = self.lastBorderViewTransform;
        self.borderShapeLayer.borderWidth = self.lastBorderViewBorderWidth;
        self.transform = self.lastTransForm;
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

//恢复到拖动状态
- (void)transToRecordPosWithSuperView:(UIView *)superView
                           completion:(void (^)(void))completion
{
    [self transToRecordPosWithSuperView:superView animationDuration:0.3 completion:completion];
}

// 更新POI贴纸
- (void)initPosWithSuperView:(UIView *)superView
{
    [self p_updateFrame];
    
    if (self.isInteractionSticker) { //需求定义只存在1个POI贴纸
        AWEStoryBackgroundTextView *poiSticker = [self poiStickerInContainer:superView];
        if (poiSticker) {
            [poiSticker removeFromSuperview];
        }
    }
    
    if (self.superview) {
        CGPoint centerInMaskTop = self.center;
        CGPoint centerInContainer = [superView convertPoint:centerInMaskTop fromView:self.superview];
        self.superview.hidden = YES;
        [self removeFromSuperview];
        [superView addSubview:self];
        self.center = centerInContainer;
    } else {
        [superView addSubview:self];
    }
    
    [self handleContentScaleFactor];

    self.layer.anchorPoint = self.lastAnchorPoint;
    self.center = self.lastCenter;
    self.transform = self.lastTransForm;
}

- (void)p_showHandle:(BOOL)show
{
    self.lastHandleState = self.selected;
    self.borderView.hidden = !show;
    self.selected = show;
}

- (void)hideHandle
{
    if (self.gestureManager.gestureActiveStatus != AWEGestureActiveTypeNone && self.borderView.hidden) {
        return;
    }
    [self p_showHandle:NO];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self.bubble setBubbleVisible:NO animated:YES];
}

- (void)autoDismissHandle
{
    [self hideHandle];
    if (self.autoDismissHandleBlock) {
        self.autoDismissHandleBlock(self);
    }
}

- (void)showHandleThenDismiss
{
    if (self.isSelectTimeMode) {
        return;
    }
    [self p_showHandle:YES];
    [self performSelector:@selector(autoDismissHandle) withObject:nil afterDelay:3];
    
    if (self.isCaption) {
        // show bubble
        UIView *parentView = ACCBLOCK_INVOKE(self.bubble.defaultTargetView);
        CGAffineTransform transform = self.transform;
        self.transform = CGAffineTransformIdentity;
        
        CGRect rect = [self.superview convertRect:self.frame toView:parentView];
        CGPoint point = [self convertPoint:self.touchPoint toView:parentView];
        
        [self.bubble setRect:rect touchPoint:point transform:transform inParentView:parentView];
        [self.bubble setBubbleVisible:YES animated:YES];
    } else if (!self.isHidden) { // 考虑选时长贴纸会被隐藏
        // show bubble
        UIView *parentView = ACCBLOCK_INVOKE(self.bubble.defaultTargetView);
        CGAffineTransform transform = self.transform;
        self.transform = CGAffineTransformIdentity;
        CGAffineTransform borderTransform = self.borderView.transform;
        self.borderView.transform = CGAffineTransformIdentity;
        CGRect rect = [self convertRect:self.borderView.frame toView:parentView];
        self.borderView.transform = borderTransform;
        self.transform = transform;
        CGPoint point = [self convertPoint:self.touchPoint toView:parentView];
        CGFloat scaleX = 0.f;
        CGFloat scaleY = 0.f;
        CGAffineTransform realTransform = transform;
        if ([ACCRTL() enableRTL]) {
            // 文字贴纸RTL还要专门适配下
            scaleX = sqrt(transform.a * transform.a + transform.c * transform.c);
            scaleY = sqrt(transform.b * transform.b + transform.d * transform.d);
            CGFloat angle = atan2(transform.b, transform.a);
            angle = -angle;
            realTransform = CGAffineTransformConcat(CGAffineTransformMakeScale(scaleX, scaleY), CGAffineTransformMakeRotation(angle));
        }
        // 文字贴纸线框大小相对原frame有个缩小的scale...
        scaleX = sqrt(borderTransform.a * borderTransform.a + borderTransform.c * borderTransform.c);
        scaleY = sqrt(borderTransform.b * borderTransform.b + borderTransform.d * borderTransform.d);
        realTransform = CGAffineTransformScale(realTransform, scaleX, scaleY);
        [self.bubble setRect:rect touchPoint:point transform:realTransform inParentView:parentView];
        [self.bubble setBubbleVisible:YES animated:YES];
    }
}


#pragma mark - gesture action

//平移手势的回调方法
- (void)panAction:(UIPanGestureRecognizer *)sender
{
    if (self.enableEdit) {
        CGPoint currentPoint = [sender translationInView:self.superview];
        
        if ((self.frame.origin.y + currentPoint.y >= 0) || self.center.y + currentPoint.y < self.editCenter.y) {
            self.center = CGPointMake(self.center.x, self.center.y);
        } else {
            self.center = CGPointMake(self.center.x, self.center.y + currentPoint.y);
        }
        
        [sender setTranslation:CGPointZero inView:self.superview];
        return;
    }
}

- (void)handleContentScaleFactor
{
    CGFloat contentScaleFactor = self.currentScale * [UIScreen mainScreen].scale;
    if (contentScaleFactor <= 2.0) {
        contentScaleFactor = 2.0;
    } else if (contentScaleFactor >= 20.0) {
        contentScaleFactor = 20.0;
    }
    
    for (UIView *view in self.textView.subviews) {
        view.contentScaleFactor = contentScaleFactor;
    }
    
    self.contentScaleFactor = contentScaleFactor;
}

- (void)setCanOperate:(BOOL)canOperate
{
    self.userInteractionEnabled = canOperate;
}

#pragma mark - action

- (void)clickDeleteButton:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(editorSticker:clickedDeleteButton:)]) {
        [self.delegate editorSticker:self clickedDeleteButton:button];
    }
}

- (void)clickSelectTimeButton:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(editorSticker:clickedSelectTimeButton:)]) {
        [self.delegate editorSticker:self clickedSelectTimeButton:button];
    }
}

- (void)clickEditButton:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(editorSticker:clickedTextEditButton:)]) {
        [self.delegate editorSticker:self clickedTextEditButton:button];
    }
    [self hideHandle];
}

#pragma mark - getter && setter

- (void)setRealDuration:(CGFloat)realDuration {
    [super setRealDuration:realDuration];
    [self updateStartTimeAndEndTimeForInteractionStickerInfo];
}

- (void)setRealStartTime:(CGFloat)realStartTime {
    [super setRealStartTime:realStartTime];
    [self updateStartTimeAndEndTimeForInteractionStickerInfo];
}

- (AWEInteractionStickerLocationModel *)stickerLocationForInteraction {
    if (!_stickerLocationForInteraction) {
        _stickerLocationForInteraction = [[AWEInteractionStickerLocationModel alloc] init];
    }
    return _stickerLocationForInteraction;
}

- (AWEInteractionStickerModel *)interactionStickerInfo
{
    if (!_interactionStickerInfo) {
        _interactionStickerInfo = [[AWEInteractionStickerModel alloc] init];
    }
    return _interactionStickerInfo;
}

- (UIView *)borderView
{
    if (!_borderView) {
        _borderView = [[UIView alloc] init];
    }
    return _borderView;
}

- (CAShapeLayer *)borderShapeLayer
{
    if (!_borderShapeLayer) {
        _borderShapeLayer = [CAShapeLayer layer];
        _borderShapeLayer.borderWidth = 1;
        _borderShapeLayer.borderColor = [ACCUIColorFromRGBA(0xffffff, 1) CGColor];
    }
    return _borderShapeLayer;
}

- (CAShapeLayer *)centerHorizontalDashLayer {
    if (!_centerHorizontalDashLayer) {
        CAShapeLayer *dashLineLayer = [CAShapeLayer layer];
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, &CGAffineTransformIdentity, 0, 0);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, kAWEStoryBackgroundCenterHelperLineLength, 0);
        dashLineLayer.path = path;
        dashLineLayer.lineWidth = kAWEStoryBackgroundCenterHelperLineWidth;
        dashLineLayer.lineDashPattern = @[@4, @4];
        dashLineLayer.lineCap = kCALineCapButt;
        dashLineLayer.strokeColor = ACCResourceColor(ACCUIColorConstSecondary).CGColor;
        _centerHorizontalDashLayer = dashLineLayer;
        CGPathRelease(path);
    }
    return _centerHorizontalDashLayer;
}

- (AWEEditStickerBubbleManager *)bubble {
    AWEEditStickerBubbleManager *bubble;
    if (self.isInteractionSticker) {
        bubble = [AWEEditStickerBubbleManager interactiveStickerBubbleManager];
    } else {
        bubble = [AWEEditStickerBubbleManager textStickerBubbleManager];
    }
    if (!self.bubbleItems) {
        NSMutableArray *items = [NSMutableArray array];
        @weakify(self)
        if (self.isCaption) {
            // 自动字幕的气泡菜单
            self.bubbleItems = @[
                ({
                    AWEEditStickerBubbleItem *editItem = [[AWEEditStickerBubbleItem alloc] initWithImage:ACCResourceImage(@"icCameraStickerEditNew") title:ACCLocalizedString(@"auto_caption_edit_subtitle", @"编辑字幕") actionBlock:^{
                        @strongify(self)
                        [self.bubble setBubbleVisible:NO animated:NO];

                        // Call clickEditButton after bubble did dismiss
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self clickEditButton:nil];
                        });
                    }];
                    editItem;
                }),
                ({
                    AWEEditStickerBubbleItem *deleteItem = [[AWEEditStickerBubbleItem alloc] initWithImage:ACCResourceImage(@"icCaptionDelete") title:ACCLocalizedString(@"delete", @"") actionBlock:^{
                        @strongify(self)
                        [self.bubble setBubbleVisible:NO animated:NO];
                        [self clickDeleteButton:nil];
                    }];
                    deleteItem;
                })
            ];
        } else {
            if (!self.isInteractionSticker) {
                AWEEditStickerBubbleItem *selectTime = [[AWEEditStickerBubbleItem alloc] initWithImage:ACCResourceImage(@"icCameraStickerTimeNew") title:ACCLocalizedString(@"creation_edit_sticker_duration", @"") actionBlock:^{
                    @strongify(self)
                    [self.bubble setBubbleVisible:NO animated:NO];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self clickSelectTimeButton:nil];
                    });
                    //不再提醒
                    [AWEEditStickerHintView setNoNeedShowForType:AWEEditStickerHintTypeText];
                }];
                [items addObject:selectTime];
            }
            AWEEditStickerBubbleItem *edit = [[AWEEditStickerBubbleItem alloc] initWithImage:ACCResourceImage(@"icCameraStickerEditNew") title:ACCLocalizedString(@"creation_edit_text_edit", @"编辑") actionBlock:^{
                @strongify(self)
                [self clickEditButton:nil];
                //不再提醒
                [AWEEditStickerHintView setNoNeedShowForType:self.isInteractionSticker?AWEEditStickerHintTypeInteractive: AWEEditStickerHintTypeText];
            }];
            [items addObject:edit];
            self.bubbleItems = items.copy;
        }
    }
    bubble.bubbleItems = self.bubbleItems;
    return bubble;
}

- (ACCEditPageLayoutManager *)layoutManager {
    if (!_layoutManager) {
        _layoutManager = [ACCEditPageLayoutManager new];
        _layoutManager.usesFontLeading = NO;
    }
    return _layoutManager;
}

- (ACCEditPageTextStorage *)textStorage {
    if (!_textStorage) {
        _textStorage = [ACCEditPageTextStorage new];
    }
    return _textStorage;
}

- (ACCEditPageTextView *)textView
{
    if (!_textView) {
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
        textContainer.widthTracksTextView = YES;
        [self.layoutManager addTextContainer:textContainer];
        [self.textStorage addLayoutManager:self.layoutManager];
        _textView = [[ACCEditPageTextView alloc] initWithFrame:CGRectZero textContainer:textContainer];
        _textView.autocorrectionType = UITextAutocorrectionTypeNo;
        _textView.tintColor = ACCResourceColor(ACCColorPrimary);
        _textView.acc_delegate = self;
        _textView.font = [ACCFont() systemFontOfSize:self.defaultFontSize weight:ACCFontWeightHeavy];
        _textView.textColor = [UIColor blackColor];
        _textView.scrollEnabled = NO;
        _textView.showsVerticalScrollIndicator = NO;
        _textView.showsHorizontalScrollIndicator = NO;
        _textView.textAlignment = NSTextAlignmentCenter;
        _textView.textContainerInset = UIEdgeInsetsMake(kAWEStoryBackgroundTextViewContainerInset, kAWEStoryBackgroundTextViewContainerInset, kAWEStoryBackgroundTextViewContainerInset, kAWEStoryBackgroundTextViewContainerInset);
        _textView.textContainer.lineFragmentPadding = 0;
        _textView.backgroundColor = [UIColor clearColor];
        _textView.textStickerId = self.textStickerId;
        _textView.forCoverText = self.forCoverText;
    }
    return _textView;
}

- (UIView *)darkBGView
{
    if (!_darkBGView) {
        _darkBGView = [UIView new];
        _darkBGView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5f];
    }
    return _darkBGView;
}

- (NSMutableArray *)currentShowLayerArray
{
    if (!_currentShowLayerArray) {
        _currentShowLayerArray = [@[] mutableCopy];
    }
    return _currentShowLayerArray;
}

- (NSMutableArray *)layerPool
{
    if (!_layerPool) {
        _layerPool = [NSMutableArray array];
        [_layerPool addObject:[CAShapeLayer layer]];
    }
    return _layerPool;
}

- (AWEStoryTextImageModel *)textInfoModel
{
    if (!_textInfoModel) {
        _textInfoModel = [AWEStoryTextImageModel new];
        _textInfoModel.colorIndex = [NSIndexPath indexPathForRow:0 inSection:0];
        _textInfoModel.fontIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    }

    _textInfoModel.realStartTime = self.realStartTime;
    _textInfoModel.realDuration = self.realDuration;
    
    return _textInfoModel;
}

- (void)setTextStickerId:(NSString *)textStickerId {
    _textStickerId = textStickerId;
    self.textView.textStickerId = textStickerId;
}


#pragma mark - ACCTextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    ACCBLOCK_INVOKE(self.textChangedBlock, textView.text);
    self.textInfoModel.content = self.textView.text;
    [self refreshFont];
}

#pragma mark - help

- (void)setColor:(AWEStoryColor *)color
{
    _color = color;
    self.textInfoModel.fontColor = color;
    [self refreshFont];
}

- (void)setStyle:(AWEStoryTextStyle)style
{
    _style = style;
    self.textInfoModel.textStyle = style;
    [self setColor:self.color];
}

- (void)setAlignmentType:(AWEStoryTextAlignmentStyle)alignmentType
{
    _alignmentType = alignmentType;
    self.textInfoModel.alignmentType = alignmentType;
    
    if (alignmentType == AWEStoryTextAlignmentLeft) {
        _textView.textAlignment = NSTextAlignmentLeft;
    } else if (alignmentType == AWEStoryTextAlignmentRight) {
        _textView.textAlignment = NSTextAlignmentRight;
    } else {
        _textView.textAlignment = NSTextAlignmentCenter;
    }
    
    [self refreshFont];
}

- (void)setSelectFont:(AWEStoryFontModel *)selectFont
{
    _selectFont = selectFont;
    self.textInfoModel.fontModel = selectFont;
    
    UIFont *defaultFont = [ACCFont() systemFontOfSize:self.defaultFontSize weight:ACCFontWeightHeavy];
    if (!selectFont) {
        _textView.font = defaultFont;
        return;
    } else {
        CGFloat fontSize = (selectFont.defaultFontSize>0) ? selectFont.defaultFontSize : self.defaultFontSize;
        
        _textView.font = [ACCCustomFont() fontWithModel:selectFont size:fontSize];
    }
    
    [self refreshFont];
}

- (void)resetTextViewAlignment
{
    if (self.alignmentType == AWEStoryTextAlignmentLeft) {
        _textView.textAlignment = NSTextAlignmentLeft;
    } else if (self.alignmentType == AWEStoryTextAlignmentRight) {
        _textView.textAlignment = NSTextAlignmentRight;
    } else {
        _textView.textAlignment = NSTextAlignmentCenter;
    }
}

#pragma mark - 刷新文字贴纸显示样式

- (void)doAfterChange
{
    [self p_updateFrame];
    
    if (!self.isInteractionSticker) {
        [self drawBackgroundWithFillColor:self.fillColor];
    }
}

- (void)refreshFont
{
    if (self.notRefresh) {
        return;
    }
    
    if (!self.isInteractionSticker) {
        if (self.selectFont) {
            CGFloat fontSize = (self.selectFont.defaultFontSize>0) ? self.selectFont.defaultFontSize : self.defaultFontSize;
            UIFont *font = [ACCCustomFont() fontWithModel:self.selectFont size:fontSize];
            self.textView.font = font;
        }
        if (self.selectFont.hasShadeColor) {
            NSShadow *shadow = [[NSShadow alloc] init];
            shadow.shadowBlurRadius = 10;
            shadow.shadowColor = self.color.color;
            shadow.shadowOffset = CGSizeMake(0, 0);
            
            NSDictionary *params = @{
                NSShadowAttributeName : shadow,
                NSForegroundColorAttributeName : [UIColor whiteColor],
                NSFontAttributeName : self.textView.font,
                NSBaselineOffsetAttributeName: @(-1.5f),
            };
            [self.textView.textStorage setAttributes:params range:NSMakeRange(0, self.textView.text.length)];
            self.fillColor = [UIColor clearColor];
        } else {
            if (!self.selectFont.hasBgColor || self.style == AWEStoryTextStyleNo || self.style == AWEStoryTextStyleStroke) {
                self.textView.textColor = _color.color;
                self.fillColor = [UIColor clearColor];
            } else {
                if (CGColorEqualToColor(_color.color.CGColor, [ACCUIColorFromRGBA(0xffffff, 1.0) CGColor])) {
                    if (self.style == AWEStoryTextStyleBackground) {
                        self.textView.textColor = [UIColor blackColor];
                    } else {
                        self.textView.textColor = [UIColor whiteColor];
                    }
                } else {
                    self.textView.textColor = [UIColor whiteColor];
                }
                
                if (self.style == AWEStoryTextStyleBackground) {
                    self.fillColor = _color.color;
                } else {
                    self.fillColor = [_color.color colorWithAlphaComponent:0.5];
                }
            }
            NSDictionary *params = @{
                NSForegroundColorAttributeName : self.textView.textColor ?: [UIColor whiteColor],
                NSFontAttributeName : self.textView.font,
                NSBaselineOffsetAttributeName: @(-1.5f),
            };
            [self.textView.textStorage setAttributes:params range:NSMakeRange(0, self.textView.text.length)];
        }
        if ((!self.selectFont || self.selectFont.supportStroke) && self.style == AWEStoryTextStyleStroke && self.color.borderColor) {
            self.layoutManager.strokeConfig = [ACCEditPageStrokeConfig strokeWithWidth:2 color:self.color.borderColor lineJoin:kCGLineJoinRound];
        } else {
            self.layoutManager.strokeConfig = nil;
        }
        
        // 防止有selectRange的情况下，切换字体，textAlignment自动切换成居左，导致背景计算异常的问题
        [self resetTextViewAlignment];
    }
    
    [self doAfterChange];
}

- (void)drawBackgroundWithFillColor:(UIColor *)fillColor
{
    NSMutableArray *lineRangeArray = [@[] mutableCopy];
    NSMutableArray<NSValue *> *lineRectArray = [@[] mutableCopy];
    
    NSRange range = NSMakeRange(0, 0);
    CGRect lineRect = [self.textView.layoutManager lineFragmentUsedRectForGlyphAtIndex:0 effectiveRange:&range];
    
    if (range.length != 0) {
        [lineRangeArray addObject:[NSValue valueWithRange:range]];
        [lineRectArray addObject:[NSValue valueWithCGRect:lineRect]];
    }
    while (range.location + range.length < self.textView.text.length) {
        lineRect = [self.textView.layoutManager lineFragmentUsedRectForGlyphAtIndex:(range.location + range.length) effectiveRange:&range];
        if (range.length != 0) {
            [lineRangeArray addObject:[NSValue valueWithRange:range]];
            [lineRectArray addObject:[NSValue valueWithCGRect:lineRect]];
        }
    }

    NSMutableArray<NSMutableArray *> *segArray = [@[] mutableCopy];
    NSMutableArray *currentArray = [@[] mutableCopy];
    [segArray addObject:currentArray];
    int i = 0;
    while (i < lineRectArray.count) {
        if (lineRectArray[i].CGRectValue.size.width <= 0.00001) {
            if (currentArray.count != 0) {
                currentArray = [@[] mutableCopy];
                [segArray addObject:currentArray];
            }
        } else {
            [currentArray addObject:lineRectArray[i]];
        }
        i++;
    }
    
    for (CAShapeLayer *layer in self.currentShowLayerArray) {
        [layer removeFromSuperlayer];
        [self.layerPool addObject:layer];
    }
    
    [self.currentShowLayerArray removeAllObjects];
    
    for (NSArray *lineRectArray in segArray) {
        if (lineRectArray.count) {
            [self drawWithLineRectArray:lineRectArray fillColor:fillColor];
        }
    }
}

- (void)drawWithLineRectArray:(NSArray<NSValue *> *)array fillColor:(UIColor *)fillColor
{
    NSMutableArray<NSValue *> *lineRectArray = [array mutableCopy];
    
    CAShapeLayer *leftLayer = nil;
    
    if (self.layerPool.count) {
        leftLayer = self.layerPool.lastObject;
        [self.layerPool removeLastObject];
    } else {
        leftLayer = [CAShapeLayer layer];
    }
    
    leftLayer.fillColor = fillColor.CGColor;
    [self.layer insertSublayer:leftLayer atIndex:0];
    
    [self.currentShowLayerArray addObject:leftLayer];
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    if (lineRectArray.count == 1) {
        CGRect currentLineRect = lineRectArray[0].CGRectValue;
        CGPoint topMidPoint = [self topMidPointWithRect:currentLineRect];
        [path moveToPoint:topMidPoint];
        
        CGPoint leftTop = [self leftTopWithRect_up:currentLineRect];
        CGPoint leftTopCenter = CGPointMake(leftTop.x + kAWEStoryBackgroundTextViewBackgroundRadius , leftTop.y + kAWEStoryBackgroundTextViewBackgroundRadius);
        [path addLineToPoint:CGPointMake(leftTopCenter.x, leftTop.y)];
        [path addArcWithCenter:leftTopCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:M_PI * 1.5 endAngle:M_PI clockwise:NO];
        
        
        CGPoint leftBottomPoint = [self leftBottomWithRect_down:currentLineRect];
        CGPoint leftBottomCenter = CGPointMake(leftBottomPoint.x + kAWEStoryBackgroundTextViewBackgroundRadius, leftBottomPoint.y - kAWEStoryBackgroundTextViewBackgroundRadius);
        [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
        [path addArcWithCenter:leftBottomCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:M_PI endAngle:M_PI * 0.5 clockwise:NO];
        
        CGPoint bottomMid = [self bottomMidPointWithRect:currentLineRect];
        [path addLineToPoint:bottomMid];
    } else if (lineRectArray.count > 1) {
        int i = 0;
        while (i < lineRectArray.count - 1) {
            CGRect currentLineRect = lineRectArray[i].CGRectValue;
            CGRect nextLineRect = lineRectArray[i + 1].CGRectValue;
            if (fabs(currentLineRect.size.width - nextLineRect.size.width) <= (4 * kAWEStoryBackgroundTextViewBackgroundRadius + 1)) {
                //如果两行之差小于2 * kAWEStoryBackgroundTextViewBackgroundRadius
                if (currentLineRect.size.width > nextLineRect.size.width) {
                    lineRectArray[i] = @(CGRectMake(currentLineRect.origin.x, currentLineRect.origin.y, currentLineRect.size.width, currentLineRect.size.height + nextLineRect.size.height));
                } else {
                    lineRectArray[i] = @(CGRectMake(nextLineRect.origin.x, currentLineRect.origin.y, nextLineRect.size.width, currentLineRect.size.height + nextLineRect.size.height));
                }
                [lineRectArray removeObjectAtIndex:(i + 1)];
            } else {
                i ++;
            }
        }
        
        if (self.textView.textAlignment == NSTextAlignmentLeft) {
            path = [self drawAlignmentLeftLineRectArray:lineRectArray];
        } else if (self.textView.textAlignment == NSTextAlignmentRight) {
            path = [self drawAlignmentRightLineRectArray:lineRectArray];
        } else {
            path = [self drawAlignmentCenterLineRectArray:lineRectArray];
        }
    }
    
    if (self.alignmentType == AWEStoryTextAlignmentCenter || array.count == 1) {
        //先移动到原点，然后做翻转，然后再移动到指定位置
        UIBezierPath *reversingPath = path.bezierPathByReversingPath;
        CGRect boxRect = CGPathGetPathBoundingBox(reversingPath.CGPath);
        [reversingPath applyTransform:CGAffineTransformMakeTranslation(- CGRectGetMidX(boxRect), - CGRectGetMidY(boxRect))];
        [reversingPath applyTransform:CGAffineTransformMakeScale(-1, 1)];
        [reversingPath applyTransform:CGAffineTransformMakeTranslation(CGRectGetWidth(boxRect) + CGRectGetMidX(boxRect), CGRectGetMidY(boxRect))];
        [path appendPath:reversingPath];
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    leftLayer.path = path.CGPath;
    CGRect frame = self.textView.frame;
    frame.origin.x += kAWEStoryBackgroundTextViewContainerInset;
    frame.origin.y += kAWEStoryBackgroundTextViewContainerInset;
    leftLayer.frame = frame;
    [CATransaction commit];
}

////////////////////////////////////////////////////////////////////////////////

- (CGPoint)leftTopWithRect_up:(CGRect)rect
{
    return CGPointMake(rect.origin.x - kAWEStoryBackgroundTextViewBackgroundColorLeftMargin, rect.origin.y - kAWEStoryBackgroundTextViewBackgroundColorTopMargin);
}

- (CGPoint)leftTopCenterWithRect_up:(CGRect)rect
{
    CGPoint leftTop = [self leftTopWithRect_up:rect];
    return CGPointMake(leftTop.x + kAWEStoryBackgroundTextViewBackgroundRadius , leftTop.y + kAWEStoryBackgroundTextViewBackgroundRadius);
}

- (CGPoint)leftTopWithRect_down:(CGRect)rect
{
    return CGPointMake(rect.origin.x - kAWEStoryBackgroundTextViewBackgroundColorLeftMargin, rect.origin.y + kAWEStoryBackgroundTextViewBackgroundColorTopMargin);
}

- (CGPoint)leftTopCenterWithRect_down:(CGRect)rect
{
    CGPoint leftTop = [self leftTopWithRect_down:rect];
    return CGPointMake(leftTop.x - kAWEStoryBackgroundTextViewBackgroundRadius, leftTop.y + kAWEStoryBackgroundTextViewBackgroundRadius);
}

////////////////////////////////////////////////////////////////////////////////

- (CGPoint)leftBottomWithRect_up:(CGRect)rect
{
    return CGPointMake(rect.origin.x - kAWEStoryBackgroundTextViewBackgroundColorLeftMargin, rect.origin.y + rect.size.height - kAWEStoryBackgroundTextViewBackgroundColorTopMargin);
}

- (CGPoint)leftBottomCenterWithRect_up:(CGRect)rect
{
    CGPoint leftBottomPoint = [self leftBottomWithRect_up:rect];
    return CGPointMake(leftBottomPoint.x - kAWEStoryBackgroundTextViewBackgroundRadius, leftBottomPoint.y - kAWEStoryBackgroundTextViewBackgroundRadius);
}

- (CGPoint)leftBottomWithRect_down:(CGRect)rect
{
    return CGPointMake(rect.origin.x - kAWEStoryBackgroundTextViewBackgroundColorLeftMargin, rect.origin.y + rect.size.height + kAWEStoryBackgroundTextViewBackgroundColorTopMargin);
}

- (CGPoint)leftBottomCenterWithRect_down:(CGRect)rect
{
    CGPoint leftBottomPoint = [self leftBottomWithRect_down:rect];
    return CGPointMake(leftBottomPoint.x + kAWEStoryBackgroundTextViewBackgroundRadius, leftBottomPoint.y - kAWEStoryBackgroundTextViewBackgroundRadius);
}

////////////////////////////////////////////////////////////////////////////////

- (CGPoint)topMidPointWithRect:(CGRect)rect
{
    return CGPointMake(CGRectGetMidX(rect), rect.origin.y - kAWEStoryBackgroundTextViewBackgroundColorTopMargin);
}

- (CGPoint)bottomMidPointWithRect:(CGRect)rect
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect) + kAWEStoryBackgroundTextViewBackgroundColorTopMargin);
}

////////////////////////////////////////////////////////////////////////////////

- (CGPoint)rightTopWithRect_up:(CGRect)rect
{
    return CGPointMake(CGRectGetMaxX(rect) + kAWEStoryBackgroundTextViewBackgroundColorLeftMargin, rect.origin.y - kAWEStoryBackgroundTextViewBackgroundColorTopMargin);
}

- (CGPoint)rightTopCenterWithRect_up:(CGRect)rect
{
    CGPoint rightTop = [self rightTopWithRect_up:rect];
    return CGPointMake(rightTop.x - kAWEStoryBackgroundTextViewBackgroundRadius , rightTop.y + kAWEStoryBackgroundTextViewBackgroundRadius);
}

- (CGPoint)rightTopWithRect_down:(CGRect)rect
{
    return CGPointMake(CGRectGetMaxX(rect) + kAWEStoryBackgroundTextViewBackgroundColorLeftMargin, rect.origin.y + kAWEStoryBackgroundTextViewBackgroundColorTopMargin);
}

- (CGPoint)rightTopCenterWithRect_down:(CGRect)rect
{
    CGPoint rightTop = [self rightTopWithRect_down:rect];
    return CGPointMake(rightTop.x + kAWEStoryBackgroundTextViewBackgroundRadius , rightTop.y + kAWEStoryBackgroundTextViewBackgroundRadius);
}

////////////////////////////////////////////////////////////////////////////////

- (CGPoint)rightBottomWithRect_up:(CGRect)rect
{
    return CGPointMake(CGRectGetMaxX(rect) + kAWEStoryBackgroundTextViewBackgroundColorLeftMargin, CGRectGetMaxY(rect) - kAWEStoryBackgroundTextViewBackgroundColorTopMargin);
}

- (CGPoint)rightBottomCenterWithRect_up:(CGRect)rect
{
    CGPoint rightBottom = [self rightBottomWithRect_up:rect];
    return CGPointMake(rightBottom.x + kAWEStoryBackgroundTextViewBackgroundRadius , rightBottom.y - kAWEStoryBackgroundTextViewBackgroundRadius);
}

- (CGPoint)rightBottomWithRect_down:(CGRect)rect
{
    return CGPointMake(CGRectGetMaxX(rect) + kAWEStoryBackgroundTextViewBackgroundColorLeftMargin, CGRectGetMaxY(rect) + kAWEStoryBackgroundTextViewBackgroundColorTopMargin);
}

- (CGPoint)rightBottomCenterWithRect_down:(CGRect)rect
{
    CGPoint rightBottom = [self rightBottomWithRect_down:rect];
    return CGPointMake(rightBottom.x - kAWEStoryBackgroundTextViewBackgroundRadius , rightBottom.y - kAWEStoryBackgroundTextViewBackgroundRadius);
}

////////////////////////////////////////////////////////////////////////////////

- (UIBezierPath *)drawAlignmentCenterLineRectArray:(NSArray<NSValue *> *)lineRectArray
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGRect firstLineRect = lineRectArray[0].CGRectValue;
    
    CGPoint topMidPoint = [self topMidPointWithRect:firstLineRect];
    [path moveToPoint:topMidPoint];
    
    CGPoint leftTop = [self leftTopWithRect_up:firstLineRect];
    CGPoint leftTopCenter = [self leftTopCenterWithRect_up:firstLineRect];
    [path addLineToPoint:CGPointMake(leftTopCenter.x, leftTop.y)];
    [path addArcWithCenter:leftTopCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:M_PI * 1.5 endAngle:M_PI clockwise:NO];
    
    for (int i = 0; i < lineRectArray.count; i++) {
        CGRect currentLineRect = lineRectArray[i].CGRectValue;
        if (i + 1 < lineRectArray.count) {
            //当前行是中间行
            CGRect nextLineRect = lineRectArray[i + 1].CGRectValue;
            
            CGPoint leftBottomPoint;
            CGPoint leftBottomCenter;
            CGPoint nextLineLeftTopPoint;
            CGPoint nextLineLeftTopCenter;
            if (nextLineRect.origin.x > currentLineRect.origin.x) {
                leftBottomPoint = [self leftBottomWithRect_down:currentLineRect];
                leftBottomCenter = [self leftBottomCenterWithRect_down:currentLineRect];
                [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
                [path addArcWithCenter:leftBottomCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:M_PI endAngle:M_PI * 0.5 clockwise:NO];
                
                nextLineLeftTopPoint = [self leftTopWithRect_down:nextLineRect];
                nextLineLeftTopCenter = [self leftTopCenterWithRect_down:nextLineRect];
                [path addLineToPoint:CGPointMake(nextLineLeftTopCenter.x, nextLineLeftTopPoint.y)];
                [path addArcWithCenter:nextLineLeftTopCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:1.5 * M_PI endAngle:2 * M_PI clockwise:YES];
            } else {
                leftBottomPoint = [self leftBottomWithRect_up:currentLineRect];
                leftBottomCenter = [self leftBottomCenterWithRect_up:currentLineRect];
                [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
                [path addArcWithCenter:leftBottomCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:0 endAngle:M_PI * 0.5 clockwise:YES];
                
                nextLineLeftTopPoint = [self leftTopWithRect_up:nextLineRect];
                nextLineLeftTopCenter = [self leftTopCenterWithRect_up:nextLineRect];
                [path addLineToPoint:CGPointMake(nextLineLeftTopCenter.x, nextLineLeftTopPoint.y)];
                [path addArcWithCenter:nextLineLeftTopCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:1.5 * M_PI endAngle:M_PI clockwise:NO];
            }
        } else {
            //当前行是最后一行
            CGPoint leftBottomPoint;
            CGPoint leftBottomCenter;
            leftBottomPoint = [self leftBottomWithRect_down:currentLineRect];
            leftBottomCenter = [self leftBottomCenterWithRect_down:currentLineRect];
            [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
            [path addArcWithCenter:leftBottomCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:M_PI endAngle:M_PI * 0.5 clockwise:NO];
            
            CGPoint bottomMidPoint = [self bottomMidPointWithRect:currentLineRect];
            [path addLineToPoint:CGPointMake(topMidPoint.x, bottomMidPoint.y)];
        }
    }
    
    return path;
}

- (UIBezierPath *)drawAlignmentLeftLineRectArray:(NSArray<NSValue *> *)lineRectArray
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGRect firstLineRect = lineRectArray[0].CGRectValue;
    
    CGPoint leftTop = [self leftTopWithRect_up:firstLineRect];
    CGPoint leftTopCenter = [self leftTopCenterWithRect_up:firstLineRect];
    
    [path moveToPoint:CGPointMake(leftTopCenter.x, leftTop.y)];
    
    CGPoint rightTop = [self rightTopWithRect_up:firstLineRect];
    CGPoint rightTopCenter = [self rightTopCenterWithRect_up:firstLineRect];
    [path addLineToPoint:CGPointMake(rightTopCenter.x, rightTop.y)];
    [path addArcWithCenter:rightTopCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:M_PI * 1.5 endAngle:M_PI * 2 clockwise:YES];
    
    for (int i = 0; i < lineRectArray.count; i++) {
        CGRect currentLineRect = lineRectArray[i].CGRectValue;
        if (i + 1 < lineRectArray.count) {
            //当前行是中间行
            CGRect nextLineRect = lineRectArray[i + 1].CGRectValue;
            
            CGPoint rightBottomPoint;
            CGPoint rightBottomCenter;
            CGPoint nextLineRightTopPoint;
            CGPoint nextLineRightTopCenter;
            if (nextLineRect.size.width < currentLineRect.size.width) {
                rightBottomPoint = [self rightBottomWithRect_down:currentLineRect];
                rightBottomCenter = [self rightBottomCenterWithRect_down:currentLineRect];
                [path addLineToPoint:CGPointMake(rightBottomPoint.x, rightBottomCenter.y)];
                [path addArcWithCenter:rightBottomCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:0 endAngle:M_PI * 0.5 clockwise:YES];
                
                nextLineRightTopPoint = [self rightTopWithRect_down:nextLineRect];
                nextLineRightTopCenter = [self rightTopCenterWithRect_down:nextLineRect];
                [path addLineToPoint:CGPointMake(nextLineRightTopCenter.x, nextLineRightTopPoint.y)];
                [path addArcWithCenter:nextLineRightTopCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:1.5 * M_PI endAngle:M_PI clockwise:NO];
            } else {
                rightBottomPoint = [self rightBottomWithRect_up:currentLineRect];
                rightBottomCenter = [self rightBottomCenterWithRect_up:currentLineRect];
                [path addLineToPoint:CGPointMake(rightBottomPoint.x, rightBottomCenter.y)];
                [path addArcWithCenter:rightBottomCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:M_PI endAngle:M_PI * 0.5 clockwise:NO];
                
                nextLineRightTopPoint = [self rightTopWithRect_up:nextLineRect];
                nextLineRightTopCenter = [self rightTopCenterWithRect_up:nextLineRect];
                [path addLineToPoint:CGPointMake(nextLineRightTopCenter.x, nextLineRightTopPoint.y)];
                [path addArcWithCenter:nextLineRightTopCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:1.5 * M_PI endAngle:M_PI * 2 clockwise:YES];
            }
        } else {
            //当前行是最后一行
            CGPoint rightBottomPoint;
            CGPoint rightBottomCenter;
            rightBottomPoint = [self rightBottomWithRect_down:currentLineRect];
            rightBottomCenter = [self rightBottomCenterWithRect_down:currentLineRect];
            [path addLineToPoint:CGPointMake(rightBottomPoint.x, rightBottomCenter.y)];
            [path addArcWithCenter:rightBottomCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:0 endAngle:M_PI * 0.5 clockwise:YES];
            
            CGPoint leftBottomPoint = [self leftBottomWithRect_down:currentLineRect];
            CGPoint leftBottomCenterPoint = [self leftBottomCenterWithRect_down:currentLineRect];
            [path addLineToPoint:CGPointMake(leftBottomCenterPoint.x, leftBottomPoint.y)];
            [path addArcWithCenter:leftBottomCenterPoint radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:M_PI * 0.5 endAngle:M_PI clockwise:YES];
            [path addLineToPoint:CGPointMake(leftTop.x, leftTopCenter.y)];
            [path addArcWithCenter:leftTopCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:M_PI endAngle:1.5 * M_PI clockwise:YES];
        }
    }
    
    return path;
}

- (UIBezierPath *)drawAlignmentRightLineRectArray:(NSArray<NSValue *> *)lineRectArray
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGRect firstLineRect = lineRectArray[0].CGRectValue;
    
    CGPoint rightTopPoint = [self rightTopWithRect_up:firstLineRect];
    CGPoint rightTopCenterPoint = [self rightTopCenterWithRect_up:firstLineRect];
    
    [path moveToPoint:CGPointMake(rightTopCenterPoint.x, rightTopPoint.y)];
    
    CGPoint leftTop = [self leftTopWithRect_up:firstLineRect];
    CGPoint leftTopCenter = [self leftTopCenterWithRect_up:firstLineRect];
    [path addLineToPoint:CGPointMake(leftTopCenter.x, leftTop.y)];
    [path addArcWithCenter:leftTopCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:M_PI * 1.5 endAngle:M_PI clockwise:NO];
    
    for (int i = 0; i < lineRectArray.count; i++) {
        CGRect currentLineRect = lineRectArray[i].CGRectValue;
        if (i + 1 < lineRectArray.count) {
            //当前行是中间行
            CGRect nextLineRect = lineRectArray[i + 1].CGRectValue;
            
            CGPoint leftBottomPoint;
            CGPoint leftBottomCenter;
            CGPoint nextLineLeftTopPoint;
            CGPoint nextLineLeftTopCenter;
            if (nextLineRect.origin.x > currentLineRect.origin.x) {
                leftBottomPoint = [self leftBottomWithRect_down:currentLineRect];
                leftBottomCenter = [self leftBottomCenterWithRect_down:currentLineRect];
                [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
                [path addArcWithCenter:leftBottomCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:M_PI endAngle:M_PI * 0.5 clockwise:NO];
                
                nextLineLeftTopPoint = [self leftTopWithRect_down:nextLineRect];
                nextLineLeftTopCenter = [self leftTopCenterWithRect_down:nextLineRect];
                [path addLineToPoint:CGPointMake(nextLineLeftTopCenter.x, nextLineLeftTopPoint.y)];
                [path addArcWithCenter:nextLineLeftTopCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:1.5 * M_PI endAngle:2 * M_PI clockwise:YES];
            } else {
                leftBottomPoint = [self leftBottomWithRect_up:currentLineRect];
                leftBottomCenter = [self leftBottomCenterWithRect_up:currentLineRect];
                [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
                [path addArcWithCenter:leftBottomCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:0 endAngle:M_PI * 0.5 clockwise:YES];
                
                nextLineLeftTopPoint = [self leftTopWithRect_up:nextLineRect];
                nextLineLeftTopCenter = [self leftTopCenterWithRect_up:nextLineRect];
                [path addLineToPoint:CGPointMake(nextLineLeftTopCenter.x, nextLineLeftTopPoint.y)];
                [path addArcWithCenter:nextLineLeftTopCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:1.5 * M_PI endAngle:M_PI clockwise:NO];
            }
        } else {
            //当前行是最后一行
            CGPoint leftBottomPoint;
            CGPoint leftBottomCenter;
            leftBottomPoint = [self leftBottomWithRect_down:currentLineRect];
            leftBottomCenter = [self leftBottomCenterWithRect_down:currentLineRect];
            [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
            [path addArcWithCenter:leftBottomCenter radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:M_PI endAngle:M_PI * 0.5 clockwise:NO];
            
            CGPoint rightBottomPoint = [self rightBottomWithRect_down:currentLineRect];
            CGPoint rightBottomCenterPoint = [self rightBottomCenterWithRect_down:currentLineRect];
            [path addLineToPoint:CGPointMake(rightBottomCenterPoint.x, rightBottomPoint.y)];
            [path addArcWithCenter:rightBottomCenterPoint radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:M_PI * 0.5 endAngle:0 clockwise:NO];
            [path addLineToPoint:CGPointMake(rightTopPoint.x, rightTopCenterPoint.y)];
            [path addArcWithCenter:rightTopCenterPoint radius:kAWEStoryBackgroundTextViewBackgroundRadius startAngle:2 * M_PI endAngle:1.5 * M_PI clockwise:NO];
        }
    }
    
    return path;
}

#pragma mark -

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    [self handleContentScaleFactor];
    
    if (nil == self.window) {
        // fix AME-84279
        [self hideHandle];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    self.touchPoint = point;
    if (self.enableEdit) {
        return [super hitTest:point withEvent:event];
    }
    return nil;
}

#pragma mark - interaction sticker methods

- (NSString *)poiContent:(NSString *)poiName {
    NSString *icon = @"\U0000e900";//poi icon
    NSString *fontName = @"icomoon";
    NSString *poiAddress = poiName;
    
    NSString *totalStr;
    NSString *fontFullName = [NSString stringWithFormat:@"%@.ttf",fontName];
    NSURL *poiFontPath = [NSURL fileURLWithPath:ACCResourceFile(fontFullName)];
    UIFont *iconFont = [ACCFont() iconFontWithPath:poiFontPath name:fontName size:20];
    if (iconFont) {
        totalStr = [NSString stringWithFormat:@"%@ %@",icon,poiAddress];
    } else {
        totalStr = poiAddress;
    }
    return totalStr;
}

- (NSAttributedString *)poiAttributedStringWithName:(NSString *)poiName {
    NSString *fontName = @"icomoon";
    NSString *totalStr = [self poiContent:self.poiName];
    NSString *fontFullName = [NSString stringWithFormat:@"%@.ttf",fontName];
    NSURL *poiFontPath = [NSURL fileURLWithPath:ACCResourceFile(fontFullName)];
    
    NSMutableAttributedString *atts = [[NSMutableAttributedString alloc]initWithString:totalStr];
    NSRange poiRange = [totalStr rangeOfString:poiName];
    
    CGFloat width = [totalStr acc_widthWithFont:[ACCFont() systemFontOfSize:self.defaultFontSize weight:ACCFontWeightMedium] height:34];
    if (width > (ACC_SCREEN_WIDTH - 16*2 - 16*2 + 2)) {//contaner screen edge gap 16*2,textview container gap 16*2, 2-compensation
        UIFont *iconFont = [ACCFont() iconFontWithPath:poiFontPath name:fontName size:16];
        if (iconFont) {
            [atts addAttribute:NSFontAttributeName value:iconFont range:NSMakeRange(0, poiRange.location)];
            [atts addAttribute:NSBaselineOffsetAttributeName value:@0.5 range:NSMakeRange(0, poiRange.location)];
            [atts addAttribute:NSKernAttributeName value:@(-1.0) range:NSMakeRange(0, poiRange.location)];
        }
        [atts addAttribute:NSFontAttributeName value:[ACCFont() systemFontOfSize:20 weight:ACCFontWeightMedium] range:poiRange];
    } else {
        UIFont *iconFont = [ACCFont() iconFontWithPath:poiFontPath name:fontName size:20];
        if (iconFont) {
            [atts addAttribute:NSFontAttributeName value:iconFont range:NSMakeRange(0, poiRange.location)];
            [atts addAttribute:NSBaselineOffsetAttributeName value:@1.5 range:NSMakeRange(0, poiRange.location)];
            [atts addAttribute:NSKernAttributeName value:@(-1.0) range:NSMakeRange(0, poiRange.location)];
        }
        [atts addAttribute:NSFontAttributeName value:[ACCFont() systemFontOfSize:self.defaultFontSize weight:ACCFontWeightMedium] range:poiRange];
    }
    
    return atts;
}

- (CGFloat)poiContainerWidth {
    NSString *poiContent = [self poiContent:self.poiName];
    CGFloat width = [poiContent acc_widthWithFont:[ACCFont() systemFontOfSize:self.defaultFontSize weight:ACCFontWeightMedium] height:34];
    if (width > (ACC_SCREEN_WIDTH - 16*2 - 16*2 + 2)) {
        width = [poiContent acc_widthWithFont:[ACCFont() systemFontOfSize:20 weight:ACCFontWeightMedium] height:26];
    }
    return width + 16*2 - 10;//-10因为文本是左对齐
}

- (CGFloat)poiContainerHeight {
    NSString *poiContent = [self poiContent:self.poiName];
    CGFloat width = [poiContent acc_widthWithFont:[ACCFont() systemFontOfSize:self.defaultFontSize weight:ACCFontWeightMedium] height:34];
    CGFloat height = 34;
    if (width > (ACC_SCREEN_WIDTH - 16*2 - 16*2 + 2)) {
        height = 26;
    }
    return height + 2*8;
}

- (UILabel *)poiLblWithAlpha:(CGFloat)alpha {
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(14, 0, self.textView.frame.size.width-14, self.textView.frame.size.height)];
    label1.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:alpha];
    label1.textAlignment = NSTextAlignmentLeft;
    label1.attributedText = [self poiAttributedStringWithName:self.poiName];
    return label1;
}

- (AWEStoryBackgroundTextView *)poiStickerInContainer:(UIView *)superView {
    __block AWEStoryBackgroundTextView *poiSticker;
    [[superView subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[AWEStoryBackgroundTextView class]]) {
            if (((AWEStoryBackgroundTextView *)obj).isInteractionSticker) {
                poiSticker = (AWEStoryBackgroundTextView *)obj;
                *stop = YES;
            }
        }
    }];
    return poiSticker;
}

- (void)setIsInteractionSticker:(BOOL)isInteractionSticker
{
    _isInteractionSticker = isInteractionSticker;
    self.textInfoModel.isPOISticker = isInteractionSticker;
}

- (void)updateStartTimeAndEndTimeForInteractionStickerInfo {
    NSString *startTime = [NSString stringWithFormat:@"%.4f",(CGFloat)(self.realStartTime * 1000.f)];
    NSString *endTime = [NSString stringWithFormat:@"%.4f",(CGFloat)(self.realStartTime + self.realDuration) * 1000.f];

    self.stickerLocation.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
    self.stickerLocation.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
}

#pragma mark - Public

- (void)showAngleHelperDashLine {
    if (self.centerHorizontalDashLayer.hidden) {
        self.centerHorizontalDashLayer.hidden = NO;
        [UIView animateWithDuration:0.2f animations:^{
            self.centerHorizontalDashLayer.strokeColor = ACCResourceColor(ACCUIColorConstSecondary).CGColor;
        }];
    }
}

- (void)hideAngleHelperDashLine {
    if (!self.centerHorizontalDashLayer.hidden) {
        self.centerHorizontalDashLayer.hidden = YES;
        self.centerHorizontalDashLayer.strokeColor = [UIColor clearColor].CGColor;
    }
}

- (void)regenerateInteractionStickerInfo {
    [self updateLocation];
    [self updateStartTimeAndEndTimeForInteractionStickerInfo];
}

#pragma mark - 字幕

- (void)updateLocation
{
    if (!self.superview || ![self.superview isKindOfClass:[AWEStoryTextContainerView class]]) {
        return;
    }
    
    CGRect playerFrame = ((AWEStoryTextContainerView *)self.superview).playerFrame.CGRectValue;
    NSString *x = [NSString stringWithFormat:@"%.4f",(CGFloat)(self.center.x/playerFrame.size.width)];
    NSString *y = [NSString stringWithFormat:@"%.4f",(CGFloat)(self.center.y/playerFrame.size.height)];
    if (CGRectGetHeight(playerFrame) < CGRectGetHeight(self.frame)) {
        //上下有黑边
        y = [NSString stringWithFormat:@"%.4f",(CGFloat)((self.center.y - playerFrame.origin.y)/playerFrame.size.height)];
    } else if (CGRectGetWidth(playerFrame) < CGRectGetWidth(self.frame)) {
        //左右有黑边
        x = [NSString stringWithFormat:@"%.4f",(CGFloat)((self.center.x - playerFrame.origin.x)/playerFrame.size.width)];
    }
    self.stickerLocation.x = [NSDecimalNumber decimalNumberWithString:x];
    self.stickerLocation.y = [NSDecimalNumber decimalNumberWithString:y];
    
    if (self.currentScale) {
        CGFloat touchScale = 1.f;
        NSString *width = [NSString stringWithFormat:@"%.4f",(CGFloat)(touchScale*self.textView.bounds.size.width*self.currentScale/playerFrame.size.width)];
        NSString *height = [NSString stringWithFormat:@"%.4f",(CGFloat)(touchScale*self.textView.bounds.size.height*self.currentScale/playerFrame.size.height)];
        self.stickerLocation.width = [NSDecimalNumber decimalNumberWithString:width];
        self.stickerLocation.height = [NSDecimalNumber decimalNumberWithString:height];
        
        NSString *scaleStr = [NSString stringWithFormat:@"%.4f",self.currentScale];
        self.stickerLocation.scale = [NSDecimalNumber decimalNumberWithString:scaleStr];
        CGFloat radius = atan2f(self.transform.b, self.transform.a);
        CGFloat degree = radius * (180 / M_PI);
        NSString *dStr = [NSString stringWithFormat:@"%.4f",degree];
        self.stickerLocation.rotation = [NSDecimalNumber decimalNumberWithString:dStr];
    }
}

- (BOOL)setBounds:(CGRect)bounds scale:(CGFloat)scale
{
    if (bounds.size.width > 10 && bounds.size.height > 10) {
        if (![self isValidRect:bounds]) {
            return NO;
        }
        [self setBounds:bounds];
        [self updateLocation];
        return YES;
    }
    return NO;
}

- (BOOL)isValidRect:(CGRect)rect {
    if (isnan(rect.origin.x) || isnan(rect.origin.y) || isnan(rect.size.width) || isnan(rect.size.height)) {
        return NO;
    }
    return YES;
}

#pragma mark - util

- (void)configTouchPointForShowBubble
{
    if (CGPointEqualToPoint(self.touchPoint, CGPointZero) ) {
        self.touchPoint = CGPointMake(self.acc_width / 2, self.acc_height/2);
    }
}

@end
