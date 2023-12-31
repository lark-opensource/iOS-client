//
//  ACCStickerAutoCaptionsPlugin.m
//  CameraClient
//
//  Created by Yangguocheng on 2020/7/27.
//

#import "ACCStickerAutoCaptionsPlugin.h"
#import <CreativeKitSticker/ACCBaseStickerView.h>
#import "ACCAutoCaptionsTextStickerView.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCStickerBizDefines.h"
#import "ACCCommonStickerConfig.h"

@implementation ACCStickerAutoCaptionsPlugin
@synthesize stickerContainer;

+ (nonnull instancetype)createPlugin
{
    return [[ACCStickerAutoCaptionsPlugin alloc] init];
}

- (ACCStickerContainerFeature)implementedContainerFeature
{
    return ACCStickerContainerFeatureAutoCaptions;
}

- (void)loadPlugin
{

}

- (void)playerFrameChange:(CGRect)playerFrame
{
    
}

- (void)didChangeLocationWithOperationStickerView:(ACCBaseStickerView *)stickerView
{
    
}

- (void)sticker:(ACCBaseStickerView *)stickerView willHandleGesture:(UIGestureRecognizer *)gesture
{
    if ([stickerView.contentView isKindOfClass:[ACCAutoCaptionsTextStickerView class]] &&
        [gesture isKindOfClass:[UIRotationGestureRecognizer class]] ) {
        ((UIRotationGestureRecognizer *)gesture).rotation = 0;
    }
    if ([stickerView.contentView isKindOfClass:[ACCAutoCaptionsTextStickerView class]] &&
        gesture.state == UIGestureRecognizerStateBegan) {
        [stickerView acc_setAnchorPointForRotateAndScale:CGPointMake(0.5, 0.5)];
    }
}

- (void)sticker:(ACCBaseStickerView *)stickerView didHandleGesture:(UIGestureRecognizer *)gesture
{
}

- (void)sticker:(ACCBaseStickerView *)stickerView didEndGesture:(UIGestureRecognizer *)gesture
{
    
}

- (CGPoint)fixOperatingStickerView:(ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *)stickerView withWillChangeLocationWithCenter:(CGPoint)newCenter
{
    // auto captions always center horizontally
    if ([stickerView.contentView isKindOfClass:[ACCAutoCaptionsTextStickerView class]]) {
        newCenter.x = self.stickerContainer.bounds.size.width / 2.f;
    }
    return newCenter;
}

- (BOOL)featureSupportSticker:(id<ACCStickerProtocol>)sticker
{
    if (![sticker.config isKindOfClass:[ACCCommonStickerConfig class]]) {
        return NO;
    }
    return [self implementedContainerFeature] & ((ACCCommonStickerConfig *)sticker.config).preferredContainerFeature;
}

@end
