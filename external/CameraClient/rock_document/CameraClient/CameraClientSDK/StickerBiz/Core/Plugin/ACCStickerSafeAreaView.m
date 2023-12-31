//
//  ACCStickerSafeAreaView.m
//  CameraClient
//
//  Created by guocheng on 2020/5/26.
//

#import "ACCStickerSafeAreaView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import "AWEXScreenAdaptManager.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKitSticker/ACCBaseStickerView.h>
#import "ACCStickerBizDefines.h"
#import "ACCCommonStickerConfig.h"

CGFloat const ACCStickerContainerSafeAreaLineWidth = 1.5f;

typedef NS_OPTIONS(NSInteger, ACCStickerContainerSafeAreaLine) {
    ACCStickerContainerSafeAreaLineNone = 0,
    ACCStickerContainerSafeAreaLineLeft = 1 << 0,
    ACCStickerContainerSafeAreaLineBottom = 1 << 1,
    ACCStickerContainerSafeAreaLineRight = 1 << 2,
    ACCStickerContainerSafeAreaLineTop = 1 << 3,
};

@interface ACCStickerSafeAreaView ()

@property (nonatomic, strong) UIView *leftGuideLine;
@property (nonatomic, strong) UIView *rightGuideLine;
@property (nonatomic, strong) UIView *bottomGuideLine;
@property (nonatomic, strong) UIView *topGuideLine;

@property (nonatomic, assign) CGAffineTransform previousTransform;
@property (nonatomic, assign) CGPoint previousCenter;
@property (nonatomic, assign) CGFloat previousScale;

@property (nonatomic, assign) CGFloat currentGestureScale;

@property (nonatomic, assign) ACCStickerContainerSafeAreaLine guideLineState;

@end

@implementation ACCStickerSafeAreaView

@synthesize stickerContainer = _stickerContainer;

+ (instancetype)createPlugin
{
    return [[self alloc] initWithFrame:CGRectZero];
}

