//
//  ACCStickerDeSelectPlugin.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2020/12/7.
//

#import "ACCStickerDeSelectPlugin.h"
#import <CreativeKitSticker/ACCBaseStickerView.h>

@implementation ACCStickerDeSelectPlugin
@synthesize stickerContainer = _stickerContainer;

+ (instancetype)createPlugin
{
    return [[ACCStickerDeSelectPlugin alloc] init];
}

- (void)loadPlugin
{
    
}

- (void)playerFrameChange:(CGRect)playerFrame
{
    
}

- (void)stickerContainer:(UIView<ACCStickerContainerProtocol> *)container beforeRecognizerGesture:(UIGestureRecognizer *)gesture
{
    if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        for (ACCBaseStickerView *stickerView in self.stickerContainer.allStickerViews) {
            if (stickerView.isSelected) {
                [stickerView doDeselect];
            }
        }
    }
}

- (BOOL)featureSupportSticker:(nonnull id<ACCStickerProtocol>)sticker
{
    return NO;
}

@end
