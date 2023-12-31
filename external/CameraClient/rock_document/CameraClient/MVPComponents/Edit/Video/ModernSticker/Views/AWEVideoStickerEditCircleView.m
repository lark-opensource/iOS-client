//
//  AWEVideoStickerEditCircleView.m
//  AWEStudio
//
//  Created by guochenxiang on 2018/9/25.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEVideoStickerEditCircleView.h"
#import <CreativeKit/UIImageView+ACCAddtions.h>
#import "AWEEditStickerBubbleManager.h"
#import "AWEEditStickerHintView.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <Masonry/View+MASAdditions.h>
#import "IESInfoSticker+ACCAdditions.h"
#import <CreationKitArch/ACCRepoContextModel.h>

static const CGFloat kVideoStickerEditCircleViewPadding = 12;
static const CGFloat kVideoStickerEditCircleViewEdgeInset = 22;

static const CGFloat kAWEVideoStickerEditViewCenterHelperLineWidth = 1.f;
static const CGFloat kAWEVideoStickerEditViewCenterHelperLineLength = 2000.f;

@interface AWEVideoStickerEditCircleView() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *borderView;
//水平居中的虚线，当达到特定角度时展示，比如0, 45 90 135
@property (nonatomic, strong) CAShapeLayer *centerHorizontalDashLayer;
@property (nonatomic, assign, readwrite) NSInteger stickerEditId;

@property (nonatomic, assign) BOOL isActiveBefore;
@property (nonatomic, assign) BOOL isForImage; // 为图片添加信息化贴纸
// --- 新交互的气泡
@property (nonatomic, weak, readonly) AWEEditStickerBubbleManager *bubble;
@property (nonatomic, copy) NSArray<AWEEditStickerBubbleItem *> *bubbleItems;
@property (nonatomic, assign) CGPoint touchPoint;

//backup
@property (nonatomic, assign, readwrite) CGRect backupBounds;
@property (nonatomic, strong, readwrite) IESInfoStickerProps *backupStickerInfos;

@end

@implementation AWEVideoStickerEditCircleView

@synthesize isLyricSticker;

- (instancetype)initWithFrame:(CGRect)frame isForImage:(BOOL)isForImage
{
    if (self = [super initWithFrame:frame]) {
        _stickerEditId = -1;
        _isForImage = isForImage;
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = YES;
    CGFloat edgeInset = -([self linePadding] + [self edgeInset]);
    self.acc_hitTestEdgeInsets = UIEdgeInsetsMake(edgeInset, edgeInset, edgeInset, edgeInset);

    [self addSubview:self.borderView];
    [self setupDashLineLayers];

    ACCMasMaker(self.borderView, {
        make.top.leading.equalTo(self).offset(-[self linePadding]);
        make.size.mas_equalTo(CGSizeMake(self.bounds.size.width + 2 * [self linePadding], self.bounds.size.height + 2 * [self linePadding]));
    });
    
}

- (void)setupDashLineLayers {
    [self.layer addSublayer:self.centerHorizontalDashLayer];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self refreshDashLayerFrame];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self refreshDashLayerFrame];
}

- (void)refreshDashLayerFrame {
    CGRect rect =  CGRectMake(- kAWEVideoStickerEditViewCenterHelperLineLength / 2.f,
               (self.bounds.size.height-1)/2.f,
               kAWEVideoStickerEditViewCenterHelperLineLength,
               kAWEVideoStickerEditViewCenterHelperLineWidth);
    if (![self isValidRect:rect]) {
        return;
    }
    CATransform3D transform = self.centerHorizontalDashLayer.transform;
    self.centerHorizontalDashLayer.transform = CATransform3DIdentity;
    self.centerHorizontalDashLayer.frame = rect;
    self.centerHorizontalDashLayer.hidden = YES;
    self.centerHorizontalDashLayer.transform = transform;
}

- (void)setTransform:(CGAffineTransform)transform {
    [super setTransform:transform];
    // 保证dashLineLayer在外部缩放的同时效果不变
    CGFloat aimedScale = 1 / sqrt(transform.a*transform.a + transform.c*transform.c);
    CGAffineTransform aimedTransform = CGAffineTransformMakeScale(aimedScale, aimedScale);
    self.centerHorizontalDashLayer.affineTransform = aimedTransform;
}