- (void)loadPlugin
{
    self.frame = [self.stickerContainer containerView].bounds;
    _leftGuideLine = [self createLine];
    [self addSubview:_leftGuideLine];
    _rightGuideLine = [self createLine];
    [self addSubview:_rightGuideLine];
    _bottomGuideLine = [self createLine];
    [self addSubview:_bottomGuideLine];
    _topGuideLine = [self createLine];
    [self addSubview:_topGuideLine];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

- (void)playerFrameChange:(CGRect)playerFrame
{
    [self updateWithPlayerFrame:playerFrame playerPreviewView:self.stickerContainer.playerPreviewView];
}

- (UIView *)pluginView
{
    return self;
}

- (void)updateWithPlayerFrame:(CGRect)playerFrame playerPreviewView:(UIView *)previewView
{
    CGFloat wGap = 0.f;
    // adaption for mask horizontally
    if (playerFrame.size.width > 0 && playerFrame.size.height > 0 && self.acc_width > playerFrame.size.width) {
        wGap = (self.acc_width - playerFrame.size.width) / 2;
    }
    CGFloat lineWidth = ACCStickerContainerSafeAreaLineWidth;
    self.leftGuideLine.frame = CGRectMake(20.f + wGap, 0, lineWidth, self.acc_height);
    self.rightGuideLine.frame = CGRectMake(self.acc_width - lineWidth - 56.f - wGap, 0, lineWidth, self.acc_height);

    CGFloat bottomOffset = -200;
    if (@available(iOS 11.0,*)) {
        if ([AWEXScreenAdaptManager needAdaptScreen]) {
            bottomOffset = - ACC_IPHONE_X_BOTTOM_OFFSET - 73 - 130;
            if ([UIDevice acc_isIPhoneXsMax]) {
                bottomOffset = - ACC_IPHONE_X_BOTTOM_OFFSET - 85 - 130;
            }
        }
    }

    CGFloat topOffset = 48;
    if (@available(iOS 11.0,*)) {
        if ([AWEXScreenAdaptManager needAdaptScreen]) {
            topOffset = 64;
        }
    }

    self.bottomGuideLine.frame = CGRectMake(0, self.acc_height + bottomOffset, self.acc_width, lineWidth);
    self.topGuideLine.frame = CGRectMake(0, ACC_STATUS_BAR_NORMAL_HEIGHT + topOffset, self.acc_width, lineWidth);

    [self showLeftGuideLine:NO];
    [self showRightGuideLine:NO];
    [self showBottomGuideLine:NO];
    [self showTopGuideLine:NO];
}

#pragma mark - Guides

BOOL acc_greaterThan(CGFloat one, CGFloat other)
{
    return (NSInteger)(one * 100) > (NSInteger)(other * 100);
}

BOOL acc_lessThan(CGFloat one, CGFloat other)
{
    return (NSInteger)(one * 100) < (NSInteger)(other * 100);
}

- (void)checkAlignLineForStickerView:(UIView *)stickerView
{
    if (acc_greaterThan(stickerView.acc_left, self.leftGuideLine.acc_right + 1)) {
        [self showLeftGuideLine:NO];
    } else {
        [self showLeftGuideLine:YES];
    }
    if (acc_lessThan(stickerView.acc_right, self.rightGuideLine.acc_left - 1)) {
        [self showRightGuideLine:NO];
    } else {
        [self showRightGuideLine:YES];
    }
    if (acc_lessThan(stickerView.acc_bottom, self.bottomGuideLine.acc_top - 1)) {
        [self showBottomGuideLine:NO];
    } else {
        [self showBottomGuideLine:YES];
    }
    if (acc_greaterThan(stickerView.acc_top, self.topGuideLine.acc_bottom + 1)) {
        [self showTopGuideLine:NO];
    } else {
        [self showTopGuideLine:YES];
    }
}

- (void)showLeftGuideLine:(BOOL)show
{
    if (self.leftGuideLine.hidden && show) {
        [self generateLightImpactFeedBack];
    }
    [self applyLineBitMask:ACCStickerContainerSafeAreaLineLeft shouldSet:show];
}

- (void)showRightGuideLine:(BOOL)show
{
    if (self.rightGuideLine.hidden && show) {
        [self generateLightImpactFeedBack];
    }
    [self applyLineBitMask:ACCStickerContainerSafeAreaLineRight shouldSet:show];
}

- (void)showBottomGuideLine:(BOOL)show
{
    if (self.bottomGuideLine.hidden && show) {
        [self generateLightImpactFeedBack];
    }
    [self applyLineBitMask:ACCStickerContainerSafeAreaLineBottom shouldSet:show];
}

- (void)showTopGuideLine:(BOOL)show
{
    if (self.topGuideLine.hidden & show) {
        [self generateLightImpactFeedBack];
    }
    [self applyLineBitMask:ACCStickerContainerSafeAreaLineTop shouldSet:show];
}

- (void)applyLineBitMask:(ACCStickerContainerSafeAreaLine)mask shouldSet:(BOOL)shouldSet
{
    ACCStickerContainerSafeAreaLine newState;
    if (shouldSet) {
        newState = self.guideLineState | mask;
    } else {
        newState = self.guideLineState & ~mask;
    }

    [self updateGuideLineWithState:newState animated:NO];
}

- (void)updateGuideLineWithState:(ACCStickerContainerSafeAreaLine)state animated:(BOOL)animated
{
    self.guideLineState = state;
    NSMutableArray *viewsToHide = [NSMutableArray array];
    NSMutableArray *viewsToDisplay = [NSMutableArray array];

    void (^updateVisableState)(UIView *theView, BOOL shouldDisplay) = ^void(UIView *theView, BOOL shouldDisplay) {
        if (shouldDisplay) {
            if (theView.hidden == NO) {
                // the target view is visiable already, no need to update.
            } else {
                [viewsToDisplay addObject:theView];
            }
        } else {
            if (theView.hidden == NO) {
                [viewsToHide addObject:theView];
            } else {
                // the target view is invisiable already, no need to update.
            }
        }
    };

    if (state & ACCStickerContainerSafeAreaLineLeft) {
        updateVisableState(self.leftGuideLine, YES);
    } else {
        updateVisableState(self.leftGuideLine, NO);
    }

    if (state & ACCStickerContainerSafeAreaLineRight) {
        updateVisableState(self.rightGuideLine, YES);
    } else {
        updateVisableState(self.rightGuideLine, NO);
    }

    if (state & ACCStickerContainerSafeAreaLineBottom) {
        updateVisableState(self.bottomGuideLine, YES);
    } else {
        updateVisableState(self.bottomGuideLine, NO);
    }

    if (state & ACCStickerContainerSafeAreaLineTop) {
        updateVisableState(self.topGuideLine, YES);
    } else {
        updateVisableState(self.topGuideLine, NO);
    }

    if (animated) {
        for (UIView *aView in viewsToDisplay) {
            aView.hidden = NO;
        }
        [UIView animateWithDuration:0.2f animations:^{
            for (UIView *aView in viewsToHide) {
                aView.hidden = YES;
                aView.alpha = 0.0f;
            }

            for (UIView *aView in viewsToDisplay) {
                aView.alpha = 1.0f;
            }
        }];
    } else {
        for (UIView *aView in viewsToDisplay) {
            aView.hidden = NO;
            aView.alpha = 1.0f;
        }

        for (UIView *aView in viewsToHide) {
            aView.hidden = YES;
            aView.alpha = 0.0f;
        }
    }
}

- (void)generateLightImpactFeedBack
{
    if (self.leftGuideLine.hidden == NO || self.rightGuideLine.hidden == NO || self.bottomGuideLine.hidden == NO) {
        return;
    }
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *fbGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [fbGenerator prepare];
        [fbGenerator impactOccurred];
    }
}

