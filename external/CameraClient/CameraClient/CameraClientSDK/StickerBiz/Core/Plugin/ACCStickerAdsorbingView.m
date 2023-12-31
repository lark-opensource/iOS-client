//
//  ACCStickerAdsorbingView.m
//  CameraClient
//
//  Created by guocheng on 2020/6/2.
//

#import "ACCStickerAdsorbingView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKitSticker/ACCBaseStickerView.h>
#import "ACCStickerBizDefines.h"
#import "ACCCommonStickerConfig.h"

typedef NS_OPTIONS(NSInteger, ACCStickerAdsorbingLine) {
    ACCStickerAdsorbingLineNone = 0,
    ACCStickerAdsorbingLineCenterH = 1 << 0,
    ACCStickerAdsorbingLineCenterV = 1 << 1,
};

@interface ACCStickerAdsorbingView ()

@property (nonatomic, strong) UIView *centerVerticalGuideLine;
@property (nonatomic, strong) UIView *centerHorizontalGuideLine;

@property (nonatomic, assign) ACCStickerAdsorbingLine guideLineState;

@end

@implementation ACCStickerAdsorbingView
@synthesize stickerContainer;

+ (nonnull instancetype)createPlugin
{
    return [[ACCStickerAdsorbingView alloc] initWithFrame:CGRectZero];
}

- (void)loadPlugin
{
    
}

- (UIView *)pluginView
{
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _centerVerticalGuideLine = [self createLine];
        [self addSubview:_centerVerticalGuideLine];
        _centerHorizontalGuideLine = [self createLine];
        [self addSubview:_centerHorizontalGuideLine];
    }
    return self;
}

- (UIView *)createLine
{
    UIView *line = [UIView new];
    line.backgroundColor = ACCResourceColor(ACCUIColorConstSecondary);
    return line;
}

- (void)playerFrameChange:(CGRect)playerFrame
{
    self.frame = playerFrame;
    [self updateWithPlayerFrame:playerFrame playerPreviewView:self.stickerContainer.playerPreviewView];
}

- (void)updateWithPlayerFrame:(CGRect)playerFrame playerPreviewView:(UIView *)previewView
{
    self.centerHorizontalGuideLine.frame = CGRectMake(0, self.acc_width, self.acc_width, 1.5f);
    self.centerHorizontalGuideLine.acc_centerY = self.acc_height / 2.f;

    if ((playerFrame.size.width && playerFrame.size.height) && (playerFrame.size.height <= playerFrame.size.width) && previewView != nil) {
        self.centerVerticalGuideLine.frame = CGRectMake(0, previewView.acc_top, 1.5f, previewView.acc_height);
    } else {
        self.centerVerticalGuideLine.frame = CGRectMake(0, 0, 1.5f, self.acc_height);
    }
    self.centerVerticalGuideLine.acc_centerX = self.acc_width / 2.f;
    
    [self updateGuideLineWithState:ACCStickerAdsorbingLineNone animated:NO];
}

#pragma mark - Guides

- (void)updateGuideLineWithState:(ACCStickerAdsorbingLine)state animated:(BOOL)animated
{
    self.guideLineState = state;
    NSMutableArray *viewsToHide = [NSMutableArray array];
    NSMutableArray *viewsToDisplay = [NSMutableArray array];
    
    void (^updateVisableState)(UIView *theView, BOOL shouldDisplay) = ^void(UIView *theView, BOOL shouldDisplay) {
        if (shouldDisplay) {
            if (theView.hidden) {
                [viewsToDisplay addObject:theView];
            }
        } else {
            if (theView.hidden == NO) {
                [viewsToHide addObject:theView];
            }
        }
    };
    
    updateVisableState(self.centerHorizontalGuideLine, state & ACCStickerAdsorbingLineCenterH);
    updateVisableState(self.centerVerticalGuideLine, state & ACCStickerAdsorbingLineCenterV);
    
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

- (void)checkAdsorbingStateWithView:(UIView *)view
{
    // center vertical line
    CGPoint anchorDiff = [self anchorDiffWithStickerView:view];
    if (ACC_FLOAT_EQUAL_TO(view.center.x - anchorDiff.x, self.centerVerticalGuideLine.acc_centerX + self.acc_left)) {
        [self updateGuideLineWithState:self.guideLineState | ACCStickerAdsorbingLineCenterV animated:YES];
    } else {
        [self updateGuideLineWithState:self.guideLineState & ~ACCStickerAdsorbingLineCenterV animated:NO];
    }

    // center horizontal line
    if (ACC_FLOAT_EQUAL_TO(view.center.y - anchorDiff.y, self.centerHorizontalGuideLine.acc_centerY + self.acc_top)) {
        [self updateGuideLineWithState:self.guideLineState | ACCStickerAdsorbingLineCenterH animated:YES];
    } else {
        [self updateGuideLineWithState:self.guideLineState & ~ACCStickerAdsorbingLineCenterH animated:NO];
    }
}

- (CGPoint)anchorDiffWithStickerView:(UIView *)stickerView
{
    CGPoint newPoint = CGPointMake(stickerView.bounds.size.width * stickerView.layer.anchorPoint.x,
                                   stickerView.bounds.size.height * stickerView.layer.anchorPoint.y);
    CGPoint oldPoint = CGPointMake(stickerView.bounds.size.width * 0.5,
                                   stickerView.bounds.size.height * 0.5);
    newPoint = CGPointApplyAffineTransform(newPoint, stickerView.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, stickerView.transform);
    return CGPointMake(newPoint.x - oldPoint.x, newPoint.y - oldPoint.y);
}

- (CGPoint)fixOperatingStickerView:(ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *)stickerView withWillChangeLocationWithCenter:(CGPoint)newCenter
{
    CGFloat AdsorbingSensitiveValue = 10.f;
    
    CGPoint anchorDiff = [self anchorDiffWithStickerView:stickerView];
    if (fabs(newCenter.x - anchorDiff.x - (self.centerVerticalGuideLine.acc_centerX + self.acc_left)) <= AdsorbingSensitiveValue) {
        newCenter.x = (self.centerVerticalGuideLine.acc_centerX + self.acc_left) + anchorDiff.x;
    }
    if (fabs(newCenter.y - anchorDiff.y - (self.centerHorizontalGuideLine.acc_centerY + self.acc_top)) <= AdsorbingSensitiveValue) {
        newCenter.y = (self.centerHorizontalGuideLine.acc_centerY + self.acc_top) + anchorDiff.y;
    }
    return newCenter;
}

- (void)didChangeLocationWithOperationStickerView:(UIView *)stickerView
{
    
}

- (void)sticker:(ACCBaseStickerView *)stickerView willHandleGesture:(UIGestureRecognizer *)gesture
{

}

- (void)sticker:(ACCBaseStickerView *)stickerView didHandleGesture:(UIGestureRecognizer *)gesture
{
    if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        [self checkAdsorbingStateWithView:stickerView];
    }
}

- (void)sticker:(ACCBaseStickerView *)stickerView didEndGesture:(UIGestureRecognizer *)gesture
{
    [self updateGuideLineWithState:self.guideLineState & ~ACCStickerAdsorbingLineCenterV animated:NO];
    [self updateGuideLineWithState:self.guideLineState & ~ACCStickerAdsorbingLineCenterH animated:NO];
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
    return ACCStickerContainerFeatureAdsorbing;
}

@end
