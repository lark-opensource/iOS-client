//
//  ACCImageAlbumSafeAreaPlugin.m
//  CameraClient-Pods-AwemeCore
//
//  Created by yangguocheng on 2021/10/9.
//

#import "ACCImageAlbumSafeAreaPlugin.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>

@implementation ACCImageAlbumSafeAreaPlugin

- (void)playerFrameChange:(CGRect)playerFrame
{
    [super playerFrameChange:playerFrame];

    self.bottomGuideLine.acc_top = self.bottomGuideLine.acc_top + 83; // image album have a more higher bottom line of safe area, due to it's player size is smaller than video, but PM wants to align the bottom line to the videos

    CGFloat materialHeightInContainer= -1;
    if (self.materialSize.width > 0) {
        materialHeightInContainer = self.materialSize.height * ([self.stickerContainer containerView].acc_width / self.materialSize.width) ;
    }
    if (materialHeightInContainer == -1) {
        return;
    }
    self.bottomGuideLine.acc_top = MIN(self.bottomGuideLine.acc_top, [self.stickerContainer containerView].acc_height / 2.f + materialHeightInContainer / 2.f);
    self.topGuideLine.acc_bottom = MAX(self.topGuideLine.acc_bottom, [self.stickerContainer containerView].acc_height / 2.f - materialHeightInContainer / 2.f);
}

@end