- (UIView *)createLine
{
    UIView *line = [[UIView alloc] init];
    line.translatesAutoresizingMaskIntoConstraints = NO;
    line.backgroundColor = ACCResourceColor(ACCUIColorConstSecondary);
    return line;
}

- (CGPoint)fixOperatingStickerView:(ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *)stickerView withWillChangeLocationWithCenter:(CGPoint)newCenter
{
    return [self fixStickerView:stickerView withWillChangeLocationWithCenter:newCenter];
}

- (CGPoint)fixStickerView:(UIView *)stickerView withWillChangeLocationWithCenter:(CGPoint)newCenter
{
    if (newCenter.x - [stickerView acc_centerToBorderDirection:ACCViewDirectionLeft] < self.leftGuideLine.acc_right ||
        stickerView.acc_left < self.leftGuideLine.acc_right) {
        newCenter.x = MAX(self.leftGuideLine.acc_right + [stickerView acc_centerToBorderDirection:ACCViewDirectionLeft], newCenter.x);
    }

    if (newCenter.x + [stickerView acc_centerToBorderDirection:ACCViewDirectionRight] > self.rightGuideLine.acc_left ||
        stickerView.acc_right > self.rightGuideLine.acc_left) {
        newCenter.x = MIN(self.rightGuideLine.acc_left - [stickerView acc_centerToBorderDirection:ACCViewDirectionRight], newCenter.x);
    }

    if (newCenter.y + [stickerView acc_centerToBorderDirection:ACCViewDirectionBottom] > self.bottomGuideLine.acc_top ||
        stickerView.acc_bottom > self.bottomGuideLine.acc_top) {
        newCenter.y = MIN(self.bottomGuideLine.acc_top - [stickerView acc_centerToBorderDirection:ACCViewDirectionBottom], newCenter.y);
    }

    if (newCenter.y - [stickerView acc_centerToBorderDirection:ACCViewDirectionTop] < self.topGuideLine.acc_bottom ||
        stickerView.acc_top < self.topGuideLine.acc_bottom) {
        newCenter.y = MAX(self.topGuideLine.acc_bottom + [stickerView acc_centerToBorderDirection:ACCViewDirectionTop], newCenter.y);
    }

    return newCenter;

}