- (void)backupLocationInfo
{
    [self backupLocation];
    self.backupBounds = self.bounds;
    
    self.backupStickerInfos = [IESInfoStickerProps new];
    self.backupStickerInfos.stickerId = self.stickerInfos.stickerId;
    self.backupStickerInfos.angle = self.stickerInfos.angle;
    self.backupStickerInfos.offsetX = self.stickerInfos.offsetX;
    self.backupStickerInfos.offsetY = self.stickerInfos.offsetY;
    self.backupStickerInfos.scale = self.stickerInfos.scale;
    self.backupStickerInfos.alpha = self.stickerInfos.alpha;
    
    
    self.backupStickerInfos.startTime = self.stickerInfos.startTime;
    self.backupStickerInfos.duration = self.stickerInfos.duration;
    self.backupStickerInfos.userInfo = [self.stickerInfos.userInfo copy];
    self.backupStickerInfos.pinStatus = self.stickerInfos.pinStatus;
    self.backupStickerInfos.srtColor = self.stickerInfos.srtColor;
    self.backupStickerInfos.srtFontPath = self.stickerInfos.srtFontPath;
    self.backupStickerInfos.srt = self.stickerInfos.srt;
    self.backupStickerInfos.srtStartTime = self.stickerInfos.srtStartTime;
}

#pragma mark - Getters

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
        _borderView.backgroundColor = [UIColor clearColor];
        _borderView.layer.borderColor = ACCResourceColor(ACCUIColorConstBGContainer).CGColor;
        _borderView.layer.borderWidth = 1.f;
        _borderView.hidden = YES;
    }
    return _borderView;
}

- (CAShapeLayer *)centerHorizontalDashLayer {
    if (!_centerHorizontalDashLayer) {
        CAShapeLayer *dashLineLayer = [CAShapeLayer layer];
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, &CGAffineTransformIdentity, 0, 0);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, kAWEVideoStickerEditViewCenterHelperLineLength, 0);
        dashLineLayer.path = path;
        dashLineLayer.lineWidth = kAWEVideoStickerEditViewCenterHelperLineWidth;
        dashLineLayer.lineDashPattern = @[@4, @4];
        dashLineLayer.lineCap = kCALineCapButt;
        dashLineLayer.strokeColor = ACCResourceColor(ACCUIColorConstSecondary).CGColor;
        _centerHorizontalDashLayer = dashLineLayer;
        CGPathRelease(path);
    }
    return _centerHorizontalDashLayer;
}

- (NSInteger)stickerEditId
{
    return self.stickerInfos.stickerId;
}

- (BOOL)isActive
{
    return !self.borderView.hidden;
}

- (AWEEditStickerBubbleManager *)bubble {
    AWEEditStickerBubbleManager *bubble = [AWEEditStickerBubbleManager videoStickerBubbleManager];
    if (!self.bubbleItems) {
        NSMutableArray *items = [NSMutableArray array];
        @weakify(self)
        if ([self.delegate respondsToSelector:@selector(publishModel)]) {
            AWEVideoPublishViewModel *publishModel = [self.delegate publishModel];
            // status页面屏蔽Pin
            if (publishModel.repoContext.videoType != AWEVideoTypeStory && publishModel.repoContext.videoType != AWEVideoTypeStoryPicture) {
                AWEEditStickerBubbleItem *pinSticker = [[AWEEditStickerBubbleItem alloc] initWithImage:ACCResourceImage(@"icEditPageStickerPin") title:ACCLocalizedString(@"creation_edit_sticker_pin", @"Pin") actionBlock:^{
                    @strongify(self);
                    [self.bubble setBubbleVisible:NO animated:NO];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self clickPinStickerButton];
                    });
                    //不再提醒
                    [AWEEditStickerHintView setNoNeedShowForType:AWEEditStickerHintTypeInfo];
                }];
                [items addObject:pinSticker];
            }
        }
        AWEEditStickerBubbleItem *selectTime = [[AWEEditStickerBubbleItem alloc] initWithImage:ACCResourceImage(@"icCameraStickerTimeNew") title:ACCLocalizedString(@"creation_edit_sticker_duration", @"") actionBlock:^{
            @strongify(self)
            // fix:(点击气泡，进入时长设置页面之后再返回 会有遗留的气泡)  选时长会先截个屏,等下一个runloop再执行先让气泡消失
            [self.bubble setBubbleVisible:NO animated:NO];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self clickSelectTimeButton];
            });
            //不再提醒
            [AWEEditStickerHintView setNoNeedShowForType:AWEEditStickerHintTypeInfo];
        }];
        [items addObject:selectTime];
        self.bubbleItems = items.copy;
    }
    bubble.bubbleItems = self.bubbleItems;
    return bubble;
}

 - (void)setStickerInfos:(IESInfoStickerProps *)stickerInfos
{
    _stickerInfos = stickerInfos;
    self.realStartTime = stickerInfos.startTime;
    self.realDuration = stickerInfos.duration;
}

