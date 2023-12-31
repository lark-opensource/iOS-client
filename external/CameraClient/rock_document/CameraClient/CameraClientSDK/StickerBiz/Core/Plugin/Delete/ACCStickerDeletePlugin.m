//
//  ACCStickerDeletePlugin.m
//  CameraClient
//
//  Created by Yangguocheng on 2020/6/5.
//

#import "ACCStickerDeletePlugin.h"
#import "AWEStoryDeleteView.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitArch/AWEFeedBackGenerator.h>
#import <CreativeKitSticker/ACCBaseStickerView.h>
#import "ACCStickerBizDefines.h"
#import "ACCCommonStickerConfig.h"
#import "ACCStickerDeleteView.h"
#import "ACCConfigKeyDefines.h"
#import "ACCStickerEditContentProtocol.h"

@interface ACCStickerDeletePlugin ()

@property (nonatomic, strong) UIView<ACCStickerDeleteViewProtocol> *deleteView;
@property (nonatomic, assign) BOOL isInDeleting;

@end

@implementation ACCStickerDeletePlugin
@synthesize stickerContainer = _stickerContainer;

+ (instancetype)createPlugin
{
    return [[ACCStickerDeletePlugin alloc] init];
}

- (void)loadPlugin
{
    self.deleteView.acc_centerX = CGRectGetMidX([self.stickerContainer containerView].bounds);
}

- (UIView *)pluginView
{
    return self.deleteView;
}

- (UIView<ACCStickerDeleteViewProtocol> *)deleteView
{
    if (!_deleteView) {
        if (ACCConfigBool(ACCConfigBOOL__sticker_delete_new_style)) {
            _deleteView = [[ACCStickerDeleteView alloc] init];
        } else {
            _deleteView = [[AWEStoryDeleteView alloc] init];
        }
        _deleteView.alpha = 0;
    }
    return _deleteView;
}

- (void)playerFrameChange:(CGRect)playerFrame
{

}

- (void)didChangeLocationWithOperationStickerView:(UIView *)stickerView
{
    
}


- (void)sticker:(ACCBaseStickerView *)stickerView willHandleGesture:(UIGestureRecognizer *)gesture
{
    if (self.stickerContainer.contextID != nil) {
        return;
    }
    if ([gesture isKindOfClass:[UIPanGestureRecognizer class]] && gesture.state == UIGestureRecognizerStateBegan) {
        if (![[stickerView bizStickerConfig].deleteable isEqual:@(NO)]) {
            [self.deleteView onDeleteActived];
        }
    }
}

- (void)sticker:(ACCBaseStickerView *)stickerView didHandleGesture:(UIGestureRecognizer *)gesture
{
    if (self.stickerContainer.contextID != nil) {
        return;
    }
    if ([[stickerView bizStickerConfig].deleteable isEqual:@(NO)]) {
        return;
    }

    BOOL isInDeleteRect = NO;
    CGRect rect = [[self.deleteView class] handleFrame];

    // 如果是投票贴纸的话，deleteView需要在顶部安全线之下
    // If typeId is ACCStickerTypeIdPoll, then deleteView needs an adjustment
    BOOL needToAdjust = [stickerView.config.typeId isEqualToString:ACCStickerTypeIdPoll]
    || [stickerView.config.typeId isEqualToString:ACCStickerTypeIdLive]
    || [stickerView.config.typeId isEqualToString:ACCStickerTypeIdVideoReply]
    || [stickerView.config.typeId isEqualToString:ACCStickerTypeIdVideoComment]
    || [stickerView.config.typeId isEqualToString:ACCStickerTypeIdVideoReplyComment];
    rect.origin.y = [[self.deleteView class] recommendTopWithAdjustment:needToAdjust];
    self.deleteView.acc_top = [[self.deleteView class] recommendTopWithAdjustment:needToAdjust];

    rect = [[UIApplication sharedApplication].keyWindow convertRect:rect toView:stickerView.superview];
    CGPoint currentPoint = [gesture locationInView:stickerView.superview];
    if (CGRectContainsPoint(rect, currentPoint)) {
        isInDeleteRect = YES;
    }
    CGRect intersectionRect = CGRectIntersection(self.stickerContainer.playerRect, stickerView.frame);
    if (CGRectIsNull(intersectionRect) || CGRectGetWidth(intersectionRect) <= 1 / [UIScreen mainScreen].scale || CGRectGetHeight(intersectionRect) <= 1 / [UIScreen mainScreen].scale) {
        isInDeleteRect = YES;
    }

    if (isInDeleteRect) {
        [self.deleteView startAnimation];
        stickerView.alpha = 0.34;
        ACCCommonStickerConfig *config = [stickerView bizStickerConfig];
        if (config.isInDeleteStateCallback) {
            config.isInDeleteStateCallback();
        }
    } else {
        [self.deleteView stopAnimation];
        stickerView.alpha = 1;
    }
    
    if (isInDeleteRect ^ self.isInDeleting) {
        [[AWEFeedBackGenerator sharedInstance] doFeedback];
    }
    self.isInDeleting = isInDeleteRect;
}

- (void)sticker:(ACCBaseStickerView *)stickerView didEndGesture:(UIGestureRecognizer *)gesture
{
    if (self.stickerContainer.contextID != nil) {
        return;
    }
    if (self.isInDeleting) {
        if ([[stickerView contentView] conformsToProtocol:@protocol(ACCStickerEditContentProtocol)]) {
            UIView<ACCStickerEditContentProtocol> *contentView = (UIView<ACCStickerEditContentProtocol> *)[stickerView contentView];
            if ([contentView respondsToSelector:@selector(triggerDragDeleteCallback)]) {
                if (contentView.triggerDragDeleteCallback != nil) {
                    contentView.triggerDragDeleteCallback();
                }
            }
        }
        [self.stickerContainer removeStickerView:stickerView];
        self.isInDeleting = NO; // will refactor without flag using internal logic within delete view's state change
    }
    if (![[stickerView bizStickerConfig].deleteable isEqual:@(NO)]) {
        [self.deleteView onDeleteInActived];
    }
}

- (BOOL)featureSupportForType:(id)typeId
{
    return typeId != ACCStickerTypeIdCanvas && typeId != ACCStickerTypeIdKaraoke;
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
    return ACCStickerContainerFeatureReserved;
}

@end