- (BOOL)checkSafeWithStickerView:(UIView *)stickerView
{
    BOOL leftLimit = acc_lessThan(ceilf(stickerView.acc_left), floorf(self.leftGuideLine.acc_right));
    BOOL rightLimit = acc_greaterThan(floorf(stickerView.acc_right), ceilf(self.rightGuideLine.acc_left));
    BOOL bottomLimit = acc_greaterThan(floorf(stickerView.acc_bottom), ceilf(self.bottomGuideLine.acc_top));
    BOOL topLimit = acc_lessThan(ceilf(stickerView.acc_top), floorf(self.topGuideLine.acc_bottom));
    if (leftLimit || rightLimit || bottomLimit || topLimit) {
        return NO;
    }
    return YES;
}

- (void)didChangeLocationWithOperationStickerView:(UIView *)stickerView
{
    [self checkAlignLineForStickerView:stickerView];
}

- (void)sticker:(ACCBaseStickerView <ACCGestureResponsibleStickerProtocol> *)stickerView willHandleGesture:(UIGestureRecognizer *)gesture
{
    if ([gesture isKindOfClass:[UIPinchGestureRecognizer class]] || [gesture isKindOfClass:[UIRotationGestureRecognizer class]]) {
        self.previousTransform = stickerView.transform;
        self.previousCenter = stickerView.center;
        if ([stickerView conformsToProtocol:@protocol(ACCGestureResponsibleStickerProtocol)]) {
            self.previousScale = stickerView.currentScale;
        }
        if ([gesture isKindOfClass:[UIPinchGestureRecognizer class]]) {
            CGFloat maxScale = [stickerView acc_maxScaleWithinRect:CGRectMake(self.leftGuideLine.acc_right, 0, self.rightGuideLine.acc_left - self.leftGuideLine.acc_right, self.bottomGuideLine.acc_top)];
            if (maxScale > 1 && maxScale < ((UIPinchGestureRecognizer *)gesture).scale && ((UIPinchGestureRecognizer *)gesture).scale > 1) {
                ((UIPinchGestureRecognizer *)gesture).scale = maxScale;
            }
            self.currentGestureScale = ((UIPinchGestureRecognizer *)gesture).scale;
        } else if ([gesture isKindOfClass:[UIRotationGestureRecognizer class]]) {

        }
    }
}

- (void)sticker:(ACCBaseStickerView <ACCGestureResponsibleStickerProtocol> *)stickerView didHandleGesture:(UIGestureRecognizer *)gesture
{
    if ([gesture isKindOfClass:[UIPinchGestureRecognizer class]] || [gesture isKindOfClass:[UIRotationGestureRecognizer class]]) {
        if (![self checkSafeWithStickerView:stickerView] && (self.currentGestureScale > 1 || [gesture isKindOfClass:[UIRotationGestureRecognizer class]])) {
            stickerView.center = _previousCenter;
            stickerView.transform = _previousTransform;
            if ([stickerView conformsToProtocol:@protocol(ACCGestureResponsibleStickerProtocol)]) {
                stickerView.currentScale = _previousScale;
            }
        }
        self.previousTransform = CGAffineTransformIdentity;
        self.previousCenter = CGPointZero;
        self.previousScale = 1;
        self.currentGestureScale = 1;
    }
}

- (void)sticker:(nonnull ACCBaseStickerView *)stickerView didEndGesture:(nonnull UIGestureRecognizer *)gesture
{
    [self showLeftGuideLine:NO];
    [self showRightGuideLine:NO];
    [self showBottomGuideLine:NO];
    [self showTopGuideLine:NO];
}

- (BOOL)featureSupportSticker:(id<ACCStickerProtocol>)sticker
{
    if (![sticker.config isKindOfClass:[ACCCommonStickerConfig class]]) {
        return NO;
    }
    return [self implementedContainerFeature] & ((ACCCommonStickerConfig *)sticker.config).preferredContainerFeature;
}

- (ACCStickerContainerFeature)implementedContainerFeature
{
    return ACCStickerContainerFeatureSafeArea;
}

@end