#pragma mark - Event Handling

- (void)clickSelectTimeButton
{
    [self resignActive];
    self.finalStartTime = self.realStartTime;
    self.finalDuration = self.realDuration;
    if ([self.delegate respondsToSelector:@selector(editorSticker:clickedSelectTimeButton:)]) {
        [self.delegate editorSticker:self clickedSelectTimeButton:nil];
    }
}

- (void)clickPinStickerButton {
    [self resignActive];
    if ([self.delegate respondsToSelector:@selector(editorSticker:clickedPinStickerButton:)]) {
        [self.delegate editorSticker:self clickedPinStickerButton:nil];
    }
}

#pragma mark - Status Management

- (void)becomeActive
{
    self.borderView.hidden = NO;
    // show bubble
    UIView *parentView = ACCBLOCK_INVOKE(self.bubble.defaultTargetView);
    CGAffineTransform transform = self.transform;
    self.transform = CGAffineTransformIdentity;
    [self updateUI];
    [self setNeedsLayout];
    [self layoutIfNeeded];
    CGRect rect = [self convertRect:self.borderView.frame toView:parentView];
    self.transform = transform;
    CGPoint point = [self convertPoint:self.touchPoint toView:parentView];
    [self.bubble setRect:rect touchPoint:point transform:self.transform inParentView:parentView];
    [self.bubble setBubbleVisible:YES animated:YES];
}

- (void)resignActive
{
    if ([self.delegate respondsToSelector:@selector(resignActiveFinished)]) {
        [self.delegate resignActiveFinished];
    }
    self.borderView.hidden = YES;
    [self.bubble setBubbleVisible:NO animated:YES];
}

- (void)backupActive
{
    if (self.gestureManager.gestureActiveStatus != AWEGestureActiveTypeNone) {
        return;
    }
    if (!self.borderView.hidden) {
        [self resignActive];
    }
}

- (void)restoreActive
{
    [self.bubble setBubbleVisible:NO animated:NO];
}

#pragma mark - Sizing

- (BOOL)setBounds:(CGRect)bounds scale:(CGFloat)scale
{
    BOOL isValidSize = (bounds.size.width > [self edgeInset] && bounds.size.height > [self edgeInset]);
    
    // "lyric sticker" has some case : that the size changes after the transform is set, so we can't simply judge with size
    if(self.isLyricSticker &&
       [self isValidRect:bounds] &&
       !CGAffineTransformIsIdentity(self.transform)) {
        
    }

    if ([self isMagnifierSticker] && bounds.size.width > self.superview.bounds.size.width) {
        return NO;
    }
    
    if (isValidSize) {
        if (![self isValidRect:bounds]) {
            return NO;
        }
        [self setBounds:bounds];
        [self updateUI];
        return YES;
    }
    return NO;
}

- (void)updateBorderCenter:(CGPoint)center
{
    if (!CGPointEqualToPoint(self.center, center)) {
        self.center = center;
    }
}

- (CGFloat)linePadding
{
    return kVideoStickerEditCircleViewPadding;
}

- (void)updateUI
{
    ACCMasUpdate(self.borderView, {
        make.size.mas_equalTo(CGSizeMake(self.bounds.size.width + 2 * [self linePadding], self.bounds.size.height + 2 * [self linePadding]));
    });
}

- (CGFloat)edgeInset
{
    return kVideoStickerEditCircleViewEdgeInset;
}

+ (CGFloat)linePadding
{
    return kVideoStickerEditCircleViewPadding;
}

#pragma mark -

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    self.touchPoint = point;
    return nil;
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    if (nil == self.window) {
        // fix AME-84279
        [self.bubble setBubbleVisible:NO animated:NO];
    }
}

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

- (void)hideHandle {
    // 临时解决gestureSticker unrecognized sel的问题
}

- (BOOL)isValidRect:(CGRect)rect {
    if (isnan(rect.origin.x) || isnan(rect.origin.y) || isnan(rect.size.width) || isnan(rect.size.height)) {
        return NO;
    }
    return YES;
}

- (BOOL)isMagnifierSticker
{
    return self.stickerInfos.userInfo.acc_stickerType == ACCEditEmbeddedStickerTypeMagnifier;
}

@end
